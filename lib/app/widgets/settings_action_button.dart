import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../router/route_names.dart';

class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return IconButton(
      tooltip: l.settingsTitle,
      onPressed: () {
        context.pushNamed(RouteNames.settings);
      },
      icon: const Icon(Icons.settings_outlined),
    );
  }
}
