import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/attachment_service.dart';
import 'package:perfica/core/services/portable_backup_builder.dart';

void main() {
  late Directory temporaryRoot;
  late AppDatabase database;
  late AttachmentService attachments;
  late PortableBackupBuilder builder;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'perfica_backup_v4_test_',
    );

    database = AppDatabase.forTesting(NativeDatabase.memory());

    attachments = AttachmentService(
      supportDirectoryProvider: () async => temporaryRoot,
    );

    builder = PortableBackupBuilder(database, attachments);
  });

  tearDown(() async {
    await database.close();

    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('v4 zip exports normalized task extras and focus sessions', () async {
    final taskId = await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Portable task'));

    final storedPath = await attachments.importBytes(
      bytes: const [1, 2, 3, 254, 255],
      fileName: 'receipt photo.jpg',
    );

    await database
        .into(database.taskExtrasRows)
        .insert(
          TaskExtrasRowsCompanion.insert(
            taskId: Value(taskId),
            recurrence: const Value('weekly'),
            monthlyAnchorDay: const Value(31),
            reminderRepeatMinutes: const Value(10),
          ),
        );

    await database
        .into(database.taskTagsRows)
        .insert(
          TaskTagsRowsCompanion.insert(
            taskId: taskId,
            position: 0,
            value: 'travel',
          ),
        );

    await database
        .into(database.taskAttachmentsRows)
        .insert(
          TaskAttachmentsRowsCompanion.insert(
            taskId: taskId,
            position: 0,
            path: storedPath,
          ),
        );

    await database
        .into(database.focusSessionRows)
        .insert(
          FocusSessionRowsCompanion.insert(
            completedAt: DateTime(2099, 1, 2, 8),
            durationMinutes: 25,
          ),
        );

    // Deliberately stale transitional mirrors.
    await database
        .into(database.appMetadata)
        .insert(
          AppMetadataCompanion.insert(
            key: 'task:$taskId:extras',
            value: '{"recurrence":"daily"}',
            updatedAt: DateTime(2099, 1, 2),
          ),
        );

    await database
        .into(database.appMetadata)
        .insert(
          AppMetadataCompanion.insert(
            key: 'focus:sessions:v1',
            value: '[]',
            updatedAt: DateTime(2099, 1, 2),
          ),
        );

    await database
        .into(database.appMetadata)
        .insert(
          AppMetadataCompanion.insert(
            key: 'unrelated:key',
            value: '{"theme":"system"}',
            updatedAt: DateTime(2099, 1, 2),
          ),
        );

    final zipBytes = await builder.build();

    final archive = ZipDecoder().decodeBytes(zipBytes);

    final manifestBytes = archive.find('manifest.json')!.readBytes()!;

    final manifest =
        jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;

    expect(manifest['formatVersion'], 4);

    final taskExtras = manifest['taskExtras'] as List<dynamic>;

    expect(taskExtras, hasLength(1));

    final extras = taskExtras.single as Map<String, dynamic>;

    expect(extras['taskId'], taskId);

    expect(extras['recurrence'], 'weekly');

    expect(extras['monthlyAnchorDay'], 31);

    expect(extras['reminderRepeatMinutes'], 10);

    expect(extras['tags'], ['travel']);

    final portablePath =
        (extras['attachments'] as List<dynamic>).single as String;

    expect(portablePath, startsWith('attachments/'));

    expect(portablePath, isNot(storedPath));

    expect(archive.find(portablePath)!.readBytes(), const [1, 2, 3, 254, 255]);

    final focus = manifest['focusSessions'] as List<dynamic>;

    expect(focus, hasLength(1));

    expect((focus.single as Map<String, dynamic>)['durationMinutes'], 25);

    final metadata = manifest['metadata'] as List<dynamic>;

    expect(metadata, hasLength(1));

    expect((metadata.single as Map<String, dynamic>)['key'], 'unrelated:key');

    expect(utf8.decode(manifestBytes), isNot(contains(temporaryRoot.path)));
  });

  test('v4 export promotes valid legacy task extras when normalized rows are absent', () async {
    final taskId = await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Legacy fallback'));

    final storedPath = await attachments.importBytes(
      bytes: const [9, 8, 7],
      fileName: 'legacy.bin',
    );

    await database
        .into(database.appMetadata)
        .insert(
          AppMetadataCompanion.insert(
            key: 'task:$taskId:extras',
            value: jsonEncode({
              'recurrence': 'monthly',
              'monthlyAnchorDay': 31,
              'tags': ['legacy'],
              'attachments': [storedPath],
            }),
            updatedAt: DateTime(2099, 2, 1),
          ),
        );

    final archive = ZipDecoder().decodeBytes(await builder.build());

    final manifest = jsonDecode(
      utf8.decode(archive.find('manifest.json')!.readBytes()!),
    ) as Map<String, dynamic>;

    final extras =
        (manifest['taskExtras'] as List<dynamic>).single
            as Map<String, dynamic>;

    expect(extras['recurrence'], 'monthly');

    expect(extras['monthlyAnchorDay'], 31);

    expect(extras['tags'], ['legacy']);

    expect(manifest['metadata'], isEmpty);
  });

  test('v4 zip preserves unrelated metadata unchanged', () async {
    const metadataValue = '{"theme":"system"}';

    await database
        .into(database.appMetadata)
        .insert(
          AppMetadataCompanion.insert(
            key: 'unrelated:key',
            value: metadataValue,
            updatedAt: DateTime(2099, 3, 1),
          ),
        );

    final archive = ZipDecoder().decodeBytes(await builder.build());

    final manifest = jsonDecode(
      utf8.decode(archive.find('manifest.json')!.readBytes()!),
    ) as Map<String, dynamic>;

    final metadata = manifest['metadata'] as List<dynamic>;

    expect(metadata, hasLength(1));

    expect((metadata.single as Map<String, dynamic>)['value'], metadataValue);
  });

  test('v4 zip rejects unmanaged normalized attachment paths', () async {
    final taskId = await database
        .into(database.tasks)
        .insert(TasksCompanion.insert(title: 'Unsafe task'));

    final outsideFile = File(
      '${temporaryRoot.path}'
      '${Platform.pathSeparator}'
      'outside.txt',
    );

    await outsideFile.writeAsString('outside');

    await database
        .into(database.taskExtrasRows)
        .insert(TaskExtrasRowsCompanion.insert(taskId: Value(taskId)));

    await database
        .into(database.taskAttachmentsRows)
        .insert(
          TaskAttachmentsRowsCompanion.insert(
            taskId: taskId,
            position: 0,
            path: outsideFile.path,
          ),
        );

    await expectLater(builder.build(), throwsStateError);
  });
}
