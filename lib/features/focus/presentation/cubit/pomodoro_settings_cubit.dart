import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/data/app_preferences.dart';
import '../../domain/pomodoro_settings.dart';

class PomodoroSettingsCubit extends Cubit<PomodoroSettings> {
  PomodoroSettingsCubit(
    this._preferences, {
    required PomodoroSettings initialSettings,
  }) : super(initialSettings);

  final AppPreferences _preferences;

  Future<void> setFocusMinutes(int value) async {
    if (value < 1 || value > 720) {
      throw RangeError.range(value, 1, 720, 'focusMinutes');
    }

    await _save(state.copyWith(focusMinutes: value));
  }

  Future<void> setShortBreakMinutes(int value) async {
    if (value < 1 || value > 180) {
      throw RangeError.range(value, 1, 180, 'shortBreakMinutes');
    }

    await _save(state.copyWith(shortBreakMinutes: value));
  }

  Future<void> setLongBreakMinutes(int value) async {
    if (value < 1 || value > 180) {
      throw RangeError.range(value, 1, 180, 'longBreakMinutes');
    }

    await _save(state.copyWith(longBreakMinutes: value));
  }

  Future<void> setSessionsPerCycle(int value) async {
    if (value < 1 || value > 12) {
      throw RangeError.range(value, 1, 12, 'sessionsPerCycle');
    }

    await _save(state.copyWith(sessionsPerCycle: value));
  }

  Future<void> setAutoStartBreaks(bool value) {
    return _save(state.copyWith(autoStartBreaks: value));
  }

  Future<void> setAutoStartFocus(bool value) {
    return _save(state.copyWith(autoStartFocus: value));
  }

  Future<void> setCompletionSound(bool value) {
    return _save(state.copyWith(completionSound: value));
  }

  Future<void> setVibration(bool value) {
    return _save(state.copyWith(vibration: value));
  }

  Future<void> _save(PomodoroSettings next) async {
    await _preferences.writePomodoroSettings(next);

    emit(next);
  }
}
