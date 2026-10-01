import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int focusTimerNotificationId = 900001;
  static const int focusImmediateNotificationId = 900002;

  static const String taskDoneActionId = 'task_done';
  static const String taskSnooze10ActionId = 'task_snooze_10';
  static const String taskActionsCategoryId = 'task_actions';

  String _taskDoneActionLabel = 'Done';
  String _taskSnooze10ActionLabel = 'Snooze 10m';

  Future<void> Function(String actionId, int taskId)? _taskActionHandler;

  final List<_PendingTaskAction> _pendingTaskActions = [];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _appEnabled = true;

  bool _taskReminderSound = true;

  bool _taskReminderVibration = true;

  bool get appEnabled => _appEnabled;

  bool get taskReminderSound => _taskReminderSound;

  bool get taskReminderVibration => _taskReminderVibration;

  void setAppEnabled(bool enabled) {
    _appEnabled = enabled;
  }

  void setTaskReminderBehavior({
    required bool playSound,
    required bool enableVibration,
  }) {
    _taskReminderSound = playSound;
    _taskReminderVibration = enableVibration;
  }

  void setTaskActionLabels({
    required String done,
    required String snooze10Minutes,
  }) {
    _taskDoneActionLabel = done;
    _taskSnooze10ActionLabel = snooze10Minutes;
  }

  void setTaskActionHandler(
    Future<void> Function(String actionId, int taskId) handler,
  ) {
    _taskActionHandler = handler;

    if (_pendingTaskActions.isEmpty) {
      return;
    }

    final pending = List<_PendingTaskAction>.of(_pendingTaskActions);

    _pendingTaskActions.clear();

    for (final action in pending) {
      unawaited(handler(action.actionId, action.taskId));
    }
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // UTC/default timezone remains available as a safe fallback.
    }

    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_stat_perfica'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              taskActionsCategoryId,
              actions: [
                DarwinNotificationAction.plain(
                  taskDoneActionId,
                  _taskDoneActionLabel,
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  taskSnooze10ActionId,
                  _taskSnooze10ActionLabel,
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;

      if (response != null) {
        _handleNotificationResponse(response);
      }
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.notificationResponseType !=
        NotificationResponseType.selectedNotificationAction) {
      return;
    }

    final actionId = response.actionId;

    if (actionId == null) {
      return;
    }

    if (actionId != taskDoneActionId && actionId != taskSnooze10ActionId) {
      return;
    }

    final payload = response.payload;

    if (payload == null || !payload.startsWith('task:')) {
      return;
    }

    final taskId = int.tryParse(payload.substring('task:'.length));

    if (taskId == null) {
      return;
    }

    final handler = _taskActionHandler;

    if (handler == null) {
      _pendingTaskActions.add(
        _PendingTaskAction(actionId: actionId, taskId: taskId),
      );

      return;
    }

    unawaited(handler(actionId, taskId));
  }

  Future<bool> requestPermission() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return android ?? ios ?? true;
  }

  Future<bool> requestExactAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) {
      return true;
    }

    final allowed = await android.canScheduleExactNotifications();

    if (allowed == true) {
      return true;
    }

    return await android.requestExactAlarmsPermission() ?? false;
  }

  Future<bool> areNotificationsEnabled() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();

    if (android != null) {
      return android;
    }

    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();

    return ios?.isEnabled ?? true;
  }

  Future<void> openNotificationSettings() {
    return _plugin.openAppNotificationSettings();
  }

  Future<void> cancelAll() {
    return _plugin.cancelAll();
  }

  static const int taskRepeatAlertCount = 5;

  Future<AndroidScheduleMode> _taskScheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final canScheduleExact = await android?.canScheduleExactNotifications();

    return canScheduleExact == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  int _taskRepeatNotificationId(int taskId, int index) {
    final normalizedTaskId = taskId.abs() % 100000000;

    return 1000000000 + (normalizedTaskId * 10) + index;
  }

  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {
    if (!_appEnabled || !when.isAfter(DateTime.now())) {
      return;
    }

    final scheduleMode = await _taskScheduleMode();

    await _plugin.zonedSchedule(
      id: taskId,
      title: 'Perfica',
      body: title,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _taskNotificationDetails(),
      androidScheduleMode: scheduleMode,
      payload: 'task:$taskId',
    );
  }

  Future<void> scheduleTaskSeries({
    required int taskId,
    required String title,
    required DateTime when,
    required int repeatIntervalMinutes,
  }) async {
    if (!_appEnabled || repeatIntervalMinutes <= 0) {
      return;
    }

    final scheduleMode = await _taskScheduleMode();
    final now = DateTime.now();

    for (var index = 0; index < taskRepeatAlertCount; index++) {
      final scheduledAt = when.add(
        Duration(minutes: repeatIntervalMinutes * index),
      );

      if (!scheduledAt.isAfter(now)) {
        continue;
      }

      final notificationId = index == 0
          ? taskId
          : _taskRepeatNotificationId(taskId, index);

      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Perfica',
        body: title,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: _taskNotificationDetails(),
        androidScheduleMode: scheduleMode,
        payload: 'task:$taskId',
      );
    }
  }

  NotificationDetails _taskNotificationDetails() {
    final soundPart = _taskReminderSound ? 'sound' : 'silent';

    final vibrationPart = _taskReminderVibration ? 'vibrate' : 'no_vibrate';

    final channelId =
        'task_reminders_v3_'
        '${soundPart}_$vibrationPart';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Task reminders',
        channelDescription: 'Reminders for Perfica tasks.',
        icon: 'ic_stat_perfica',
        importance: Importance.high,
        priority: Priority.high,
        playSound: _taskReminderSound,
        enableVibration: _taskReminderVibration,
        actions: [
          AndroidNotificationAction(
            taskDoneActionId,
            _taskDoneActionLabel,
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            taskSnooze10ActionId,
            _taskSnooze10ActionLabel,
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: _taskReminderSound,
        categoryIdentifier: taskActionsCategoryId,
      ),
    );
  }

  Future<void> scheduleFocusPhase({
    required DateTime when,
    required String title,
    required String body,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    if (!_appEnabled || !when.isAfter(DateTime.now())) {
      return;
    }

    await _plugin.cancel(id: focusTimerNotificationId);

    await _plugin.zonedSchedule(
      id: focusTimerNotificationId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _focusNotificationDetails(
        playSound: playSound,
        enableVibration: enableVibration,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'focus:scheduled-completion',
    );
  }

  Future<void> showFocusCompletion({
    required String title,
    required String body,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    if (!_appEnabled) {
      return;
    }

    await _plugin.show(
      id: focusImmediateNotificationId,
      title: title,
      body: body,
      notificationDetails: _focusNotificationDetails(
        playSound: playSound,
        enableVibration: enableVibration,
      ),
      payload: 'focus:immediate-completion',
    );
  }

  NotificationDetails _focusNotificationDetails({
    required bool playSound,
    required bool enableVibration,
  }) {
    final soundPart = playSound ? 'sound' : 'silent';

    final vibrationPart = enableVibration ? 'vibrate' : 'no_vibrate';

    final channelId =
        'focus_timer_v3_'
        '${soundPart}_$vibrationPart';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Focus timer',
        channelDescription: 'Pomodoro focus and break completion alerts.',
        icon: 'ic_stat_perfica',
        importance: Importance.max,
        priority: Priority.max,
        playSound: playSound,
        enableVibration: enableVibration,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: playSound,
      ),
    );
  }

  Future<void> cancelTask(int taskId) async {
    await _plugin.cancel(id: taskId);

    for (var index = 1; index < taskRepeatAlertCount; index++) {
      await _plugin.cancel(id: _taskRepeatNotificationId(taskId, index));
    }
  }

  Future<void> cancelFocusPhase() async {
    await _plugin.cancel(id: focusTimerNotificationId);

    await _plugin.cancel(id: focusImmediateNotificationId);
  }
}

class _PendingTaskAction {
  const _PendingTaskAction({required this.actionId, required this.taskId});

  final String actionId;
  final int taskId;
}
