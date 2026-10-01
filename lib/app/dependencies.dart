import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/database/app_database.dart';
import '../core/services/attachment_service.dart';
import '../core/services/backup_service.dart';
import '../core/services/data_backup_service.dart';
import '../core/services/diagnostic_recorder.dart';
import '../core/services/notification_service.dart';
import '../core/services/portable_backup_builder.dart';
import '../core/services/portable_backup_restorer.dart';
import '../core/services/update_service.dart';
import '../features/bug_report/data/bug_report_environment_service.dart';
import '../features/bug_report/data/bug_report_submission_service.dart';
import '../features/focus/data/focus_repository.dart';
import '../features/focus/presentation/cubit/focus_cubit.dart';
import '../features/focus/presentation/cubit/pomodoro_settings_cubit.dart';
import '../features/insights/presentation/cubit/insights_cubit.dart';
import '../features/settings/data/app_preferences.dart';
import '../features/settings/data/theme_preferences.dart';
import '../features/settings/presentation/cubit/theme_cubit.dart';
import '../features/tasks/data/repositories/drift_task_extras_repository.dart';
import '../features/tasks/application/services/task_widget_snapshot_service.dart';
import '../features/tasks/data/repositories/drift_task_repository.dart';
import '../features/tasks/domain/repositories/task_extras_repository.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import '../features/tasks/presentation/cubit/tasks_cubit.dart';
import '../l10n/app_localizations_en.dart';

Future<Widget> provideAppDependencies({
  required Widget child,
  DiagnosticRecorder? diagnosticRecorder,
}) async {
  final themePreferences = ThemePreferences();

  final appPreferences = AppPreferences();

  // Start independent preference reads together so startup I/O can overlap.
  final initialThemeModeFuture = themePreferences.readThemeMode();

  final notificationsEnabledFuture = appPreferences.readNotificationsEnabled();

  final taskReminderSoundFuture = appPreferences.readTaskReminderSound();

  final taskReminderVibrationFuture = appPreferences
      .readTaskReminderVibration();

  final pomodoroSettingsFuture = appPreferences.readPomodoroSettings();

  final focusRuntimeFuture = appPreferences.readFocusRuntimeSnapshot();

  final initialThemeMode = await initialThemeModeFuture;

  final notificationsEnabled = await notificationsEnabledFuture;

  final taskReminderSound = await taskReminderSoundFuture;

  final taskReminderVibration = await taskReminderVibrationFuture;

  final pomodoroSettings = await pomodoroSettingsFuture;

  final focusRuntime = await focusRuntimeFuture;

  final notifications = NotificationService();

  final notificationStrings = AppLocalizationsEn();

  notifications.setTaskActionLabels(
    done: notificationStrings.taskReminderDoneAction,
    snooze10Minutes: notificationStrings.taskReminderSnooze10Action,
  );

  notifications.setAppEnabled(notificationsEnabled);

  notifications.setTaskReminderBehavior(
    playSound: taskReminderSound,
    enableVibration: taskReminderVibration,
  );

  await notifications.initialize();

  return MultiProvider(
    providers: [
      if (diagnosticRecorder != null)
        Provider<DiagnosticRecorder>.value(value: diagnosticRecorder),
      Provider<ThemePreferences>.value(value: themePreferences),
      Provider<AppPreferences>.value(value: appPreferences),
      Provider<NotificationService>.value(value: notifications),
      Provider<AttachmentService>(create: (_) => AttachmentService()),
      Provider<AppDatabase>(
        create: (_) => AppDatabase(),
        dispose: (_, db) => db.close(),
      ),
      Provider<TaskRepository>(
        create: (context) => DriftTaskRepository(context.read<AppDatabase>()),
      ),
      Provider<TaskExtrasRepository>(
        create: (context) =>
            DriftTaskExtrasRepository(context.read<AppDatabase>()),
      ),
      Provider<TaskWidgetSnapshotService>(
        lazy: false,
        create: (context) => TaskWidgetSnapshotService(
          context.read<TaskRepository>(),
          context.read<TaskExtrasRepository>(),
        ),
        dispose: (_, service) => service.dispose(),
      ),
      Provider<FocusRepository>(
        create: (context) => FocusRepository(context.read<AppDatabase>()),
      ),
      Provider<DataBackupService>(
        create: (context) {
          final database = context.read<AppDatabase>();

          final attachments = context.read<AttachmentService>();

          final legacy = BackupService(database);

          final builder = PortableBackupBuilder(database, attachments);

          final restorer = PortableBackupRestorer(
            database,
            attachments,
            legacy,
          );

          return DataBackupService(legacy, builder, restorer);
        },
      ),
      Provider<BugReportEnvironmentService>(
        create: (_) => BugReportEnvironmentService(),
      ),
      Provider<BugReportSubmissionService>(
        create: (_) => BugReportSubmissionService(
          endpoint: Uri.parse(AppConstants.bugReportEndpoint),
        ),
        dispose: (_, service) => service.dispose(),
      ),
      Provider<UpdateService>(
        create: (_) => UpdateService(),
        dispose: (_, service) => service.dispose(),
      ),
      BlocProvider<ThemeCubit>(
        create: (_) =>
            ThemeCubit(themePreferences, initialThemeMode: initialThemeMode),
      ),
      BlocProvider<PomodoroSettingsCubit>(
        create: (_) => PomodoroSettingsCubit(
          appPreferences,
          initialSettings: pomodoroSettings,
        ),
      ),
      BlocProvider<FocusCubit>(
        lazy: false,
        create: (context) {
          final cubit = FocusCubit(
            context.read<FocusRepository>(),
            context.read<NotificationService>(),
            FocusNotificationMessages(
              focusCompleteTitle:
                  notificationStrings.pomodoroFocusNotificationTitle,
              focusCompleteBody:
                  notificationStrings.pomodoroFocusNotificationBody,
              breakCompleteTitle:
                  notificationStrings.pomodoroBreakNotificationTitle,
              breakCompleteBody:
                  notificationStrings.pomodoroBreakNotificationBody,
            ),
            initialSettings: pomodoroSettings,
            initialRuntime: focusRuntime,
            runtimePreferences: appPreferences,
          );

          unawaited(cubit.syncClock());

          return cubit;
        },
      ),
      BlocProvider<InsightsCubit>(
        create: (context) => InsightsCubit(
          context.read<TaskRepository>(),
          context.read<FocusRepository>(),
        ),
      ),
      BlocProvider<TasksCubit>(
        lazy: false,
        create: (context) {
          final cubit = TasksCubit(
            context.read<TaskRepository>(),
            context.read<TaskExtrasRepository>(),
            context.read<NotificationService>(),
            context.read<AttachmentService>(),
          );

          notifications.setTaskActionHandler((actionId, taskId) {
            return cubit.handleNotificationAction(
              actionId: actionId,
              taskId: taskId,
            );
          });

          return cubit;
        },
      ),
    ],
    child: child,
  );
}
