import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/settings/presentation/pages/settings_page.dart';
import 'package:perfica/l10n/app_localizations.dart';

void main() {
  testWidgets('root settings exposes five focused destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Data & backup'), findsOneWidget);
    expect(find.text('Help & feedback'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    expect(find.byType(ListTile), findsNWidgets(5));
  });
}
