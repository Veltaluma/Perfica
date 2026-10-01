import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/settings/presentation/widgets/settings_theme_selector.dart';
import 'package:perfica/l10n/app_localizations.dart';

Widget _buildTestApp({
  required ThemeMode value,
  required ValueChanged<ThemeMode> onChanged,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SettingsThemeSelector(value: value, onChanged: onChanged),
    ),
  );
}

void main() {
  testWidgets('renders localized theme choices and selected state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(value: ThemeMode.dark, onChanged: (_) {}),
    );

    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);

    expect(find.text('Light'), findsOneWidget);

    expect(find.text('Dark'), findsOneWidget);

    final selector = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );

    expect(selector.selected, {ThemeMode.dark});
  });

  testWidgets('reports newly selected theme mode', (tester) async {
    ThemeMode? selected;

    await tester.pumpWidget(
      _buildTestApp(
        value: ThemeMode.system,
        onChanged: (value) {
          selected = value;
        },
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Light'));

    await tester.pump();

    expect(selected, ThemeMode.light);
  });
}
