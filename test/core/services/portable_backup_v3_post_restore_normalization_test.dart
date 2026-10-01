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

  late Directory root;
  late AppDatabase database;
  late AttachmentService attachments;
  late PortableBackupRestorer restorer;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('perfica_v3_normalization_');

    database = AppDatabase.forTesting(NativeDatabase.memory());

    attachments = AttachmentService(supportDirectoryProvider: () async => root);

    restorer = PortableBackupRestorer(
      database,
      attachments,
      BackupService(database),
    );
  });

  tearDown(() async {
    await database.close();

    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test(
    'valid V3 focus metadata is normalized and V4 re-export stays normalized',
    () async {
      final manifest = {
        'formatVersion': 3,
        'tasks': <dynamic>[],
        'subtasks': <dynamic>[],
        'completionEvents': <dynamic>[],
        'metadata': [
          {
            'key': 'focus:sessions:v1',
            'value': jsonEncode([
              {'completedAt': '2099-03-01T08:00:00.000', 'durationMinutes': 25},
              {'completedAt': '2099-03-01T09:00:00.000', 'durationMinutes': 50},
            ]),
            'updatedAt': '2099-03-01T10:00:00.000',
          },
          {
            'key': 'unrelated:test',
            'value': '{"preserve":true}',
            'updatedAt': '2099-03-01T10:00:00.000',
          },
        ],
      };

      await restorer.restore(_createZip(manifest));

      final focus = await database.select(database.focusSessionRows).get();

      expect(focus, hasLength(2));

      expect(focus.map((row) => row.durationMinutes).toList(), [25, 50]);

      final metadata = await database.select(database.appMetadata).get();

      expect(metadata, hasLength(1));

      expect(metadata.single.key, 'unrelated:test');

      final builder = PortableBackupBuilder(database, attachments);

      final bytes = await builder.build();

      final archive = ZipDecoder().decodeBytes(bytes);

      final manifestBytes = archive.find('manifest.json')!.readBytes()!;

      final exported =
          jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;

      expect(exported['formatVersion'], 4);

      final exportedFocus = exported['focusSessions'] as List<dynamic>;

      expect(exportedFocus, hasLength(2));

      final exportedMetadata = exported['metadata'] as List<dynamic>;

      expect(exportedMetadata, hasLength(1));

      expect(
        (exportedMetadata.single as Map<String, dynamic>)['key'],
        'unrelated:test',
      );
    },
  );

  test(
    'V3 normalization preserves malformed orphan and unrelated metadata',
    () async {
      final manifest = {
        'formatVersion': 3,
        'tasks': [
          {
            'id': 1,
            'title': 'Compatibility task',
            'description': null,
            'isCompleted': false,
            'priority': 0,
            'workflowStatus': 0,
            'dueAt': null,
            'createdAt': '2099-04-01T08:00:00.000',
            'updatedAt': '2099-04-01T08:00:00.000',
            'completedAt': null,
            'sortOrder': 0,
          },
        ],
        'subtasks': <dynamic>[],
        'completionEvents': <dynamic>[],
        'metadata': [
          {
            'key': 'task:1:extras',
            'value': jsonEncode({'recurrence': 42}),
            'updatedAt': '2099-04-01T09:00:00.000',
          },
          {
            'key': 'task:999:extras',
            'value': jsonEncode({
              'recurrence': 'daily',
              'tags': <String>[],
              'attachments': <String>[],
            }),
            'updatedAt': '2099-04-01T09:00:00.000',
          },
          {
            'key': 'focus:sessions:v1',
            'value': jsonEncode([
              {'completedAt': 'not-a-date', 'durationMinutes': 25},
            ]),
            'updatedAt': '2099-04-01T09:00:00.000',
          },
          {
            'key': 'unrelated:test',
            'value': '{"keep":true}',
            'updatedAt': '2099-04-01T09:00:00.000',
          },
        ],
      };

      await restorer.restore(_createZip(manifest));

      expect(await database.select(database.taskExtrasRows).get(), isEmpty);

      expect(await database.select(database.taskTagsRows).get(), isEmpty);

      expect(
        await database.select(database.taskAttachmentsRows).get(),
        isEmpty,
      );

      expect(await database.select(database.focusSessionRows).get(), isEmpty);

      final metadata = await database.select(database.appMetadata).get();

      final keys = metadata.map((row) => row.key).toSet();

      expect(keys, {
        'task:1:extras',
        'task:999:extras',
        'focus:sessions:v1',
        'unrelated:test',
      });
    },
  );
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
