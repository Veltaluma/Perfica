import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_extras_repository.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';
import 'package:perfica/features/tasks/presentation/cubit/tasks_cubit.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;
  late DriftTaskExtrasRepository extrasRepository;
  late FakeNotificationService notifications;
  late TasksCubit cubit;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = DriftTaskRepository(database);

    extrasRepository = DriftTaskExtrasRepository(database);

    notifications = FakeNotificationService();

    cubit = TasksCubit(repository, extrasRepository, notifications);
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('Done action completes a normal task', () async {
    final id = await cubit.saveTask(
      title: 'Normal',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await cubit.handleNotificationAction(
      actionId: NotificationService.taskDoneActionId,
      taskId: id,
    );

    final task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.done);

    expect(notifications.cancelledTaskIds, contains(id));
  });

  test('Done action advances recurring occurrence', () async {
    final dueAt = DateTime(2099, 1, 10, 9);

    final id = await cubit.saveTask(
      title: 'Daily',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
      dueAt: dueAt,
      recurrence: 'daily',
    );

    await cubit.handleNotificationAction(
      actionId: NotificationService.taskDoneActionId,
      taskId: id,
    );

    final task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.todo);

    expect(task.dueAt, DateTime(2099, 1, 11, 9));
  });

  test('Snooze keeps original schedule and delays current alerts', () async {
    final dueAt = DateTime(2099, 2, 10, 10);

    final reminderAt = DateTime(2099, 2, 10, 9, 30);

    final id = await cubit.saveTask(
      title: 'Snooze',
      priority: TaskPriority.medium,
      workflowStatus: TaskWorkflowStatus.todo,
      dueAt: dueAt,
      recurrence: 'daily',
      reminderAt: reminderAt,
      reminderRepeatMinutes: 5,
    );

    notifications.reset();

    final before = DateTime.now();

    await cubit.handleNotificationAction(
      actionId: NotificationService.taskSnooze10ActionId,
      taskId: id,
    );

    final after = DateTime.now();

    final task = await repository.getTask(id);

    final extras = await extrasRepository.getExtras(id);

    expect(task!.dueAt, dueAt);
    expect(extras.reminderAt, reminderAt);
    expect(extras.recurrence, 'daily');
    expect(extras.reminderRepeatMinutes, 5);

    final snoozedUntil = extras.reminderSnoozedUntil;

    expect(snoozedUntil, isNotNull);

    expect(
      snoozedUntil!.isBefore(before.add(const Duration(minutes: 10))),
      isFalse,
    );

    expect(
      snoozedUntil.isAfter(after.add(const Duration(minutes: 10, seconds: 1))),
      isFalse,
    );

    expect(notifications.cancelledTaskIds, contains(id));

    expect(notifications.seriesTaskId, id);

    expect(notifications.seriesWhen, snoozedUntil);

    expect(notifications.seriesIntervalMinutes, 5);
  });
}

class FakeNotificationService extends NotificationService {
  final List<int> cancelledTaskIds = [];

  int? seriesTaskId;
  DateTime? seriesWhen;
  int? seriesIntervalMinutes;

  void reset() {
    cancelledTaskIds.clear();
    seriesTaskId = null;
    seriesWhen = null;
    seriesIntervalMinutes = null;
  }

  @override
  Future<void> cancelTask(int taskId) async {
    cancelledTaskIds.add(taskId);
  }

  @override
  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {}

  @override
  Future<void> scheduleTaskSeries({
    required int taskId,
    required String title,
    required DateTime when,
    required int repeatIntervalMinutes,
  }) async {
    seriesTaskId = taskId;
    seriesWhen = when;
    seriesIntervalMinutes = repeatIntervalMinutes;
  }
}
