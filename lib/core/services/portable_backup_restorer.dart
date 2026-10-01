import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import 'attachment_service.dart';
import 'backup_service.dart';
import 'portable_backup_builder.dart';

class PortableBackupRestorer {
  PortableBackupRestorer(
    this._database,
    this._attachmentService,
    this._backupService,
  );

  static final RegExp _taskExtrasKeyPattern = RegExp(r'^task:(\d+):extras$');

  final AppDatabase _database;
  final AttachmentService _attachmentService;
  final BackupService _backupService;

  Future<void> restore(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.find('manifest.json');

    if (manifestFile == null) {
      throw const FormatException('Backup manifest is missing.');
    }

    final manifestBytes = manifestFile.readBytes();

    if (manifestBytes == null) {
      throw const FormatException('Backup manifest is unreadable.');
    }

    final decoded = jsonDecode(utf8.decode(manifestBytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup manifest root must be an object.');
    }

    final version = decoded['formatVersion'];

    if (version != 3 && version != PortableBackupBuilder.formatVersion) {
      throw const FormatException('Unsupported portable backup version.');
    }

    final oldAttachmentPaths = await _collectCurrentManagedAttachments();

    final importedPaths = <String>[];

    try {
      if (version == 3) {
        await _restoreV3(decoded, archive, importedPaths);
      } else {
        await _restoreV4(decoded, archive, importedPaths);
      }
    } catch (_) {
      for (final path in importedPaths.reversed) {
        await _attachmentService.deleteStored(path);
      }

      rethrow;
    }

    final importedSet = importedPaths.toSet();

    for (final oldPath in oldAttachmentPaths) {
      if (!importedSet.contains(oldPath)) {
        await _attachmentService.deleteStored(oldPath);
      }
    }
  }

  // ========================================================
  // V3 BACKWARD COMPATIBILITY
  // ========================================================

  Future<void> _restoreV3(
    Map<String, dynamic> decoded,
    Archive archive,
    List<String> importedPaths,
  ) async {
    final metadata = decoded['metadata'] as List<dynamic>? ?? const <dynamic>[];

    final rewrittenMetadata = await _restorePortableMetadataV3(
      metadata,
      archive,
      importedPaths,
    );

    final restorable = Map<String, dynamic>.from(decoded);

    restorable['formatVersion'] = BackupService.formatVersion;

    restorable['metadata'] = rewrittenMetadata;

    // V3 itself is metadata-based, but schema v6 uses normalized
    // TaskExtras and Focus storage. Restore the historical format
    // first, then normalize recoverable transitional metadata in
    // the same database transaction.
    //
    // Invalid, orphaned, or unrelated metadata is intentionally
    // left untouched for compatibility and manual recovery.
    await _database.transaction(() async {
      await _backupService.restoreFromMap(restorable);

      await _normalizeRestoredV3Metadata();
    });
  }

  Future<void> _normalizeRestoredV3Metadata() async {
    final metadataRows = await _database.select(_database.appMetadata).get();

    for (final metadata in metadataRows) {
      final taskMatch = _taskExtrasKeyPattern.firstMatch(metadata.key);

      if (taskMatch != null) {
        final taskId = int.tryParse(taskMatch.group(1) ?? '');

        if (taskId == null) {
          continue;
        }

        final taskQuery = _database.select(_database.tasks)
          ..where((table) => table.id.equals(taskId));

        final task = await taskQuery.getSingleOrNull();

        // Preserve orphaned legacy metadata.
        if (task == null) {
          continue;
        }

        final extras = _decodeV3TaskExtrasForNormalization(
          taskId,
          metadata.value,
        );

        // Preserve malformed or unsupported legacy metadata.
        if (extras == null) {
          continue;
        }

        await _database
            .into(_database.taskExtrasRows)
            .insertOnConflictUpdate(
              TaskExtrasRowsCompanion.insert(
                taskId: Value(taskId),
                recurrence: Value(extras.recurrence),
                monthlyAnchorDay: Value(extras.monthlyAnchorDay),
                reminderAt: Value(extras.reminderAt),
                reminderRepeatMinutes: Value(extras.reminderRepeatMinutes),
                reminderSnoozedUntil: Value(extras.reminderSnoozedUntil),
              ),
            );

        for (var position = 0; position < extras.tags.length; position++) {
          await _database
              .into(_database.taskTagsRows)
              .insert(
                TaskTagsRowsCompanion.insert(
                  taskId: taskId,
                  position: position,
                  value: extras.tags[position],
                ),
              );
        }

        for (
          var position = 0;
          position < extras.attachments.length;
          position++
        ) {
          await _database
              .into(_database.taskAttachmentsRows)
              .insert(
                TaskAttachmentsRowsCompanion.insert(
                  taskId: taskId,
                  position: position,
                  path: extras.attachments[position],
                ),
              );
        }

        await (_database.delete(
          _database.appMetadata,
        )..where((table) => table.key.equals(metadata.key))).go();

        continue;
      }

      if (metadata.key == 'focus:sessions:v1') {
        final sessions = _decodeV3FocusForNormalization(metadata.value);

        // Preserve malformed focus metadata.
        if (sessions == null) {
          continue;
        }

        for (final session in sessions) {
          await _database
              .into(_database.focusSessionRows)
              .insert(
                FocusSessionRowsCompanion.insert(
                  completedAt: session.completedAt,
                  durationMinutes: session.durationMinutes,
                ),
              );
        }

        await (_database.delete(
          _database.appMetadata,
        )..where((table) => table.key.equals(metadata.key))).go();
      }
    }
  }

  _RestoredTaskExtras? _decodeV3TaskExtrasForNormalization(
    int taskId,
    String rawValue,
  ) {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final recurrence = decoded['recurrence'];

      final monthlyAnchor = decoded['monthlyAnchorDay'];

      final reminderAtRaw = decoded['reminderAt'];

      final repeat = decoded['reminderRepeatMinutes'];

      final snoozedRaw = decoded['reminderSnoozedUntil'];

      final tagsRaw = decoded['tags'];

      final attachmentsRaw = decoded['attachments'];

      if (recurrence != null && recurrence is! String) {
        return null;
      }

      if (monthlyAnchor != null && monthlyAnchor is! num) {
        return null;
      }

      if (repeat != null && repeat is! num) {
        return null;
      }

      DateTime? reminderAt;

      if (reminderAtRaw != null) {
        if (reminderAtRaw is! String) {
          return null;
        }

        reminderAt = DateTime.tryParse(reminderAtRaw);

        if (reminderAt == null) {
          return null;
        }
      }

      DateTime? snoozedUntil;

      if (snoozedRaw != null) {
        if (snoozedRaw is! String) {
          return null;
        }

        snoozedUntil = DateTime.tryParse(snoozedRaw);

        if (snoozedUntil == null) {
          return null;
        }
      }

      if (tagsRaw != null && tagsRaw is! List<dynamic>) {
        return null;
      }

      if (attachmentsRaw != null && attachmentsRaw is! List<dynamic>) {
        return null;
      }

      final tags = <String>[];

      for (final raw in tagsRaw as List<dynamic>? ?? const <dynamic>[]) {
        if (raw is! String) {
          return null;
        }

        tags.add(raw);
      }

      final attachments = <String>[];

      for (final raw in attachmentsRaw as List<dynamic>? ?? const <dynamic>[]) {
        if (raw is! String) {
          return null;
        }

        attachments.add(raw);
      }

      return _RestoredTaskExtras(
        taskId: taskId,
        recurrence: recurrence as String?,
        monthlyAnchorDay: monthlyAnchor is num ? monthlyAnchor.toInt() : null,
        reminderAt: reminderAt,
        reminderRepeatMinutes: repeat is num ? repeat.toInt() : null,
        reminderSnoozedUntil: snoozedUntil,
        tags: tags,
        attachments: attachments,
      );
    } catch (_) {
      return null;
    }
  }

