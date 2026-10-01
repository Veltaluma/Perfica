import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';
import 'package:perfica/features/tasks/domain/repositories/task_repository.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = DriftTaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates task as todo by default', () async {
    final id = await repository.createTask(
      title: 'First task',
      priority: TaskPriority.medium,
    );

    final task = await repository.getTask(id);

    expect(task, isNotNull);
    expect(task!.workflowStatus, TaskWorkflowStatus.todo);
    expect(task.isCompleted, isFalse);
  });

  test('workflow status synchronizes completed state', () async {
    final id = await repository.createTask(title: 'Workflow task');

    await repository.setWorkflowStatus(
      id: id,
      status: TaskWorkflowStatus.inProgress,
    );

    var task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.inProgress);
    expect(task.isCompleted, isFalse);

    await repository.setWorkflowStatus(id: id, status: TaskWorkflowStatus.done);

    task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.done);
    expect(task.isCompleted, isTrue);
    expect(task.completedAt, isNotNull);
  });

  test('records completion history independently from tasks', () async {
    final id = await repository.createTask(title: 'History task');

    await repository.recordCompletion(taskId: id, taskTitle: 'History task');

    await repository.deleteTask(id);

    final history = await repository.watchCompletionHistory().first;

    expect(history, hasLength(1));
    expect(history.single.taskTitle, 'History task');
  });

  test('creates and streams a subtask', () async {
    final taskId = await repository.createTask(title: 'Parent task');

    final subtaskId = await repository.createSubtask(
      taskId: taskId,
      title: 'Child task',
    );

    final subtasks = await repository.watchSubtasks(taskId).first;

    expect(subtasks, hasLength(1));
    expect(subtasks.single.id, subtaskId);
    expect(subtasks.single.taskId, taskId);
    expect(subtasks.single.title, 'Child task');
    expect(subtasks.single.isCompleted, isFalse);
  });

  test('updates subtask completion state', () async {
    final taskId = await repository.createTask(title: 'Parent task');

    final subtaskId = await repository.createSubtask(
      taskId: taskId,
      title: 'Child task',
    );

    await repository.setSubtaskCompleted(id: subtaskId, completed: true);

    var subtasks = await repository.watchSubtasks(taskId).first;

    expect(subtasks.single.isCompleted, isTrue);

    await repository.setSubtaskCompleted(id: subtaskId, completed: false);

    subtasks = await repository.watchSubtasks(taskId).first;

    expect(subtasks.single.isCompleted, isFalse);
  });

  test('deletes only the selected subtask', () async {
    final taskId = await repository.createTask(title: 'Parent task');

    final firstId = await repository.createSubtask(
      taskId: taskId,
      title: 'First child',
    );

    final secondId = await repository.createSubtask(
      taskId: taskId,
      title: 'Second child',
    );

    await repository.deleteSubtask(firstId);

    final subtasks = await repository.watchSubtasks(taskId).first;

    expect(subtasks, hasLength(1));
    expect(subtasks.single.id, secondId);
    expect(subtasks.single.title, 'Second child');
  });

  test('deleting a task cascades to subtasks', () async {
    await database.customStatement('PRAGMA foreign_keys = ON');

    final taskId = await repository.createTask(title: 'Parent task');

    await repository.createSubtask(taskId: taskId, title: 'Child');

    await repository.deleteTask(taskId);

    expect(await repository.watchSubtasks(taskId).first, isEmpty);
  });
}
