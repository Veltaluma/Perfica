import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_completion.dart';
import '../models/task_priority.dart';
import '../models/task_workflow_status.dart';

abstract interface class TaskRepository {
  Stream<List<Task>> watchTasks();

  Stream<List<TaskCompletion>> watchCompletionHistory();

  Future<Task?> getTask(int id);

  Future<int> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.none,
    TaskWorkflowStatus workflowStatus = TaskWorkflowStatus.todo,
    DateTime? dueAt,
  });

  Future<void> updateTask({
    required int id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskWorkflowStatus? workflowStatus,
    DateTime? dueAt,
    bool clearDueAt = false,
  });

  Future<void> setTaskCompleted({required int id, required bool completed});

  Future<void> setWorkflowStatus({
    required int id,
    required TaskWorkflowStatus status,
  });

  Future<void> recordCompletion({
    required int taskId,
    required String taskTitle,
    DateTime? completedAt,
  });

  Future<void> removeLatestCompletion(int taskId);

  Future<void> deleteTask(int id);

  Stream<List<Subtask>> watchSubtasks(int taskId);

  Future<int> createSubtask({required int taskId, required String title});

  Future<void> setSubtaskCompleted({required int id, required bool completed});

  Future<void> deleteSubtask(int id);
}
