import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import 'attachment_service.dart';

class PortableBackupBuilder {
  PortableBackupBuilder(this._database, this._attachmentService);

  static const formatVersion = 4;

  static final RegExp _taskExtrasKeyPattern = RegExp(r'^task:(\d+):extras$');

  static const String _focusLegacyKey = 'focus:sessions:v1';

  final AppDatabase _database;
  final AttachmentService _attachmentService;

  Future<List<int>> build() async {
    final tasks = await _database.select(_database.tasks).get();

    final subtasks = await _database.select(_database.subtasks).get();

    final metadata = await _database.select(_database.appMetadata).get();

    final completionEvents = await _database
        .select(_database.completionEvents)
        .get();

    final scalarRows = await _database.select(_database.taskExtrasRows).get();

    final tagRows = await _database.select(_database.taskTagsRows).get();

    final attachmentRows = await _database
        .select(_database.taskAttachmentsRows)
        .get();

    final focusRows = await _database.select(_database.focusSessionRows).get();

    final archive = Archive();

    var attachmentIndex = 0;

    String nextAttachmentPath(String originalPath) {
      attachmentIndex++;

      final baseName = _safeArchiveFileName(originalPath);

      final sequence = attachmentIndex.toString().padLeft(6, '0');

      return 'attachments/'
          '${sequence}_$baseName';
    }

    // ======================================================
    // NORMALIZED TASK EXTRAS
    // ======================================================

    final scalarByTaskId = {for (final row in scalarRows) row.taskId: row};

    tagRows.sort((first, second) {
      final taskComparison = first.taskId.compareTo(second.taskId);

      if (taskComparison != 0) {
        return taskComparison;
      }

      return first.position.compareTo(second.position);
    });

    attachmentRows.sort((first, second) {
      final taskComparison = first.taskId.compareTo(second.taskId);

      if (taskComparison != 0) {
        return taskComparison;
      }

      return first.position.compareTo(second.position);
    });

    final tagsByTaskId = <int, List<String>>{};

    for (final row in tagRows) {
      tagsByTaskId.putIfAbsent(row.taskId, () => <String>[]).add(row.value);
    }

    final attachmentsByTaskId = <int, List<String>>{};

    for (final row in attachmentRows) {
      attachmentsByTaskId
          .putIfAbsent(row.taskId, () => <String>[])
          .add(row.path);
    }

    final normalizedTaskIds = <int>{
      ...scalarByTaskId.keys,
      ...tagsByTaskId.keys,
      ...attachmentsByTaskId.keys,
    }.toList()..sort();

    final taskIdsInDatabase = tasks.map((task) => task.id).toSet();

    final portableTaskExtras = <Map<String, Object?>>[];

    for (final taskId in normalizedTaskIds) {
      final scalar = scalarByTaskId[taskId];

      final portableAttachments = await _makeAttachmentsPortable(
        attachmentsByTaskId[taskId] ?? const <String>[],
        archive,
        nextAttachmentPath: nextAttachmentPath,
      );

      portableTaskExtras.add({
        'taskId': taskId,
        'recurrence': scalar?.recurrence,
        'monthlyAnchorDay': scalar?.monthlyAnchorDay,
        'reminderAt': scalar?.reminderAt?.toIso8601String(),
        'reminderRepeatMinutes': scalar?.reminderRepeatMinutes,
        'reminderSnoozedUntil': scalar?.reminderSnoozedUntil?.toIso8601String(),
        'tags': tagsByTaskId[taskId] ?? const <String>[],
        'attachments': portableAttachments,
      });
    }

    // ======================================================
    // TRANSITIONAL LEGACY TASK FALLBACK
    //
    // A v3 backup restored into schema v5 can legitimately
    // have metadata but no normalized row until the task is
    // edited. V4 export must not lose that data.
    // ======================================================

    final exportedLegacyTaskIds = <int>{};

    for (final item in metadata) {
      final match = _taskExtrasKeyPattern.firstMatch(item.key);

      if (match == null) {
        continue;
      }

      final taskId = int.tryParse(match.group(1)!);

      if (taskId == null ||
          normalizedTaskIds.contains(taskId) ||
          !taskIdsInDatabase.contains(taskId)) {
        continue;
      }

      final legacy = _decodeLegacyTaskExtras(item.value);

      if (legacy == null) {
        continue;
      }

      final rawAttachments = (legacy['attachments'] as List<dynamic>)
          .cast<String>();

      final portableAttachments = await _makeAttachmentsPortable(
        rawAttachments,
        archive,
        nextAttachmentPath: nextAttachmentPath,
      );

      portableTaskExtras.add({
        'taskId': taskId,
        'recurrence': legacy['recurrence'],
        'monthlyAnchorDay': legacy['monthlyAnchorDay'],
        'reminderAt': legacy['reminderAt'],
        'reminderRepeatMinutes': legacy['reminderRepeatMinutes'],
        'reminderSnoozedUntil': legacy['reminderSnoozedUntil'],
        'tags': legacy['tags'],
        'attachments': portableAttachments,
      });

      exportedLegacyTaskIds.add(taskId);
    }

    portableTaskExtras.sort(
      (first, second) =>
          (first['taskId'] as int).compareTo(second['taskId'] as int),
    );

    // ======================================================
    // FOCUS
    // ======================================================

    focusRows.sort((first, second) => first.id.compareTo(second.id));

    List<Map<String, Object?>>? portableFocusSessions;

    var focusLegacyWasNormalized = false;

    if (focusRows.isNotEmpty) {
      portableFocusSessions = focusRows
          .map(
            (row) => <String, Object?>{
              'completedAt': row.completedAt.toIso8601String(),
              'durationMinutes': row.durationMinutes,
            },
          )
          .toList(growable: false);

      focusLegacyWasNormalized = true;
    } else {
      AppMetadataData? legacyFocus;

      for (final item in metadata) {
        if (item.key == _focusLegacyKey) {
          legacyFocus = item;
          break;
        }
      }

      if (legacyFocus != null) {
        final decodedFocus = _decodeLegacyFocusSessions(legacyFocus.value);

        if (decodedFocus != null) {
          portableFocusSessions = decodedFocus;

          focusLegacyWasNormalized = true;
        }
      }
    }

    // ======================================================
    // UNRELATED / UNRECOVERABLE LEGACY METADATA
    // ======================================================

    final portableMetadata = <Map<String, Object?>>[];

    for (final item in metadata) {
      final taskMatch = _taskExtrasKeyPattern.firstMatch(item.key);

      if (taskMatch != null) {
        final taskId = int.tryParse(taskMatch.group(1)!);

        if (taskId != null &&
            (normalizedTaskIds.contains(taskId) ||
                exportedLegacyTaskIds.contains(taskId))) {
          continue;
        }
      }

      if (item.key == _focusLegacyKey && focusLegacyWasNormalized) {
        continue;
      }

      portableMetadata.add({
        'key': item.key,
        'value': item.value,
        'updatedAt': item.updatedAt.toIso8601String(),
      });
    }

    // ======================================================
    // MANIFEST
    // ======================================================

    final manifest = <String, Object?>{
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tasks': tasks
          .map(
            (task) => <String, Object?>{
              'id': task.id,
              'title': task.title,
              'description': task.description,
              'isCompleted': task.isCompleted,
              'priority': task.priority,
              'workflowStatus': task.workflowStatus,
              'dueAt': task.dueAt?.toIso8601String(),
              'createdAt': task.createdAt.toIso8601String(),
              'updatedAt': task.updatedAt.toIso8601String(),
              'completedAt': task.completedAt?.toIso8601String(),
              'sortOrder': task.sortOrder,
            },
          )
          .toList(growable: false),
      'subtasks': subtasks
          .map(
            (subtask) => <String, Object?>{
              'id': subtask.id,
              'taskId': subtask.taskId,
              'title': subtask.title,
              'isCompleted': subtask.isCompleted,
              'createdAt': subtask.createdAt.toIso8601String(),
              'updatedAt': subtask.updatedAt.toIso8601String(),
              'sortOrder': subtask.sortOrder,
            },
          )
          .toList(growable: false),
      'metadata': portableMetadata,
      'completionEvents': completionEvents
          .map(
            (event) => <String, Object?>{
              'id': event.id,
              'taskId': event.taskId,
              'taskTitle': event.taskTitle,
              'completedAt': event.completedAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'taskExtras': portableTaskExtras,
      'focusSessions': ?portableFocusSessions,
    };

    archive.add(
      ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest),
      ),
    );

    return ZipEncoder().encodeBytes(archive);
  }

