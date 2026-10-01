import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/focus/data/focus_repository.dart';
import 'package:perfica/features/focus/data/focus_runtime_snapshot.dart';
import 'package:perfica/features/focus/domain/pomodoro_phase.dart';
import 'package:perfica/features/focus/domain/pomodoro_settings.dart';
import 'package:perfica/features/focus/presentation/cubit/focus_cubit.dart';

void main() {
  late AppDatabase database;
  late FocusRepository repository;
  late DateTime now;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = FocusRepository(database);

    now = DateTime(2026, 9, 28, 13);
  });

  tearDown(() async {
    await database.close();
  });

  FocusCubit createCubit(FocusRuntimeSnapshot runtime) {
    return FocusCubit(
      repository,
      _NoopNotificationService(),
      const FocusNotificationMessages(
        focusCompleteTitle: 'Focus complete',
        focusCompleteBody: 'Take a break.',
        breakCompleteTitle: 'Break complete',
        breakCompleteBody: 'Ready to focus.',
      ),
      initialSettings: PomodoroSettings.defaults,
      initialRuntime: runtime,
      now: () => now,
    );
  }

  test('restores a running focus session from endsAt', () async {
    final cubit = createCubit(
      FocusRuntimeSnapshot(
        phase: PomodoroPhase.focus,
        completedInCycle: 1,
        remainingSeconds: 999,
        isRunning: true,
        breakWasSkipped: false,
        endsAt: now.add(const Duration(minutes: 10)),
      ),
    );

    addTearDown(cubit.close);

    expect(cubit.state.phase, PomodoroPhase.focus);

    expect(cubit.state.isRunning, isTrue);

    expect(cubit.state.remainingSeconds, 10 * 60);

    expect(cubit.state.completedInCycle, 1);
  });

  test('expired restored focus completes on syncClock', () async {
    final cubit = createCubit(
      FocusRuntimeSnapshot(
        phase: PomodoroPhase.focus,
        completedInCycle: 0,
        remainingSeconds: 1,
        isRunning: true,
        breakWasSkipped: false,
        endsAt: now.subtract(const Duration(seconds: 5)),
      ),
    );

    addTearDown(cubit.close);

    await cubit.syncClock();

    expect(cubit.state.phase, PomodoroPhase.shortBreak);

    expect(cubit.state.isRunning, isFalse);

    expect((await repository.getSessions()), hasLength(1));
  });

  test('restores paused state without an end time', () async {
    final cubit = createCubit(
      const FocusRuntimeSnapshot(
        phase: PomodoroPhase.shortBreak,
        completedInCycle: 2,
        remainingSeconds: 123,
        isRunning: false,
        breakWasSkipped: false,
      ),
    );

    addTearDown(cubit.close);

    expect(cubit.state.phase, PomodoroPhase.shortBreak);

    expect(cubit.state.isRunning, isFalse);

    expect(cubit.state.remainingSeconds, 123);
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
