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

  test('normal task completion can be undone', () async {
    final id = await repository.createTask(
      title: 'Normal task',
      priority: TaskPriority.medium,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    final result = await cubit.setTaskCompleted(id: id, completed: true);

    expect(result, isNotNull);

    var task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.done);

    expect(task.isCompleted, isTrue);

    var history = await repository.watchCompletionHistory().first;

    expect(history, hasLength(1));

    await cubit.undoTaskCompletion(result!);

    task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.todo);

    expect(task.isCompleted, isFalse);

    history = await repository.watchCompletionHistory().first;

    expect(history, isEmpty);
  });

  test(
    'recurring completion advances due date and reminder with the same offset',
    () async {
      final dueAt = DateTime(2099, 1, 15, 9);
      final reminderAt = DateTime(2099, 1, 15, 8, 30);

      final id = await repository.createTask(
        title: 'Recurring task',
        priority: TaskPriority.medium,
        workflowStatus: TaskWorkflowStatus.todo,
        dueAt: dueAt,
      );

      await extrasRepository.saveExtras(
        id,
        TaskExtras(recurrence: 'daily', reminderAt: reminderAt),
      );

      final result = await cubit.setTaskCompleted(id: id, completed: true);

      expect(result, isNotNull);
      expect(result!.wasRecurring, isTrue);

      final task = await repository.getTask(id);
      final extras = await extrasRepository.getExtras(id);

      expect(task!.workflowStatus, TaskWorkflowStatus.todo);

      expect(task.dueAt, DateTime(2099, 1, 16, 9));

      expect(extras.reminderAt, DateTime(2099, 1, 16, 8, 30));

      expect(notifications.scheduled[id], DateTime(2099, 1, 16, 8, 30));

      final history = await repository.watchCompletionHistory().first;

      expect(history, hasLength(1));
    },
  );

  test(
    'undo recurring completion restores due date reminder status and history',
    () async {
      final dueAt = DateTime(2099, 3, 20, 18);
      final reminderAt = DateTime(2099, 3, 20, 17, 15);

      final id = await repository.createTask(
        title: 'Undo recurring task',
        priority: TaskPriority.high,
        workflowStatus: TaskWorkflowStatus.inProgress,
        dueAt: dueAt,
      );

      await extrasRepository.saveExtras(
        id,
        TaskExtras(
          recurrence: 'weekly',
          reminderAt: reminderAt,
          tags: const ['work'],
        ),
      );

      final result = await cubit.setTaskCompleted(id: id, completed: true);

      expect(result, isNotNull);

      await cubit.undoTaskCompletion(result!);

      final task = await repository.getTask(id);
      final extras = await extrasRepository.getExtras(id);

      expect(task!.workflowStatus, TaskWorkflowStatus.inProgress);

      expect(task.dueAt, dueAt);
      expect(extras.recurrence, 'weekly');
      expect(extras.reminderAt, reminderAt);
      expect(extras.tags, const ['work']);

      expect(notifications.scheduled[id], reminderAt);

      final history = await repository.watchCompletionHistory().first;

      expect(history, isEmpty);
    },
  );

  test('monthly recurring reminder follows clamped next due date', () async {
    final dueAt = DateTime(2099, 1, 31, 9);
    final reminderAt = DateTime(2099, 1, 31, 8);

    final id = await repository.createTask(
      title: 'Month end task',
      workflowStatus: TaskWorkflowStatus.todo,
      dueAt: dueAt,
    );

    await extrasRepository.saveExtras(
      id,
      TaskExtras(recurrence: 'monthly', reminderAt: reminderAt),
    );

    await cubit.setTaskCompleted(id: id, completed: true);

    final task = await repository.getTask(id);
    final extras = await extrasRepository.getExtras(id);

    expect(task!.dueAt, DateTime(2099, 2, 28, 9));

    expect(extras.reminderAt, DateTime(2099, 2, 28, 8));
  });
}

class FakeNotificationService extends NotificationService {
  final List<int> cancelled = <int>[];
  final Map<int, DateTime> scheduled = <int, DateTime>{};

  @override
  Future<void> cancelTask(int taskId) async {
    cancelled.add(taskId);
    scheduled.remove(taskId);
  }

  @override
  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {
    scheduled[taskId] = when;
  }
}