  Future<List<String>> _makeAttachmentsPortable(
    Iterable<String> originalPaths,
    Archive archive, {
    required String Function(String originalPath) nextAttachmentPath,
  }) async {
    final portablePaths = <String>[];

    for (final rawPath in originalPaths) {
      final originalPath = rawPath.trim();

      if (originalPath.isEmpty) {
        continue;
      }

      final managed = await _attachmentService.isManagedPath(originalPath);

      if (!managed) {
        throw StateError(
          'Backup contains an unmanaged '
          'attachment path.',
        );
      }

      final bytes = await _attachmentService.readStored(originalPath);

      final archivePath = nextAttachmentPath(originalPath);

      archive.add(ArchiveFile.bytes(archivePath, bytes));

      portablePaths.add(archivePath);
    }

    return portablePaths;
  }

  Map<String, Object?>? _decodeLegacyTaskExtras(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final recurrence = decoded['recurrence'];

      final monthlyAnchor = decoded['monthlyAnchorDay'];

      final reminderAt = _validatedDateString(decoded['reminderAt']);

      final repeat = decoded['reminderRepeatMinutes'];

      final snoozed = _validatedDateString(decoded['reminderSnoozedUntil']);

      final tags = decoded['tags'];

      final attachments = decoded['attachments'];

      if (recurrence != null && recurrence is! String) {
        return null;
      }

      if (monthlyAnchor != null && monthlyAnchor is! num) {
        return null;
      }

      if (repeat != null && repeat is! num) {
        return null;
      }

      if (tags != null && tags is! List<dynamic>) {
        return null;
      }

      if (attachments != null && attachments is! List<dynamic>) {
        return null;
      }

      return {
        'recurrence': recurrence as String?,
        'monthlyAnchorDay': monthlyAnchor is num ? monthlyAnchor.toInt() : null,
        'reminderAt': reminderAt,
        'reminderRepeatMinutes': repeat is num ? repeat.toInt() : null,
        'reminderSnoozedUntil': snoozed,
        'tags': (tags as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList(growable: false),
        'attachments': (attachments as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList(growable: false),
      };
    } on FormatException {
      return null;
    }
  }

  List<Map<String, Object?>>? _decodeLegacyFocusSessions(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! List<dynamic>) {
        return null;
      }

      final sessions = <Map<String, Object?>>[];

      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) {
          return null;
        }

        final completedAt = raw['completedAt'];

        final duration = raw['durationMinutes'];

        if (completedAt is! String ||
            DateTime.tryParse(completedAt) == null ||
            duration is! num) {
          return null;
        }

        sessions.add({
          'completedAt': completedAt,
          'durationMinutes': duration.toInt(),
        });
      }

      return sessions;
    } on FormatException {
      return null;
    }
  }

  String? _validatedDateString(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String || DateTime.tryParse(value) == null) {
      throw const FormatException('Invalid legacy DateTime.');
    }

    return value;
  }

  String _safeArchiveFileName(String originalPath) {
    final normalized = originalPath.replaceAll(r'\', '/');

    var name = p.posix.basename(normalized);

    if (name.isEmpty || name == '.' || name == '..') {
      name = 'attachment';
    }

    name = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');

    if (name.isEmpty) {
      return 'attachment';
    }

    return name;
  }
}
