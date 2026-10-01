import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import 'about_settings_page.dart';
import 'appearance_settings_page.dart';
import 'data_backup_settings_page.dart';
import 'help_feedback_settings_page.dart';
import 'notifications_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
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
                    _SettingsDestinationTile(
                      icon: Icons.palette_outlined,
                      title: l.appearance,
                      subtitle: l.settingsAppearanceDescription,
                      onTap: () {
                        _openPage(context, const AppearanceSettingsPage());
                      },
                    ),
                    _SettingsDestinationTile(
                      icon: Icons.notifications_outlined,
                      title: l.notifications,
                      subtitle: l.settingsNotificationsDescription,
                      onTap: () {
                        _openPage(context, const NotificationsSettingsPage());
                      },
                    ),
                    _SettingsDestinationTile(
                      icon: Icons.storage_outlined,
                      title: l.settingsDataBackupTitle,
                      subtitle: l.settingsDataBackupDescription,
                      onTap: () {
                        _openPage(context, const DataBackupSettingsPage());
                      },
                    ),
                    _SettingsDestinationTile(
                      icon: Icons.help_outline_rounded,
                      title: l.settingsHelpFeedbackTitle,
                      subtitle: l.settingsHelpFeedbackDescription,
                      onTap: () {
                        _openPage(context, const HelpFeedbackSettingsPage());
                      },
                    ),
                    _SettingsDestinationTile(
                      icon: Icons.info_outline_rounded,
                      title: l.about,
                      subtitle: l.settingsAboutDescription,
                      onTap: () {
                        _openPage(context, const AboutSettingsPage());
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

class _SettingsDestinationTile extends StatelessWidget {
  const _SettingsDestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
