import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/backup_service.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  late AppDatabase database;
  late BackupService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    service = BackupService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('legacy v2 restore preserves core data', () async {
    final backup = {
      'formatVersion': 2,
      'exportedAt': '2099-01-04T00:00:00.000Z',
      'tasks': [
        {
          'id': 11,
          'title': 'Backup task',
          'description': 'Description',
          'isCompleted': true,
          'priority': 2,
          'workflowStatus': 2,
          'dueAt': '2099-01-05T12:00:00.000',
          'createdAt': '2099-01-02T08:00:00.000',
          'updatedAt': '2099-01-03T09:00:00.000',
          'completedAt': '2099-01-03T10:00:00.000',
          'sortOrder': 3,
        },
      ],
      'subtasks': [
        {
          'id': 21,
          'taskId': 11,
          'title': 'Child',
          'isCompleted': true,
          'createdAt': '2099-01-02T08:00:00.000',
          'updatedAt': '2099-01-03T09:00:00.000',
          'sortOrder': 1,
        },
      ],
      'metadata': [
        {
          'key': 'task:11:extras',
          'value': jsonEncode({
            'tags': ['work'],
            'attachments': ['/old/device/a.txt'],
          }),
          'updatedAt': '2099-01-03T09:00:00.000',
        },
      ],
      'completionEvents': [
        {
          'id': 31,
          'taskId': 11,
          'taskTitle': 'Backup task',
          'completedAt': '2099-01-03T10:00:00.000',
        },
      ],
    };

    await service.restoreFromBytes(utf8.encode(jsonEncode(backup)));

    final tasks = await database.select(database.tasks).get();

    final subtasks = await database.select(database.subtasks).get();

    final metadata = await database.select(database.appMetadata).get();

    final completions = await database.select(database.completionEvents).get();

    expect(tasks, hasLength(1));
    expect(tasks.single.id, 11);
    expect(tasks.single.title, 'Backup task');
    expect(tasks.single.workflowStatus, 2);

    expect(subtasks, hasLength(1));
    expect(subtasks.single.taskId, 11);

    expect(metadata, hasLength(1));
    expect(metadata.single.key, 'task:11:extras');

    final extras = jsonDecode(metadata.single.value) as Map<String, dynamic>;

    expect(extras['attachments'], ['/old/device/a.txt']);

    expect(completions, hasLength(1));
    expect(completions.single.id, 31);
  });

  test('legacy v1 restore backfills completion history', () async {
    final backup = {
      'formatVersion': 1,
      'tasks': [
        {
          'id': 7,
          'title': 'Legacy completed',
          'description': null,
          'isCompleted': true,
          'priority': 0,
          'dueAt': null,
          'createdAt': '2099-02-01T08:00:00.000',
          'updatedAt': '2099-02-02T09:00:00.000',
          'completedAt': '2099-02-02T10:00:00.000',
          'sortOrder': 0,
        },
      ],
      'subtasks': <dynamic>[],
      'metadata': <dynamic>[],
    };

    await service.restoreFromBytes(utf8.encode(jsonEncode(backup)));

    final tasks = await database.select(database.tasks).get();

    final completions = await database.select(database.completionEvents).get();

    expect(tasks, hasLength(1));
    expect(tasks.single.workflowStatus, 2);

    expect(completions, hasLength(1));

    expect(completions.single.taskId, 7);

    expect(completions.single.taskTitle, 'Legacy completed');
  });

  test(
    'unsupported legacy version does not replace current database',
    () async {
      await database
          .into(database.tasks)
          .insert(TasksCompanion.insert(title: 'Keep me'));

      final invalidBackup = {
        'formatVersion': 999,
        'tasks': <dynamic>[],
        'subtasks': <dynamic>[],
        'metadata': <dynamic>[],
      };

      await expectLater(
        service.restoreFromBytes(utf8.encode(jsonEncode(invalidBackup))),
        throwsFormatException,
      );

      final tasks = await database.select(database.tasks).get();

      expect(tasks, hasLength(1));
      expect(tasks.single.title, 'Keep me');
    },
  );

  test('malformed legacy row rolls back destructive restore', () async {
    await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Existing task'));

    final malformedBackup = {
      'formatVersion': 2,
      'tasks': [
        {
          'id': 1,
          // Required title deliberately missing.
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

    await expectLater(
      service.restoreFromBytes(utf8.encode(jsonEncode(malformedBackup))),
      throwsA(anything),
    );

    final tasks = await database.select(database.tasks).get();

    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Existing task');
  });
}
