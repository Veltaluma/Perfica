import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../../../settings/data/app_preferences.dart';
import '../../data/repositories/drift_task_extras_repository.dart';
import '../../data/repositories/drift_task_repository.dart';
import '../../domain/services/task_reminder_scheduler.dart';
import 'task_completion_service.dart';
import 'task_widget_snapshot_service.dart';

const _channel = MethodChannel('com.veltaluma.perfica/task_widget_background');

@pragma('vm:entry-point')
Future<void> taskWidgetBackgroundCallbackMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  var ok = false;

  try {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getArgs');

    if (raw == null) {
      throw StateError('Widget background arguments are unavailable.');
    }

    final taskId = (raw['taskId'] as num?)?.toInt();
    final completed = raw['completed'] as bool?;
    final filesDirectory = raw['filesDirectory'] as String?;

    if (taskId == null ||
        taskId <= 0 ||
        completed == null ||
        filesDirectory == null ||
        filesDirectory.isEmpty) {
      throw ArgumentError('Invalid widget background arguments.');
    }

    await _performTaskWidgetAction(
      taskId: taskId,
      completed: completed,
      filesDirectory: filesDirectory,
    );

    ok = true;
  } finally {
    try {
      await _channel.invokeMethod<void>('done', <String, dynamic>{'ok': ok});
    } catch (_) {
      // Native JobService/runner owns timeout and cleanup.
    }
  }
}

@pragma('vm:entry-point')
Future<void> taskWidgetBackgroundMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  var ok = false;

  try {
    if (args.length != 3) {
      throw ArgumentError(
        'Expected task id, completed flag, and app files directory.',
      );
    }

    await _performTaskWidgetAction(
      taskId: int.parse(args[0]),
      completed: args[1] == 'true',
      filesDirectory: args[2],
    );

    ok = true;
  } finally {
    try {
      await _channel.invokeMethod<void>('done', <String, dynamic>{'ok': ok});
    } catch (_) {
      // Compatibility entrypoint is not used by the rebuilt native runner.
    }
  }
}

Future<void> _performTaskWidgetAction({
  required int taskId,
  required bool completed,
  required String filesDirectory,
}) async {
  AppDatabase? database;

  try {
    final preferences = AppPreferences();

    final notifications = NotificationService()
      ..setAppEnabled(await preferences.readNotificationsEnabled())
      ..setTaskReminderBehavior(
        playSound: await preferences.readTaskReminderSound(),
        enableVibration: await preferences.readTaskReminderVibration(),
      );

    await notifications.initialize();

    database = AppDatabase();

    final repository = DriftTaskRepository(database);
    final extrasRepository = DriftTaskExtrasRepository(database);
    final reminderScheduler = TaskReminderScheduler(notifications);

    final completionService = TaskCompletionService(
      repository,
      extrasRepository,
      notifications,
      reminderScheduler,
    );

    await completionService.setCompleted(id: taskId, completed: completed);

    await TaskWidgetSnapshotService.publishRepository(
      repository,
      extrasRepository: extrasRepository,
      directoryPath: filesDirectory,
    );
  } finally {
    await database?.close();
  }
}
