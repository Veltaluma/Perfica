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

  test(
    'Stop repeating keeps task active and preserves current schedule',
    () async {
      final dueAt = DateTime(2099, 3, 10, 10);
      final reminderAt = DateTime(2099, 3, 10, 9, 30);
      final snoozedUntil = DateTime(2099, 3, 10, 9, 45);

      final id = await cubit.saveTask(
        title: 'Recurring',
        priority: TaskPriority.medium,
        workflowStatus: TaskWorkflowStatus.inProgress,
        dueAt: dueAt,
        recurrence: 'daily',
        reminderAt: reminderAt,
        reminderRepeatMinutes: 5,
      );

      final current = await extrasRepository.getExtras(id);

      await extrasRepository.saveExtras(
        id,
        current.copyWith(reminderSnoozedUntil: snoozedUntil),
      );

      final before = await cubit.stopRepeating(id);

      final task = await repository.getTask(id);

      final extras = await extrasRepository.getExtras(id);

      expect(before, isNotNull);
      expect(before!.recurrence, 'daily');

      expect(task!.workflowStatus, TaskWorkflowStatus.inProgress);

      expect(task.dueAt, dueAt);

      expect(extras.recurrence, isNull);
      expect(extras.reminderAt, reminderAt);

      expect(extras.reminderRepeatMinutes, 5);

      expect(extras.reminderSnoozedUntil, snoozedUntil);
    },
  );

  test('Undo stop repeating restores recurrence', () async {
    final id = await cubit.saveTask(
      title: 'Recurring',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
      dueAt: DateTime(2099, 4, 1, 10),
      recurrence: 'weekly',
      reminderAt: DateTime(2099, 4, 1, 9),
      reminderRepeatMinutes: 10,
    );

    final before = await cubit.stopRepeating(id);

    expect(before, isNotNull);

    await cubit.undoStopRepeating(id: id, extrasBefore: before!);

    final extras = await extrasRepository.getExtras(id);

    expect(extras.recurrence, 'weekly');

    expect(extras.reminderRepeatMinutes, 10);

    expect(notifications.scheduledTaskId, id);
  });

  test('Complete forever ends recurrence and clears reminders', () async {
    final id = await cubit.saveTask(
      title: 'Forever',
      priority: TaskPriority.high,
      workflowStatus: TaskWorkflowStatus.todo,
      dueAt: DateTime(2099, 5, 5, 12),
      recurrence: 'monthly',
      reminderAt: DateTime(2099, 5, 5, 11),
      reminderRepeatMinutes: 15,
    );

    final current = await extrasRepository.getExtras(id);

    await extrasRepository.saveExtras(
      id,
      current.copyWith(reminderSnoozedUntil: DateTime(2099, 5, 5, 11, 10)),
    );

    final result = await cubit.completeTaskForever(id);

    final task = await repository.getTask(id);

    final extras = await extrasRepository.getExtras(id);

    final history = await repository.watchCompletionHistory().first;

    expect(result, isNotNull);

    expect(task!.workflowStatus, TaskWorkflowStatus.done);

    expect(extras.recurrence, isNull);
    expect(extras.reminderAt, isNull);

    expect(extras.reminderRepeatMinutes, isNull);

    expect(extras.reminderSnoozedUntil, isNull);

    expect(history, hasLength(1));

    expect(notifications.cancelledTaskIds, contains(id));
  });

  test('Undo complete forever restores original recurring task', () async {
    final dueAt = DateTime(2099, 6, 7, 14);
    final reminderAt = DateTime(2099, 6, 7, 13, 30);

    final id = await cubit.saveTask(
      title: 'Restore',
      priority: TaskPriority.low,
      workflowStatus: TaskWorkflowStatus.inProgress,
      dueAt: dueAt,
      recurrence: 'daily',
      reminderAt: reminderAt,
      reminderRepeatMinutes: 5,
    );

    final result = await cubit.completeTaskForever(id);

    expect(result, isNotNull);

    await cubit.undoTaskCompletion(result!);

    final task = await repository.getTask(id);

    final extras = await extrasRepository.getExtras(id);

    final history = await repository.watchCompletionHistory().first;

    expect(task!.workflowStatus, TaskWorkflowStatus.inProgress);

    expect(task.dueAt, dueAt);
    expect(extras.recurrence, 'daily');
    expect(extras.reminderAt, reminderAt);

    expect(extras.reminderRepeatMinutes, 5);

    expect(history, isEmpty);

    expect(notifications.scheduledTaskId, id);
  });
}

class FakeNotificationService extends NotificationService {
  final List<int> cancelledTaskIds = [];

  int? scheduledTaskId;
  DateTime? scheduledWhen;
  int? scheduledRepeatMinutes;

  @override
  Future<void> cancelTask(int taskId) async {
    cancelledTaskIds.add(taskId);
  }

  @override
  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {
    scheduledTaskId = taskId;
    scheduledWhen = when;
    scheduledRepeatMinutes = null;
  }

  @override
  Future<void> scheduleTaskSeries({
    required int taskId,
    required String title,
    required DateTime when,
    required int repeatIntervalMinutes,
  }) async {
    scheduledTaskId = taskId;
    scheduledWhen = when;
    scheduledRepeatMinutes = repeatIntervalMinutes;
  }
}
