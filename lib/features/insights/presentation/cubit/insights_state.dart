enum InsightsStatus { loading, success, failure }

class InsightsDaySummary {
  const InsightsDaySummary({
    required this.date,
    required this.completedTasks,
    required this.focusMinutes,
  });

  final DateTime date;
  final int completedTasks;
  final int focusMinutes;
}

class InsightsPeriodSummary {
  const InsightsPeriodSummary({
    required this.completedTasks,
    required this.focusMinutes,
  });

  const InsightsPeriodSummary.zero() : completedTasks = 0, focusMinutes = 0;

  final int completedTasks;
  final int focusMinutes;
}

class InsightsState {
  const InsightsState({
    required this.status,
    required this.completedToday,
    required this.completedTotal,
    required this.currentStreak,
    required this.focusMinutes,
    required this.last7Days,
    required this.thisWeek,
    required this.previousWeek,
    required this.thisMonth,
    required this.bestDay,
    required this.averageTasksPerDay,
    required this.averageFocusMinutesPerDay,
    required this.tasksWeekOverWeekPercent,
    required this.focusWeekOverWeekPercent,
  });

  const InsightsState.initial()
    : status = InsightsStatus.loading,
      completedToday = 0,
      completedTotal = 0,
      currentStreak = 0,
      focusMinutes = 0,
      last7Days = const [],
      thisWeek = const InsightsPeriodSummary.zero(),
      previousWeek = const InsightsPeriodSummary.zero(),
      thisMonth = const InsightsPeriodSummary.zero(),
      bestDay = null,
      averageTasksPerDay = 0,
      averageFocusMinutesPerDay = 0,
      tasksWeekOverWeekPercent = null,
      focusWeekOverWeekPercent = null;

  final InsightsStatus status;

  final int completedToday;
  final int completedTotal;
  final int currentStreak;
  final int focusMinutes;

  final List<InsightsDaySummary> last7Days;

  final InsightsPeriodSummary thisWeek;
  final InsightsPeriodSummary previousWeek;
  final InsightsPeriodSummary thisMonth;

  final InsightsDaySummary? bestDay;

  final double averageTasksPerDay;
  final double averageFocusMinutesPerDay;

  final double? tasksWeekOverWeekPercent;
  final double? focusWeekOverWeekPercent;

  InsightsState copyWith({
    InsightsStatus? status,
    int? completedToday,
    int? completedTotal,
    int? currentStreak,
    int? focusMinutes,
    List<InsightsDaySummary>? last7Days,
    InsightsPeriodSummary? thisWeek,
    InsightsPeriodSummary? previousWeek,
    InsightsPeriodSummary? thisMonth,
    InsightsDaySummary? bestDay,
    bool clearBestDay = false,
    double? averageTasksPerDay,
    double? averageFocusMinutesPerDay,
    double? tasksWeekOverWeekPercent,
    bool clearTasksWeekOverWeekPercent = false,
    double? focusWeekOverWeekPercent,
    bool clearFocusWeekOverWeekPercent = false,
  }) {
    return InsightsState(
      status: status ?? this.status,
      completedToday: completedToday ?? this.completedToday,
      completedTotal: completedTotal ?? this.completedTotal,
      currentStreak: currentStreak ?? this.currentStreak,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      last7Days: last7Days ?? this.last7Days,
      thisWeek: thisWeek ?? this.thisWeek,
      previousWeek: previousWeek ?? this.previousWeek,
      thisMonth: thisMonth ?? this.thisMonth,
      bestDay: clearBestDay ? null : bestDay ?? this.bestDay,
      averageTasksPerDay: averageTasksPerDay ?? this.averageTasksPerDay,
      averageFocusMinutesPerDay:
          averageFocusMinutesPerDay ?? this.averageFocusMinutesPerDay,
      tasksWeekOverWeekPercent: clearTasksWeekOverWeekPercent
          ? null
          : tasksWeekOverWeekPercent ?? this.tasksWeekOverWeekPercent,
      focusWeekOverWeekPercent: clearFocusWeekOverWeekPercent
          ? null
          : focusWeekOverWeekPercent ?? this.focusWeekOverWeekPercent,
    );
  }
}
