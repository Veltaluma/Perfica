import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/tasks/domain/models/task_extras.dart';
import 'package:perfica/features/tasks/domain/services/task_reminder_scheduler.dart';

void main() {
  late _FakeNotificationService notifications;
  late TaskReminderScheduler scheduler;

  setUp(() {
    notifications = _FakeNotificationService();

    scheduler = TaskReminderScheduler(notifications);
  });

  test('single reminder uses scheduleTask', () async {
    final when = DateTime(2099, 1, 10, 8);

    await scheduler.schedule(taskId: 1, title: 'Single reminder', when: when);

    expect(notifications.singleScheduled, hasLength(1));

    expect(notifications.seriesScheduled, isEmpty);

    expect(notifications.singleScheduled.single.taskId, 1);

    expect(notifications.singleScheduled.single.when, when);
  });

  test('repeating reminder uses scheduleTaskSeries', () async {
    final when = DateTime(2099, 1, 10, 8);

    await scheduler.schedule(
      taskId: 2,
      title: 'Repeat reminder',
      when: when,
      repeatMinutes: 10,
    );

    expect(notifications.singleScheduled, isEmpty);

    expect(notifications.seriesScheduled, hasLength(1));

    expect(notifications.seriesScheduled.single.repeatMinutes, 10);
  });

  test('stored reminder uses normal reminder when not snoozed', () async {
    final reminderAt = DateTime(2099, 1, 10, 8);

    await scheduler.scheduleStored(
      taskId: 3,
      title: 'Stored reminder',
      extras: TaskExtras(reminderAt: reminderAt),
      now: DateTime(2099, 1, 10, 7),
    );

    expect(notifications.singleScheduled, hasLength(1));

    expect(notifications.singleScheduled.single.when, reminderAt);
  });

  test('snoozed reminder takes priority over original reminder', () async {
    final reminderAt = DateTime(2099, 1, 10, 8);

    final snoozedUntil = DateTime(2099, 1, 10, 9);

    await scheduler.scheduleStored(
      taskId: 4,
      title: 'Snoozed reminder',
      extras: TaskExtras(
        reminderAt: reminderAt,
        reminderSnoozedUntil: snoozedUntil,
      ),
      now: DateTime(2099, 1, 10, 8, 30),
    );

    expect(notifications.singleScheduled, hasLength(1));

    expect(notifications.singleScheduled.single.when, snoozedUntil);
  });

  test('expired single reminder is not scheduled', () async {
    await scheduler.scheduleStored(
      taskId: 5,
      title: 'Expired reminder',
      extras: TaskExtras(reminderAt: DateTime(2099, 1, 10, 8)),
      now: DateTime(2099, 1, 10, 9),
    );

    expect(notifications.singleScheduled, isEmpty);

    expect(notifications.seriesScheduled, isEmpty);
  });

  test('repeat series remains schedulable while an alert is future', () {
    final result = scheduler.hasFutureAlert(
      base: DateTime(2099, 1, 10, 8),
      repeatMinutes: 10,
      now: DateTime(2099, 1, 10, 8, 25),
    );

    expect(result, isTrue);
  });

  test('repeat series expires after its final alert', () {
    final result = scheduler.hasFutureAlert(
      base: DateTime(2099, 1, 10, 8),
      repeatMinutes: 10,
      now: DateTime(2099, 1, 10, 9),
    );

    expect(result, isFalse);
  });

  test('missing reminder does nothing', () async {
    await scheduler.scheduleStored(
      taskId: 6,
      title: 'No reminder',
      extras: const TaskExtras(),
      now: DateTime(2099, 1, 10),
    );

    expect(notifications.singleScheduled, isEmpty);

    expect(notifications.seriesScheduled, isEmpty);
  });
}

class _FakeNotificationService extends NotificationService {
  final List<_SingleSchedule> singleScheduled = [];
  final List<_SeriesSchedule> seriesScheduled = [];

  @override
  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {
    singleScheduled.add(
      _SingleSchedule(taskId: taskId, title: title, when: when),
    );
  }

  @override
  Future<void> scheduleTaskSeries({
    required int taskId,
    required String title,
    required DateTime when,
    required int repeatIntervalMinutes,
  }) async {
    seriesScheduled.add(
      _SeriesSchedule(
        taskId: taskId,
        title: title,
        when: when,
        repeatMinutes: repeatIntervalMinutes,
      ),
    );
  }
}

class _SingleSchedule {
  const _SingleSchedule({
    required this.taskId,
    required this.title,
    required this.when,
  });

  final int taskId;
  final String title;
  final DateTime when;
}

class _SeriesSchedule {
  const _SeriesSchedule({
    required this.taskId,
    required this.title,
    required this.when,
    required this.repeatMinutes,
  });

  final int taskId;
  final String title;
  final DateTime when;
  final int repeatMinutes;
}
