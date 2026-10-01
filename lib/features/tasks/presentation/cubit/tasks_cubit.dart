import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/attachment_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../application/services/task_completion_service.dart';
import '../../application/services/task_recurrence_service.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_extras.dart';
import '../../domain/models/task_completion_result.dart';
import '../../domain/models/task_priority.dart';
import '../../domain/models/task_workflow_status.dart';
import '../../domain/repositories/task_extras_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/task_reminder_scheduler.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(
    this._repository,
    this._extrasRepository,
    this._notificationService, [
    AttachmentService? attachmentService,
  ]) : _attachmentService = attachmentService ?? AttachmentService(),
       super(TasksState.initial()) {
    _tasksSubscription = _repository.watchTasks().listen(
      (tasks) => emit(TasksState.success(tasks)),
      onError: (_) => emit(TasksState.failure(state.tasks)),
    );
  }

  final TaskRepository _repository;
  final TaskExtrasRepository _extrasRepository;
  final NotificationService _notificationService;
  late final TaskReminderScheduler _reminderScheduler = TaskReminderScheduler(
    _notificationService,
  );
  final AttachmentService _attachmentService;
  late final TaskRecurrenceService _recurrenceService = TaskRecurrenceService(
    _repository,
    _extrasRepository,
    _notificationService,
    _reminderScheduler,
  );

  late final TaskCompletionService _completionService = TaskCompletionService(
    _repository,
    _extrasRepository,
    _notificationService,
    _reminderScheduler,
  );

  StreamSubscription<List<Task>>? _tasksSubscription;

  Future<void> handleNotificationAction({
    required String actionId,
    required int taskId,
  }) async {
    switch (actionId) {
      case NotificationService.taskDoneActionId:
        await setTaskCompleted(id: taskId, completed: true);
      case NotificationService.taskSnooze10ActionId:
        await snoozeTaskReminder(taskId);
    }
  }

  Future<void> snoozeTaskReminder(
    int taskId, {
    Duration delay = const Duration(minutes: 10),
  }) async {
    final task = await _repository.getTask(taskId);

    if (task == null || task.workflowStatus == TaskWorkflowStatus.done) {
      return;
    }

    final extras = await _extrasRepository.getExtras(taskId);

    if (extras.reminderAt == null) {
      return;
    }

    final snoozedUntil = DateTime.now().add(delay);

    await _notificationService.cancelTask(taskId);

    await _extrasRepository.saveExtras(
      taskId,
      extras.copyWith(reminderSnoozedUntil: snoozedUntil),
    );

    await _reminderScheduler.schedule(
      taskId: taskId,
      title: task.title,
      when: snoozedUntil,
      repeatMinutes: extras.reminderRepeatMinutes,
    );
  }

  List<String> _normalizeUniqueStrings(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  int? _resolveMonthlyAnchorDay({
    required String? recurrence,
    required DateTime? dueAt,
    required DateTime? reminderAt,
    required Task? previousTask,
    required TaskExtras previousExtras,
  }) {
    if (recurrence != 'monthly') {
      return null;
    }

    if (dueAt != null) {
      final canPreserveExistingAnchor =
          previousExtras.recurrence == 'monthly' &&
          previousExtras.monthlyAnchorDay != null &&
          previousTask?.dueAt == dueAt;

      return canPreserveExistingAnchor
          ? previousExtras.monthlyAnchorDay
          : dueAt.day;
    }

    if (reminderAt != null) {
      final canPreserveExistingAnchor =
          previousExtras.recurrence == 'monthly' &&
          previousExtras.monthlyAnchorDay != null &&
          previousTask?.dueAt == null &&
          previousExtras.reminderAt == reminderAt;

      return canPreserveExistingAnchor
          ? previousExtras.monthlyAnchorDay
          : reminderAt.day;
    }

    return null;
  }

  Future<int> _persistTaskCore({
    required int? taskId,
    required String title,
    required String? description,
    required TaskPriority priority,
    required DateTime? dueAt,
  }) async {
    final id =
        taskId ??
        await _repository.createTask(
          title: title,
          description: description == null || description.isEmpty
              ? null
              : description,
          priority: priority,
          workflowStatus: TaskWorkflowStatus.todo,
          dueAt: dueAt,
        );

    if (taskId != null) {
      await _repository.updateTask(
        id: id,
        title: title,
        description: description ?? '',
        priority: priority,
        dueAt: dueAt,
        clearDueAt: dueAt == null,
      );
    }

    return id;
  }

  Future<void> _cleanupDetachedAttachments({
    required TaskExtras previousExtras,
    required List<String> retainedAttachments,
  }) async {
    final retained = retainedAttachments.toSet();

    final removed = previousExtras.attachments.where(
      (path) => !retained.contains(path),
    );

    for (final path in removed) {
      await _attachmentService.deleteStored(path);
    }
  }

  Future<int> saveTask({
    int? taskId,
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskWorkflowStatus workflowStatus,
    DateTime? dueAt,
    String? recurrence,
    DateTime? reminderAt,
    int? reminderRepeatMinutes,
    List<String> tags = const [],
    List<String> attachments = const [],
  }) async {
    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Task title must not be empty.',
      );
    }

    final normalizedDescription = description?.trim();

    final normalizedTags = _normalizeUniqueStrings(tags);

    final previousTask = taskId == null
        ? null
        : await _repository.getTask(taskId);

    final previousExtras = taskId == null
        ? const TaskExtras()
        : await _extrasRepository.getExtras(taskId);

    final normalizedAttachments = _normalizeUniqueStrings(attachments);

    final monthlyAnchorDay = _resolveMonthlyAnchorDay(
      recurrence: recurrence,
      dueAt: dueAt,
      reminderAt: reminderAt,
      previousTask: previousTask,
      previousExtras: previousExtras,
    );

    final id = await _persistTaskCore(
      taskId: taskId,
      title: normalizedTitle,
      description: normalizedDescription,
      priority: priority,
      dueAt: dueAt,
    );

    final savedExtras = TaskExtras(
      recurrence: recurrence,
      monthlyAnchorDay: monthlyAnchorDay,
      reminderAt: reminderAt,
      reminderRepeatMinutes: reminderRepeatMinutes,
      tags: normalizedTags,
      attachments: List<String>.unmodifiable(normalizedAttachments),
    );

    await _extrasRepository.saveExtras(id, savedExtras);

    if (taskId != null) {
      await _cleanupDetachedAttachments(
        previousExtras: previousExtras,
        retainedAttachments: normalizedAttachments,
      );
    }

    await _notificationService.cancelTask(id);

    final previousStatus =
        previousTask?.workflowStatus ?? TaskWorkflowStatus.todo;

    if (workflowStatus != previousStatus) {
      await setWorkflowStatus(id: id, status: workflowStatus);
    }

    if (workflowStatus != TaskWorkflowStatus.done) {
      await _reminderScheduler.scheduleStored(
        taskId: id,
        title: normalizedTitle,
        extras: savedExtras,
      );
    }

    return id;
  }

  Future<TaskCompletionResult?> setTaskCompleted({
    required int id,
    required bool completed,
  }) {
    return _completionService.setCompleted(id: id, completed: completed);
  }

  Future<void> undoTaskCompletion(TaskCompletionResult result) {
    return _completionService.undo(result);
  }

  Future<TaskExtras?> stopRepeating(int id) {
    return _recurrenceService.stopRepeating(id);
  }

  Future<void> undoStopRepeating({
    required int id,
    required TaskExtras extrasBefore,
  }) {
    return _recurrenceService.undoStopRepeating(
      id: id,
      extrasBefore: extrasBefore,
    );
  }

  Future<TaskCompletionResult?> completeTaskForever(int id) {
    return _completionService.completeForever(id);
  }

  Future<void> setWorkflowStatus({
    required int id,
    required TaskWorkflowStatus status,
  }) async {
    final task = await _repository.getTask(id);

    if (task == null || task.workflowStatus == status) {
      return;
    }

    // Explicit workflow changes from Board or Editor are literal.
    // Selecting Done means the task itself moves to Done, even when
    // the task has recurrence configured.
    //
    // Recurring occurrence completion is handled separately by
    // setTaskCompleted(), which is used by the completion checkbox.
    if (status == TaskWorkflowStatus.done) {
      await _repository.recordCompletion(
        taskId: task.id,
        taskTitle: task.title,
      );

      await _notificationService.cancelTask(task.id);

      await _repository.setWorkflowStatus(
        id: task.id,
        status: TaskWorkflowStatus.done,
      );

      return;
    }

    // Moving a completed task back to an active workflow state is
    // treated as undoing its latest explicit completion.
    if (task.workflowStatus == TaskWorkflowStatus.done) {
      await _repository.removeLatestCompletion(task.id);
    }

    await _repository.setWorkflowStatus(id: task.id, status: status);
  }

  Future<void> completeAllActive() async {
    final activeTasks = List<Task>.of(
      state.tasks.where(
        (task) => task.workflowStatus != TaskWorkflowStatus.done,
      ),
    );

    for (final task in activeTasks) {
      await setTaskCompleted(id: task.id, completed: true);
    }
  }

  Future<void> clearCompleted() async {
    final completedTasks = List<Task>.of(
      state.tasks.where(
        (task) => task.workflowStatus == TaskWorkflowStatus.done,
      ),
    );

    for (final task in completedTasks) {
      await deleteTask(task.id);
    }
  }

  Future<void> deleteTask(int id) async {
    final extras = await _extrasRepository.getExtras(id);

    await _notificationService.cancelTask(id);
    await _extrasRepository.deleteExtras(id);
    await _repository.deleteTask(id);

    for (final path in extras.attachments) {
      await _attachmentService.deleteStored(path);
    }
  }

  Future<int> createSubtask({required int taskId, required String title}) {
    final normalized = title.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Subtask title is required.');
    }

    return _repository.createSubtask(taskId: taskId, title: normalized);
  }

  Future<void> setSubtaskCompleted({required int id, required bool completed}) {
    return _repository.setSubtaskCompleted(id: id, completed: completed);
  }

  Future<void> deleteSubtask(int id) {
    return _repository.deleteSubtask(id);
  }

  Future<void> rescheduleTaskReminders() async {
    final now = DateTime.now();

    for (final task in state.tasks) {
      await _notificationService.cancelTask(task.id);

      if (task.workflowStatus == TaskWorkflowStatus.done) {
        continue;
      }

      final extras = await _extrasRepository.getExtras(task.id);

      await _reminderScheduler.scheduleStored(
        taskId: task.id,
        title: task.title,
        extras: extras,
        now: now,
      );
    }
  }

  @override
  Future<void> close() async {
    await _tasksSubscription?.cancel();

    return super.close();
  }
}
