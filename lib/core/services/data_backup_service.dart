import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'backup_service.dart';
import 'portable_backup_builder.dart';
import 'portable_backup_restorer.dart';

class DataBackupService {
  DataBackupService(
    this._legacyBackupService,
    this._portableBuilder,
    this._portableRestorer,
  );

  final BackupService _legacyBackupService;
  final PortableBackupBuilder _portableBuilder;
  final PortableBackupRestorer _portableRestorer;

  Future<List<int>> createPortableBackupBytes() {
    return _portableBuilder.build();
  }

  Future<bool> exportBackup() async {
    final bytes = await createPortableBackupBytes();

    final fileName =
        'perfica-backup-'
        '${DateTime.now().millisecondsSinceEpoch}'
        '.perfica';

    final savedFile = await FilePicker.saveFile(
      dialogTitle: 'Save Perfica backup',
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/zip',
    );

    return savedFile != null;
  }

  Future<bool> restoreFromPicker() async {
    final file = await FilePicker.pickFile(type: FileType.any);

    if (file == null) {
      return false;
    }

    await restoreFromBytes(
      bytes: await file.readAsBytes(),
      fileName: file.name,
    );

    return true;
  }

  Future<void> restoreFromBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    final extension = p.extension(fileName).toLowerCase();

    switch (extension) {
      case '.perfica':
        await _portableRestorer.restore(bytes);

      case '.json':
        await _legacyBackupService.restoreFromBytes(bytes);

      default:
        throw const FormatException('Unsupported backup file type.');
    }
  }
}
