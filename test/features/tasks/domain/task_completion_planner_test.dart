import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/tasks/domain/models/task.dart';
import 'package:perfica/features/tasks/domain/models/task_extras.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';
import 'package:perfica/features/tasks/domain/services/task_completion_planner.dart';

void main() {
  test('daily recurrence advances due date', () {
    final task = _task(dueAt: DateTime(2099, 1, 10, 9));

    final plan = TaskCompletionPlanner.recurring(
      task: task,
      extras: const TaskExtras(recurrence: 'daily'),
      now: DateTime(2099, 1, 10, 12),
    );

    expect(plan.nextDueAt, DateTime(2099, 1, 11, 9));

    expect(plan.nextReminderAt, isNull);
  });

  test('overdue daily recurrence skips directly into future', () {
    final task = _task(dueAt: DateTime(2099, 1, 1, 9));

    final plan = TaskCompletionPlanner.recurring(
      task: task,
      extras: const TaskExtras(recurrence: 'daily'),
      now: DateTime(2099, 1, 10, 12),
    );

    expect(plan.nextDueAt, DateTime(2099, 1, 11, 9));
  });

  test('reminder preserves its offset from recurring due date', () {
    final task = _task(dueAt: DateTime(2099, 1, 10, 9));

    final plan = TaskCompletionPlanner.recurring(
      task: task,
      extras: TaskExtras(
        recurrence: 'daily',
        reminderAt: DateTime(2099, 1, 10, 8, 30),
      ),
      now: DateTime(2099, 1, 10, 12),
    );

    expect(plan.nextDueAt, DateTime(2099, 1, 11, 9));

    expect(plan.nextReminderAt, DateTime(2099, 1, 11, 8, 30));
  });

  test('reminder-only recurrence advances independently', () {
    final task = _task();

    final plan = TaskCompletionPlanner.recurring(
      task: task,
      extras: TaskExtras(
        recurrence: 'weekly',
        reminderAt: DateTime(2099, 1, 1, 8),
      ),
      now: DateTime(2099, 1, 10),
    );

    expect(plan.nextDueAt, isNull);

    expect(plan.nextReminderAt, DateTime(2099, 1, 15, 8));
  });

  test('monthly recurrence clamps then preserves original anchor', () {
    final januaryTask = _task(dueAt: DateTime(2099, 1, 31, 9));

    final februaryPlan = TaskCompletionPlanner.recurring(
      task: januaryTask,
      extras: const TaskExtras(recurrence: 'monthly', monthlyAnchorDay: 31),
      now: DateTime(2099, 1, 31, 10),
    );

    expect(februaryPlan.monthlyAnchorDay, 31);

    expect(februaryPlan.nextDueAt, DateTime(2099, 2, 28, 9));

    final februaryTask = _task(dueAt: februaryPlan.nextDueAt);

    final marchPlan = TaskCompletionPlanner.recurring(
      task: februaryTask,
      extras: TaskExtras(
        recurrence: 'monthly',
        monthlyAnchorDay: februaryPlan.monthlyAnchorDay,
      ),
      now: DateTime(2099, 2, 28, 10),
    );

    expect(marchPlan.nextDueAt, DateTime(2099, 3, 31, 9));
  });

  test('monthly anchor can originate from due date', () {
    final task = _task(dueAt: DateTime(2099, 1, 31, 9));

    final plan = TaskCompletionPlanner.recurring(
      task: task,
      extras: const TaskExtras(recurrence: 'monthly'),
      now: DateTime(2099, 1, 31, 10),
    );

    expect(plan.monthlyAnchorDay, 31);
  });

  test('monthly reminder-only anchor originates from reminder', () {
    final task = _task();

    final plan = TaskCompletionPlanner.recurring(
      task: task,
      extras: TaskExtras(
        recurrence: 'monthly',
        reminderAt: DateTime(2099, 1, 31, 8),
      ),
      now: DateTime(2099, 1, 31, 9),
    );

    expect(plan.monthlyAnchorDay, 31);

    expect(plan.nextReminderAt, DateTime(2099, 2, 28, 8));
  });

  test('non-recurring extras are rejected', () {
    expect(
      () => TaskCompletionPlanner.recurring(
        task: _task(),
        extras: const TaskExtras(),
        now: DateTime(2099, 1, 1),
      ),
      throwsArgumentError,
    );
  });
}

Task _task({DateTime? dueAt}) {
  final created = DateTime(2098, 1, 1);

  return Task(
    id: 1,
    title: 'Test task',
    isCompleted: false,
    priority: TaskPriority.none,
    workflowStatus: TaskWorkflowStatus.todo,
    dueAt: dueAt,
    createdAt: created,
    updatedAt: created,
    completedAt: null,
    sortOrder: 0,
  );
}
