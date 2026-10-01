import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Compatibility importer for historical Perfica JSON backups.
///
/// Production backups use the portable `.perfica` format through
/// [DataBackupService]. This service deliberately exposes no JSON
/// export or file-picker UI API.
///
/// Supported historical JSON formats:
/// - v1
/// - v2
///
/// It is also used internally by [PortableBackupRestorer] for the
/// common tasks/subtasks/metadata/completion-events restore step.
class BackupService {
  BackupService(this._database);

  static const formatVersion = 2;

  final AppDatabase _database;

  Future<void> restoreFromBytes(List<int> bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be an object');
    }

    await restoreFromMap(decoded);
  }

  Future<void> restoreFromMap(Map<String, dynamic> root) async {
    final version = root['formatVersion'];

    if (version != 1 && version != 2) {
      throw const FormatException('Unsupported backup version');
    }

    final tasks = root['tasks'] as List<dynamic>? ?? const <dynamic>[];

    final subtasks = root['subtasks'] as List<dynamic>? ?? const <dynamic>[];

    final metadata = root['metadata'] as List<dynamic>? ?? const <dynamic>[];

    final completionEvents =
        root['completionEvents'] as List<dynamic>? ?? const <dynamic>[];

    await _database.transaction(() async {
      await _database.delete(_database.subtasks).go();

      // Normalized TaskExtras/tags/attachments are removed by
      // ON DELETE CASCADE when tasks are deleted.
      await _database.delete(_database.focusSessionRows).go();

      await _database.delete(_database.tasks).go();

      await _database.delete(_database.completionEvents).go();

      await _database.delete(_database.appMetadata).go();

      for (final raw in tasks) {
        final data = raw as Map<String, dynamic>;

        final completed = data['isCompleted'] as bool? ?? false;

        final workflowStatus =
            data['workflowStatus'] as int? ?? (completed ? 2 : 0);

        await _database
            .into(_database.tasks)
            .insert(
              TasksCompanion(
                id: Value(data['id'] as int),
                title: Value(data['title'] as String),
                description: Value(data['description'] as String?),
                isCompleted: Value(completed),
                priority: Value(data['priority'] as int),
                workflowStatus: Value(workflowStatus),
                dueAt: Value(
                  data['dueAt'] == null
                      ? null
                      : DateTime.parse(data['dueAt'] as String),
                ),
                createdAt: Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
                completedAt: Value(
                  data['completedAt'] == null
                      ? null
                      : DateTime.parse(data['completedAt'] as String),
                ),
                sortOrder: Value(data['sortOrder'] as int),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      for (final raw in subtasks) {
        final data = raw as Map<String, dynamic>;

        await _database
            .into(_database.subtasks)
            .insert(
              SubtasksCompanion(
                id: Value(data['id'] as int),
                taskId: Value(data['taskId'] as int),
                title: Value(data['title'] as String),
                isCompleted: Value(data['isCompleted'] as bool),
                createdAt: Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
                sortOrder: Value(data['sortOrder'] as int),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      for (final raw in metadata) {
        final data = raw as Map<String, dynamic>;

        await _database
            .into(_database.appMetadata)
            .insert(
              AppMetadataCompanion.insert(
                key: data['key'] as String,
                value: data['value'] as String,
                updatedAt: DateTime.parse(data['updatedAt'] as String),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      if (version == 2) {
        for (final raw in completionEvents) {
          final data = raw as Map<String, dynamic>;

          await _database
              .into(_database.completionEvents)
              .insert(
                CompletionEventsCompanion(
                  id: Value(data['id'] as int),
                  taskId: Value(data['taskId'] as int?),
                  taskTitle: Value(data['taskTitle'] as String),
                  completedAt: Value(
                    DateTime.parse(data['completedAt'] as String),
                  ),
                ),
                mode: InsertMode.insertOrReplace,
              );
        }

        return;
      }

      // Historical V1 did not have completionEvents.
      // Reconstruct completion history from completed tasks.
      for (final raw in tasks) {
        final data = raw as Map<String, dynamic>;

        if (data['isCompleted'] != true) {
          continue;
        }

        final completedAt = data['completedAt'] == null
            ? DateTime.parse(data['updatedAt'] as String)
            : DateTime.parse(data['completedAt'] as String);

        await _database
            .into(_database.completionEvents)
            .insert(
              CompletionEventsCompanion.insert(
                taskId: Value(data['id'] as int),
                taskTitle: data['title'] as String,
                completedAt: completedAt,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }
}
