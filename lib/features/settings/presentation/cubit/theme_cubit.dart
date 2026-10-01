import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/theme_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences, {required ThemeMode initialThemeMode})
    : super(initialThemeMode);

  final ThemePreferencesStore _preferences;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (state == themeMode) {
      return;
    }

    emit(themeMode);

    await _preferences.writeThemeMode(themeMode);
  }
}
