import 'package:shared_preferences/shared_preferences.dart';

import '../../focus/data/focus_runtime_snapshot.dart';
import '../../focus/domain/pomodoro_phase.dart';
import '../../focus/domain/pomodoro_settings.dart';

class AppPreferences {
  AppPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _notificationsEnabledKey = 'notifications_enabled';

  static const _taskReminderSoundKey = 'task_reminder_sound';

  static const _taskReminderVibrationKey = 'task_reminder_vibration';

  static const _pomodoroFocusMinutesKey = 'pomodoro_focus_minutes';

  static const _pomodoroShortBreakMinutesKey = 'pomodoro_short_break_minutes';

  static const _pomodoroLongBreakMinutesKey = 'pomodoro_long_break_minutes';

  static const _pomodoroSessionsPerCycleKey = 'pomodoro_sessions_per_cycle';

  static const _pomodoroAutoStartBreaksKey = 'pomodoro_auto_start_breaks';

  static const _pomodoroAutoStartFocusKey = 'pomodoro_auto_start_focus';

  static const _pomodoroCompletionSoundKey = 'pomodoro_completion_sound';

  static const _pomodoroVibrationKey = 'pomodoro_vibration';

  static const _focusRuntimePhaseKey = 'focus_runtime_phase';
  static const _focusRuntimeCompletedInCycleKey =
      'focus_runtime_completed_in_cycle';
  static const _focusRuntimeRemainingSecondsKey =
      'focus_runtime_remaining_seconds';
  static const _focusRuntimeIsRunningKey = 'focus_runtime_is_running';
  static const _focusRuntimeBreakWasSkippedKey =
      'focus_runtime_break_was_skipped';
  static const _focusRuntimeEndsAtKey = 'focus_runtime_ends_at';

  final SharedPreferencesAsync _preferences;

