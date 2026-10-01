import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/services/update_service.dart';
import '../../../../l10n/app_localizations.dart';

class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({super.key});

  @override
  State<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) {
        return;
      }

      setState(() {
        _version = info.version;
      });
    } catch (_) {
      // Version metadata is supplementary; About remains usable.
    }
  }

  Future<void> _checkUpdates() async {
    final l = AppLocalizations.of(context);

    try {
      final result = await context.read<UpdateService>().check();

      if (!mounted) {
        return;
      }

      final message = result.latestVersion == null
          ? l.updateUnavailable
          : result.hasUpdate
          ? l.updateAvailable
          : l.upToDate;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: result.hasUpdate && result.releaseUrl != null
              ? SnackBarAction(
                  label: l.openAction,
                  onPressed: () {
                    launchUrl(
                      result.releaseUrl!,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                )
              : null,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.updateUnavailable)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
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
                      leading: const Icon(Icons.apps_rounded),
                      title: Text(l.appName),
                      subtitle: Text(l.developerBy),
                    ),
                    if (_version != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(l.versionLabel(_version!)),
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.system_update_alt_rounded),
                      title: Text(l.checkUpdates),
                      subtitle: Text(l.settingsCheckUpdatesDescription),
                      onTap: _checkUpdates,
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
