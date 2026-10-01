import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/backup_service.dart';

void main() {
  late AppDatabase database;
  late BackupService service;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    await database.customStatement('PRAGMA foreign_keys = ON');

    service = BackupService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('legacy restore clears normalized v5 task and focus storage', () async {
    final taskId = await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Old local task'));

    await database
        .into(database.taskExtrasRows)
        .insert(
          TaskExtrasRowsCompanion.insert(
            taskId: Value(taskId),
            recurrence: const Value('weekly'),
          ),
        );

    await database
        .into(database.taskTagsRows)
        .insert(
          TaskTagsRowsCompanion.insert(
            taskId: taskId,
            position: 0,
            value: 'old-tag',
          ),
        );

    await database
        .into(database.taskAttachmentsRows)
        .insert(
          TaskAttachmentsRowsCompanion.insert(
            taskId: taskId,
            position: 0,
            path: 'old-attachment',
          ),
        );

    await database
        .into(database.focusSessionRows)
        .insert(
          FocusSessionRowsCompanion.insert(
            completedAt: DateTime(2099, 1, 1, 8),
            durationMinutes: 25,
          ),
        );

    expect(await database.select(database.taskExtrasRows).get(), isNotEmpty);

    expect(await database.select(database.focusSessionRows).get(), isNotEmpty);

    await service.restoreFromMap({
      'formatVersion': 2,
      'tasks': <dynamic>[],
      'subtasks': <dynamic>[],
      'metadata': <dynamic>[],
      'completionEvents': <dynamic>[],
    });

    expect(await database.select(database.tasks).get(), isEmpty);

    expect(await database.select(database.taskExtrasRows).get(), isEmpty);

    expect(await database.select(database.taskTagsRows).get(), isEmpty);

    expect(await database.select(database.taskAttachmentsRows).get(), isEmpty);

    expect(await database.select(database.focusSessionRows).get(), isEmpty);
  });

  test(
    'failed legacy restore rolls normalized cleanup back atomically',
    () async {
      await database
          .into(database.focusSessionRows)
          .insert(
            FocusSessionRowsCompanion.insert(
              completedAt: DateTime(2099, 2, 1, 8),
              durationMinutes: 50,
            ),
          );

      final malformed = {
        'formatVersion': 2,
        'tasks': [
          {
            'id': 1,

            // title deliberately missing
            'description': null,
            'isCompleted': false,
            'priority': 0,
            'workflowStatus': 0,
            'dueAt': null,
            'createdAt': '2099-01-01T00:00:00.000',
            'updatedAt': '2099-01-01T00:00:00.000',
            'completedAt': null,
            'sortOrder': 0,
          },
        ],
        'subtasks': <dynamic>[],
        'metadata': <dynamic>[],
        'completionEvents': <dynamic>[],
      };

      await expectLater(service.restoreFromMap(malformed), throwsA(anything));

      final focusRows = await database.select(database.focusSessionRows).get();

      expect(focusRows, hasLength(1));

      expect(focusRows.single.durationMinutes, 50);
    },
  );
}
