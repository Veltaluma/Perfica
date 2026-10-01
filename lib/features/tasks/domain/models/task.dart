import 'task_priority.dart';
import 'task_workflow_status.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.priority,
    required this.workflowStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
    this.description,
    this.dueAt,
    this.completedAt,
  });

  final int id;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final TaskWorkflowStatus workflowStatus;
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int sortOrder;
}
