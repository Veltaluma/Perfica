class TaskCompletion {
  const TaskCompletion({
    required this.id,
    required this.taskTitle,
    required this.completedAt,
    this.taskId,
  });

  final int id;
  final int? taskId;
  final String taskTitle;
  final DateTime completedAt;
}
