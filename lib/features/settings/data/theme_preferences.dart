import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemePreferencesStore {
  Future<ThemeMode> readThemeMode();

  Future<void> writeThemeMode(ThemeMode themeMode);
}

class ThemePreferences implements ThemePreferencesStore {
  ThemePreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _themeModeKey = 'theme_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ThemeMode> readThemeMode() async {
    final String? storedValue = await _preferences.getString(_themeModeKey);

    return switch (storedValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) async {
    await _preferences.setString(_themeModeKey, themeMode.name);
  }
}
