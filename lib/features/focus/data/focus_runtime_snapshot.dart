import '../domain/pomodoro_phase.dart';

class FocusRuntimeSnapshot {
  const FocusRuntimeSnapshot({
    required this.phase,
    required this.completedInCycle,
    required this.remainingSeconds,
    required this.isRunning,
    required this.breakWasSkipped,
    this.endsAt,
  });

  final PomodoroPhase phase;
  final int completedInCycle;
  final int remainingSeconds;
  final bool isRunning;
  final bool breakWasSkipped;
  final DateTime? endsAt;
}
