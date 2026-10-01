class PomodoroSettings {
  const PomodoroSettings({
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.sessionsPerCycle,
    required this.autoStartBreaks,
    required this.autoStartFocus,
    required this.completionSound,
    required this.vibration,
  });

  static const defaults = PomodoroSettings(
    focusMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    sessionsPerCycle: 4,
    autoStartBreaks: false,
    autoStartFocus: false,
    completionSound: true,
    vibration: true,
  );

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsPerCycle;

  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool completionSound;
  final bool vibration;

  PomodoroSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsPerCycle,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? completionSound,
    bool? vibration,
  }) {
    return PomodoroSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsPerCycle: sessionsPerCycle ?? this.sessionsPerCycle,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      completionSound: completionSound ?? this.completionSound,
      vibration: vibration ?? this.vibration,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PomodoroSettings &&
        other.focusMinutes == focusMinutes &&
        other.shortBreakMinutes == shortBreakMinutes &&
        other.longBreakMinutes == longBreakMinutes &&
        other.sessionsPerCycle == sessionsPerCycle &&
        other.autoStartBreaks == autoStartBreaks &&
        other.autoStartFocus == autoStartFocus &&
        other.completionSound == completionSound &&
        other.vibration == vibration;
  }

  @override
  int get hashCode {
    return Object.hash(
      focusMinutes,
      shortBreakMinutes,
      longBreakMinutes,
      sessionsPerCycle,
      autoStartBreaks,
      autoStartFocus,
      completionSound,
      vibration,
    );
  }
}
