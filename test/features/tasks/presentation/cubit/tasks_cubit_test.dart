import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/tasks/domain/models/subtask.dart';
import 'package:perfica/features/tasks/domain/models/task.dart';
import 'package:perfica/features/tasks/domain/models/task_completion.dart';
import 'package:perfica/features/tasks/domain/models/task_extras.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';
import 'package:perfica/features/tasks/domain/repositories/task_extras_repository.dart';
import 'package:perfica/features/tasks/domain/repositories/task_repository.dart';
import 'package:perfica/features/tasks/presentation/cubit/tasks_cubit.dart';

void main() {
  late FakeTaskRepository tasks;
  late FakeTaskExtrasRepository extras;
  late FakeNotificationService notifications;
  late TasksCubit cubit;

  setUp(() {
    tasks = FakeTaskRepository();
    extras = FakeTaskExtrasRepository();
    notifications = FakeNotificationService();

    cubit = TasksCubit(tasks, extras, notifications);
  });

  tearDown(() async {
    await cubit.close();
    await tasks.close();
  });

  test('recurring completion advances the same task without cloning', () async {
    final task = _task(id: 7, dueAt: DateTime(2099, 1, 31, 9));

    tasks.items[7] = task;
    extras.items[7] = const TaskExtras(recurrence: 'monthly');

    await cubit.setTaskCompleted(id: 7, completed: true);

    expect(tasks.createCount, 0);
    expect(tasks.completions, hasLength(1));

    final updated = tasks.items[7]!;

    expect(updated.workflowStatus, TaskWorkflowStatus.todo);
    expect(updated.dueAt, DateTime(2099, 2, 28, 9));
    expect(notifications.cancelledTaskIds, contains(7));
  });

  test('non-recurring completion moves the task to done', () async {
    tasks.items[1] = _task(id: 1);

    await cubit.setTaskCompleted(id: 1, completed: true);

    expect(tasks.items[1]!.workflowStatus, TaskWorkflowStatus.done);
    expect(tasks.completions, hasLength(1));
  });

  test('clear completed removes rows but preserves history', () async {
    tasks.items[1] = _task(id: 1, workflowStatus: TaskWorkflowStatus.done);

    tasks.items[2] = _task(id: 2, workflowStatus: TaskWorkflowStatus.todo);

    tasks.emit();

    await Future<void>.delayed(Duration.zero);
    await cubit.clearCompleted();

    expect(tasks.items.containsKey(1), isFalse);
    expect(tasks.items.containsKey(2), isTrue);
  });
}

Task _task({
  required int id,
  TaskWorkflowStatus workflowStatus = TaskWorkflowStatus.todo,
  DateTime? dueAt,
}) {
  final now = DateTime(2026, 1, 1);

  return Task(
    id: id,
    title: 'Task $id',
    isCompleted: workflowStatus == TaskWorkflowStatus.done,
    priority: TaskPriority.none,
    workflowStatus: workflowStatus,
    dueAt: dueAt,
    createdAt: now,
    updatedAt: now,
    completedAt: workflowStatus == TaskWorkflowStatus.done ? now : null,
    sortOrder: 0,
  );
}

class FakeNotificationService extends NotificationService {
  final List<int> cancelledTaskIds = [];

  @override
  Future<void> cancelTask(int taskId) async {
    cancelledTaskIds.add(taskId);
  }
}

class FakeTaskExtrasRepository implements TaskExtrasRepository {
  final Map<int, TaskExtras> items = {};

  @override
  Future<TaskExtras> getExtras(int taskId) async {
    return items[taskId] ?? const TaskExtras();
  }

  @override
  Future<void> saveExtras(int taskId, TaskExtras extras) async {
    items[taskId] = extras;
  }

  @override
  Future<void> deleteExtras(int taskId) async {
    items.remove(taskId);
  }
}

class FakeTaskRepository implements TaskRepository {
  final controller = StreamController<List<Task>>.broadcast();

  final Map<int, Task> items = {};
  final List<TaskCompletion> completions = [];

  int createCount = 0;

  void emit() {
    controller.add(items.values.toList());
  }

  Future<void> close() => controller.close();

  @override
  Stream<List<Task>> watchTasks() => controller.stream;

  @override
  Stream<List<TaskCompletion>> watchCompletionHistory() {
    return Stream.value(List.unmodifiable(completions));
  }

  @override
  Future<Task?> getTask(int id) async => items[id];

  @override
  Future<int> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.none,
    TaskWorkflowStatus workflowStatus = TaskWorkflowStatus.todo,
    DateTime? dueAt,
  }) async {
    createCount++;
    final id = createCount + 100;

    items[id] = _task(id: id, workflowStatus: workflowStatus, dueAt: dueAt);

    emit();
    return id;
  }

  @override
  Future<void> updateTask({
    required int id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskWorkflowStatus? workflowStatus,
    DateTime? dueAt,
    bool clearDueAt = false,
  }) async {
    final current = items[id];

    if (current == null) {
      return;
    }

    final status = workflowStatus ?? current.workflowStatus;

    items[id] = Task(
      id: current.id,
      title: title ?? current.title,
      description: description ?? current.description,
      isCompleted: status == TaskWorkflowStatus.done,
      priority: priority ?? current.priority,
      workflowStatus: status,
      dueAt: clearDueAt ? null : dueAt ?? current.dueAt,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      completedAt: status == TaskWorkflowStatus.done ? DateTime.now() : null,
      sortOrder: current.sortOrder,
    );

    emit();
  }

  @override
  Future<void> setTaskCompleted({required int id, required bool completed}) {
    return setWorkflowStatus(
      id: id,
      status: completed ? TaskWorkflowStatus.done : TaskWorkflowStatus.todo,
    );
  }

  @override
  Future<void> setWorkflowStatus({
    required int id,
    required TaskWorkflowStatus status,
  }) async {
    await updateTask(id: id, workflowStatus: status);
  }

  @override
  Future<void> recordCompletion({
    required int taskId,
    required String taskTitle,
    DateTime? completedAt,
  }) async {
    completions.add(
      TaskCompletion(
        id: completions.length + 1,
        taskId: taskId,
        taskTitle: taskTitle,
        completedAt: completedAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Future<void> removeLatestCompletion(int taskId) async {
    final index = completions.lastIndexWhere((item) => item.taskId == taskId);

    if (index >= 0) {
      completions.removeAt(index);
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    items.remove(id);
    emit();
  }

  @override
  Stream<List<Subtask>> watchSubtasks(int taskId) {
    return const Stream<List<Subtask>>.empty();
  }

  @override
  Future<int> createSubtask({
    required int taskId,
    required String title,
  }) async {
    return 1;
  }

  @override
  Future<void> setSubtaskCompleted({
    required int id,
    required bool completed,
  }) async {}

  @override
  Future<void> deleteSubtask(int id) async {}
}
