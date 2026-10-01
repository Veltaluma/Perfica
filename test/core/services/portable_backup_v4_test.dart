import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/attachment_service.dart';
import 'package:perfica/core/services/backup_service.dart';
import 'package:perfica/core/services/portable_backup_builder.dart';
import 'package:perfica/core/services/portable_backup_restorer.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  test('v4 round trip restores normalized task extras focus history and attachments', () async {
    final sourceRoot = await Directory.systemTemp.createTemp(
      'perfica_v4_source_',
    );

    final targetRoot = await Directory.systemTemp.createTemp(
      'perfica_v4_target_',
    );

    final sourceDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    final targetDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    try {
      final sourceAttachments = AttachmentService(
        supportDirectoryProvider: () async => sourceRoot,
      );

      final targetAttachments = AttachmentService(
        supportDirectoryProvider: () async => targetRoot,
      );

      final taskId = await sourceDatabase
          .into(sourceDatabase.tasks)
          .insert(TasksCompanion.insert(title: 'V4 portable task'));

      final sourcePath = await sourceAttachments.importBytes(
        bytes: const [10, 20, 30, 200],
        fileName: 'document.bin',
      );

      await sourceDatabase
          .into(sourceDatabase.taskExtrasRows)
          .insert(
            TaskExtrasRowsCompanion.insert(
              taskId: Value(taskId),
              recurrence: const Value('monthly'),
              monthlyAnchorDay: const Value(31),
              reminderRepeatMinutes: const Value(15),
            ),
          );

      await sourceDatabase
          .into(sourceDatabase.taskTagsRows)
          .insert(
            TaskTagsRowsCompanion.insert(
              taskId: taskId,
              position: 0,
              value: 'portable',
            ),
          );

      await sourceDatabase
          .into(sourceDatabase.taskAttachmentsRows)
          .insert(
            TaskAttachmentsRowsCompanion.insert(
              taskId: taskId,
              position: 0,
              path: sourcePath,
            ),
          );

      await sourceDatabase
          .into(sourceDatabase.focusSessionRows)
          .insert(
            FocusSessionRowsCompanion.insert(
              completedAt: DateTime(2099, 6, 1, 8),
              durationMinutes: 50,
            ),
          );

      await sourceDatabase
          .into(sourceDatabase.appMetadata)
          .insert(
            AppMetadataCompanion.insert(
              key: 'unrelated:key',
              value: '{"preserve":true}',
              updatedAt: DateTime(2099, 6, 1),
            ),
          );

      final builder = PortableBackupBuilder(sourceDatabase, sourceAttachments);

      final bytes = await builder.build();

      final restorer = PortableBackupRestorer(
        targetDatabase,
        targetAttachments,
        BackupService(targetDatabase),
      );

      await restorer.restore(bytes);

      final tasks = await targetDatabase.select(targetDatabase.tasks).get();

      expect(tasks, hasLength(1));

      expect(tasks.single.title, 'V4 portable task');

      final extras = await targetDatabase
          .select(targetDatabase.taskExtrasRows)
          .get();

      expect(extras, hasLength(1));

      expect(extras.single.recurrence, 'monthly');

      expect(extras.single.monthlyAnchorDay, 31);

      final tags = await targetDatabase
          .select(targetDatabase.taskTagsRows)
          .get();

      expect(tags.map((row) => row.value), ['portable']);

      final attachmentRows = await targetDatabase
          .select(targetDatabase.taskAttachmentsRows)
          .get();

      expect(attachmentRows, hasLength(1));

      final restoredPath = attachmentRows.single.path;

      expect(restoredPath, isNot(sourcePath));

      expect(await targetAttachments.isManagedPath(restoredPath), isTrue);

      expect(await targetAttachments.readStored(restoredPath), const [
        10,
        20,
        30,
        200,
      ]);

      final focus = await targetDatabase
          .select(targetDatabase.focusSessionRows)
          .get();

      expect(focus, hasLength(1));

      expect(focus.single.durationMinutes, 50);

      final metadata = await targetDatabase
          .select(targetDatabase.appMetadata)
          .get();

      expect(metadata.any((row) => row.key == 'unrelated:key'), isTrue);

      // V4 restore does not recreate retired legacy mirrors.
      expect(metadata.any((row) => row.key == 'task:$taskId:extras'), isFalse);

      expect(metadata.any((row) => row.key == 'focus:sessions:v1'), isFalse);
    } finally {
      await sourceDatabase.close();
      await targetDatabase.close();

      if (await sourceRoot.exists()) {
        await sourceRoot.delete(recursive: true);
      }

      if (await targetRoot.exists()) {
        await targetRoot.delete(recursive: true);
      }
    }
  });

  test(
    'v4 rejects attachment traversal before replacing current database',
    () async {
      final root = await Directory.systemTemp.createTemp('perfica_v4_unsafe_');

      final database = AppDatabase.forTesting(NativeDatabase.memory());

      try {
        final attachments = AttachmentService(
          supportDirectoryProvider: () async => root,
        );

        await database
            .into(database.tasks)
            .insert(TasksCompanion.insert(title: 'Keep current data'));

        final manifest = {
          'formatVersion': 4,
          'tasks': [
            {
              'id': 1,
              'title': 'Replacement',
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
          'completionEvents': <dynamic>[],
          'metadata': <dynamic>[],
          'taskExtras': [
            {
              'taskId': 1,
              'recurrence': null,
              'monthlyAnchorDay': null,
              'reminderAt': null,
              'reminderRepeatMinutes': null,
              'reminderSnoozedUntil': null,
              'tags': <dynamic>[],
              'attachments': ['attachments/../evil.txt'],
            },
          ],
          'focusSessions': <dynamic>[],
        };

        final archive = Archive()
          ..add(ArchiveFile.string('manifest.json', jsonEncode(manifest)))
          ..add(ArchiveFile.bytes('attachments/../evil.txt', const [1, 2, 3]));

        final restorer = PortableBackupRestorer(
          database,
          attachments,
          BackupService(database),
        );

        await expectLater(
          restorer.restore(ZipEncoder().encodeBytes(archive)),
          throwsFormatException,
        );

        final tasks = await database.select(database.tasks).get();

        expect(tasks, hasLength(1));

        expect(tasks.single.title, 'Keep current data');
      } finally {
        await database.close();

        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    },
  );
}
