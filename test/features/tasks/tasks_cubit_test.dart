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

  Future<int> createTask({
    TaskWorkflowStatus status = TaskWorkflowStatus.todo,
    DateTime? dueAt,
    String? recurrence,
  }) async {
    final id = await repository.createTask(
      title: 'Test task',
      priority: TaskPriority.medium,
      workflowStatus: status,
      dueAt: dueAt,
    );

    if (recurrence != null) {
      await extrasRepository.saveExtras(id, TaskExtras(recurrence: recurrence));
    }

    return id;
  }

  test('explicit Done moves normal task to Done', () async {
    final id = await createTask();

    await cubit.setWorkflowStatus(id: id, status: TaskWorkflowStatus.done);

    final task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.done);

    expect(task.isCompleted, isTrue);

    final history = await repository.watchCompletionHistory().first;

    expect(history, hasLength(1));
  });

  test(
    'explicit Done moves recurring task to Done without advancing occurrence',
    () async {
      final originalDueAt = DateTime(2099, 9, 24, 8, 30);

      final id = await createTask(dueAt: originalDueAt, recurrence: 'daily');

      await cubit.setWorkflowStatus(id: id, status: TaskWorkflowStatus.done);

      final task = await repository.getTask(id);

      expect(task!.workflowStatus, TaskWorkflowStatus.done);

      expect(task.isCompleted, isTrue);

      expect(task.dueAt, originalDueAt);

      final extras = await extrasRepository.getExtras(id);

      expect(extras.recurrence, 'daily');

      final history = await repository.watchCompletionHistory().first;

      expect(history, hasLength(1));
    },
  );

  test('checkbox completion advances recurring occurrence', () async {
    final id = await createTask(
      dueAt: DateTime(2099, 9, 24, 8, 30),
      recurrence: 'daily',
    );

    await cubit.setTaskCompleted(id: id, completed: true);

    final task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.todo);

    expect(task.isCompleted, isFalse);

    expect(task.dueAt, DateTime(2099, 9, 25, 8, 30));

    final history = await repository.watchCompletionHistory().first;

    expect(history, hasLength(1));
  });

  test('checkbox monthly recurrence clamps end of month', () async {
    final id = await createTask(
      dueAt: DateTime(2099, 1, 31, 9),
      recurrence: 'monthly',
    );

    await cubit.setTaskCompleted(id: id, completed: true);

    final task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.todo);

    expect(task.dueAt, DateTime(2099, 2, 28, 9));
  });

  test('moving Done task back to Todo removes latest completion', () async {
    final id = await createTask();

    await cubit.setWorkflowStatus(id: id, status: TaskWorkflowStatus.done);

    await cubit.setWorkflowStatus(id: id, status: TaskWorkflowStatus.todo);

    final task = await repository.getTask(id);

    expect(task!.workflowStatus, TaskWorkflowStatus.todo);

    final history = await repository.watchCompletionHistory().first;

    expect(history, isEmpty);
  });

  test(
    'Todo and In progress transitions do not create completion history',
    () async {
      final id = await createTask();

      await cubit.setWorkflowStatus(
        id: id,
        status: TaskWorkflowStatus.inProgress,
      );

      var task = await repository.getTask(id);

      expect(task!.workflowStatus, TaskWorkflowStatus.inProgress);

      await cubit.setWorkflowStatus(id: id, status: TaskWorkflowStatus.todo);

      task = await repository.getTask(id);

      expect(task!.workflowStatus, TaskWorkflowStatus.todo);

      final history = await repository.watchCompletionHistory().first;

      expect(history, isEmpty);
    },
  );

  test('complete all uses occurrence completion semantics', () async {
    final normalId = await createTask();

    final recurringId = await createTask(
      dueAt: DateTime(2099, 9, 24),
      recurrence: 'daily',
    );

    await cubit.stream.firstWhere((state) => state.tasks.length == 2);

    await cubit.completeAllActive();

    final normal = await repository.getTask(normalId);
    final recurring = await repository.getTask(recurringId);

    expect(normal!.workflowStatus, TaskWorkflowStatus.done);

    expect(recurring!.workflowStatus, TaskWorkflowStatus.todo);

    expect(recurring.dueAt, DateTime(2099, 9, 25));

    final history = await repository.watchCompletionHistory().first;

    expect(history, hasLength(2));
  });

  test('clear completed does not delete recurring task after occurrence completion', () async {
    final id = await createTask(
      dueAt: DateTime(2099, 9, 24, 8),
      recurrence: 'daily',
    );

    final advancedState = cubit.stream.firstWhere(
      (state) => state.tasks.any(
        (task) =>
            task.id == id && task.workflowStatus == TaskWorkflowStatus.todo,
      ),
    );

    await cubit.setTaskCompleted(id: id, completed: true);

    await advancedState;

    await cubit.clearCompleted();

    final task = await repository.getTask(id);

    expect(task, isNotNull);

    expect(task!.workflowStatus, TaskWorkflowStatus.todo);

    expect(task.dueAt, DateTime(2099, 9, 25, 8));

    final history = await repository.watchCompletionHistory().first;

    expect(history, hasLength(1));
  });

  test(
    'clear completed removes complete-forever task but preserves history',
    () async {
      final id = await createTask(
        dueAt: DateTime(2099, 10, 1, 9),
        recurrence: 'weekly',
      );

      final completedState = cubit.stream.firstWhere(
        (state) => state.tasks.any(
          (task) =>
              task.id == id && task.workflowStatus == TaskWorkflowStatus.done,
        ),
      );

      final result = await cubit.completeTaskForever(id);

      expect(result, isNotNull);

      await completedState;

      await cubit.clearCompleted();

      expect(await repository.getTask(id), isNull);

      final history = await repository.watchCompletionHistory().first;

      expect(history, hasLength(1));

      expect(history.single.taskTitle, 'Test task');
    },
  );
}

class FakeNotificationService extends NotificationService {
  final List<int> cancelledTasks = [];

  @override
  Future<void> cancelTask(int taskId) async {
    cancelledTasks.add(taskId);
  }

  @override
  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {}
}