  Future<bool> readNotificationsEnabled() async {
    return await _preferences.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> writeNotificationsEnabled(bool value) {
    return _preferences.setBool(_notificationsEnabledKey, value);
  }

  Future<bool> readTaskReminderSound() async {
    return await _preferences.getBool(_taskReminderSoundKey) ?? true;
  }

  Future<void> writeTaskReminderSound(bool value) {
    return _preferences.setBool(_taskReminderSoundKey, value);
  }

  Future<bool> readTaskReminderVibration() async {
    return await _preferences.getBool(_taskReminderVibrationKey) ?? true;
  }

  Future<void> writeTaskReminderVibration(bool value) {
    return _preferences.setBool(_taskReminderVibrationKey, value);
  }

  Future<PomodoroSettings> readPomodoroSettings() async {
    final defaults = PomodoroSettings.defaults;

    final focusMinutes =
        await _preferences.getInt(_pomodoroFocusMinutesKey) ??
        defaults.focusMinutes;

    final shortBreakMinutes =
        await _preferences.getInt(_pomodoroShortBreakMinutesKey) ??
        defaults.shortBreakMinutes;

    final longBreakMinutes =
        await _preferences.getInt(_pomodoroLongBreakMinutesKey) ??
        defaults.longBreakMinutes;

    final sessionsPerCycle =
        await _preferences.getInt(_pomodoroSessionsPerCycleKey) ??
        defaults.sessionsPerCycle;

    final autoStartBreaks =
        await _preferences.getBool(_pomodoroAutoStartBreaksKey) ??
        defaults.autoStartBreaks;

    final autoStartFocus =
        await _preferences.getBool(_pomodoroAutoStartFocusKey) ??
        defaults.autoStartFocus;

    final completionSound =
        await _preferences.getBool(_pomodoroCompletionSoundKey) ??
        defaults.completionSound;

    final vibration =
        await _preferences.getBool(_pomodoroVibrationKey) ?? defaults.vibration;

    return PomodoroSettings(
      focusMinutes: focusMinutes.clamp(1, 720),
      shortBreakMinutes: shortBreakMinutes.clamp(1, 180),
      longBreakMinutes: longBreakMinutes.clamp(1, 180),
      sessionsPerCycle: sessionsPerCycle.clamp(1, 12),
      autoStartBreaks: autoStartBreaks,
      autoStartFocus: autoStartFocus,
      completionSound: completionSound,
      vibration: vibration,
    );
  }

  Future<void> writePomodoroSettings(PomodoroSettings settings) async {
    await Future.wait([
      _preferences.setInt(_pomodoroFocusMinutesKey, settings.focusMinutes),
      _preferences.setInt(
        _pomodoroShortBreakMinutesKey,
        settings.shortBreakMinutes,
      ),
      _preferences.setInt(
        _pomodoroLongBreakMinutesKey,
        settings.longBreakMinutes,
      ),
      _preferences.setInt(
        _pomodoroSessionsPerCycleKey,
        settings.sessionsPerCycle,
      ),
      _preferences.setBool(
        _pomodoroAutoStartBreaksKey,
        settings.autoStartBreaks,
      ),
      _preferences.setBool(_pomodoroAutoStartFocusKey, settings.autoStartFocus),
      _preferences.setBool(
        _pomodoroCompletionSoundKey,
        settings.completionSound,
      ),
      _preferences.setBool(_pomodoroVibrationKey, settings.vibration),
    ]);
  }

  Future<FocusRuntimeSnapshot?> readFocusRuntimeSnapshot() async {
    final rawPhase = await _preferences.getString(_focusRuntimePhaseKey);

    if (rawPhase == null) {
      return null;
    }

    final phase = switch (rawPhase) {
      'focus' => PomodoroPhase.focus,
      'shortBreak' => PomodoroPhase.shortBreak,
      'longBreak' => PomodoroPhase.longBreak,
      _ => null,
    };

    if (phase == null) {
      return null;
    }

    final completedInCycle =
        await _preferences.getInt(_focusRuntimeCompletedInCycleKey) ?? 0;

    final remainingSeconds =
        await _preferences.getInt(_focusRuntimeRemainingSecondsKey) ?? 0;

    var isRunning =
        await _preferences.getBool(_focusRuntimeIsRunningKey) ?? false;

    final breakWasSkipped =
        await _preferences.getBool(_focusRuntimeBreakWasSkippedKey) ?? false;

    final rawEndsAt = await _preferences.getString(_focusRuntimeEndsAtKey);

    final endsAt = rawEndsAt == null ? null : DateTime.tryParse(rawEndsAt);

    if (isRunning && endsAt == null) {
      isRunning = false;
    }

    return FocusRuntimeSnapshot(
      phase: phase,
      completedInCycle: completedInCycle,
      remainingSeconds: remainingSeconds,
      isRunning: isRunning,
      breakWasSkipped: breakWasSkipped,
      endsAt: endsAt,
    );
  }

  Future<void> writeFocusRuntimeSnapshot(FocusRuntimeSnapshot snapshot) async {
    await Future.wait([
      _preferences.setString(_focusRuntimePhaseKey, snapshot.phase.name),
      _preferences.setInt(
        _focusRuntimeCompletedInCycleKey,
        snapshot.completedInCycle,
      ),
      _preferences.setInt(
        _focusRuntimeRemainingSecondsKey,
        snapshot.remainingSeconds,
      ),
      _preferences.setBool(_focusRuntimeIsRunningKey, snapshot.isRunning),
      _preferences.setBool(
        _focusRuntimeBreakWasSkippedKey,
        snapshot.breakWasSkipped,
      ),
      if (snapshot.endsAt == null)
        _preferences.remove(_focusRuntimeEndsAtKey)
      else
        _preferences.setString(
          _focusRuntimeEndsAtKey,
          snapshot.endsAt!.toIso8601String(),
        ),
    ]);
  }

  Future<void> clearFocusRuntimeSnapshot() async {
    await Future.wait([
      _preferences.remove(_focusRuntimePhaseKey),
      _preferences.remove(_focusRuntimeCompletedInCycleKey),
      _preferences.remove(_focusRuntimeRemainingSecondsKey),
      _preferences.remove(_focusRuntimeIsRunningKey),
      _preferences.remove(_focusRuntimeBreakWasSkippedKey),
      _preferences.remove(_focusRuntimeEndsAtKey),
    ]);
  }
}
