import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:perfica/core/services/attachment_service.dart';

void main() {
  late Directory temporaryRoot;
  late AttachmentService service;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'perfica_attachment_test_',
    );

    service = AttachmentService(
      supportDirectoryProvider: () async => temporaryRoot,
    );
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('import and read round trip preserves attachment bytes', () async {
    final path = await service.importBytes(
      bytes: const [1, 2, 3, 4, 255],
      fileName: 'document.bin',
    );

    expect(await service.isManagedPath(path), isTrue);

    expect(await File(path).exists(), isTrue);

    expect(await service.readStored(path), const [1, 2, 3, 4, 255]);
  });

  test('import sanitizes traversal-like file names', () async {
    final path = await service.importBytes(
      bytes: const [10, 20],
      fileName: r'../../..\outside.txt',
    );

    final attachmentRoot = p.normalize(
      p.join(temporaryRoot.path, 'attachments'),
    );

    final normalizedPath = p.normalize(path);

    expect(p.isWithin(attachmentRoot, normalizedPath), isTrue);

    expect(p.basename(normalizedPath), isNot(contains('..')));

    expect(p.basename(normalizedPath), endsWith('outside.txt'));
  });

  test('read rejects paths outside managed attachment directory', () async {
    final outsideFile = File(
      p.join(temporaryRoot.parent.path, 'perfica-unmanaged-test.txt'),
    );

    await outsideFile.writeAsString('outside');

    try {
      await expectLater(
        service.readStored(outsideFile.path),
        throwsArgumentError,
      );
    } finally {
      if (await outsideFile.exists()) {
        await outsideFile.delete();
      }
    }
  });

  test('delete removes managed file but ignores unmanaged file', () async {
    final managedPath = await service.importBytes(
      bytes: const [1],
      fileName: 'managed.txt',
    );

    final outsideFile = File(
      p.join(temporaryRoot.parent.path, 'perfica-delete-guard-test.txt'),
    );

    await outsideFile.writeAsString('keep');

    await service.deleteStored(managedPath);

    await service.deleteStored(outsideFile.path);

    expect(await File(managedPath).exists(), isFalse);

    expect(await outsideFile.exists(), isTrue);

    if (await outsideFile.exists()) {
      await outsideFile.delete();
    }
  });
}
