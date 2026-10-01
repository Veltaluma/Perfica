import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/focus/domain/pomodoro_settings.dart';
import 'package:perfica/features/focus/presentation/cubit/pomodoro_settings_cubit.dart';
import 'package:perfica/features/focus/presentation/focus_settings_page.dart';
import 'package:perfica/features/settings/data/app_preferences.dart';
import 'package:perfica/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PomodoroSettingsCubit settingsCubit;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    settingsCubit = PomodoroSettingsCubit(
      AppPreferences(),
      initialSettings: PomodoroSettings.defaults,
    );
  });

  tearDown(() async {
    await settingsCubit.close();
  });

  Widget buildApp() {
    return BlocProvider<PomodoroSettingsCubit>.value(
      value: settingsCubit,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FocusSettingsPage(),
      ),
    );
  }

  testWidgets('renders default pomodoro settings', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final l = AppLocalizations.of(
      tester.element(find.byType(FocusSettingsPage)),
    );

    expect(find.text(l.focusSettingsTitle), findsOneWidget);
    expect(find.text(l.pomodoroFocusDuration), findsOneWidget);
    expect(find.text(l.pomodoroShortBreakDuration), findsOneWidget);
    expect(find.text(l.pomodoroLongBreakDuration), findsOneWidget);
    expect(find.text(l.pomodoroSessionsPerCycle), findsOneWidget);
  });

  testWidgets('auto start breaks toggle updates settings', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final l = AppLocalizations.of(
      tester.element(find.byType(FocusSettingsPage)),
    );

    final tile = find.widgetWithText(SwitchListTile, l.pomodoroAutoStartBreaks);

    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(settingsCubit.state.autoStartBreaks, isTrue);
  });

  testWidgets('focus duration dialog updates focus minutes', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final l = AppLocalizations.of(
      tester.element(find.byType(FocusSettingsPage)),
    );

    final tile = find.widgetWithText(ListTile, l.pomodoroFocusDuration);

    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '50');

    await tester.tap(find.widgetWithText(FilledButton, l.apply));

    await tester.pumpAndSettle();

    expect(settingsCubit.state.focusMinutes, 50);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('invalid focus duration keeps dialog open', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final l = AppLocalizations.of(
      tester.element(find.byType(FocusSettingsPage)),
    );

    final tile = find.widgetWithText(ListTile, l.pomodoroFocusDuration);

    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '0');

    await tester.tap(find.widgetWithText(FilledButton, l.apply));

    await tester.pump();

    expect(find.text(l.pomodoroInvalidValue), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(settingsCubit.state.focusMinutes, 25);
  });
}
