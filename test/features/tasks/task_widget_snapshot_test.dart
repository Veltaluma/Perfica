import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/tasks/application/services/task_widget_snapshot_service.dart';
import 'package:perfica/features/tasks/domain/models/task.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';

void main() {
  Task task({
    required int id,
    required String title,
    required TaskWorkflowStatus status,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title,
      isCompleted: status == TaskWorkflowStatus.done,
      priority: TaskPriority.none,
      workflowStatus: status,
      createdAt: DateTime(2026),
      updatedAt: updatedAt,
      completedAt: completedAt,
      sortOrder: id,
    );
  }

  test('widget snapshot separates active and completed tasks', () {
    final payload = buildTaskWidgetPayload([
      task(
        id: 1,
        title: 'Active',
        status: TaskWorkflowStatus.todo,
        updatedAt: DateTime(2026, 9, 28, 10),
      ),
      task(
        id: 2,
        title: 'Completed',
        status: TaskWorkflowStatus.done,
        updatedAt: DateTime(2026, 9, 28, 11),
        completedAt: DateTime(2026, 9, 28, 11),
      ),
    ]);

    final active = payload['active']! as List<dynamic>;
    final completed = payload['completed']! as List<dynamic>;

    expect(active.single['id'], 1);
    expect(completed.single['id'], 2);
  });

  test('completed widget tasks are newest first', () {
    final payload = buildTaskWidgetPayload([
      task(
        id: 1,
        title: 'Older',
        status: TaskWorkflowStatus.done,
        updatedAt: DateTime(2026, 9, 28, 10),
        completedAt: DateTime(2026, 9, 28, 10),
      ),
      task(
        id: 2,
        title: 'Newer',
        status: TaskWorkflowStatus.done,
        updatedAt: DateTime(2026, 9, 28, 12),
        completedAt: DateTime(2026, 9, 28, 12),
      ),
    ]);

    final completed = payload['completed']! as List<dynamic>;

    expect(completed.map((item) => item['id']), [2, 1]);
  });
}
