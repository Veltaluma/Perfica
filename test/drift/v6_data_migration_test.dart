import 'dart:convert';

import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v4.dart' as v4;
import 'generated_migrations/schema_v5.dart' as v5;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v5 to v6 removes only legacy metadata that exactly matches normalized storage', () async {
    final schema = await verifier.schemaAt(5);

    final oldDb = v5.DatabaseAtV5(schema.newConnection());

    final createdAt = DateTime(2099, 5, 1, 8).toIso8601String();

    final updatedAt = DateTime(2099, 5, 1, 9).toIso8601String();

    await oldDb.customStatement(
      '''
INSERT INTO tasks (
  id,
  title,
  description,
  is_completed,
  priority,
  workflow_status,
  due_at,
  created_at,
  updated_at,
  completed_at,
  sort_order
)
VALUES (?, ?, NULL, 0, 0, 0, NULL, ?, ?, NULL, 0)
''',
      [1, 'Normalized task', createdAt, updatedAt],
    );

    await oldDb.customStatement(
      '''
INSERT INTO task_extras (
  task_id,
  recurrence,
  monthly_anchor_day,
  reminder_at,
  reminder_repeat_minutes,
  reminder_snoozed_until
)
VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        1,
        'monthly',
        31,
        '2099-05-31T08:30:00.000',
        15,
        '2099-05-31T08:45:00.000',
      ],
    );

    await oldDb.customStatement(
      '''
INSERT INTO task_tags (
  task_id,
  position,
  value
)
VALUES (?, ?, ?)
''',
      [1, 0, 'work'],
    );

    await oldDb.customStatement(
      '''
INSERT INTO task_tags (
  task_id,
  position,
  value
)
VALUES (?, ?, ?)
''',
      [1, 1, 'monthly'],
    );

    await oldDb.customStatement(
      '''
INSERT INTO task_attachments (
  task_id,
  position,
  path
)
VALUES (?, ?, ?)
''',
      [1, 0, r'C:\Perfica\receipt.pdf'],
    );

    final validTaskLegacy = jsonEncode({
      'recurrence': 'monthly',
      'monthlyAnchorDay': 31,
      'reminderAt': '2099-05-31T08:30:00.000',
      'reminderRepeatMinutes': 15,
      'reminderSnoozedUntil': '2099-05-31T08:45:00.000',
      'tags': ['work', 'monthly'],
      'attachments': [r'C:\Perfica\receipt.pdf'],
    });

    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      ['task:1:extras', validTaskLegacy, updatedAt],
    );

    // A real task exists, but this metadata is malformed and
    // therefore must survive the cleanup.
    await oldDb.customStatement(
      '''
INSERT INTO tasks (
  id,
  title,
  description,
  is_completed,
  priority,
  workflow_status,
  due_at,
  created_at,
  updated_at,
  completed_at,
  sort_order
)
VALUES (?, ?, NULL, 0, 0, 0, NULL, ?, ?, NULL, 0)
''',
      [2, 'Malformed legacy task', createdAt, updatedAt],
    );

    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      ['task:2:extras', '{"recurrence":42}', updatedAt],
    );

    // Valid but orphaned legacy metadata must also survive.
    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      [
        'task:999:extras',
        '{"recurrence":"daily","tags":[],"attachments":[]}',
        updatedAt,
      ],
    );

    await oldDb.customStatement(
      '''
INSERT INTO focus_sessions (
  completed_at,
  duration_minutes
)
VALUES (?, ?)
''',
      ['2099-05-02T08:00:00.000', 25],
    );

    await oldDb.customStatement(
      '''
INSERT INTO focus_sessions (
  completed_at,
  duration_minutes
)
VALUES (?, ?)
''',
      ['2099-05-02T09:00:00.000', 50],
    );

    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      [
        'focus:sessions:v1',
        jsonEncode([
          {'completedAt': '2099-05-02T08:00:00.000', 'durationMinutes': 25},
          {'completedAt': '2099-05-02T09:00:00.000', 'durationMinutes': 50},
        ]),
        updatedAt,
      ],
    );

    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      ['unrelated:test', '{"preserve":true}', updatedAt],
    );

    await oldDb.close();

    final database = AppDatabase.forTesting(schema.newConnection());

    try {
      await verifier.migrateAndValidate(database, 6);

      final metadata = await database.select(database.appMetadata).get();

      final keys = metadata.map((row) => row.key).toSet();

      expect(keys.contains('task:1:extras'), isFalse);

      expect(keys.contains('focus:sessions:v1'), isFalse);

      expect(keys.contains('task:2:extras'), isTrue);

      expect(keys.contains('task:999:extras'), isTrue);

      expect(keys.contains('unrelated:test'), isTrue);

      final extras = await database.select(database.taskExtrasRows).get();

      expect(extras, hasLength(1));

      expect(extras.single.taskId, 1);

      expect(extras.single.recurrence, 'monthly');

      final focus = await database.select(database.focusSessionRows).get();

      expect(focus.map((row) => row.durationMinutes), [25, 50]);
    } finally {
      await database.close();
    }
  });

  test(
    'v5 to v6 preserves valid legacy metadata when normalized data differs',
    () async {
      final schema = await verifier.schemaAt(5);

      final oldDb = v5.DatabaseAtV5(schema.newConnection());

      final timestamp = '2099-06-01T08:00:00.000';

      await oldDb.customStatement(
        '''
INSERT INTO tasks (
  id,
  title,
  description,
  is_completed,
  priority,
  workflow_status,
  due_at,
  created_at,
  updated_at,
  completed_at,
  sort_order
)
VALUES (?, ?, NULL, 0, 0, 0, NULL, ?, ?, NULL, 0)
''',
        [1, 'Mismatch task', timestamp, timestamp],
      );

      await oldDb.customStatement(
        '''
INSERT INTO task_extras (
  task_id,
  recurrence,
  monthly_anchor_day,
  reminder_at,
  reminder_repeat_minutes,
  reminder_snoozed_until
)
VALUES (?, ?, NULL, NULL, NULL, NULL)
''',
        [1, 'daily'],
      );

      await oldDb.customStatement(
        '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
        [
          'task:1:extras',
          jsonEncode({
            'recurrence': 'weekly',
            'tags': <String>[],
            'attachments': <String>[],
          }),
          timestamp,
        ],
      );

      // Malformed focus metadata must never be deleted merely
      // because normalized focus rows happen to exist.
      await oldDb.customStatement(
        '''
INSERT INTO focus_sessions (
  completed_at,
  duration_minutes
)
VALUES (?, ?)
''',
        [timestamp, 25],
      );

      await oldDb.customStatement(
        '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
        [
          'focus:sessions:v1',
          '[{"completedAt":"invalid","durationMinutes":25}]',
          timestamp,
        ],
      );

      await oldDb.close();

      final database = AppDatabase.forTesting(schema.newConnection());

      try {
        await verifier.migrateAndValidate(database, 6);

        final metadata = await database.select(database.appMetadata).get();

        final keys = metadata.map((row) => row.key).toSet();

        expect(keys.contains('task:1:extras'), isTrue);

        expect(keys.contains('focus:sessions:v1'), isTrue);
      } finally {
        await database.close();
      }
    },
  );

  test('v4 to v6 backfills normalized storage then retires successful legacy copies', () async {
    final schema = await verifier.schemaAt(4);

    final oldDb = v4.DatabaseAtV4(schema.newConnection());

    final timestamp = '2099-07-01T08:00:00.000';

    await oldDb.customStatement(
      '''
INSERT INTO tasks (
  id,
  title,
  description,
  is_completed,
  priority,
  workflow_status,
  due_at,
  created_at,
  updated_at,
  completed_at,
  sort_order
)
VALUES (?, ?, NULL, 0, 0, 0, NULL, ?, ?, NULL, 0)
''',
      [1, 'V4 legacy task', timestamp, timestamp],
    );

    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      [
        'task:1:extras',
        jsonEncode({
          'recurrence': 'monthly',
          'monthlyAnchorDay': 31,
          'tags': ['legacy'],
          'attachments': [r'C:\Perfica\legacy.pdf'],
        }),
        timestamp,
      ],
    );

    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      [
        'focus:sessions:v1',
        jsonEncode([
          {'completedAt': '2099-07-01T09:00:00.000', 'durationMinutes': 25},
        ]),
        timestamp,
      ],
    );

    await oldDb.customStatement(
      '''
INSERT INTO app_metadata (
  key,
  value,
  updated_at
)
VALUES (?, ?, ?)
''',
      ['unrelated:test', '{"keep":true}', timestamp],
    );

    await oldDb.close();

    final database = AppDatabase.forTesting(schema.newConnection());

    try {
      await verifier.migrateAndValidate(database, 6);

      final extras = await database.select(database.taskExtrasRows).get();

      expect(extras, hasLength(1));

      expect(extras.single.recurrence, 'monthly');

      expect(extras.single.monthlyAnchorDay, 31);

      final tags = await database.select(database.taskTagsRows).get();

      expect(tags.map((row) => row.value), ['legacy']);

      final attachments = await database
          .select(database.taskAttachmentsRows)
          .get();

      expect(attachments.map((row) => row.path), [r'C:\Perfica\legacy.pdf']);

      final focus = await database.select(database.focusSessionRows).get();

      expect(focus, hasLength(1));

      expect(focus.single.durationMinutes, 25);

      final metadata = await database.select(database.appMetadata).get();

      final keys = metadata.map((row) => row.key).toSet();

      expect(keys.contains('task:1:extras'), isFalse);

      expect(keys.contains('focus:sessions:v1'), isFalse);

      expect(keys, contains('unrelated:test'));
    } finally {
      await database.close();
    }
  });
}
