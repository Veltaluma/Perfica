import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

class AttachmentService {
  AttachmentService({SupportDirectoryProvider? supportDirectoryProvider})
    : _supportDirectoryProvider =
          supportDirectoryProvider ?? getApplicationSupportDirectory;

  final SupportDirectoryProvider _supportDirectoryProvider;

  Future<String?> pickAndStore() async {
    final picked = await FilePicker.pickFile();

    if (picked == null) {
      return null;
    }

    if (picked.path != null && picked.path!.isNotEmpty) {
      final bytes = await File(picked.path!).readAsBytes();

      return importBytes(bytes: bytes, fileName: picked.name);
    }

    return importBytes(
      bytes: await picked.readAsBytes(),
      fileName: picked.name,
    );
  }

  Future<String> importBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    final directory = await _attachmentDirectory();

    final safeName = _sanitizeFileName(fileName);

    final targetPath = p.join(
      directory.path,
      '${DateTime.now().microsecondsSinceEpoch}_$safeName',
    );

    final file = File(targetPath);

    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  Future<List<int>> readStored(String path) async {
    final normalizedInput = path.trim();

    if (normalizedInput.isEmpty) {
      throw ArgumentError.value(
        path,
        'path',
        'Attachment path must not be empty.',
      );
    }

    if (!await isManagedPath(normalizedInput)) {
      throw ArgumentError.value(
        path,
        'path',
        'Attachment path is outside the managed attachment directory.',
      );
    }

    return File(normalizedInput).readAsBytes();
  }

  Future<bool> isManagedPath(String path) async {
    final normalizedInput = path.trim();

    if (normalizedInput.isEmpty) {
      return false;
    }

    final root = await _attachmentDirectory();

    final attachmentRoot = p.normalize(root.absolute.path);

    final targetPath = p.normalize(File(normalizedInput).absolute.path);

    return p.isWithin(attachmentRoot, targetPath);
  }

  Future<void> deleteStored(String path) async {
    final normalizedInput = path.trim();

    if (normalizedInput.isEmpty) {
      return;
    }

    if (!await isManagedPath(normalizedInput)) {
      return;
    }

    final target = File(normalizedInput);

    try {
      if (await target.exists()) {
        await target.delete();
      }
    } on FileSystemException {
      // Best-effort cleanup.
    }
  }

  Future<Directory> _attachmentDirectory() async {
    final root = await _supportDirectoryProvider();

    final directory = Directory(p.join(root.path, 'attachments'));

    await directory.create(recursive: true);

    return directory;
  }

  String _sanitizeFileName(String fileName) {
    final normalized = fileName.trim().replaceAll(r'\', '/');

    var name = p.posix.basename(normalized);

    if (name.isEmpty || name == '.' || name == '..') {
      name = 'attachment';
    }

    name = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');

    if (name.isEmpty) {
      return 'attachment';
    }

    return name;
  }
}
