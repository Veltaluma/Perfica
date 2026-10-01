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
  late Directory targetRoot;
  late AppDatabase targetDatabase;
  late AttachmentService targetAttachments;
  late BackupService targetBackupService;
  late PortableBackupRestorer restorer;

  setUp(() async {
    targetRoot = await Directory.systemTemp.createTemp(
      'perfica_v3_restore_target_',
    );

    targetDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    targetAttachments = AttachmentService(
      supportDirectoryProvider: () async => targetRoot,
    );

    targetBackupService = BackupService(targetDatabase);

    restorer = PortableBackupRestorer(
      targetDatabase,
      targetAttachments,
      targetBackupService,
    );
  });

  tearDown(() async {
    await targetDatabase.close();

    if (await targetRoot.exists()) {
      await targetRoot.delete(recursive: true);
    }
  });

  test(
    'v4 legacy-source round trip restores attachment into normalized storage',
    () async {
      final sourceRoot = await Directory.systemTemp.createTemp(
        'perfica_v4_legacy_source_',
      );

      final sourceDatabase = AppDatabase.forTesting(NativeDatabase.memory());

      try {
        final sourceAttachments = AttachmentService(
          supportDirectoryProvider: () async => sourceRoot,
        );

        final taskId = await sourceDatabase
            .into(sourceDatabase.tasks)
            .insert(TasksCompanion.insert(title: 'Portable task'));

        final sourcePath = await sourceAttachments.importBytes(
          bytes: const [10, 20, 30, 200],
          fileName: 'document.bin',
        );

        // Simulate a transitional database that still has
        // only legacy task-extras metadata.
        await sourceDatabase
            .into(sourceDatabase.appMetadata)
            .insert(
              AppMetadataCompanion.insert(
                key: 'task:$taskId:extras',
                value: jsonEncode({
                  'tags': ['portable'],
                  'attachments': [sourcePath],
                }),
                updatedAt: DateTime(2099, 1, 2),
              ),
            );

        final builder = PortableBackupBuilder(
          sourceDatabase,
          sourceAttachments,
        );

        final bytes = await builder.build();

        await restorer.restore(bytes);

        final tasks = await targetDatabase.select(targetDatabase.tasks).get();

        expect(tasks, hasLength(1));

        expect(tasks.single.title, 'Portable task');

        final extras = await targetDatabase
            .select(targetDatabase.taskExtrasRows)
            .get();

        expect(extras, hasLength(1));

        expect(extras.single.taskId, taskId);

        final tags = await targetDatabase
            .select(targetDatabase.taskTagsRows)
            .get();

        expect(tags, hasLength(1));

        expect(tags.single.value, 'portable');

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

        // V4 must not recreate retired compatibility mirrors.
        final metadata = await targetDatabase
            .select(targetDatabase.appMetadata)
            .get();

        expect(metadata, isEmpty);
      } finally {
        await sourceDatabase.close();

        if (await sourceRoot.exists()) {
          await sourceRoot.delete(recursive: true);
        }
      }
    },
  );

  test(
    'v3 restore normalizes legacy task metadata and restores attachment',
    () async {
      final manifest = {
        'formatVersion': 3,
        'tasks': [
          {
            'id': 1,
            'title': 'Legacy portable task',
            'description': null,
            'isCompleted': false,
            'priority': 0,
            'workflowStatus': 0,
            'dueAt': null,
            'createdAt': '2099-01-01T08:00:00.000',
            'updatedAt': '2099-01-01T08:00:00.000',
            'completedAt': null,
            'sortOrder': 0,
          },
        ],
        'subtasks': <dynamic>[],
        'completionEvents': <dynamic>[],
        'metadata': [
          {
            'key': 'task:1:extras',
            'value': jsonEncode({
              'recurrence': 'weekly',
              'monthlyAnchorDay': 31,
              'reminderAt': '2099-01-02T09:00:00.000',
              'reminderRepeatMinutes': 20,
              'reminderSnoozedUntil': '2099-01-02T09:15:00.000',
              'tags': ['legacy'],
              'attachments': ['attachments/000001_document.bin'],
            }),
            'updatedAt': '2099-01-01T08:00:00.000',
          },
        ],
      };

      final bytes = _createZip(
        manifest,
        attachments: {
          'attachments/000001_document.bin': const [11, 22, 33, 201],
        },
      );

      await restorer.restore(bytes);

      final tasks = await targetDatabase.select(targetDatabase.tasks).get();

      expect(tasks, hasLength(1));

      expect(tasks.single.title, 'Legacy portable task');

      // Valid transitional metadata is retired immediately.
      expect(
        await targetDatabase.select(targetDatabase.appMetadata).get(),
        isEmpty,
      );

      final extras = await targetDatabase
          .select(targetDatabase.taskExtrasRows)
          .get();

      expect(extras, hasLength(1));
      expect(extras.single.taskId, 1);
      expect(extras.single.recurrence, 'weekly');
      expect(extras.single.monthlyAnchorDay, 31);
      expect(extras.single.reminderRepeatMinutes, 20);

      final tags = await targetDatabase
          .select(targetDatabase.taskTagsRows)
          .get();

      expect(tags, hasLength(1));
      expect(tags.single.value, 'legacy');

      final attachments = await targetDatabase
          .select(targetDatabase.taskAttachmentsRows)
          .get();

      expect(attachments, hasLength(1));

      final restoredPath = attachments.single.path;

      expect(restoredPath, isNot('attachments/000001_document.bin'));

      expect(await targetAttachments.isManagedPath(restoredPath), isTrue);

      expect(await targetAttachments.readStored(restoredPath), const [
        11,
        22,
        33,
        201,
      ]);
    },
  );

  test(
    'v3 restore rejects attachment traversal and preserves database',
    () async {
      await targetDatabase
          .into(targetDatabase.tasks)
          .insert(TasksCompanion.insert(title: 'Existing task'));

      final manifest = {
        'formatVersion': 3,
        'tasks': <dynamic>[],
        'subtasks': <dynamic>[],
        'completionEvents': <dynamic>[],
        'metadata': [
          {
            'key': 'task:1:extras',
            'value': jsonEncode({
              'attachments': ['attachments/../evil.txt'],
            }),
            'updatedAt': '2099-01-01T00:00:00.000',
          },
        ],
      };

      final bytes = _createZip(
        manifest,
        attachments: {
          'attachments/../evil.txt': const [1, 2, 3],
        },
      );

      await expectLater(restorer.restore(bytes), throwsFormatException);

      final tasks = await targetDatabase.select(targetDatabase.tasks).get();

      expect(tasks, hasLength(1));

      expect(tasks.single.title, 'Existing task');
    },
  );

  test(
    'v3 restore rejects missing attachment and preserves database',
    () async {
      await targetDatabase
          .into(targetDatabase.tasks)
          .insert(TasksCompanion.insert(title: 'Keep current data'));

      final manifest = {
        'formatVersion': 3,
        'tasks': <dynamic>[],
        'subtasks': <dynamic>[],
        'completionEvents': <dynamic>[],
        'metadata': [
          {
            'key': 'task:1:extras',
            'value': jsonEncode({
              'attachments': ['attachments/000001_missing.txt'],
            }),
            'updatedAt': '2099-01-01T00:00:00.000',
          },
        ],
      };

      final bytes = _createZip(manifest);

      await expectLater(restorer.restore(bytes), throwsFormatException);

      final tasks = await targetDatabase.select(targetDatabase.tasks).get();

      expect(tasks, hasLength(1));

      expect(tasks.single.title, 'Keep current data');
    },
  );

  test('database restore failure removes newly imported files and preserves old attachment', () async {
    final oldTaskId = await targetDatabase
        .into(targetDatabase.tasks)
        .insert(TasksCompanion.insert(title: 'Old task'));

    final oldPath = await targetAttachments.importBytes(
      bytes: const [9, 9, 9],
      fileName: 'old.txt',
    );

    await targetDatabase
        .into(targetDatabase.appMetadata)
        .insert(
          AppMetadataCompanion.insert(
            key: 'task:$oldTaskId:extras',
            value: jsonEncode({
              'attachments': [oldPath],
            }),
            updatedAt: DateTime(2099, 1, 1),
          ),
        );

    final manifest = {
      'formatVersion': 3,
      'tasks': [
        {
          'id': 99,
          // Deliberately missing title.
          'description': null,
          'isCompleted': false,
          'priority': 0,
          'workflowStatus': 0,
          'dueAt': null,
          'createdAt': '2099-02-01T00:00:00.000',
          'updatedAt': '2099-02-01T00:00:00.000',
          'completedAt': null,
          'sortOrder': 0,
        },
      ],
      'subtasks': <dynamic>[],
      'completionEvents': <dynamic>[],
      'metadata': [
        {
          'key': 'task:99:extras',
          'value': jsonEncode({
            'attachments': ['attachments/000001_new.txt'],
          }),
          'updatedAt': '2099-02-01T00:00:00.000',
        },
      ],
    };

    final bytes = _createZip(
      manifest,
      attachments: {
        'attachments/000001_new.txt': const [1, 2, 3, 4],
      },
    );

    await expectLater(restorer.restore(bytes), throwsA(anything));

    final tasks = await targetDatabase.select(targetDatabase.tasks).get();

    expect(tasks, hasLength(1));

    expect(tasks.single.title, 'Old task');

    expect(await File(oldPath).exists(), isTrue);

    final attachmentDirectory = Directory(
      '${targetRoot.path}'
      '${Platform.pathSeparator}'
      'attachments',
    );

    final files = await attachmentDirectory
        .list()
        .where((entity) => entity is File)
        .toList();

    expect(files, hasLength(1));

    expect(files.single.path, oldPath);
  });
}

List<int> _createZip(
  Map<String, dynamic> manifest, {
  Map<String, List<int>> attachments = const {},
}) {
  final archive = Archive();

  archive.add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));

  for (final entry in attachments.entries) {
    archive.add(ArchiveFile.bytes(entry.key, entry.value));
  }

  return ZipEncoder().encodeBytes(archive);
}
