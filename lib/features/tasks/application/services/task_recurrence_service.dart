import '../../../../core/services/notification_service.dart';
import '../../domain/models/task_extras.dart';
import '../../domain/models/task_workflow_status.dart';
import '../../domain/repositories/task_extras_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/task_reminder_scheduler.dart';

class TaskRecurrenceService {
  TaskRecurrenceService(
    this._repository,
    this._extrasRepository,
    this._notificationService,
    this._reminderScheduler,
  );

  final TaskRepository _repository;
  final TaskExtrasRepository _extrasRepository;
  final NotificationService _notificationService;
  final TaskReminderScheduler _reminderScheduler;

  Future<TaskExtras?> stopRepeating(int id) async {
    final task = await _repository.getTask(id);

    if (task == null || task.workflowStatus == TaskWorkflowStatus.done) {
      return null;
    }

    final extras = await _extrasRepository.getExtras(id);

    if (extras.recurrence == null) {
      return null;
    }

    await _extrasRepository.saveExtras(
      id,
      extras.copyWith(clearRecurrence: true),
    );

    return extras;
  }

  Future<void> undoStopRepeating({
    required int id,
    required TaskExtras extrasBefore,
  }) async {
    final task = await _repository.getTask(id);

    if (task == null || task.workflowStatus == TaskWorkflowStatus.done) {
      return;
    }

    await _notificationService.cancelTask(id);

    await _extrasRepository.saveExtras(id, extrasBefore);

    await _reminderScheduler.scheduleStored(
      taskId: id,
      title: task.title,
      extras: extrasBefore,
    );
  }
}
