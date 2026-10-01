import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/services/data_backup_service.dart';
import '../../../../l10n/app_localizations.dart';

class DataBackupSettingsPage extends StatelessWidget {
  const DataBackupSettingsPage({super.key});

  Future<void> _exportBackup(BuildContext context) async {
    final l = AppLocalizations.of(context);

    try {
      await context.read<DataBackupService>().exportBackup();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.backupFailed)));
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final l = AppLocalizations.of(context);

    try {
      final restored = await context
          .read<DataBackupService>()
          .restoreFromPicker();

      if (restored && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.backupRestored)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.backupFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsDataBackupTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.upload_file_rounded),
                      title: Text(l.exportBackup),
                      subtitle: Text(l.settingsExportBackupDescription),
                      onTap: () {
                        _exportBackup(context);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restore_rounded),
                      title: Text(l.restoreBackup),
                      subtitle: Text(l.settingsRestoreBackupDescription),
                      onTap: () {
                        _restoreBackup(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
