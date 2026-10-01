import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/focus/data/tables/focus_session_rows.dart';
import '../../features/tasks/data/tables/completion_events.dart';
import '../../features/tasks/data/tables/subtasks.dart';
import '../../features/tasks/data/tables/tasks.dart';
import '../../features/tasks/data/tables/task_attachments_rows.dart';
import '../../features/tasks/data/tables/task_extras_rows.dart';
import '../../features/tasks/data/tables/task_tags_rows.dart';
import 'database_connection.dart';

part 'app_database.g.dart';

class AppMetadata extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    AppMetadata,
    Tasks,
    Subtasks,
    CompletionEvents,
    TaskExtrasRows,
    TaskTagsRows,
    TaskAttachmentsRows,
    FocusSessionRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDatabaseConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        if (from < 2) {
          await migrator.alterTable(
            TableMigration(
              appMetadata,
              columnTransformer: {
                appMetadata.updatedAt: DateTimeExpressions.fromUnixEpoch(
                  appMetadata.updatedAt.dartCast<int>(),
                ),
              },
            ),
          );

          // Current table definitions are used here. A direct migration
          // from v1 creates the task schema in its current form.
          await migrator.createTable(tasks);
          await migrator.createTable(subtasks);
          await migrator.createTable(completionEvents);

          await _createTaskIndexes();
          await _createCompletionIndexes();
        } else if (from == 2) {
          await migrator.addColumn(tasks, tasks.workflowStatus);

          await customStatement(
            'UPDATE tasks '
            'SET workflow_status = CASE '
            'WHEN is_completed = 1 THEN 2 '
            'ELSE 0 END',
          );

          await migrator.createTable(completionEvents);

          await _createTaskIndexes();
          await _createCompletionIndexes();
          await _backfillCompletionHistory();
        } else if (from == 3) {
          await migrator.createTable(completionEvents);

          await _createCompletionIndexes();
          await _backfillCompletionHistory();
        }

        if (from < 5) {
          await _createV5Tables(migrator);
          await _backfillV5Metadata();
        }

        if (from < 6) {
          await _cleanupV6LegacyMetadata();
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static final RegExp _taskExtrasMetadataPattern = RegExp(
    r'^task:(\d+):extras$',
  );

  static const String _focusSessionsMetadataKey = 'focus:sessions:v1';

  Future<void> _createV5Tables(Migrator migrator) async {
    await migrator.createTable(taskExtrasRows);
    await migrator.createTable(taskTagsRows);
    await migrator.createTable(taskAttachmentsRows);
    await migrator.createTable(focusSessionRows);
  }

  Future<void> _backfillV5Metadata() async {
    final metadataRows = await select(appMetadata).get();

    for (final metadata in metadataRows) {
      final taskMatch = _taskExtrasMetadataPattern.firstMatch(metadata.key);

      if (taskMatch != null) {
        final taskId = int.tryParse(taskMatch.group(1) ?? '');

        if (taskId == null) {
          continue;
        }

        final existingTask = await (select(
          tasks,
        )..where((table) => table.id.equals(taskId))).getSingleOrNull();

        if (existingTask == null) {
          continue;
        }

        await _backfillTaskExtras(taskId, metadata.value);

        continue;
      }

      if (metadata.key == _focusSessionsMetadataKey) {
        await _backfillFocusSessions(metadata.value);
      }
    }
  }

  Future<void> _backfillTaskExtras(int taskId, String rawValue) async {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final recurrenceRaw = decoded['recurrence'];

      if (recurrenceRaw != null && recurrenceRaw is! String) {
        return;
      }

      final monthlyAnchorRaw = decoded['monthlyAnchorDay'];

      if (monthlyAnchorRaw != null && monthlyAnchorRaw is! num) {
        return;
      }

      final reminderAtRaw = decoded['reminderAt'];

      if (reminderAtRaw != null && reminderAtRaw is! String) {
        return;
      }

      final repeatRaw = decoded['reminderRepeatMinutes'];

      if (repeatRaw != null && repeatRaw is! num) {
        return;
      }

      final snoozedRaw = decoded['reminderSnoozedUntil'];

      if (snoozedRaw != null && snoozedRaw is! String) {
        return;
      }

      final tagsRaw = decoded['tags'];

      if (tagsRaw != null && tagsRaw is! List<dynamic>) {
        return;
      }

      final attachmentsRaw = decoded['attachments'];

      if (attachmentsRaw != null && attachmentsRaw is! List<dynamic>) {
        return;
      }

      final tags = (tagsRaw as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false);

      final attachments =
          (attachmentsRaw as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false);

      await into(taskExtrasRows).insertOnConflictUpdate(
        TaskExtrasRowsCompanion.insert(
          taskId: Value(taskId),
          recurrence: Value(recurrenceRaw as String?),
          monthlyAnchorDay: Value(
            monthlyAnchorRaw is num ? monthlyAnchorRaw.toInt() : null,
          ),
          reminderAt: Value(
            reminderAtRaw is String ? DateTime.tryParse(reminderAtRaw) : null,
          ),
          reminderRepeatMinutes: Value(
            repeatRaw is num ? repeatRaw.toInt() : null,
          ),
          reminderSnoozedUntil: Value(
            snoozedRaw is String ? DateTime.tryParse(snoozedRaw) : null,
          ),
        ),
      );

      await (delete(
        taskTagsRows,
      )..where((table) => table.taskId.equals(taskId))).go();

      for (var index = 0; index < tags.length; index++) {
        await into(taskTagsRows).insert(
          TaskTagsRowsCompanion.insert(
            taskId: taskId,
            position: index,
            value: tags[index],
          ),
        );
      }

      await (delete(
        taskAttachmentsRows,
      )..where((table) => table.taskId.equals(taskId))).go();

      for (var index = 0; index < attachments.length; index++) {
        await into(taskAttachmentsRows).insert(
          TaskAttachmentsRowsCompanion.insert(
            taskId: taskId,
            position: index,
            path: attachments[index],
          ),
        );
      }
    } catch (_) {
      // Malformed legacy metadata remains preserved in AppMetadata.
      // It is intentionally not destroyed during migration.
    }
  }

  Future<void> _backfillFocusSessions(String rawValue) async {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! List<dynamic>) {
        return;
      }

      final sessions = <({DateTime completedAt, int durationMinutes})>[];

      for (final rawSession in decoded) {
        if (rawSession is! Map<String, dynamic>) {
          return;
        }

        final completedAtRaw = rawSession['completedAt'];
        final durationRaw = rawSession['durationMinutes'];

        if (completedAtRaw is! String || durationRaw is! int) {
          return;
        }

        final completedAt = DateTime.tryParse(completedAtRaw);

        if (completedAt == null) {
          return;
        }

        sessions.add((completedAt: completedAt, durationMinutes: durationRaw));
      }

      for (final session in sessions) {
        await into(focusSessionRows).insert(
          FocusSessionRowsCompanion.insert(
            completedAt: session.completedAt,
            durationMinutes: session.durationMinutes,
          ),
        );
      }
    } catch (_) {
      // Keep malformed legacy metadata untouched for compatibility.
    }
  }

  Future<void> _cleanupV6LegacyMetadata() async {
    final metadataRows = await select(appMetadata).get();

    for (final metadata in metadataRows) {
      final taskMatch = _taskExtrasMetadataPattern.firstMatch(metadata.key);

      if (taskMatch != null) {
        final taskId = int.tryParse(taskMatch.group(1) ?? '');

        if (taskId == null) {
          continue;
        }

        final safeToDelete = await _legacyTaskExtrasMatchesNormalized(
          taskId,
          metadata.value,
        );

        if (safeToDelete) {
          await (delete(
            appMetadata,
          )..where((table) => table.key.equals(metadata.key))).go();
        }

        continue;
      }

      if (metadata.key == _focusSessionsMetadataKey) {
        final safeToDelete = await _legacyFocusMatchesNormalized(
          metadata.value,
        );

        if (safeToDelete) {
          await (delete(
            appMetadata,
          )..where((table) => table.key.equals(metadata.key))).go();
        }
      }
    }
  }

  Future<bool> _legacyTaskExtrasMatchesNormalized(
    int taskId,
    String rawValue,
  ) async {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final recurrenceRaw = decoded['recurrence'];
      final monthlyAnchorRaw = decoded['monthlyAnchorDay'];
      final reminderAtRaw = decoded['reminderAt'];
      final repeatRaw = decoded['reminderRepeatMinutes'];
      final snoozedRaw = decoded['reminderSnoozedUntil'];
      final tagsRaw = decoded['tags'];
      final attachmentsRaw = decoded['attachments'];

      if (recurrenceRaw != null && recurrenceRaw is! String) {
        return false;
      }

      if (monthlyAnchorRaw != null && monthlyAnchorRaw is! int) {
        return false;
      }

      if (repeatRaw != null && repeatRaw is! int) {
        return false;
      }

      DateTime? reminderAt;

      if (reminderAtRaw != null) {
        if (reminderAtRaw is! String) {
          return false;
        }

        reminderAt = DateTime.tryParse(reminderAtRaw);

        if (reminderAt == null) {
          return false;
        }
      }

      DateTime? snoozedUntil;

      if (snoozedRaw != null) {
        if (snoozedRaw is! String) {
          return false;
        }

        snoozedUntil = DateTime.tryParse(snoozedRaw);

        if (snoozedUntil == null) {
          return false;
        }
      }

      if (tagsRaw != null && tagsRaw is! List<dynamic>) {
        return false;
      }

      if (attachmentsRaw != null && attachmentsRaw is! List<dynamic>) {
        return false;
      }

      final tags = <String>[];

      for (final value in tagsRaw as List<dynamic>? ?? const <dynamic>[]) {
        if (value is! String) {
          return false;
        }

        tags.add(value);
      }

      final attachments = <String>[];

      for (final value
          in attachmentsRaw as List<dynamic>? ?? const <dynamic>[]) {
        if (value is! String) {
          return false;
        }

        attachments.add(value);
      }

      final extrasQuery = select(taskExtrasRows)
        ..where((table) => table.taskId.equals(taskId));

      final extras = await extrasQuery.getSingleOrNull();

      if (extras == null) {
        return false;
      }

      if (extras.recurrence != recurrenceRaw ||
          extras.monthlyAnchorDay != monthlyAnchorRaw ||
          extras.reminderRepeatMinutes != repeatRaw) {
        return false;
      }

      if (!_sameNullableDateTime(extras.reminderAt, reminderAt)) {
        return false;
      }

      if (!_sameNullableDateTime(extras.reminderSnoozedUntil, snoozedUntil)) {
        return false;
      }

      final tagsQuery = select(taskTagsRows)
        ..where((table) => table.taskId.equals(taskId))
        ..orderBy([(table) => OrderingTerm.asc(table.position)]);

      final normalizedTags = (await tagsQuery.get())
          .map((row) => row.value)
          .toList(growable: false);

      if (!_sameStringList(normalizedTags, tags)) {
        return false;
      }

      final attachmentsQuery = select(taskAttachmentsRows)
        ..where((table) => table.taskId.equals(taskId))
        ..orderBy([(table) => OrderingTerm.asc(table.position)]);

      final normalizedAttachments = (await attachmentsQuery.get())
          .map((row) => row.path)
          .toList(growable: false);

      return _sameStringList(normalizedAttachments, attachments);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _legacyFocusMatchesNormalized(String rawValue) async {
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! List<dynamic>) {
        return false;
      }

      final legacySessions = <({DateTime completedAt, int durationMinutes})>[];

      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) {
          return false;
        }

        final completedAtRaw = raw['completedAt'];

        final durationRaw = raw['durationMinutes'];

        if (completedAtRaw is! String || durationRaw is! int) {
          return false;
        }

        final completedAt = DateTime.tryParse(completedAtRaw);

        if (completedAt == null) {
          return false;
        }

        legacySessions.add((
          completedAt: completedAt,
          durationMinutes: durationRaw,
        ));
      }

      final focusQuery = select(focusSessionRows)
        ..orderBy([(table) => OrderingTerm.asc(table.id)]);

      final normalized = await focusQuery.get();

      if (normalized.length != legacySessions.length) {
        return false;
      }

      for (var index = 0; index < normalized.length; index++) {
        final current = normalized[index];

        final legacy = legacySessions[index];

        if (current.durationMinutes != legacy.durationMinutes) {
          return false;
        }

        if (!_sameWallClockDateTime(current.completedAt, legacy.completedAt)) {
          return false;
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  bool _sameNullableDateTime(DateTime? first, DateTime? second) {
    if (first == null || second == null) {
      return first == null && second == null;
    }

    return _sameWallClockDateTime(first, second);
  }

  bool _sameWallClockDateTime(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute &&
        first.second == second.second &&
        first.millisecond == second.millisecond &&
        first.microsecond == second.microsecond;
  }

  bool _sameStringList(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }

  Future<void> _createTaskIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS tasks_completed_due_at '
      'ON tasks (is_completed, due_at)',
    );

    await customStatement(
      'CREATE INDEX IF NOT EXISTS tasks_sort_order '
      'ON tasks (sort_order)',
    );

    await customStatement(
      'CREATE INDEX IF NOT EXISTS tasks_workflow_due_at '
      'ON tasks (workflow_status, due_at)',
    );

    await customStatement(
      'CREATE INDEX IF NOT EXISTS subtasks_task_sort_order '
      'ON subtasks (task_id, sort_order)',
    );
  }

  Future<void> _createCompletionIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS completion_events_completed_at '
      'ON completion_events (completed_at)',
    );

    await customStatement(
      'CREATE INDEX IF NOT EXISTS completion_events_task_id '
      'ON completion_events (task_id)',
    );
  }

  Future<void> _backfillCompletionHistory() async {
    await customStatement(
      'INSERT INTO completion_events '
      '(task_id, task_title, completed_at) '
      'SELECT id, title, COALESCE(completed_at, updated_at) '
      'FROM tasks '
      'WHERE is_completed = 1',
    );
  }
}
