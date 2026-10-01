import '../../domain/pomodoro_phase.dart';
import '../../domain/pomodoro_settings.dart';

class FocusState {
  const FocusState({
    required this.phase,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.sessionsPerCycle,
    required this.completedInCycle,
    required this.remainingSeconds,
    required this.isRunning,
    required this.breakWasSkipped,
    required this.autoStartBreaks,
    required this.autoStartFocus,
    required this.completionSound,
    required this.vibration,
    this.endsAt,
  });

  factory FocusState.initial(PomodoroSettings settings) {
    return FocusState(
      phase: PomodoroPhase.focus,
      focusMinutes: settings.focusMinutes,
      shortBreakMinutes: settings.shortBreakMinutes,
      longBreakMinutes: settings.longBreakMinutes,
      sessionsPerCycle: settings.sessionsPerCycle,
      completedInCycle: 0,
      remainingSeconds: settings.focusMinutes * 60,
      isRunning: false,
      breakWasSkipped: false,
      autoStartBreaks: settings.autoStartBreaks,
      autoStartFocus: settings.autoStartFocus,
      completionSound: settings.completionSound,
      vibration: settings.vibration,
    );
  }

  final PomodoroPhase phase;

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsPerCycle;

  final int completedInCycle;
  final int remainingSeconds;

  final bool isRunning;
  final bool breakWasSkipped;

  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool completionSound;
  final bool vibration;

  final DateTime? endsAt;

  int get phaseMinutes {
    return switch (phase) {
      PomodoroPhase.focus => focusMinutes,
      PomodoroPhase.shortBreak => shortBreakMinutes,
      PomodoroPhase.longBreak => longBreakMinutes,
    };
  }

  int get phaseTotalSeconds => phaseMinutes * 60;

  int get currentSession {
    if (phase == PomodoroPhase.longBreak) {
      return sessionsPerCycle;
    }

    final value = completedInCycle + 1;

    return value.clamp(1, sessionsPerCycle);
  }

  double get progress {
    if (phaseTotalSeconds <= 0) {
      return 0;
    }

    return (1 - (remainingSeconds / phaseTotalSeconds)).clamp(0.0, 1.0);
  }

  FocusState copyWith({
    PomodoroPhase? phase,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsPerCycle,
    int? completedInCycle,
    int? remainingSeconds,
    bool? isRunning,
    bool? breakWasSkipped,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? completionSound,
    bool? vibration,
    DateTime? endsAt,
    bool clearEndsAt = false,
  }) {
    return FocusState(
      phase: phase ?? this.phase,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsPerCycle: sessionsPerCycle ?? this.sessionsPerCycle,
      completedInCycle: completedInCycle ?? this.completedInCycle,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      breakWasSkipped: breakWasSkipped ?? this.breakWasSkipped,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      completionSound: completionSound ?? this.completionSound,
      vibration: vibration ?? this.vibration,
      endsAt: clearEndsAt ? null : endsAt ?? this.endsAt,
    );
  }
}
