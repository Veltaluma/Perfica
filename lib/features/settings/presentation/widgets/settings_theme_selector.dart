import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class SettingsThemeSelector extends StatelessWidget {
  const SettingsThemeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
        ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
        ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
      ],
      selected: {value},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }

        onChanged(selection.first);
      },
    );
  }
}
