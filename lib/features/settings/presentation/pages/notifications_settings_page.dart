import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../../data/app_preferences.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _taskReminderSound = true;
  bool _taskReminderVibration = true;
  bool _notificationPermissionAvailable = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = context.read<AppPreferences>();
      final notifications = context.read<NotificationService>();

      final results = await Future.wait<Object>([
        preferences.readNotificationsEnabled(),
        notifications.areNotificationsEnabled(),
        preferences.readTaskReminderSound(),
        preferences.readTaskReminderVibration(),
      ]);

      if (!mounted) {
        return;
      }

      final notificationPreference = results[0] as bool;
      final osNotificationPermission = results[1] as bool;
      final taskReminderSound = results[2] as bool;
      final taskReminderVibration = results[3] as bool;

      notifications.setAppEnabled(notificationPreference);
      notifications.setTaskReminderBehavior(
        playSound: taskReminderSound,
        enableVibration: taskReminderVibration,
      );

      setState(() {
        _notificationsEnabled =
            notificationPreference && osNotificationPermission;
        _notificationPermissionAvailable = osNotificationPermission;
        _taskReminderSound = taskReminderSound;
        _taskReminderVibration = taskReminderVibration;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsLoadFailure),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    final preferences = context.read<AppPreferences>();
    final service = context.read<NotificationService>();
    final tasksCubit = context.read<TasksCubit>();

    if (!enabled) {
      await preferences.writeNotificationsEnabled(false);

      service.setAppEnabled(false);

      await service.cancelAll();

      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
        });
      }

      return;
    }

    final granted = await service.requestPermission();

    final available = granted && await service.areNotificationsEnabled();

    await preferences.writeNotificationsEnabled(available);

    service.setAppEnabled(available);

    if (available) {
      await tasksCubit.rescheduleTaskReminders();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = available;
      _notificationPermissionAvailable = available;
    });

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).notificationPermissionDenied,
          ),
        ),
      );
    }
  }

  Future<void> _applyTaskReminderBehavior({
    required bool playSound,
    required bool enableVibration,
  }) async {
    final preferences = context.read<AppPreferences>();
    final notifications = context.read<NotificationService>();

    await Future.wait([
      preferences.writeTaskReminderSound(playSound),
      preferences.writeTaskReminderVibration(enableVibration),
    ]);

    notifications.setTaskReminderBehavior(
      playSound: playSound,
      enableVibration: enableVibration,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _taskReminderSound = playSound;
      _taskReminderVibration = enableVibration;
    });

    if (_notificationsEnabled) {
      await context.read<TasksCubit>().rescheduleTaskReminders();
    }
  }

  Future<void> _setTaskReminderSound(bool enabled) {
    return _applyTaskReminderBehavior(
      playSound: enabled,
      enableVibration: _taskReminderVibration,
    );
  }

  Future<void> _setTaskReminderVibration(bool enabled) {
    return _applyTaskReminderBehavior(
      playSound: _taskReminderSound,
      enableVibration: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.notificationSettings)),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SettingsSectionTitle(l.notifications),
                          const SizedBox(height: AppSpacing.xs),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.notifications_outlined),
                            title: Text(l.enableNotifications),
                            subtitle: !_notificationPermissionAvailable
                                ? Text(l.notificationPermissionDenied)
                                : null,
                            value: _notificationsEnabled,
                            onChanged: _setNotificationsEnabled,
                          ),
                          if (!_notificationPermissionAvailable)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.settings_outlined),
                              title: Text(l.openSystemSettings),
                              trailing: const Icon(Icons.open_in_new_rounded),
                              onTap: () {
                                context
                                    .read<NotificationService>()
                                    .openNotificationSettings();
                              },
                            ),
                          const SizedBox(height: AppSpacing.xl),
                          _SettingsSectionTitle(l.taskReminders),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l.taskRemindersDescription,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.volume_up_outlined),
                            title: Text(l.taskReminderSound),
                            subtitle: Text(l.taskReminderSoundDescription),
                            value: _taskReminderSound,
                            onChanged: _notificationsEnabled
                                ? _setTaskReminderSound
                                : null,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.vibration_rounded),
                            title: Text(l.taskReminderVibration),
                            subtitle: Text(l.taskReminderVibrationDescription),
                            value: _taskReminderVibration,
                            onChanged: _notificationsEnabled
                                ? _setTaskReminderVibration
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
