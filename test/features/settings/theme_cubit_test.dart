import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/settings/data/theme_preferences.dart';
import 'package:perfica/features/settings/presentation/cubit/theme_cubit.dart';

class _FakeThemePreferences implements ThemePreferencesStore {
  ThemeMode storedMode = ThemeMode.system;

  int writeCount = 0;

  @override
  Future<ThemeMode> readThemeMode() async {
    return storedMode;
  }

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) async {
    writeCount++;

    storedMode = themeMode;
  }
}

void main() {
  late _FakeThemePreferences preferences;

  setUp(() {
    preferences = _FakeThemePreferences();
  });

  test('initial state uses provided theme mode', () async {
    final cubit = ThemeCubit(preferences, initialThemeMode: ThemeMode.dark);

    expect(cubit.state, ThemeMode.dark);

    expect(preferences.writeCount, 0);

    await cubit.close();
  });

  test('setting same theme mode does not persist again', () async {
    final cubit = ThemeCubit(preferences, initialThemeMode: ThemeMode.system);

    await cubit.setThemeMode(ThemeMode.system);

    expect(cubit.state, ThemeMode.system);

    expect(preferences.writeCount, 0);

    await cubit.close();
  });

  test('changing theme emits and persists new mode', () async {
    final cubit = ThemeCubit(preferences, initialThemeMode: ThemeMode.system);

    await cubit.setThemeMode(ThemeMode.dark);

    expect(cubit.state, ThemeMode.dark);

    expect(preferences.writeCount, 1);

    expect(preferences.storedMode, ThemeMode.dark);

    await cubit.close();
  });
}