  List<_RestoredFocusSession>? _decodeV3FocusForNormalization(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! List<dynamic>) {
        return null;
      }

      final sessions = <_RestoredFocusSession>[];

      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) {
          return null;
        }

        final completedAtRaw = raw['completedAt'];

        final durationRaw = raw['durationMinutes'];

        if (completedAtRaw is! String || durationRaw is! num) {
          return null;
        }

        final completedAt = DateTime.tryParse(completedAtRaw);

        if (completedAt == null) {
          return null;
        }

        sessions.add(
          _RestoredFocusSession(
            completedAt: completedAt,
            durationMinutes: durationRaw.toInt(),
          ),
        );
      }

      return sessions;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, Object?>>> _restorePortableMetadataV3(
    List<dynamic> metadata,
    Archive archive,
    List<String> importedPaths,
  ) async {
    final rewritten = <Map<String, Object?>>[];

    final importedByArchivePath = <String, String>{};

    for (final raw in metadata) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid metadata row.');
      }

      final key = raw['key'];
      final value = raw['value'];
      final updatedAt = raw['updatedAt'];

      if (key is! String || value is! String || updatedAt is! String) {
        throw const FormatException('Invalid metadata row.');
      }

      var restoredValue = value;

      if (_taskExtrasKeyPattern.hasMatch(key)) {
        restoredValue = await _restoreTaskExtrasV3(
          value,
          archive,
          importedPaths,
          importedByArchivePath,
        );
      }

      rewritten.add({
        'key': key,
        'value': restoredValue,
        'updatedAt': updatedAt,
      });
    }

    return rewritten;
  }

  Future<String> _restoreTaskExtrasV3(
    String rawValue,
    Archive archive,
    List<String> importedPaths,
    Map<String, String> importedByArchivePath,
  ) async {
    Object? decoded;

    try {
      decoded = jsonDecode(rawValue);
    } on FormatException {
      throw const FormatException('Invalid task extras metadata.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid task extras metadata.');
    }

    final rawAttachments = decoded['attachments'];

    if (rawAttachments == null) {
      return rawValue;
    }

    if (rawAttachments is! List<dynamic>) {
      throw const FormatException('Invalid attachment list.');
    }

    decoded['attachments'] = await _restoreAttachmentPaths(
      rawAttachments,
      archive,
      importedPaths,
      importedByArchivePath,
    );

    return jsonEncode(decoded);
  }

  // ========================================================
  // V4 NORMALIZED RESTORE
  // ========================================================

  Future<void> _restoreV4(
    Map<String, dynamic> decoded,
    Archive archive,
    List<String> importedPaths,
  ) async {
    final metadata = _validateMetadata(
      decoded['metadata'] as List<dynamic>? ?? const <dynamic>[],
    );

    final rawTaskExtras = decoded['taskExtras'];

    if (rawTaskExtras is! List<dynamic>) {
      throw const FormatException('V4 taskExtras must be a list.');
    }

    final importedByArchivePath = <String, String>{};

    final taskExtras = <_RestoredTaskExtras>[];

    for (final raw in rawTaskExtras) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid V4 task extras row.');
      }

      final taskId = raw['taskId'];

      final recurrence = raw['recurrence'];

      final monthlyAnchorDay = raw['monthlyAnchorDay'];

      final reminderAtRaw = raw['reminderAt'];

      final repeat = raw['reminderRepeatMinutes'];

      final snoozeRaw = raw['reminderSnoozedUntil'];

      final tagsRaw = raw['tags'];

      final attachmentsRaw = raw['attachments'];

      if (taskId is! int ||
          (recurrence != null && recurrence is! String) ||
          (monthlyAnchorDay != null && monthlyAnchorDay is! int) ||
          (repeat != null && repeat is! int) ||
          tagsRaw is! List<dynamic> ||
          attachmentsRaw is! List<dynamic>) {
        throw const FormatException('Invalid V4 task extras row.');
      }

      final reminderAt = _parseNullableDateTime(reminderAtRaw, 'reminderAt');

      final snoozedUntil = _parseNullableDateTime(
        snoozeRaw,
        'reminderSnoozedUntil',
      );

      final tags = <String>[];

      for (final rawTag in tagsRaw) {
        if (rawTag is! String) {
          throw const FormatException('Invalid V4 task tag.');
        }

        tags.add(rawTag);
      }

      final localAttachments = await _restoreAttachmentPaths(
        attachmentsRaw,
        archive,
        importedPaths,
        importedByArchivePath,
      );

      taskExtras.add(
        _RestoredTaskExtras(
          taskId: taskId,
          recurrence: recurrence as String?,
          monthlyAnchorDay: monthlyAnchorDay as int?,
          reminderAt: reminderAt,
          reminderRepeatMinutes: repeat as int?,
          reminderSnoozedUntil: snoozedUntil,
          tags: tags,
          attachments: localAttachments,
        ),
      );
    }

    final hasFocusSessions = decoded.containsKey('focusSessions');

    final focusSessions = <_RestoredFocusSession>[];

    if (hasFocusSessions) {
      final rawFocus = decoded['focusSessions'];

      if (rawFocus is! List<dynamic>) {
        throw const FormatException('V4 focusSessions must be a list.');
      }

      for (final raw in rawFocus) {
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('Invalid V4 focus session.');
        }

        final completedAtRaw = raw['completedAt'];

        final duration = raw['durationMinutes'];

        if (completedAtRaw is! String || duration is! int) {
          throw const FormatException('Invalid V4 focus session.');
        }

        final completedAt = DateTime.tryParse(completedAtRaw);

        if (completedAt == null) {
          throw const FormatException('Invalid V4 focus DateTime.');
        }

        focusSessions.add(
          _RestoredFocusSession(
            completedAt: completedAt,
            durationMinutes: duration,
          ),
        );
      }
    }

    final restorable = Map<String, dynamic>.from(decoded);

    restorable['formatVersion'] = BackupService.formatVersion;

    restorable['metadata'] = metadata;

    // The outer transaction includes the existing BackupService
    // transaction as a nested transaction. Normalized rows and
    // the core restore therefore commit or roll back together.
    await _database.transaction(() async {
      await _backupService.restoreFromMap(restorable);

      for (final extras in taskExtras) {
        await _database
            .into(_database.taskExtrasRows)
            .insertOnConflictUpdate(
              TaskExtrasRowsCompanion.insert(
                taskId: Value(extras.taskId),
                recurrence: Value(extras.recurrence),
                monthlyAnchorDay: Value(extras.monthlyAnchorDay),
                reminderAt: Value(extras.reminderAt),
                reminderRepeatMinutes: Value(extras.reminderRepeatMinutes),
                reminderSnoozedUntil: Value(extras.reminderSnoozedUntil),
              ),
            );

        for (var position = 0; position < extras.tags.length; position++) {
          await _database
              .into(_database.taskTagsRows)
              .insert(
                TaskTagsRowsCompanion.insert(
                  taskId: extras.taskId,
                  position: position,
                  value: extras.tags[position],
                ),
              );
        }

        for (
          var position = 0;
          position < extras.attachments.length;
          position++
        ) {
          await _database
              .into(_database.taskAttachmentsRows)
              .insert(
                TaskAttachmentsRowsCompanion.insert(
                  taskId: extras.taskId,
                  position: position,
                  path: extras.attachments[position],
                ),
              );
        }
      }

      if (hasFocusSessions) {
        for (final session in focusSessions) {
          await _database
              .into(_database.focusSessionRows)
              .insert(
                FocusSessionRowsCompanion.insert(
                  completedAt: session.completedAt,
                  durationMinutes: session.durationMinutes,
                ),
              );
        }
      }
    });
  }

  List<Map<String, Object?>> _validateMetadata(List<dynamic> metadata) {
    final result = <Map<String, Object?>>[];

    for (final raw in metadata) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid metadata row.');
      }

      final key = raw['key'];
      final value = raw['value'];
      final updatedAt = raw['updatedAt'];

      if (key is! String ||
          value is! String ||
          updatedAt is! String ||
          DateTime.tryParse(updatedAt) == null) {
        throw const FormatException('Invalid metadata row.');
      }

      result.add({'key': key, 'value': value, 'updatedAt': updatedAt});
    }

    return result;
  }

  DateTime? _parseNullableDateTime(Object? value, String fieldName) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('Invalid V4 $fieldName.');
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw FormatException('Invalid V4 $fieldName.');
    }

    return parsed;
  }

  Future<List<String>> _restoreAttachmentPaths(
    List<dynamic> rawAttachments,
    Archive archive,
    List<String> importedPaths,
    Map<String, String> importedByArchivePath,
  ) async {
    final restored = <String>[];

    for (final rawPath in rawAttachments) {
      if (rawPath is! String) {
        throw const FormatException('Invalid attachment path.');
      }

      final archivePath = rawPath.trim();

      _validatePortableAttachmentPath(archivePath);

      var localPath = importedByArchivePath[archivePath];

      if (localPath == null) {
        final archiveFile = archive.find(archivePath);

        if (archiveFile == null) {
          throw const FormatException('Backup attachment is missing.');
        }

        final fileBytes = archiveFile.readBytes();

        if (fileBytes == null) {
          throw const FormatException('Backup attachment is unreadable.');
        }

        localPath = await _attachmentService.importBytes(
          bytes: fileBytes,
          fileName: p.posix.basename(archivePath),
        );

        importedPaths.add(localPath);

        importedByArchivePath[archivePath] = localPath;
      }

      restored.add(localPath);
    }

    return restored;
  }

  void _validatePortableAttachmentPath(String path) {
    if (path.isEmpty ||
        path.contains(r'\') ||
        p.posix.isAbsolute(path) ||
        !path.startsWith('attachments/') ||
        p.posix.normalize(path) != path) {
      throw const FormatException('Unsafe backup attachment path.');
    }

    final segments = p.posix.split(path);

    if (segments.length < 2 ||
        segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        )) {
      throw const FormatException('Unsafe backup attachment path.');
    }
  }

  Future<Set<String>> _collectCurrentManagedAttachments() async {
    final paths = <String>{};

    // V5 normalized source.
    final normalized = await _database
        .select(_database.taskAttachmentsRows)
        .get();

    for (final item in normalized) {
      if (await _attachmentService.isManagedPath(item.path)) {
        paths.add(item.path);
      }
    }

    // Transitional legacy fallback.
    final metadata = await _database.select(_database.appMetadata).get();

    for (final item in metadata) {
      if (!_taskExtrasKeyPattern.hasMatch(item.key)) {
        continue;
      }

      Object? decoded;

      try {
        decoded = jsonDecode(item.value);
      } on FormatException {
        continue;
      }

      if (decoded is! Map<String, dynamic>) {
        continue;
      }

      final attachments = decoded['attachments'];

      if (attachments is! List<dynamic>) {
        continue;
      }

      for (final raw in attachments) {
        final path = raw.toString().trim();

        if (path.isEmpty) {
          continue;
        }

        if (await _attachmentService.isManagedPath(path)) {
          paths.add(path);
        }
      }
    }

    return paths;
  }
}

class _RestoredTaskExtras {
  const _RestoredTaskExtras({
    required this.taskId,
    required this.recurrence,
    required this.monthlyAnchorDay,
    required this.reminderAt,
    required this.reminderRepeatMinutes,
    required this.reminderSnoozedUntil,
    required this.tags,
    required this.attachments,
  });

  final int taskId;
  final String? recurrence;
  final int? monthlyAnchorDay;
  final DateTime? reminderAt;
  final int? reminderRepeatMinutes;
  final DateTime? reminderSnoozedUntil;
  final List<String> tags;
  final List<String> attachments;
}

class _RestoredFocusSession {
  const _RestoredFocusSession({
    required this.completedAt,
    required this.durationMinutes,
  });

  final DateTime completedAt;
  final int durationMinutes;
}
