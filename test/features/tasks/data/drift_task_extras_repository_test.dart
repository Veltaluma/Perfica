import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_extras_repository.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_extras.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository taskRepository;
  late DriftTaskExtrasRepository extrasRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    taskRepository = DriftTaskRepository(database);

    extrasRepository = DriftTaskExtrasRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createTask() {
    return taskRepository.createTask(title: 'Extras storage test');
  }

  test('saveExtras writes normalized rows and preserves ordering', () async {
    final taskId = await createTask();

    final reminderAt = DateTime(2099, 6, 15, 9, 30);

    final snoozedUntil = DateTime(2099, 6, 15, 9, 45);

    final expected = TaskExtras(
      recurrence: 'monthly',
      monthlyAnchorDay: 31,
      reminderAt: reminderAt,
      reminderRepeatMinutes: 15,
      reminderSnoozedUntil: snoozedUntil,
      tags: const ['third', 'first', 'second'],
      attachments: const [r'C:\files\z.pdf', r'C:\files\a.jpg'],
    );

    await extrasRepository.saveExtras(taskId, expected);

    final actual = await extrasRepository.getExtras(taskId);

    expect(actual.recurrence, expected.recurrence);

    expect(actual.monthlyAnchorDay, expected.monthlyAnchorDay);

    expect(actual.reminderAt, expected.reminderAt);

    expect(actual.reminderRepeatMinutes, expected.reminderRepeatMinutes);

    expect(actual.reminderSnoozedUntil, expected.reminderSnoozedUntil);

    expect(actual.tags, expected.tags);

    expect(actual.attachments, expected.attachments);

    final scalarRows = await database.select(database.taskExtrasRows).get();

    expect(scalarRows, hasLength(1));

    final tagRows = await (database.select(
      database.taskTagsRows,
    )..orderBy([(table) => OrderingTerm.asc(table.position)])).get();

    expect(tagRows.map((row) => row.position), [0, 1, 2]);

    expect(tagRows.map((row) => row.value), expected.tags);

    final attachmentRows = await (database.select(
      database.taskAttachmentsRows,
    )..orderBy([(table) => OrderingTerm.asc(table.position)])).get();

    expect(attachmentRows.map((row) => row.position), [0, 1]);

    expect(attachmentRows.map((row) => row.path), expected.attachments);
  });

  test('normalized rows are the read source of truth', () async {
    final taskId = await createTask();

    await extrasRepository.saveExtras(
      taskId,
      TaskExtras(
        recurrence: 'weekly',
        monthlyAnchorDay: 17,
        reminderAt: DateTime(2099, 7, 1, 8),
        reminderRepeatMinutes: 10,
        tags: const ['normalized'],
        attachments: const [r'C:\normalized.pdf'],
      ),
    );

    // Deliberately corrupt the legacy compatibility copy.
    // getExtras must ignore it while normalized rows exist.
    final legacy = jsonEncode({
      'recurrence': 'daily',
      'monthlyAnchorDay': 1,
      'tags': ['legacy'],
      'attachments': ['legacy.txt'],
    });

    await database
        .into(database.appMetadata)
        .insertOnConflictUpdate(
          AppMetadataCompanion.insert(
            key: 'task:$taskId:extras',
            value: legacy,
            updatedAt: DateTime.now(),
          ),
        );

    final actual = await extrasRepository.getExtras(taskId);

    expect(actual.recurrence, 'weekly');

    expect(actual.monthlyAnchorDay, 17);

    expect(actual.tags, const ['normalized']);

    expect(actual.attachments, const [r'C:\normalized.pdf']);
  });

  test(
    'saveExtras writes normalized storage without creating legacy metadata',
    () async {
      final taskId = await createTask();

      await extrasRepository.saveExtras(
        taskId,
        TaskExtras(
          recurrence: 'daily',
          monthlyAnchorDay: 23,
          reminderAt: DateTime(2099, 8, 10, 7, 30),
          reminderRepeatMinutes: 20,
          tags: const ['normalized-only'],
          attachments: const [r'C:\normalized\one.pdf'],
        ),
      );

      final metadataQuery = database.select(database.appMetadata)
        ..where((table) => table.key.equals('task:$taskId:extras'));

      expect(await metadataQuery.getSingleOrNull(), isNull);

      final restored = await extrasRepository.getExtras(taskId);

      expect(restored.recurrence, 'daily');

      expect(restored.monthlyAnchorDay, 23);

      expect(restored.reminderRepeatMinutes, 20);

      expect(restored.tags, const ['normalized-only']);

      expect(restored.attachments, const [r'C:\normalized\one.pdf']);
    },
  );

  test(
    'getExtras falls back to legacy metadata when normalized row is absent',
    () async {
      final taskId = await createTask();

      final legacy = jsonEncode({
        'recurrence': 'weekly',
        'monthlyAnchorDay': 28,
        'reminderAt': '2099-09-01T08:00:00.000',
        'reminderRepeatMinutes': 30,
        'reminderSnoozedUntil': '2099-09-01T08:10:00.000',
        'tags': ['legacy', 'fallback'],
        'attachments': ['old.pdf'],
      });

      await database
          .into(database.appMetadata)
          .insertOnConflictUpdate(
            AppMetadataCompanion.insert(
              key: 'task:$taskId:extras',
              value: legacy,
              updatedAt: DateTime.now(),
            ),
          );

      final actual = await extrasRepository.getExtras(taskId);

      expect(actual.recurrence, 'weekly');

      expect(actual.monthlyAnchorDay, 28);

      expect(actual.reminderRepeatMinutes, 30);

      expect(actual.tags, const ['legacy', 'fallback']);

      expect(actual.attachments, const ['old.pdf']);
    },
  );

  test('deleteExtras removes normalized and legacy storage', () async {
    final taskId = await createTask();

    await extrasRepository.saveExtras(
      taskId,
      TaskExtras(
        recurrence: 'daily',
        tags: const ['delete-me'],
        attachments: const ['delete.pdf'],
      ),
    );

    await extrasRepository.deleteExtras(taskId);

    expect(await database.select(database.taskExtrasRows).get(), isEmpty);

    expect(await database.select(database.taskTagsRows).get(), isEmpty);

    expect(await database.select(database.taskAttachmentsRows).get(), isEmpty);

    final legacy =
        await (database.select(database.appMetadata)
              ..where((table) => table.key.equals('task:$taskId:extras')))
            .getSingleOrNull();

    expect(legacy, isNull);

    expect(await extrasRepository.getExtras(taskId), isA<TaskExtras>());
  });
}
