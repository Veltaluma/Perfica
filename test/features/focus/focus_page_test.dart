import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/focus/data/focus_repository.dart';
import 'package:perfica/features/focus/domain/pomodoro_phase.dart';
import 'package:perfica/features/focus/domain/pomodoro_settings.dart';
import 'package:perfica/features/focus/presentation/cubit/focus_cubit.dart';
import 'package:perfica/features/focus/presentation/cubit/pomodoro_settings_cubit.dart';
import 'package:perfica/features/focus/presentation/focus_page.dart';
import 'package:perfica/features/settings/data/app_preferences.dart';
import 'package:perfica/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late FocusRepository repository;
  late FocusCubit focusCubit;
  late PomodoroSettingsCubit settingsCubit;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FocusRepository(database);

    focusCubit = FocusCubit(
      repository,
      _NoopNotificationService(),
      const FocusNotificationMessages(
        focusCompleteTitle: 'Focus complete',
        focusCompleteBody: 'Take a break.',
        breakCompleteTitle: 'Break complete',
        breakCompleteBody: 'Ready to focus.',
      ),
      initialSettings: PomodoroSettings.defaults,
    );

    settingsCubit = PomodoroSettingsCubit(
      AppPreferences(),
      initialSettings: PomodoroSettings.defaults,
    );
  });

  tearDown(() async {
    await focusCubit.close();
    await settingsCubit.close();
    await database.close();
  });

  Widget buildApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FocusCubit>.value(value: focusCubit),
        BlocProvider<PomodoroSettingsCubit>.value(value: settingsCubit),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FocusPage(),
      ),
    );
  }

  testWidgets('renders default focus timer state', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('25 min'), findsWidgets);
  });

  testWidgets('preset duration updates focus settings', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final preset = find.widgetWithText(ChoiceChip, '50 min');

    await tester.ensureVisible(preset);
    await tester.pumpAndSettle();

    await tester.tap(preset);
    await tester.pumpAndSettle();

    expect(settingsCubit.state.focusMinutes, 50);
    expect(focusCubit.state.focusMinutes, 50);
    expect(find.text('50:00'), findsOneWidget);
  });

  testWidgets('start action starts the current focus phase', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final l = AppLocalizations.of(tester.element(find.byType(FocusPage)));

    final startButton = find.widgetWithText(FilledButton, l.focusStart);

    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();

    await tester.tap(startButton);
    await tester.pump();

    expect(focusCubit.state.isRunning, isTrue);
    expect(focusCubit.state.endsAt, isNotNull);

    // Stop the periodic production ticker before the widget test ends.
    await focusCubit.pause();
    await tester.pump();

    expect(focusCubit.state.isRunning, isFalse);
    expect(focusCubit.state.endsAt, isNull);
  });

  testWidgets('skip action moves focus to short break', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final l = AppLocalizations.of(tester.element(find.byType(FocusPage)));

    final skipButton = find.widgetWithText(OutlinedButton, l.pomodoroSkipPhase);

    await tester.ensureVisible(skipButton);
    await tester.pumpAndSettle();

    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    expect(focusCubit.state.phase, PomodoroPhase.shortBreak);

    expect(focusCubit.state.breakWasSkipped, isTrue);
  });
}

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> scheduleFocusPhase({
    required DateTime when,
    required String title,
    required String body,
    bool playSound = true,
    bool enableVibration = true,
  }) async {}

  @override
  Future<void> cancelFocusPhase() async {}

  @override
  Future<void> showFocusCompletion({
    required String title,
    required String body,
    bool playSound = true,
    bool enableVibration = true,
  }) async {}
}
