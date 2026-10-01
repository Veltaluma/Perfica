import '../../domain/models/task.dart';

enum TasksStatus { loading, success, failure }

class TasksState {
  TasksState._({required this.status, required List<Task> tasks})
    : tasks = List<Task>.unmodifiable(tasks);

  factory TasksState.initial() {
    return TasksState._(status: TasksStatus.loading, tasks: const []);
  }

  factory TasksState.success(List<Task> tasks) {
    return TasksState._(status: TasksStatus.success, tasks: tasks);
  }

  factory TasksState.failure(List<Task> tasks) {
    return TasksState._(status: TasksStatus.failure, tasks: tasks);
  }

  final TasksStatus status;
  final List<Task> tasks;
}
