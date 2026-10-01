import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_extras_repository.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_extras.dart';
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
    'monthly recurrence restores original day after a short month',
    () async {
      final id = await cubit.saveTask(
        title: 'Month end',
        priority: TaskPriority.none,
        workflowStatus: TaskWorkflowStatus.todo,
        dueAt: DateTime(2099, 1, 31, 9),
        recurrence: 'monthly',
      );

      var extras = await extrasRepository.getExtras(id);

      expect(extras.monthlyAnchorDay, 31);

      await cubit.setTaskCompleted(id: id, completed: true);

      var task = await repository.getTask(id);

      expect(task!.dueAt, DateTime(2099, 2, 28, 9));

      extras = await extrasRepository.getExtras(id);

      expect(extras.monthlyAnchorDay, 31);

      await cubit.setTaskCompleted(id: id, completed: true);

      task = await repository.getTask(id);

      expect(task!.dueAt, DateTime(2099, 3, 31, 9));
    },
  );

  test(
    'monthly reminder-only recurrence preserves original calendar day',
    () async {
      final id = await cubit.saveTask(
        title: 'Reminder only',
        priority: TaskPriority.none,
        workflowStatus: TaskWorkflowStatus.todo,
        recurrence: 'monthly',
        reminderAt: DateTime(2099, 1, 31, 8),
      );

      var extras = await extrasRepository.getExtras(id);

      expect(extras.monthlyAnchorDay, 31);

      await cubit.setTaskCompleted(id: id, completed: true);

      var task = await repository.getTask(id);

      extras = await extrasRepository.getExtras(id);

      expect(task!.dueAt, isNull);

      expect(extras.reminderAt, DateTime(2099, 2, 28, 8));

      expect(extras.monthlyAnchorDay, 31);

      await cubit.setTaskCompleted(id: id, completed: true);

      extras = await extrasRepository.getExtras(id);

      expect(extras.reminderAt, DateTime(2099, 3, 31, 8));
    },
  );

  test(
    'editing a clamped monthly task preserves its original anchor',
    () async {
      final id = await cubit.saveTask(
        title: 'Original title',
        priority: TaskPriority.medium,
        workflowStatus: TaskWorkflowStatus.todo,
        dueAt: DateTime(2099, 1, 31, 10),
        recurrence: 'monthly',
      );

      await cubit.setTaskCompleted(id: id, completed: true);

      var task = await repository.getTask(id);

      expect(task!.dueAt, DateTime(2099, 2, 28, 10));

      final extrasBefore = await extrasRepository.getExtras(id);

      expect(extrasBefore.monthlyAnchorDay, 31);

      await cubit.saveTask(
        taskId: id,
        title: 'Edited title',
        priority: task.priority,
        workflowStatus: task.workflowStatus,
        dueAt: task.dueAt,
        recurrence: extrasBefore.recurrence,
        reminderAt: extrasBefore.reminderAt,
        reminderRepeatMinutes: extrasBefore.reminderRepeatMinutes,
        tags: extrasBefore.tags,
        attachments: extrasBefore.attachments,
      );

      final extrasAfter = await extrasRepository.getExtras(id);

      expect(extrasAfter.monthlyAnchorDay, 31);

      await cubit.setTaskCompleted(id: id, completed: true);

      task = await repository.getTask(id);

      expect(task!.dueAt, DateTime(2099, 3, 31, 10));
    },
  );

  test('monthly anchor survives extras storage round trip', () async {
    final taskId = await repository.createTask(
      title: 'Monthly anchor persistence',
    );

    await extrasRepository.saveExtras(
      taskId,
      const TaskExtras(
        recurrence: 'monthly',
        monthlyAnchorDay: 31,
        tags: ['billing'],
      ),
    );

    final restored = await extrasRepository.getExtras(taskId);

    expect(restored.recurrence, 'monthly');

    expect(restored.monthlyAnchorDay, 31);

    expect(restored.tags, const ['billing']);
  });
}

class FakeNotificationService extends NotificationService {
  @override
  Future<void> cancelTask(int taskId) async {}

  @override
  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {}
}
