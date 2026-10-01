import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/attachment_service.dart';
import 'package:perfica/core/services/backup_service.dart';
import 'package:perfica/core/services/data_backup_service.dart';
import 'package:perfica/core/services/portable_backup_builder.dart';
import 'package:perfica/core/services/portable_backup_restorer.dart';

void main() {
  late Directory temporaryRoot;
  late AppDatabase database;
  late AttachmentService attachments;
  late BackupService legacy;
  late DataBackupService service;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'perfica_data_backup_test_',
    );

    database = AppDatabase.forTesting(NativeDatabase.memory());

    attachments = AttachmentService(
      supportDirectoryProvider: () async => temporaryRoot,
    );

    legacy = BackupService(database);

    final builder = PortableBackupBuilder(database, attachments);

    final restorer = PortableBackupRestorer(database, attachments, legacy);

    service = DataBackupService(legacy, builder, restorer);
  });

  tearDown(() async {
    await database.close();

    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('portable production backup uses v4 manifest', () async {
    await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Portable export'));

    final bytes = await service.createPortableBackupBytes();

    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.find('manifest.json');

    expect(manifestFile, isNotNull);

    final manifest = jsonDecode(
      utf8.decode(manifestFile!.readBytes()!),
    ) as Map<String, dynamic>;

    expect(manifest['formatVersion'], 4);

    expect(manifest['tasks'], hasLength(1));
  });

  test('json extension routes legacy v1 restore', () async {
    final legacyBackup = {
      'formatVersion': 1,
      'tasks': [
        {
          'id': 7,
          'title': 'Legacy imported task',
          'description': null,
          'isCompleted': false,
          'priority': 0,
          'dueAt': null,
          'createdAt': '2099-01-01T00:00:00.000',
          'updatedAt': '2099-01-01T00:00:00.000',
          'completedAt': null,
          'sortOrder': 0,
        },
      ],
      'subtasks': <dynamic>[],
      'metadata': <dynamic>[],
    };

    await service.restoreFromBytes(
      bytes: utf8.encode(jsonEncode(legacyBackup)),
      fileName: 'legacy-backup.json',
    );

    final tasks = await database.select(database.tasks).get();

    expect(tasks, hasLength(1));

    expect(tasks.single.title, 'Legacy imported task');
  });

  test('perfica extension routes portable v3 restore', () async {
    final manifest = {
      'formatVersion': 3,
      'tasks': [
        {
          'id': 88,
          'title': 'Portable imported task',
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
      'metadata': <dynamic>[],
      'completionEvents': <dynamic>[],
    };

    final archive = Archive();

    archive.add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));

    final bytes = ZipEncoder().encodeBytes(archive);

    await service.restoreFromBytes(
      bytes: bytes,
      fileName: 'portable-backup.perfica',
    );

    final tasks = await database.select(database.tasks).get();

    expect(tasks, hasLength(1));

    expect(tasks.single.id, 88);

    expect(tasks.single.title, 'Portable imported task');
  });

  test('unsupported extension does not alter database', () async {
    await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Keep current task'));

    await expectLater(
      service.restoreFromBytes(bytes: const [1, 2, 3], fileName: 'backup.txt'),
      throwsFormatException,
    );

    final tasks = await database.select(database.tasks).get();

    expect(tasks, hasLength(1));

    expect(tasks.single.title, 'Keep current task');
  });
}
