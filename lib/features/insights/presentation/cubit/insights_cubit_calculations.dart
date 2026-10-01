part of 'insights_cubit.dart';

InsightsState _buildInsightsState({
  required List<TaskCompletion> completions,
  required List<FocusSession> focusSessions,
  required DateTime now,
}) {
  final completedToday = completions
      .where((completion) => _isSameCalendarDay(completion.completedAt, now))
      .length;

  final focusMinutes = focusSessions.fold<int>(
    0,
    (sum, session) => sum + session.durationMinutes,
  );

  final today = _calendarDate(now);
  final weekStart = _startOfIsoWeek(today);
  final previousWeekStart = _addCalendarDays(weekStart, -7);
  final previousWeekEnd = _addCalendarDays(weekStart, -1);
  final monthStart = DateTime(today.year, today.month, 1);

  final last7Days = _buildLast7Days(
    completions: completions,
    focusSessions: focusSessions,
    now: now,
  );

  final thisWeek = _buildPeriodSummary(
    completions: completions,
    focusSessions: focusSessions,
    start: weekStart,
    end: today,
  );

  final previousWeek = _buildPeriodSummary(
    completions: completions,
    focusSessions: focusSessions,
    start: previousWeekStart,
    end: previousWeekEnd,
  );

  final previousComparableWeekEnd = _addCalendarDays(
    previousWeekStart,
    today.weekday - DateTime.monday,
  );

  final previousComparableWeek = _buildPeriodSummary(
    completions: completions,
    focusSessions: focusSessions,
    start: previousWeekStart,
    end: previousComparableWeekEnd,
  );

  final thisMonth = _buildPeriodSummary(
    completions: completions,
    focusSessions: focusSessions,
    start: monthStart,
    end: today,
  );

  return InsightsState(
    status: InsightsStatus.success,
    completedToday: completedToday,
    completedTotal: completions.length,
    currentStreak: _calculateStreak(
      completions
          .map((completion) => completion.completedAt)
          .toList(growable: false),
      now,
    ),
    focusMinutes: focusMinutes,
    last7Days: last7Days,
    thisWeek: thisWeek,
    previousWeek: previousWeek,
    thisMonth: thisMonth,
    bestDay: _calculateBestDay(last7Days),
    averageTasksPerDay: _averageCompletedTasks(last7Days),
    averageFocusMinutesPerDay: _averageFocusMinutes(last7Days),
    tasksWeekOverWeekPercent: _calculatePercentChange(
      current: thisWeek.completedTasks,
      previous: previousComparableWeek.completedTasks,
    ),
    focusWeekOverWeekPercent: _calculatePercentChange(
      current: thisWeek.focusMinutes,
      previous: previousComparableWeek.focusMinutes,
    ),
  );
}

List<InsightsDaySummary> _buildLast7Days({
  required List<TaskCompletion> completions,
  required List<FocusSession> focusSessions,
  required DateTime now,
}) {
  final today = _calendarDate(now);
  final result = <InsightsDaySummary>[];

  for (var offset = 6; offset >= 0; offset--) {
    final date = _addCalendarDays(today, -offset);

    final completedTasks = completions
        .where((completion) => _isSameCalendarDay(completion.completedAt, date))
        .length;

    final focusMinutes = focusSessions
        .where((session) => _isSameCalendarDay(session.completedAt, date))
        .fold<int>(0, (sum, session) => sum + session.durationMinutes);

    result.add(
      InsightsDaySummary(
        date: date,
        completedTasks: completedTasks,
        focusMinutes: focusMinutes,
      ),
    );
  }

  return List.unmodifiable(result);
}

InsightsPeriodSummary _buildPeriodSummary({
  required List<TaskCompletion> completions,
  required List<FocusSession> focusSessions,
  required DateTime start,
  required DateTime end,
}) {
  final completedTasks = completions
      .where(
        (completion) =>
            _isWithinCalendarRange(completion.completedAt, start, end),
      )
      .length;

  final focusMinutes = focusSessions
      .where(
        (session) => _isWithinCalendarRange(session.completedAt, start, end),
      )
      .fold<int>(0, (sum, session) => sum + session.durationMinutes);

  return InsightsPeriodSummary(
    completedTasks: completedTasks,
    focusMinutes: focusMinutes,
  );
}

InsightsDaySummary? _calculateBestDay(List<InsightsDaySummary> days) {
  InsightsDaySummary? best;

  for (final day in days) {
    if (day.completedTasks <= 0) {
      continue;
    }

    if (best == null ||
        day.completedTasks > best.completedTasks ||
        day.completedTasks == best.completedTasks &&
            day.date.isAfter(best.date)) {
      best = day;
    }
  }

  return best;
}

double _averageCompletedTasks(List<InsightsDaySummary> days) {
  if (days.isEmpty) {
    return 0;
  }

  final total = days.fold<int>(0, (sum, day) => sum + day.completedTasks);

  return total / days.length;
}

double _averageFocusMinutes(List<InsightsDaySummary> days) {
  if (days.isEmpty) {
    return 0;
  }

  final total = days.fold<int>(0, (sum, day) => sum + day.focusMinutes);

  return total / days.length;
}

double? _calculatePercentChange({required int current, required int previous}) {
  if (previous == 0) {
    return null;
  }

  return ((current - previous) / previous) * 100;
}

bool _isWithinCalendarRange(DateTime value, DateTime start, DateTime end) {
  final date = _calendarDate(value);

  return !date.isBefore(start) && !date.isAfter(end);
}

bool _isSameCalendarDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

DateTime _calendarDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _startOfIsoWeek(DateTime value) {
  return _addCalendarDays(value, -(value.weekday - DateTime.monday));
}

DateTime _addCalendarDays(DateTime value, int days) {
  return DateTime(value.year, value.month, value.day + days);
}

int _calculateStreak(List<DateTime> dates, DateTime now) {
  final days = dates.map(_calendarDate).toSet();

  if (days.isEmpty) {
    return 0;
  }

  var cursor = _calendarDate(now);

  if (!days.contains(cursor)) {
    cursor = _addCalendarDays(cursor, -1);

    if (!days.contains(cursor)) {
      return 0;
    }
  }

  var count = 0;

  while (days.contains(cursor)) {
    count++;
    cursor = _addCalendarDays(cursor, -1);
  }

  return count;
}
