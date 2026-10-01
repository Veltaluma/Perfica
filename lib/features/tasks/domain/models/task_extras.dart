class TaskExtras {
  const TaskExtras({
    this.recurrence,
    this.monthlyAnchorDay,
    this.reminderAt,
    this.reminderRepeatMinutes,
    this.reminderSnoozedUntil,
    this.tags = const [],
    this.attachments = const [],
  });

  final String? recurrence;

  /// Original calendar day for monthly recurrence.
  ///
  /// For example, a task created for January 31 can temporarily
  /// occur on February 28 while still returning to March 31.
  final int? monthlyAnchorDay;

  final DateTime? reminderAt;

  /// Null means the reminder is delivered once.
  final int? reminderRepeatMinutes;

  /// Temporary reminder time for the current occurrence only.
  final DateTime? reminderSnoozedUntil;

  final List<String> tags;
  final List<String> attachments;

  TaskExtras copyWith({
    String? recurrence,
    bool clearRecurrence = false,
    int? monthlyAnchorDay,
    bool clearMonthlyAnchorDay = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    int? reminderRepeatMinutes,
    bool clearReminderRepeat = false,
    DateTime? reminderSnoozedUntil,
    bool clearReminderSnooze = false,
    List<String>? tags,
    List<String>? attachments,
  }) {
    return TaskExtras(
      recurrence: clearRecurrence ? null : recurrence ?? this.recurrence,
      monthlyAnchorDay: clearRecurrence || clearMonthlyAnchorDay
          ? null
          : monthlyAnchorDay ?? this.monthlyAnchorDay,
      reminderAt: clearReminder ? null : reminderAt ?? this.reminderAt,
      reminderRepeatMinutes: clearReminderRepeat
          ? null
          : reminderRepeatMinutes ?? this.reminderRepeatMinutes,
      reminderSnoozedUntil: clearReminderSnooze
          ? null
          : reminderSnoozedUntil ?? this.reminderSnoozedUntil,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
    );
  }
}
