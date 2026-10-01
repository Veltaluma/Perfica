import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/theme/app_theme.dart';
import '../../../../core/services/attachment_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../settings/data/app_preferences.dart';
import '../../../settings/data/theme_preferences.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import '../../data/repositories/drift_task_extras_repository.dart';
import '../../data/repositories/drift_task_repository.dart';
import '../../domain/repositories/task_extras_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../presentation/cubit/tasks_cubit.dart';
import '../../presentation/pages/task_editor_page.dart';
import 'task_widget_snapshot_service.dart';

const _channel = MethodChannel('com.veltaluma.perfica/widget_task_editor');

@pragma('vm:entry-point')
Future<void> taskWidgetEditorCallbackMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const _WidgetEditorLoadingApp());

  int? taskId;

  try {
    taskId = await _channel.invokeMethod<int?>('getTaskId');
  } on MissingPluginException {
    taskId = null;
  } on PlatformException {
    taskId = null;
  }

  await _runWidgetEditor(taskId);
}

@pragma('vm:entry-point')
Future<void> taskWidgetEditorMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const _WidgetEditorLoadingApp());

  final rawTaskId = args.isEmpty ? 'new' : args.first;
  final taskId = rawTaskId == 'new' ? null : int.tryParse(rawTaskId);

  await _runWidgetEditor(taskId);
}

Future<void> _runWidgetEditor(int? taskId) async {
  try {
    final app = await _buildWidgetEditorDependencies(taskId: taskId);
    runApp(app);
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Perfica task home-screen widget editor',
      ),
    );

    runApp(const _WidgetEditorFailureApp());
  }
}

Future<Widget> _buildWidgetEditorDependencies({required int? taskId}) async {
  final themePreferences = ThemePreferences();
  final appPreferences = AppPreferences();

  final initialThemeModeFuture = themePreferences.readThemeMode();
  final notificationsEnabledFuture = appPreferences.readNotificationsEnabled();
  final reminderSoundFuture = appPreferences.readTaskReminderSound();
  final reminderVibrationFuture = appPreferences.readTaskReminderVibration();

  final initialThemeMode = await initialThemeModeFuture;
  final notificationsEnabled = await notificationsEnabledFuture;
  final reminderSound = await reminderSoundFuture;
  final reminderVibration = await reminderVibrationFuture;

  final notifications = NotificationService();
  final notificationStrings = AppLocalizationsEn();

  notifications.setTaskActionLabels(
    done: notificationStrings.taskReminderDoneAction,
    snooze10Minutes: notificationStrings.taskReminderSnooze10Action,
  );

  notifications.setAppEnabled(notificationsEnabled);
  notifications.setTaskReminderBehavior(
    playSound: reminderSound,
    enableVibration: reminderVibration,
  );

  await notifications.initialize();

  return MultiProvider(
    providers: [
      Provider<NotificationService>.value(value: notifications),
      Provider<AttachmentService>(create: (_) => AttachmentService()),
      Provider<AppDatabase>(
        create: (_) => AppDatabase(),
        dispose: (_, database) => database.close(),
      ),
      Provider<TaskRepository>(
        create: (context) => DriftTaskRepository(context.read<AppDatabase>()),
      ),
      Provider<TaskExtrasRepository>(
        create: (context) =>
            DriftTaskExtrasRepository(context.read<AppDatabase>()),
      ),
      BlocProvider<ThemeCubit>(
        create: (_) =>
            ThemeCubit(themePreferences, initialThemeMode: initialThemeMode),
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
    child: _WidgetTaskEditorApp(taskId: taskId),
  );
}

class _WidgetEditorLoadingApp extends StatelessWidget {
  const _WidgetEditorLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _WidgetEditorFailureApp extends StatelessWidget {
  const _WidgetEditorFailureApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to open the task editor. Return to the home screen and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WidgetTaskEditorApp extends StatelessWidget {
  const _WidgetTaskEditorApp({required this.taskId});

  final int? taskId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _WidgetTaskEditorHost(taskId: taskId),
        );
      },
    );
  }
}

class _WidgetTaskEditorHost extends StatefulWidget {
  const _WidgetTaskEditorHost({required this.taskId});

  final int? taskId;

  @override
  State<_WidgetTaskEditorHost> createState() => _WidgetTaskEditorHostState();
}

class _WidgetTaskEditorHostState extends State<_WidgetTaskEditorHost> {
  bool _opened = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openEditor();
    });
  }

  Future<void> _openEditor() async {
    if (_opened || !mounted) {
      return;
    }

    _opened = true;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskEditorPage(taskId: widget.taskId),
      ),
    );

    if (!mounted || _finishing) {
      return;
    }

    _finishing = true;

    try {
      await TaskWidgetSnapshotService.publishRepository(
        context.read<TaskRepository>(),
        extrasRepository: context.read<TaskExtrasRepository>(),
      );
    } catch (_) {
      // Task persistence is authoritative. Native refresh below can still
      // display the latest valid snapshot if publication already succeeded.
    }

    try {
      await _channel.invokeMethod<void>('refresh');
    } on MissingPluginException {
      // Activity teardown below remains the final fallback.
    } on PlatformException {
      // Activity teardown below remains the final fallback.
    }

    try {
      await _channel.invokeMethod<void>('finish');
    } on PlatformException {
      await SystemNavigator.pop(animated: true);
    } on MissingPluginException {
      await SystemNavigator.pop(animated: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
