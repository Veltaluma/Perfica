import '../../../../core/services/notification_service.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_completion_result.dart';
import '../../domain/models/task_workflow_status.dart';
import '../../domain/repositories/task_extras_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/task_completion_planner.dart';
import '../../domain/services/task_reminder_scheduler.dart';

class TaskCompletionService {
  TaskCompletionService(
    this._repository,
    this._extrasRepository,
    this._notificationService,
    this._reminderScheduler,
  );

  final TaskRepository _repository;
  final TaskExtrasRepository _extrasRepository;
  final NotificationService _notificationService;
  final TaskReminderScheduler _reminderScheduler;

  Future<TaskCompletionResult?> setCompleted({
    required int id,
    required bool completed,
  }) async {
    final task = await _repository.getTask(id);

    if (task == null) {
      return null;
    }

    if (completed) {
      if (task.workflowStatus == TaskWorkflowStatus.done) {
        return null;
      }

      return _completeCurrentOccurrence(task);
    }

    final extras = await _extrasRepository.getExtras(task.id);

    if (task.workflowStatus == TaskWorkflowStatus.done) {
      await _repository.removeLatestCompletion(task.id);
    }

    await _repository.setWorkflowStatus(
      id: task.id,
      status: TaskWorkflowStatus.todo,
    );

    await _notificationService.cancelTask(task.id);

    await _reminderScheduler.scheduleStored(
      taskId: task.id,
      title: task.title,
      extras: extras,
    );

    return null;
  }

  Future<void> undo(TaskCompletionResult result) async {
    final before = result.taskBefore;

    final existing = await _repository.getTask(before.id);

    if (existing == null) {
      return;
    }

    await _notificationService.cancelTask(before.id);

    await _repository.removeLatestCompletion(before.id);

    await _repository.updateTask(
      id: before.id,
      workflowStatus: before.workflowStatus,
      dueAt: before.dueAt,
      clearDueAt: before.dueAt == null,
    );

    await _extrasRepository.saveExtras(before.id, result.extrasBefore);

    if (before.workflowStatus != TaskWorkflowStatus.done) {
      await _reminderScheduler.scheduleStored(
        taskId: before.id,
        title: before.title,
        extras: result.extrasBefore,
      );
    }
  }

  Future<TaskCompletionResult?> completeForever(int id) async {
    final task = await _repository.getTask(id);

    if (task == null || task.workflowStatus == TaskWorkflowStatus.done) {
      return null;
    }

    final extras = await _extrasRepository.getExtras(id);

    if (extras.recurrence == null) {
      return setCompleted(id: id, completed: true);
    }

    final result = TaskCompletionResult(taskBefore: task, extrasBefore: extras);

    await _repository.recordCompletion(taskId: task.id, taskTitle: task.title);

    await _notificationService.cancelTask(task.id);

    await _repository.setWorkflowStatus(
      id: task.id,
      status: TaskWorkflowStatus.done,
    );

    await _extrasRepository.saveExtras(
      task.id,
      extras.copyWith(
        clearRecurrence: true,
        clearReminder: true,
        clearReminderRepeat: true,
        clearReminderSnooze: true,
      ),
    );

    return result;
  }

  Future<TaskCompletionResult> _completeCurrentOccurrence(Task task) async {
    final extras = await _extrasRepository.getExtras(task.id);

    final result = TaskCompletionResult(taskBefore: task, extrasBefore: extras);

    await _repository.recordCompletion(taskId: task.id, taskTitle: task.title);

    await _notificationService.cancelTask(task.id);

    final recurrence = extras.recurrence;

    if (recurrence == null) {
      await _repository.setWorkflowStatus(
        id: task.id,
        status: TaskWorkflowStatus.done,
      );

      if (extras.reminderSnoozedUntil != null) {
        await _extrasRepository.saveExtras(
          task.id,
          extras.copyWith(clearReminderSnooze: true),
        );
      }

      return result;
    }

    final plan = TaskCompletionPlanner.recurring(
      task: task,
      extras: extras,
      now: DateTime.now(),
    );

    await _repository.updateTask(
      id: task.id,
      workflowStatus: TaskWorkflowStatus.todo,
      dueAt: plan.nextDueAt,
      clearDueAt: plan.nextDueAt == null,
    );

    final nextExtras = extras.copyWith(
      monthlyAnchorDay: plan.monthlyAnchorDay,
      reminderAt: plan.nextReminderAt,
      clearReminder: plan.nextReminderAt == null,
      clearReminderSnooze: true,
    );

    await _extrasRepository.saveExtras(task.id, nextExtras);

    if (plan.nextReminderAt != null &&
        plan.nextReminderAt!.isAfter(DateTime.now())) {
      await _reminderScheduler.schedule(
        taskId: task.id,
        title: task.title,
        when: plan.nextReminderAt!,
        repeatMinutes: extras.reminderRepeatMinutes,
      );
    }

    return result;
  }
}
