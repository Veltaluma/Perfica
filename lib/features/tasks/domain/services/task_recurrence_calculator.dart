import 'dart:math' as math;

abstract final class TaskRecurrenceCalculator {
  static DateTime nextAfter({
    required DateTime base,
    required String recurrence,
    required DateTime now,
    int? monthlyAnchorDay,
  }) {
    var nextOccurrence = TaskRecurrenceCalculator.next(
      base: base,
      recurrence: recurrence,
      monthlyAnchorDay: monthlyAnchorDay,
    );

    while (!nextOccurrence.isAfter(now)) {
      final candidate = TaskRecurrenceCalculator.next(
        base: nextOccurrence,
        recurrence: recurrence,
        monthlyAnchorDay: monthlyAnchorDay,
      );

      // Invalid persisted recurrence values intentionally keep the
      // original date. Stop here to prevent an infinite loop.
      if (!candidate.isAfter(nextOccurrence)) {
        return nextOccurrence;
      }

      nextOccurrence = candidate;
    }

    return nextOccurrence;
  }

  static DateTime next({
    required DateTime base,
    required String recurrence,
    int? monthlyAnchorDay,
  }) {
    return switch (recurrence) {
      'daily' => base.add(const Duration(days: 1)),
      'weekly' => base.add(const Duration(days: 7)),
      'monthly' => _nextMonth(base, anchorDay: monthlyAnchorDay),
      _ => base,
    };
  }

  static DateTime _nextMonth(DateTime base, {int? anchorDay}) {
    final month = base.month == 12 ? 1 : base.month + 1;
    final year = base.month == 12 ? base.year + 1 : base.year;

    final lastDay = DateTime(year, month + 1, 0).day;

    final preferredDay = anchorDay ?? base.day;

    final day = math.min(preferredDay, lastDay);

    return DateTime(
      year,
      month,
      day,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }

  const TaskRecurrenceCalculator._();
}
