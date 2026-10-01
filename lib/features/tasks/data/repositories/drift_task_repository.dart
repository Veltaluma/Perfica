import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/subtask.dart' as domain;
import '../../domain/models/task.dart' as domain;
import '../../domain/models/task_completion.dart' as domain;
import '../../domain/models/task_priority.dart';
import '../../domain/models/task_workflow_status.dart';
import '../../domain/repositories/task_repository.dart';

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<domain.Task>> watchTasks() {
    final query = _database.select(_database.tasks)
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);

    return query.watch().map(
      (rows) => rows.map(_mapTask).toList(growable: false),
    );
  }

  @override
  Stream<List<domain.TaskCompletion>> watchCompletionHistory() {
    final query = _database.select(_database.completionEvents)
      ..orderBy([
        (table) => OrderingTerm.desc(table.completedAt),
        (table) => OrderingTerm.desc(table.id),
      ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => domain.TaskCompletion(
              id: row.id,
              taskId: row.taskId,
              taskTitle: row.taskTitle,
              completedAt: row.completedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<domain.Task?> getTask(int id) async {
    final query = _database.select(_database.tasks)
      ..where((table) => table.id.equals(id));

    final row = await query.getSingleOrNull();
    return row == null ? null : _mapTask(row);
  }

  @override
  Future<int> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.none,
    TaskWorkflowStatus workflowStatus = TaskWorkflowStatus.todo,
    DateTime? dueAt,
  }) {
    final now = DateTime.now();
    final completed = workflowStatus == TaskWorkflowStatus.done;

    return _database
        .into(_database.tasks)
        .insert(
          TasksCompanion.insert(
            title: title.trim(),
            description: Value(description?.trim()),
            priority: Value(priority.storageValue),
            workflowStatus: Value(workflowStatus.storageValue),
            isCompleted: Value(completed),
            dueAt: Value(dueAt),
            createdAt: Value(now),
            updatedAt: Value(now),
            completedAt: Value(completed ? now : null),
          ),
        );
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
    final now = DateTime.now();
    final existing = await getTask(id);
    final isDone = workflowStatus == TaskWorkflowStatus.done;

    final Value<DateTime?> completedAtValue;
    if (workflowStatus == null) {
      completedAtValue = const Value.absent();
    } else if (isDone) {
      completedAtValue = Value(existing?.completedAt ?? now);
    } else {
      completedAtValue = const Value(null);
    }

    final Value<String?> descriptionValue;
    if (description == null) {
      descriptionValue = const Value.absent();
    } else {
      final trimmed = description.trim();
      descriptionValue = Value(trimmed.isEmpty ? null : trimmed);
    }

    await (_database.update(
      _database.tasks,
    )..where((table) => table.id.equals(id))).write(
      TasksCompanion(
        title: title == null ? const Value.absent() : Value(title.trim()),
        description: descriptionValue,
        priority: priority == null
            ? const Value.absent()
            : Value(priority.storageValue),
        workflowStatus: workflowStatus == null
            ? const Value.absent()
            : Value(workflowStatus.storageValue),
        isCompleted: workflowStatus == null
            ? const Value.absent()
            : Value(isDone),
        completedAt: completedAtValue,
        dueAt: clearDueAt
            ? const Value(null)
            : dueAt == null
            ? const Value.absent()
            : Value(dueAt),
        updatedAt: Value(now),
      ),
    );
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
    final now = DateTime.now();
    final completed = status == TaskWorkflowStatus.done;

    await (_database.update(
      _database.tasks,
    )..where((table) => table.id.equals(id))).write(
      TasksCompanion(
        workflowStatus: Value(status.storageValue),
        isCompleted: Value(completed),
        completedAt: Value(completed ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> recordCompletion({
    required int taskId,
    required String taskTitle,
    DateTime? completedAt,
  }) async {
    await _database
        .into(_database.completionEvents)
        .insert(
          CompletionEventsCompanion.insert(
            taskId: Value(taskId),
            taskTitle: taskTitle,
            completedAt: completedAt ?? DateTime.now(),
          ),
        );
  }

  @override
  Future<void> removeLatestCompletion(int taskId) async {
    final query = _database.select(_database.completionEvents)
      ..where((table) => table.taskId.equals(taskId))
      ..orderBy([
        (table) => OrderingTerm.desc(table.completedAt),
        (table) => OrderingTerm.desc(table.id),
      ])
      ..limit(1);

    final latest = await query.getSingleOrNull();

    if (latest == null) {
      return;
    }

    await (_database.delete(
      _database.completionEvents,
    )..where((table) => table.id.equals(latest.id))).go();
  }

  @override
  Future<void> deleteTask(int id) async {
    await (_database.delete(
      _database.tasks,
    )..where((table) => table.id.equals(id))).go();
  }

  @override
  Stream<List<domain.Subtask>> watchSubtasks(int taskId) {
    final query = _database.select(_database.subtasks)
      ..where((table) => table.taskId.equals(taskId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.createdAt),
      ]);

    return query.watch().map(
      (rows) => rows.map(_mapSubtask).toList(growable: false),
    );
  }

  @override
  Future<int> createSubtask({required int taskId, required String title}) {
    final now = DateTime.now();

    return _database
        .into(_database.subtasks)
        .insert(
          SubtasksCompanion.insert(
            taskId: taskId,
            title: title.trim(),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<void> setSubtaskCompleted({
    required int id,
    required bool completed,
  }) async {
    await (_database.update(
      _database.subtasks,
    )..where((table) => table.id.equals(id))).write(
      SubtasksCompanion(
        isCompleted: Value(completed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteSubtask(int id) async {
    await (_database.delete(
      _database.subtasks,
    )..where((table) => table.id.equals(id))).go();
  }

  domain.Task _mapTask(Task row) {
    return domain.Task(
      id: row.id,
      title: row.title,
      description: row.description,
      isCompleted: row.isCompleted,
      priority: TaskPriority.fromStorageValue(row.priority),
      workflowStatus: TaskWorkflowStatus.fromStorageValue(row.workflowStatus),
      dueAt: row.dueAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      completedAt: row.completedAt,
      sortOrder: row.sortOrder,
    );
  }

  domain.Subtask _mapSubtask(Subtask row) {
    return domain.Subtask(
      id: row.id,
      taskId: row.taskId,
      title: row.title,
      isCompleted: row.isCompleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      sortOrder: row.sortOrder,
    );
  }
}
