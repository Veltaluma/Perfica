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

  test(
    'overdue daily recurrence advances to the first future occurrence',
    () async {
      final beforeCompletion = DateTime.now();

      final dueAt = beforeCompletion.subtract(const Duration(days: 40));

      final id = await repository.createTask(
        title: 'Overdue daily',
        workflowStatus: TaskWorkflowStatus.todo,
        dueAt: dueAt,
      );

      await extrasRepository.saveExtras(
        id,
        const TaskExtras(recurrence: 'daily'),
      );

      await cubit.setTaskCompleted(id: id, completed: true);

      final task = await repository.getTask(id);

      expect(task, isNotNull);

      expect(task!.workflowStatus, TaskWorkflowStatus.todo);

      expect(task.dueAt!.isAfter(beforeCompletion), isTrue);

      expect(
        task.dueAt!.difference(beforeCompletion),
        lessThanOrEqualTo(const Duration(days: 1)),
      );
    },
  );

  test(
    'overdue weekly recurrence advances to the first future occurrence',
    () async {
      final beforeCompletion = DateTime.now();

      final dueAt = beforeCompletion.subtract(const Duration(days: 100));

      final id = await repository.createTask(
        title: 'Overdue weekly',
        workflowStatus: TaskWorkflowStatus.todo,
        dueAt: dueAt,
      );

      await extrasRepository.saveExtras(
        id,
        const TaskExtras(recurrence: 'weekly'),
      );

      await cubit.setTaskCompleted(id: id, completed: true);

      final task = await repository.getTask(id);

      expect(task, isNotNull);

      expect(task!.dueAt!.isAfter(beforeCompletion), isTrue);

      expect(
        task.dueAt!.difference(beforeCompletion),
        lessThanOrEqualTo(const Duration(days: 7)),
      );
    },
  );

  test('overdue monthly recurrence advances beyond the current time', () async {
    final beforeCompletion = DateTime.now();

    final dueAt = DateTime(
      beforeCompletion.year - 2,
      beforeCompletion.month,
      15,
      9,
    );

    final id = await repository.createTask(
      title: 'Overdue monthly',
      workflowStatus: TaskWorkflowStatus.todo,
      dueAt: dueAt,
    );

    await extrasRepository.saveExtras(
      id,
      const TaskExtras(recurrence: 'monthly'),
    );

    await cubit.setTaskCompleted(id: id, completed: true);

    final task = await repository.getTask(id);

    expect(task, isNotNull);

    expect(task!.dueAt!.isAfter(beforeCompletion), isTrue);
  });

  test(
    'overdue recurring reminder keeps its offset from the next due date',
    () async {
      final beforeCompletion = DateTime.now();

      final oldDue = beforeCompletion.subtract(const Duration(days: 20));

      final oldReminder = oldDue.subtract(const Duration(minutes: 45));

      final id = await repository.createTask(
        title: 'Overdue reminder',
        workflowStatus: TaskWorkflowStatus.todo,
        dueAt: oldDue,
      );

      await extrasRepository.saveExtras(
        id,
        TaskExtras(recurrence: 'daily', reminderAt: oldReminder),
      );

      await cubit.setTaskCompleted(id: id, completed: true);

      final task = await repository.getTask(id);

      final extras = await extrasRepository.getExtras(id);

      expect(task, isNotNull);

      expect(task!.dueAt!.isAfter(beforeCompletion), isTrue);

      expect(
        extras.reminderAt,
        task.dueAt!.subtract(const Duration(minutes: 45)),
      );
    },
  );
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
