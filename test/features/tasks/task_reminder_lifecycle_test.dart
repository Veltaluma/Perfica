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

  Future<int> createTask() async {
    final id = await repository.createTask(
      title: 'Reminder lifecycle',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await cubit.stream.firstWhere(
      (state) => state.tasks.any((task) => task.id == id),
    );

    return id;
  }

  test('reschedule preserves remaining repeat alerts after primary reminder passed', () async {
    final id = await createTask();

    final base = DateTime.now().subtract(const Duration(minutes: 6));

    await extrasRepository.saveExtras(
      id,
      TaskExtras(reminderAt: base, reminderRepeatMinutes: 5),
    );

    notifications.reset();

    await cubit.rescheduleTaskReminders();

    expect(notifications.cancelledTaskIds, contains(id));

    expect(notifications.seriesTaskId, id);

    expect(notifications.seriesWhen, base);

    expect(notifications.seriesIntervalMinutes, 5);
  });

  test('expired repeat series is not recreated during reschedule', () async {
    final id = await createTask();

    final base = DateTime.now().subtract(const Duration(minutes: 30));

    await extrasRepository.saveExtras(
      id,
      TaskExtras(reminderAt: base, reminderRepeatMinutes: 5),
    );

    notifications.reset();

    await cubit.rescheduleTaskReminders();

    expect(notifications.cancelledTaskIds, contains(id));

    expect(notifications.seriesTaskId, isNull);

    expect(notifications.singleTaskId, isNull);
  });

  test('reschedule uses snoozed series as the active reminder base', () async {
    final id = await createTask();

    final original = DateTime.now().subtract(const Duration(hours: 1));

    final snoozedBase = DateTime.now().subtract(const Duration(minutes: 6));

    await extrasRepository.saveExtras(
      id,
      TaskExtras(
        reminderAt: original,
        reminderRepeatMinutes: 5,
        reminderSnoozedUntil: snoozedBase,
      ),
    );

    notifications.reset();

    await cubit.rescheduleTaskReminders();

    expect(notifications.seriesTaskId, id);

    expect(notifications.seriesWhen, snoozedBase);

    expect(notifications.seriesIntervalMinutes, 5);
  });

  test('editing task preserves remaining future alerts from an active repeat series', () async {
    final id = await createTask();

    final base = DateTime.now().subtract(const Duration(minutes: 6));

    await extrasRepository.saveExtras(
      id,
      TaskExtras(reminderAt: base, reminderRepeatMinutes: 5),
    );

    notifications.reset();

    await cubit.saveTask(
      taskId: id,
      title: 'Edited reminder lifecycle',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
      reminderAt: base,
      reminderRepeatMinutes: 5,
    );

    expect(notifications.cancelledTaskIds, contains(id));

    expect(notifications.seriesTaskId, id);

    expect(notifications.seriesWhen, base);

    expect(notifications.seriesIntervalMinutes, 5);
  });
}

class FakeNotificationService extends NotificationService {
  final List<int> cancelledTaskIds = [];

  int? singleTaskId;
  DateTime? singleWhen;

  int? seriesTaskId;
  DateTime? seriesWhen;
  int? seriesIntervalMinutes;

  void reset() {
    cancelledTaskIds.clear();

    singleTaskId = null;
    singleWhen = null;

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
  }) async {
    singleTaskId = taskId;
    singleWhen = when;
  }

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
