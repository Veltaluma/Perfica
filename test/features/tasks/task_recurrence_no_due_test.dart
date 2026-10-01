import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_extras_repository.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_extras.dart';
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

  test('recurring task without due date stays without due date', () async {
    final id = await repository.createTask(
      title: 'No due recurring',
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await extrasRepository.saveExtras(
      id,
      const TaskExtras(recurrence: 'daily'),
    );

    await cubit.setTaskCompleted(id: id, completed: true);

    final task = await repository.getTask(id);

    final extras = await extrasRepository.getExtras(id);

    expect(task, isNotNull);

    expect(task!.workflowStatus, TaskWorkflowStatus.todo);

    expect(task.dueAt, isNull);

    expect(extras.recurrence, 'daily');

    expect(extras.reminderAt, isNull);

    final history = await repository.watchCompletionHistory().first;

    expect(history, hasLength(1));
  });

  test('recurring task without due date advances reminder only', () async {
    final reminderAt = DateTime(2099, 6, 10, 9);

    final id = await repository.createTask(
      title: 'Reminder recurrence',
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await extrasRepository.saveExtras(
      id,
      TaskExtras(recurrence: 'daily', reminderAt: reminderAt),
    );

    await cubit.setTaskCompleted(id: id, completed: true);

    final task = await repository.getTask(id);

    final extras = await extrasRepository.getExtras(id);

    final expected = DateTime(2099, 6, 11, 9);

    expect(task, isNotNull);

    expect(task!.dueAt, isNull);

    expect(extras.reminderAt, expected);

    expect(notifications.scheduled[id], expected);
  });

  test(
    'overdue reminder without due date advances to first future occurrence',
    () async {
      final beforeCompletion = DateTime.now();

      final reminderAt = beforeCompletion.subtract(const Duration(days: 20));

      final id = await repository.createTask(
        title: 'Overdue reminder only',
        workflowStatus: TaskWorkflowStatus.todo,
      );

      await extrasRepository.saveExtras(
        id,
        TaskExtras(recurrence: 'daily', reminderAt: reminderAt),
      );

      await cubit.setTaskCompleted(id: id, completed: true);

      final task = await repository.getTask(id);

      final extras = await extrasRepository.getExtras(id);

      expect(task, isNotNull);

      expect(task!.dueAt, isNull);

      expect(extras.reminderAt, isNotNull);

      expect(extras.reminderAt!.isAfter(beforeCompletion), isTrue);

      expect(
        extras.reminderAt!.difference(beforeCompletion),
        lessThanOrEqualTo(const Duration(days: 1)),
      );
    },
  );
}

class FakeNotificationService extends NotificationService {
  final Map<int, DateTime> scheduled = {};

  @override
  Future<void> cancelTask(int taskId) async {
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
