import '../models/task.dart';
import '../models/task_extras.dart';
import 'task_recurrence_calculator.dart';

class TaskCompletionPlan {
  const TaskCompletionPlan({
    required this.monthlyAnchorDay,
    required this.nextDueAt,
    required this.nextReminderAt,
  });

  final int? monthlyAnchorDay;
  final DateTime? nextDueAt;
  final DateTime? nextReminderAt;
}

abstract final class TaskCompletionPlanner {
  static TaskCompletionPlan recurring({
    required Task task,
    required TaskExtras extras,
    required DateTime now,
  }) {
    final recurrence = extras.recurrence;

    if (recurrence == null) {
      throw ArgumentError.value(
        recurrence,
        'extras.recurrence',
        'Recurring completion requires a recurrence value.',
      );
    }

    final monthlyAnchorDay = recurrence == 'monthly'
        ? extras.monthlyAnchorDay ?? task.dueAt?.day ?? extras.reminderAt?.day
        : null;

    final nextDueAt = task.dueAt == null
        ? null
        : TaskRecurrenceCalculator.nextAfter(
            base: task.dueAt!,
            recurrence: recurrence,
            now: now,
            monthlyAnchorDay: monthlyAnchorDay,
          );

    DateTime? nextReminderAt;

    if (extras.reminderAt != null) {
      if (task.dueAt != null) {
        if (nextDueAt == null) {
          throw StateError(
            'A recurring task with a due date must produce a next due date.',
          );
        }

        final reminderOffset = extras.reminderAt!.difference(task.dueAt!);

        nextReminderAt = nextDueAt.add(reminderOffset);
      } else {
        nextReminderAt = TaskRecurrenceCalculator.nextAfter(
          base: extras.reminderAt!,
          recurrence: recurrence,
          now: now,
          monthlyAnchorDay: monthlyAnchorDay,
        );
      }
    }

    return TaskCompletionPlan(
      monthlyAnchorDay: monthlyAnchorDay,
      nextDueAt: nextDueAt,
      nextReminderAt: nextReminderAt,
    );
  }

  const TaskCompletionPlanner._();
}
