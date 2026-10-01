import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../../settings/data/app_preferences.dart';
import '../../data/focus_repository.dart';
import '../../data/focus_runtime_snapshot.dart';
import '../../data/focus_session.dart';
import '../../domain/pomodoro_phase.dart';
import '../../domain/pomodoro_settings.dart';
import 'focus_state.dart';

class FocusNotificationMessages {
  const FocusNotificationMessages({
    required this.focusCompleteTitle,
    required this.focusCompleteBody,
    required this.breakCompleteTitle,
    required this.breakCompleteBody,
  });

  final String focusCompleteTitle;
  final String focusCompleteBody;
  final String breakCompleteTitle;
  final String breakCompleteBody;
}

class FocusCubit extends Cubit<FocusState> {
  FocusCubit(
    this._repository,
    this._notificationService,
    this._messages, {
    required PomodoroSettings initialSettings,
    this._runtimePreferences,
    FocusRuntimeSnapshot? initialRuntime,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(
         _restoreInitialState(
           initialSettings,
           initialRuntime,
           (now ?? DateTime.now)(),
         ),
       ) {
    if (state.isRunning) {
      _startTicker();
    }
  }

  final FocusRepository _repository;
  final NotificationService _notificationService;
  final FocusNotificationMessages _messages;
  final AppPreferences? _runtimePreferences;
  final DateTime Function() _now;

  Timer? _ticker;
  bool _finishingPhase = false;

  static FocusState _restoreInitialState(
    PomodoroSettings settings,
    FocusRuntimeSnapshot? runtime,
    DateTime now,
  ) {
    final initial = FocusState.initial(settings);

    if (runtime == null) {
      return initial;
    }

    final totalSeconds = switch (runtime.phase) {
      PomodoroPhase.focus => settings.focusMinutes * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak => settings.longBreakMinutes * 60,
    };

    final completedInCycle = runtime.completedInCycle.clamp(
      0,
      settings.sessionsPerCycle,
    );

    final canRun = runtime.isRunning && runtime.endsAt != null;

    final remainingSeconds = canRun
        ? math.max(
            0,
            math.min(
              totalSeconds,
              (runtime.endsAt!.difference(now).inMilliseconds / 1000).ceil(),
            ),
          )
        : runtime.remainingSeconds.clamp(0, totalSeconds);

    return initial.copyWith(
      phase: runtime.phase,
      completedInCycle: completedInCycle,
      remainingSeconds: remainingSeconds,
      isRunning: canRun,
      breakWasSkipped: runtime.breakWasSkipped,
      endsAt: canRun ? runtime.endsAt : null,
      clearEndsAt: !canRun,
    );
  }

  Future<void> start() async {
    if (state.isRunning) {
      return;
    }

    final remaining = state.remainingSeconds <= 0
        ? state.phaseTotalSeconds
        : state.remainingSeconds;

    final endsAt = _now().add(Duration(seconds: remaining));

    _emitPersistent(
      state.copyWith(
        remainingSeconds: remaining,
        isRunning: true,
        endsAt: endsAt,
      ),
    );

    _startTicker();

    final notification = _notificationForCurrentPhase();

    try {
      await _notificationService.scheduleFocusPhase(
        when: endsAt,
        title: notification.$1,
        body: notification.$2,
        playSound: state.completionSound,
        enableVibration: state.vibration,
      );
    } catch (_) {
      // The timer remains functional even when scheduling fails.
    }
  }

  Future<void> pause() async {
    if (!state.isRunning) {
      return;
    }

    await syncClock();

    _ticker?.cancel();

    try {
      await _notificationService.cancelFocusPhase();
    } catch (_) {}

    _emitPersistent(state.copyWith(isRunning: false, clearEndsAt: true));
  }

  Future<void> toggle() async {
    if (state.isRunning) {
      await pause();
    } else {
      await start();
    }
  }

  Future<void> resetPhase() async {
    _ticker?.cancel();

    try {
      await _notificationService.cancelFocusPhase();
    } catch (_) {}

    _emitPersistent(
      state.copyWith(
        remainingSeconds: state.phaseTotalSeconds,
        isRunning: false,
        clearEndsAt: true,
      ),
    );
  }

  Future<void> resetCycle() async {
    _ticker?.cancel();

    try {
      await _notificationService.cancelFocusPhase();
    } catch (_) {}

    _emitPersistent(
      state.copyWith(
        phase: PomodoroPhase.focus,
        completedInCycle: 0,
        remainingSeconds: state.focusMinutes * 60,
        isRunning: false,
        breakWasSkipped: false,
        clearEndsAt: true,
      ),
    );
  }

  Future<void> skipPhase() async {
    _ticker?.cancel();

    try {
      await _notificationService.cancelFocusPhase();
    } catch (_) {}

    if (state.phase == PomodoroPhase.focus) {
      _emitPersistent(
        state.copyWith(
          phase: PomodoroPhase.shortBreak,
          remainingSeconds: state.shortBreakMinutes * 60,
          isRunning: false,
          breakWasSkipped: true,
          clearEndsAt: true,
        ),
      );

      return;
    }

    final completed = state.phase == PomodoroPhase.longBreak
        ? 0
        : state.completedInCycle;

    _emitPersistent(
      state.copyWith(
        phase: PomodoroPhase.focus,
        completedInCycle: completed,
        remainingSeconds: state.focusMinutes * 60,
        isRunning: false,
        breakWasSkipped: false,
        clearEndsAt: true,
      ),
    );
  }

  void setFocusMinutes(int minutes) {
    if (state.isRunning || state.phase != PomodoroPhase.focus) {
      return;
    }

    _emitPersistent(
      state.copyWith(focusMinutes: minutes, remainingSeconds: minutes * 60),
    );
  }

  void applySettings(PomodoroSettings settings) {
    final previousTotal = state.phaseTotalSeconds;

    final wasAtPhaseStart =
        !state.isRunning && state.remainingSeconds == previousTotal;

    final completed = state.completedInCycle.clamp(
      0,
      settings.sessionsPerCycle,
    );

    var next = state.copyWith(
      focusMinutes: settings.focusMinutes,
      shortBreakMinutes: settings.shortBreakMinutes,
      longBreakMinutes: settings.longBreakMinutes,
      sessionsPerCycle: settings.sessionsPerCycle,
      completedInCycle: completed,
      autoStartBreaks: settings.autoStartBreaks,
      autoStartFocus: settings.autoStartFocus,
      completionSound: settings.completionSound,
      vibration: settings.vibration,
    );

    if (wasAtPhaseStart) {
      next = next.copyWith(remainingSeconds: next.phaseTotalSeconds);
    }

    _emitPersistent(next);
  }

  Future<void> syncClock() async {
    if (!state.isRunning || state.endsAt == null || _finishingPhase) {
      return;
    }

    final milliseconds = state.endsAt!.difference(_now()).inMilliseconds;

    final remaining = milliseconds <= 0
        ? 0
        : math.max(1, (milliseconds / 1000).ceil());

    if (remaining <= 0) {
      await _finishPhase();
      return;
    }

    if (remaining != state.remainingSeconds) {
      // A ticking second is transient. Persisting every second would create
      // unnecessary I/O; endsAt is the durable source of truth while running.
      emit(state.copyWith(remainingSeconds: remaining));
    }
  }

  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      syncClock();
    });
  }

  void _emitPersistent(FocusState next) {
    emit(next);

    unawaited(_persistRuntime(next));
  }

  Future<void> _persistRuntime(FocusState value) async {
    final preferences = _runtimePreferences;

    if (preferences == null) {
      return;
    }

    try {
      await preferences.writeFocusRuntimeSnapshot(
        FocusRuntimeSnapshot(
          phase: value.phase,
          completedInCycle: value.completedInCycle,
          remainingSeconds: value.remainingSeconds,
          isRunning: value.isRunning,
          breakWasSkipped: value.breakWasSkipped,
          endsAt: value.endsAt,
        ),
      );
    } catch (_) {
      // Persistence failure must never break the focus timer.
    }
  }

  (String, String) _notificationForCurrentPhase() {
    if (state.phase == PomodoroPhase.focus) {
      return (_messages.focusCompleteTitle, _messages.focusCompleteBody);
    }

    return (_messages.breakCompleteTitle, _messages.breakCompleteBody);
  }

  Future<void> _showCompletionFeedback({
    required String title,
    required String body,
  }) async {
    try {
      await _notificationService.showFocusCompletion(
        title: title,
        body: body,
        playSound: state.completionSound,
        enableVibration: state.vibration,
      );
    } catch (_) {
      // Sound/vibration feedback must never break Pomodoro flow.
    }
  }

  Future<void> _finishPhase() async {
    if (_finishingPhase) {
      return;
    }

    _finishingPhase = true;
    _ticker?.cancel();

    try {
      try {
        await _notificationService.cancelFocusPhase();
      } catch (_) {}

      if (state.phase == PomodoroPhase.focus) {
        await _finishFocusPhase();
        return;
      }

      await _finishBreakPhase();
    } finally {
      _finishingPhase = false;
    }
  }

  Future<void> _finishFocusPhase() async {
    await _showCompletionFeedback(
      title: _messages.focusCompleteTitle,
      body: _messages.focusCompleteBody,
    );

    await _repository.addSession(
      FocusSession(completedAt: _now(), durationMinutes: state.focusMinutes),
    );

    final completed = state.completedInCycle + 1;

    final longBreak = completed >= state.sessionsPerCycle;

    final nextPhase = longBreak
        ? PomodoroPhase.longBreak
        : PomodoroPhase.shortBreak;

    final nextSeconds = longBreak
        ? state.longBreakMinutes * 60
        : state.shortBreakMinutes * 60;

    _emitPersistent(
      state.copyWith(
        phase: nextPhase,
        completedInCycle: completed,
        remainingSeconds: nextSeconds,
        isRunning: false,
        breakWasSkipped: false,
        clearEndsAt: true,
      ),
    );

    if (state.autoStartBreaks) {
      await start();
    }
  }

  Future<void> _finishBreakPhase() async {
    await _showCompletionFeedback(
      title: _messages.breakCompleteTitle,
      body: _messages.breakCompleteBody,
    );

    final wasLongBreak = state.phase == PomodoroPhase.longBreak;

    final completed = wasLongBreak ? 0 : state.completedInCycle;

    _emitPersistent(
      state.copyWith(
        phase: PomodoroPhase.focus,
        completedInCycle: completed,
        remainingSeconds: state.focusMinutes * 60,
        isRunning: false,
        breakWasSkipped: false,
        clearEndsAt: true,
      ),
    );

    if (state.autoStartFocus) {
      await start();
    }
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();

    await _persistRuntime(state);

    return super.close();
  }
}
