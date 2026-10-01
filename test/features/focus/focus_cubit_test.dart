import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/focus/data/focus_repository.dart';
import 'package:perfica/features/focus/domain/pomodoro_phase.dart';
import 'package:perfica/features/focus/domain/pomodoro_settings.dart';
import 'package:perfica/features/focus/presentation/cubit/focus_cubit.dart';

void main() {
  late AppDatabase database;
  late FocusRepository repository;
  late FakeNotificationService notifications;
  late DateTime now;
  late FocusCubit cubit;

  FocusCubit createCubit(PomodoroSettings settings) {
    return FocusCubit(
      repository,
      notifications,
      const FocusNotificationMessages(
        focusCompleteTitle: 'Focus complete',
        focusCompleteBody: 'Take a break.',
        breakCompleteTitle: 'Break complete',
        breakCompleteBody: 'Ready to focus.',
      ),
      initialSettings: settings,
      now: () => now,
    );
  }

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = FocusRepository(database);
    notifications = FakeNotificationService();

    now = DateTime(2026, 9, 24, 10);

    cubit = createCubit(PomodoroSettings.defaults);
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('starts with default Pomodoro settings', () {
    expect(cubit.state.phase, PomodoroPhase.focus);

    expect(cubit.state.focusMinutes, 25);

    expect(cubit.state.shortBreakMinutes, 5);

    expect(cubit.state.longBreakMinutes, 15);

    expect(cubit.state.sessionsPerCycle, 4);

    expect(cubit.state.remainingSeconds, 25 * 60);

    expect(cubit.state.completedInCycle, 0);

    expect(cubit.state.currentSession, 1);

    expect(cubit.state.isRunning, isFalse);
  });

  test('completed focus moves to short break and records history', () async {
    await cubit.start();

    now = now.add(const Duration(minutes: 25, seconds: 1));

    await cubit.syncClock();

    expect(cubit.state.phase, PomodoroPhase.shortBreak);

    expect(cubit.state.completedInCycle, 1);

    expect(cubit.state.breakWasSkipped, isFalse);

    expect(cubit.state.isRunning, isFalse);

    final sessions = await repository.getSessions();

    expect(sessions, hasLength(1));

    expect(sessions.single.durationMinutes, 25);

    expect(notifications.immediateShowCount, 1);

    expect(notifications.lastImmediateTitle, 'Focus complete');
  });

  test('skipping focus does not show completion feedback', () async {
    await cubit.skipPhase();

    expect(cubit.state.phase, PomodoroPhase.shortBreak);

    expect(cubit.state.completedInCycle, 0);

    expect(cubit.state.breakWasSkipped, isTrue);

    expect(notifications.immediateShowCount, 0);

    final sessions = await repository.getSessions();

    expect(sessions, isEmpty);
  });

  test('completed break shows break completion feedback', () async {
    await cubit.close();

    cubit = createCubit(
      PomodoroSettings.defaults.copyWith(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        sessionsPerCycle: 2,
      ),
    );

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    expect(notifications.immediateShowCount, 1);

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    expect(notifications.immediateShowCount, 2);

    expect(notifications.lastImmediateTitle, 'Break complete');
  });

  test('second completed focus enters long break', () async {
    await cubit.close();

    cubit = createCubit(
      PomodoroSettings.defaults.copyWith(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        longBreakMinutes: 2,
        sessionsPerCycle: 2,
      ),
    );

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    await cubit.skipPhase();

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    expect(cubit.state.phase, PomodoroPhase.longBreak);

    expect(cubit.state.completedInCycle, 2);

    expect(cubit.state.remainingSeconds, 2 * 60);
  });

  test('finishing long break resets cycle', () async {
    await cubit.close();

    cubit = createCubit(
      PomodoroSettings.defaults.copyWith(
        focusMinutes: 1,
        longBreakMinutes: 1,
        sessionsPerCycle: 1,
      ),
    );

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    expect(cubit.state.phase, PomodoroPhase.longBreak);

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    expect(cubit.state.phase, PomodoroPhase.focus);

    expect(cubit.state.completedInCycle, 0);

    expect(cubit.state.currentSession, 1);
  });

  test('auto-start break works after completed focus', () async {
    await cubit.close();

    cubit = createCubit(
      PomodoroSettings.defaults.copyWith(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        autoStartBreaks: true,
      ),
    );

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    expect(cubit.state.phase, PomodoroPhase.shortBreak);

    expect(cubit.state.isRunning, isTrue);
  });

  test('auto-start focus works after completed break', () async {
    await cubit.close();

    cubit = createCubit(
      PomodoroSettings.defaults.copyWith(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        sessionsPerCycle: 2,
        autoStartFocus: true,
      ),
    );

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    await cubit.start();

    now = now.add(const Duration(minutes: 1, seconds: 1));

    await cubit.syncClock();

    expect(cubit.state.phase, PomodoroPhase.focus);

    expect(cubit.state.currentSession, 2);

    expect(cubit.state.isRunning, isTrue);
  });

  test(
    'sound and vibration enabled are forwarded to scheduled notification',
    () async {
      await cubit.start();

      expect(notifications.scheduledPlaySound, isTrue);

      expect(notifications.scheduledEnableVibration, isTrue);
    },
  );

  test(
    'sound and vibration disabled are forwarded to scheduled notification',
    () async {
      await cubit.close();

      cubit = createCubit(
        PomodoroSettings.defaults.copyWith(
          completionSound: false,
          vibration: false,
        ),
      );

      await cubit.start();

      expect(notifications.scheduledPlaySound, isFalse);

      expect(notifications.scheduledEnableVibration, isFalse);
    },
  );

  test(
    'sound and vibration settings are forwarded to immediate completion',
    () async {
      await cubit.close();

      cubit = createCubit(
        PomodoroSettings.defaults.copyWith(
          focusMinutes: 1,
          completionSound: false,
          vibration: true,
        ),
      );

      await cubit.start();

      now = now.add(const Duration(minutes: 1, seconds: 1));

      await cubit.syncClock();

      expect(notifications.immediateShowCount, 1);

      expect(notifications.lastImmediatePlaySound, isFalse);

      expect(notifications.lastImmediateEnableVibration, isTrue);
    },
  );

  test('reset cycle returns to first focus session', () async {
    await cubit.skipPhase();
    await cubit.resetCycle();

    expect(cubit.state.phase, PomodoroPhase.focus);

    expect(cubit.state.completedInCycle, 0);

    expect(cubit.state.currentSession, 1);

    expect(cubit.state.remainingSeconds, 25 * 60);

    expect(cubit.state.isRunning, isFalse);
  });
}

class FakeNotificationService extends NotificationService {
  DateTime? scheduledAt;

  String? scheduledTitle;
  String? scheduledBody;

  bool? scheduledPlaySound;
  bool? scheduledEnableVibration;

  int cancelCount = 0;
  int immediateShowCount = 0;

  String? lastImmediateTitle;
  String? lastImmediateBody;

  bool? lastImmediatePlaySound;
  bool? lastImmediateEnableVibration;

  @override
  Future<void> scheduleFocusPhase({
    required DateTime when,
    required String title,
    required String body,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    scheduledAt = when;
    scheduledTitle = title;
    scheduledBody = body;

    scheduledPlaySound = playSound;
    scheduledEnableVibration = enableVibration;
  }

  @override
  Future<void> showFocusCompletion({
    required String title,
    required String body,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    immediateShowCount++;

    lastImmediateTitle = title;
    lastImmediateBody = body;

    lastImmediatePlaySound = playSound;

    lastImmediateEnableVibration = enableVibration;
  }

  @override
  Future<void> cancelFocusPhase() async {
    cancelCount++;
  }
}
