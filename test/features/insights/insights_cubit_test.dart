import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/features/focus/data/focus_repository.dart';
import 'package:perfica/features/focus/data/focus_session.dart';
import 'package:perfica/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:perfica/features/insights/presentation/cubit/insights_state.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository taskRepository;
  late FocusRepository focusRepository;
  late InsightsCubit cubit;

  final now = DateTime(2099, 6, 10, 14);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    taskRepository = DriftTaskRepository(database);

    focusRepository = FocusRepository(database);

    cubit = InsightsCubit(taskRepository, focusRepository, now: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  Future<InsightsState> waitForState(
    bool Function(InsightsState state) predicate,
  ) async {
    if (predicate(cubit.state)) {
      return cubit.state;
    }

    return cubit.stream.firstWhere(predicate);
  }

  test('starts with zero insight values', () async {
    final state = await waitForState(
      (state) => state.status == InsightsStatus.success,
    );

    expect(state.completedToday, 0);
    expect(state.completedTotal, 0);
    expect(state.currentStreak, 0);
    expect(state.focusMinutes, 0);
  });

  test('calculates today total and consecutive-day streak', () async {
    final taskId = await taskRepository.createTask(
      title: 'Tracked task',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Tracked task',
      completedAt: DateTime(2099, 6, 10, 8),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Tracked task',
      completedAt: DateTime(2099, 6, 9, 20),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Tracked task',
      completedAt: DateTime(2099, 6, 8, 7),
    );

    final state = await waitForState(
      (state) =>
          state.status == InsightsStatus.success && state.completedTotal == 3,
    );

    expect(state.completedToday, 1);
    expect(state.completedTotal, 3);
    expect(state.currentStreak, 3);
  });

  test('keeps yesterday streak active before today has a completion', () async {
    final taskId = await taskRepository.createTask(
      title: 'Yesterday task',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Yesterday task',
      completedAt: DateTime(2099, 6, 9, 23),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Yesterday task',
      completedAt: DateTime(2099, 6, 8, 10),
    );

    final state = await waitForState((state) => state.completedTotal == 2);

    expect(state.completedToday, 0);
    expect(state.currentStreak, 2);
  });

  test('completion history remains counted after task deletion', () async {
    final taskId = await taskRepository.createTask(
      title: 'Delete after completion',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Delete after completion',
      completedAt: DateTime(2099, 6, 10, 9),
    );

    await taskRepository.deleteTask(taskId);

    final state = await waitForState((state) => state.completedTotal == 1);

    expect(state.completedToday, 1);
    expect(state.completedTotal, 1);
  });

  test('focus minutes update reactively when a session is completed', () async {
    await waitForState((state) => state.status == InsightsStatus.success);

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 10, 10), durationMinutes: 25),
    );

    var state = await waitForState((state) => state.focusMinutes == 25);

    expect(state.focusMinutes, 25);

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 10, 11), durationMinutes: 50),
    );

    state = await waitForState((state) => state.focusMinutes == 75);

    expect(state.focusMinutes, 75);
  });
  test('builds a zero-filled seven-day series oldest to newest', () async {
    final state = await waitForState(
      (state) => state.status == InsightsStatus.success,
    );

    expect(state.last7Days, hasLength(7));

    expect(state.last7Days.map((item) => item.date).toList(), [
      DateTime(2099, 6, 4),
      DateTime(2099, 6, 5),
      DateTime(2099, 6, 6),
      DateTime(2099, 6, 7),
      DateTime(2099, 6, 8),
      DateTime(2099, 6, 9),
      DateTime(2099, 6, 10),
    ]);

    for (final item in state.last7Days) {
      expect(item.completedTasks, 0);
      expect(item.focusMinutes, 0);
    }
  });

  test(
    'aggregates task completions and focus minutes by calendar day',
    () async {
      final taskId = await taskRepository.createTask(
        title: 'Daily aggregation',
        priority: TaskPriority.none,
        workflowStatus: TaskWorkflowStatus.todo,
      );

      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Daily aggregation',
        completedAt: DateTime(2099, 6, 8, 8),
      );

      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Daily aggregation',
        completedAt: DateTime(2099, 6, 8, 18),
      );

      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Daily aggregation',
        completedAt: DateTime(2099, 6, 10, 7),
      );

      await focusRepository.addSession(
        FocusSession(completedAt: DateTime(2099, 6, 8, 9), durationMinutes: 25),
      );

      await focusRepository.addSession(
        FocusSession(
          completedAt: DateTime(2099, 6, 8, 15),
          durationMinutes: 50,
        ),
      );

      await focusRepository.addSession(
        FocusSession(
          completedAt: DateTime(2099, 6, 10, 12),
          durationMinutes: 30,
        ),
      );

      final state = await waitForState(
        (state) => state.completedTotal == 3 && state.focusMinutes == 105,
      );

      final june8 = state.last7Days.singleWhere(
        (item) => item.date == DateTime(2099, 6, 8),
      );

      final june10 = state.last7Days.singleWhere(
        (item) => item.date == DateTime(2099, 6, 10),
      );

      expect(june8.completedTasks, 2);
      expect(june8.focusMinutes, 75);

      expect(june10.completedTasks, 1);
      expect(june10.focusMinutes, 30);
    },
  );

  test(
    'seven-day series crosses month boundaries using calendar dates',
    () async {
      await cubit.close();

      cubit = InsightsCubit(
        taskRepository,
        focusRepository,
        now: () => DateTime(2099, 3, 3, 14),
      );

      final state = await waitForState(
        (state) => state.status == InsightsStatus.success,
      );

      expect(state.last7Days.map((item) => item.date).toList(), [
        DateTime(2099, 2, 25),
        DateTime(2099, 2, 26),
        DateTime(2099, 2, 27),
        DateTime(2099, 2, 28),
        DateTime(2099, 3, 1),
        DateTime(2099, 3, 2),
        DateTime(2099, 3, 3),
      ]);
    },
  );
  test('initial success state has zero period summaries', () async {
    final state = await waitForState(
      (state) => state.status == InsightsStatus.success,
    );

    expect(state.thisWeek.completedTasks, 0);
    expect(state.thisWeek.focusMinutes, 0);
    expect(state.previousWeek.completedTasks, 0);
    expect(state.previousWeek.focusMinutes, 0);
    expect(state.thisMonth.completedTasks, 0);
    expect(state.thisMonth.focusMinutes, 0);
  });

  test('calculates current and previous ISO week summaries', () async {
    final taskId = await taskRepository.createTask(
      title: 'Period summary',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    // Current week:
    // Monday 2099-06-08
    // through Wednesday 2099-06-10.
    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Period summary',
      completedAt: DateTime(2099, 6, 8, 8),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Period summary',
      completedAt: DateTime(2099, 6, 10, 10),
    );

    // Previous week:
    // Monday 2099-06-01
    // through Sunday 2099-06-07.
    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Period summary',
      completedAt: DateTime(2099, 6, 2, 9),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 8, 12), durationMinutes: 25),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 10, 13), durationMinutes: 30),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 6, 15), durationMinutes: 40),
    );

    final state = await waitForState(
      (state) => state.completedTotal == 3 && state.focusMinutes == 95,
    );

    expect(state.thisWeek.completedTasks, 2);
    expect(state.thisWeek.focusMinutes, 55);

    expect(state.previousWeek.completedTasks, 1);
    expect(state.previousWeek.focusMinutes, 40);
  });

  test('calculates current month only through today', () async {
    final taskId = await taskRepository.createTask(
      title: 'Monthly summary',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Monthly summary',
      completedAt: DateTime(2099, 6, 1, 8),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Monthly summary',
      completedAt: DateTime(2099, 6, 10, 8),
    );

    // Future event in the same month must
    // not be counted in "this month" yet.
    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Monthly summary',
      completedAt: DateTime(2099, 6, 20, 8),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 4, 10), durationMinutes: 25),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 10, 10), durationMinutes: 50),
    );

    await focusRepository.addSession(
      FocusSession(
        completedAt: DateTime(2099, 6, 20, 10),
        durationMinutes: 100,
      ),
    );

    final state = await waitForState(
      (state) => state.completedTotal == 3 && state.focusMinutes == 175,
    );

    expect(state.thisMonth.completedTasks, 2);
    expect(state.thisMonth.focusMinutes, 75);
  });

  test('week summaries cross month boundaries correctly', () async {
    await cubit.close();

    cubit = InsightsCubit(
      taskRepository,
      focusRepository,
      now: () => DateTime(2099, 3, 2, 12),
    );

    final taskId = await taskRepository.createTask(
      title: 'Boundary summary',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Boundary summary',
      completedAt: DateTime(2099, 3, 2, 8),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Boundary summary',
      completedAt: DateTime(2099, 2, 28, 8),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 3, 2, 10), durationMinutes: 30),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 2, 28, 10), durationMinutes: 45),
    );

    final state = await waitForState(
      (state) => state.completedTotal == 2 && state.focusMinutes == 75,
    );

    expect(state.thisWeek.completedTasks, 1);
    expect(state.thisWeek.focusMinutes, 30);

    expect(state.previousWeek.completedTasks, 1);
    expect(state.previousWeek.focusMinutes, 45);

    expect(state.thisMonth.completedTasks, 1);
    expect(state.thisMonth.focusMinutes, 30);
  });
  test('zero activity has no best day and zero daily averages', () async {
    final state = await waitForState(
      (state) => state.status == InsightsStatus.success,
    );

    expect(state.bestDay, isNull);
    expect(state.averageTasksPerDay, 0);
    expect(state.averageFocusMinutesPerDay, 0);
  });

  test('calculates seven-day daily averages', () async {
    final taskId = await taskRepository.createTask(
      title: 'Average task',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    for (final day in [4, 5, 6, 10]) {
      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Average task',
        completedAt: DateTime(2099, 6, day, 9),
      );
    }

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 5, 10), durationMinutes: 20),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 8, 10), durationMinutes: 50),
    );

    final state = await waitForState(
      (state) => state.completedTotal == 4 && state.focusMinutes == 70,
    );

    expect(state.averageTasksPerDay, closeTo(4 / 7, 0.000001));

    expect(state.averageFocusMinutesPerDay, closeTo(10, 0.000001));
  });

  test('best day uses highest task count', () async {
    final taskId = await taskRepository.createTask(
      title: 'Best day task',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Best day task',
      completedAt: DateTime(2099, 6, 8, 8),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Best day task',
      completedAt: DateTime(2099, 6, 9, 8),
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Best day task',
      completedAt: DateTime(2099, 6, 9, 12),
    );

    final state = await waitForState((state) => state.completedTotal == 3);

    expect(state.bestDay?.date, DateTime(2099, 6, 9));

    expect(state.bestDay?.completedTasks, 2);
  });

  test('best day tie prefers the most recent day', () async {
    final taskId = await taskRepository.createTask(
      title: 'Tie task',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    for (final date in [
      DateTime(2099, 6, 8, 8),
      DateTime(2099, 6, 8, 9),
      DateTime(2099, 6, 10, 8),
      DateTime(2099, 6, 10, 9),
    ]) {
      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Tie task',
        completedAt: date,
      );
    }

    final state = await waitForState((state) => state.completedTotal == 4);

    expect(state.bestDay?.date, DateTime(2099, 6, 10));

    expect(state.bestDay?.completedTasks, 2);
  });

  test('calculates positive and negative week over week changes', () async {
    final taskId = await taskRepository.createTask(
      title: 'Week change',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    // Previous week = 4 tasks.
    for (var i = 0; i < 4; i++) {
      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Week change',
        completedAt: DateTime(2099, 6, 3, 8 + i),
      );
    }

    // Current week = 6 tasks.
    for (var i = 0; i < 6; i++) {
      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Week change',
        completedAt: DateTime(2099, 6, 9, 8 + i),
      );
    }

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 3, 10), durationMinutes: 60),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 9, 10), durationMinutes: 30),
    );

    final state = await waitForState(
      (state) => state.completedTotal == 10 && state.focusMinutes == 90,
    );

    expect(state.tasksWeekOverWeekPercent, closeTo(50, 0.000001));

    expect(state.focusWeekOverWeekPercent, closeTo(-50, 0.000001));
  });

  test('week over week change is null when previous value is zero', () async {
    final taskId = await taskRepository.createTask(
      title: 'No previous week',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'No previous week',
      completedAt: DateTime(2099, 6, 9, 8),
    );

    await focusRepository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 9, 9), durationMinutes: 25),
    );

    final state = await waitForState(
      (state) => state.completedTotal == 1 && state.focusMinutes == 25,
    );

    expect(state.tasksWeekOverWeekPercent, isNull);

    expect(state.focusWeekOverWeekPercent, isNull);
  });
  test('calendar statistics refresh when the local day changes', () async {
    await cubit.close();

    var clock = DateTime(2099, 6, 10, 23, 59);

    cubit = InsightsCubit(taskRepository, focusRepository, now: () => clock);

    final taskId = await taskRepository.createTask(
      title: 'Midnight task',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
    );

    await taskRepository.recordCompletion(
      taskId: taskId,
      taskTitle: 'Midnight task',
      completedAt: DateTime(2099, 6, 10, 20),
    );

    var state = await waitForState((state) => state.completedToday == 1);

    expect(state.completedToday, 1);
    expect(state.last7Days.last.date, DateTime(2099, 6, 10));

    clock = DateTime(2099, 6, 11, 0, 1);

    cubit.refreshForCurrentTime();

    state = await waitForState(
      (state) => state.last7Days.last.date == DateTime(2099, 6, 11),
    );

    expect(state.completedToday, 0);

    expect(state.last7Days.last.date, DateTime(2099, 6, 11));

    expect(state.last7Days[state.last7Days.length - 2].completedTasks, 1);
  });
  test(
    'week over week ignores later days from the previous full week',
    () async {
      final taskId = await taskRepository.createTask(
        title: 'Matched week task',
        priority: TaskPriority.none,
        workflowStatus: TaskWorkflowStatus.todo,
      );

      // The injected test clock is Wednesday 2099-06-10.
      // Comparable previous period is Monday 2099-06-01
      // through Wednesday 2099-06-03.

      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Matched week task',
        completedAt: DateTime(2099, 6, 2, 8),
      );

      // These still belong to the full previous week,
      // but are outside the comparable Mon-Wed range.
      for (var i = 0; i < 4; i++) {
        await taskRepository.recordCompletion(
          taskId: taskId,
          taskTitle: 'Matched week task',
          completedAt: DateTime(2099, 6, 5, 8 + i),
        );
      }

      // Current comparable period has two task completions.
      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Matched week task',
        completedAt: DateTime(2099, 6, 9, 8),
      );

      await taskRepository.recordCompletion(
        taskId: taskId,
        taskTitle: 'Matched week task',
        completedAt: DateTime(2099, 6, 10, 8),
      );

      await focusRepository.addSession(
        FocusSession(
          completedAt: DateTime(2099, 6, 2, 10),
          durationMinutes: 20,
        ),
      );

      // Visible in full Previous week Overview,
      // but excluded from the matched Mon-Wed comparison.
      await focusRepository.addSession(
        FocusSession(
          completedAt: DateTime(2099, 6, 6, 10),
          durationMinutes: 80,
        ),
      );

      await focusRepository.addSession(
        FocusSession(
          completedAt: DateTime(2099, 6, 9, 10),
          durationMinutes: 30,
        ),
      );

      final state = await waitForState(
        (state) => state.completedTotal == 7 && state.focusMinutes == 130,
      );

      // Overview still represents the complete previous week.
      expect(state.previousWeek.completedTasks, 5);

      expect(state.previousWeek.focusMinutes, 100);

      // Matched Mon-Wed comparison:
      // tasks: 1 -> 2 = +100%
      // focus: 20 -> 30 = +50%
      expect(state.tasksWeekOverWeekPercent, closeTo(100, 0.000001));

      expect(state.focusWeekOverWeekPercent, closeTo(50, 0.000001));
    },
  );
}
