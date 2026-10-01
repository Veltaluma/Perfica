import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/task_extras.dart';
import '../../domain/repositories/task_extras_repository.dart';

class DriftTaskExtrasRepository implements TaskExtrasRepository {
  DriftTaskExtrasRepository(this._database);

  final AppDatabase _database;

  String _legacyKey(int taskId) => 'task:$taskId:extras';

  @override
  Future<TaskExtras> getExtras(int taskId) async {
    final extrasQuery = _database.select(_database.taskExtrasRows)
      ..where((table) => table.taskId.equals(taskId));

    final extrasRow = await extrasQuery.getSingleOrNull();

    if (extrasRow == null) {
      // Transitional compatibility:
      // malformed or pre-v5 metadata may intentionally have no normalized row.
      return _readLegacyExtras(taskId);
    }

    final tagsQuery = _database.select(_database.taskTagsRows)
      ..where((table) => table.taskId.equals(taskId))
      ..orderBy([(table) => OrderingTerm.asc(table.position)]);

    final attachmentsQuery = _database.select(_database.taskAttachmentsRows)
      ..where((table) => table.taskId.equals(taskId))
      ..orderBy([(table) => OrderingTerm.asc(table.position)]);

    final results = await Future.wait([
      tagsQuery.get(),
      attachmentsQuery.get(),
    ]);

    final tagRows = results[0] as List<TaskTagsRow>;
    final attachmentRows = results[1] as List<TaskAttachmentsRow>;

    return TaskExtras(
      recurrence: extrasRow.recurrence,
      monthlyAnchorDay: extrasRow.monthlyAnchorDay,
      reminderAt: extrasRow.reminderAt,
      reminderRepeatMinutes: extrasRow.reminderRepeatMinutes,
      reminderSnoozedUntil: extrasRow.reminderSnoozedUntil,
      tags: tagRows.map((row) => row.value).toList(growable: false),
      attachments: attachmentRows
          .map((row) => row.path)
          .toList(growable: false),
    );
  }

  @override
  Future<void> saveExtras(int taskId, TaskExtras extras) async {
    await _database.transaction(() async {
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

      await (_database.delete(
        _database.taskTagsRows,
      )..where((table) => table.taskId.equals(taskId))).go();

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

      await (_database.delete(
        _database.taskAttachmentsRows,
      )..where((table) => table.taskId.equals(taskId))).go();

      for (var position = 0; position < extras.attachments.length; position++) {
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

      // Temporary compatibility bridge for portable backup v3.
      // Remove this dual-write only after backup/restore has been
      // migrated to the normalized v5 tables.
    });
  }

  @override
  Future<void> deleteExtras(int taskId) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.taskTagsRows,
      )..where((table) => table.taskId.equals(taskId))).go();

      await (_database.delete(
        _database.taskAttachmentsRows,
      )..where((table) => table.taskId.equals(taskId))).go();

      await (_database.delete(
        _database.taskExtrasRows,
      )..where((table) => table.taskId.equals(taskId))).go();

      await (_database.delete(
        _database.appMetadata,
      )..where((table) => table.key.equals(_legacyKey(taskId)))).go();
    });
  }

  Future<TaskExtras> _readLegacyExtras(int taskId) async {
    final query = _database.select(_database.appMetadata)
      ..where((table) => table.key.equals(_legacyKey(taskId)));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return const TaskExtras();
    }

    try {
      final decoded = jsonDecode(row.value);

      if (decoded is! Map<String, dynamic>) {
        return const TaskExtras();
      }

      final repeatValue = decoded['reminderRepeatMinutes'];

      final monthlyAnchorValue = decoded['monthlyAnchorDay'];

      final reminderAtValue = decoded['reminderAt'];

      final snoozedValue = decoded['reminderSnoozedUntil'];

      final tagsValue = decoded['tags'];
      final attachmentsValue = decoded['attachments'];

      if (reminderAtValue != null && reminderAtValue is! String) {
        return const TaskExtras();
      }

      if (snoozedValue != null && snoozedValue is! String) {
        return const TaskExtras();
      }

      if (tagsValue != null && tagsValue is! List<dynamic>) {
        return const TaskExtras();
      }

      if (attachmentsValue != null && attachmentsValue is! List<dynamic>) {
        return const TaskExtras();
      }

      return TaskExtras(
        recurrence: decoded['recurrence'] is String
            ? decoded['recurrence'] as String
            : null,
        monthlyAnchorDay: monthlyAnchorValue is num
            ? monthlyAnchorValue.toInt()
            : null,
        reminderAt: reminderAtValue is String
            ? DateTime.tryParse(reminderAtValue)
            : null,
        reminderRepeatMinutes: repeatValue is num ? repeatValue.toInt() : null,
        reminderSnoozedUntil: snoozedValue is String
            ? DateTime.tryParse(snoozedValue)
            : null,
        tags: (tagsValue as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList(growable: false),
        attachments: (attachmentsValue as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList(growable: false),
      );
    } catch (_) {
      return const TaskExtras();
    }
  }
}
