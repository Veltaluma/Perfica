import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

class HelpFeedbackSettingsPage extends StatelessWidget {
  const HelpFeedbackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsHelpFeedbackTitle)),
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
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(l.reportBug),
                  subtitle: Text(l.reportBugDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    context.pushNamed(RouteNames.bugReport);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
