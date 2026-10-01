import '../../../../core/services/notification_service.dart';
import '../models/task_extras.dart';

class TaskReminderScheduler {
  const TaskReminderScheduler(this._notificationService);

  final NotificationService _notificationService;

  Future<void> schedule({
    required int taskId,
    required String title,
    required DateTime when,
    int? repeatMinutes,
  }) {
    if (repeatMinutes != null && repeatMinutes > 0) {
      return _notificationService.scheduleTaskSeries(
        taskId: taskId,
        title: title,
        when: when,
        repeatIntervalMinutes: repeatMinutes,
      );
    }

    return _notificationService.scheduleTask(
      taskId: taskId,
      title: title,
      when: when,
    );
  }

  Future<void> scheduleStored({
    required int taskId,
    required String title,
    required TaskExtras extras,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();

    final base = extras.reminderSnoozedUntil ?? extras.reminderAt;

    if (base == null) {
      return;
    }

    if (!hasFutureAlert(
      base: base,
      repeatMinutes: extras.reminderRepeatMinutes,
      now: reference,
    )) {
      return;
    }

    await schedule(
      taskId: taskId,
      title: title,
      when: base,
      repeatMinutes: extras.reminderRepeatMinutes,
    );
  }

  bool hasFutureAlert({
    required DateTime base,
    required int? repeatMinutes,
    required DateTime now,
  }) {
    if (base.isAfter(now)) {
      return true;
    }

    if (repeatMinutes == null || repeatMinutes <= 0) {
      return false;
    }

    final lastAlertAt = base.add(
      Duration(
        minutes: repeatMinutes * (NotificationService.taskRepeatAlertCount - 1),
      ),
    );

    return lastAlertAt.isAfter(now);
  }
}
