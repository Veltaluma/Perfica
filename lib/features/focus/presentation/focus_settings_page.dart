import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pomodoro_settings.dart';
import 'cubit/pomodoro_settings_cubit.dart';

part 'focus_settings_page_sections.dart';

class FocusSettingsPage extends StatelessWidget {
  const FocusSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<PomodoroSettingsCubit>().state;

    return Scaffold(
      appBar: AppBar(title: Text(l.focusSettingsTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.pomodoroSettingsDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _FocusSettingsSectionTitle(l.focusSettingsDurations),
                    const SizedBox(height: AppSpacing.xs),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(l.pomodoroFocusDuration),
                      trailing: _ValueDisclosure(
                        value: _minutesLabel(l, settings.focusMinutes),
                      ),
                      onTap: () {
                        _editFocusDuration(context, settings);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.coffee_outlined),
                      title: Text(l.pomodoroShortBreakDuration),
                      trailing: _ValueDisclosure(
                        value: _minutesLabel(l, settings.shortBreakMinutes),
                      ),
                      onTap: () {
                        _editShortBreak(context, settings);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.self_improvement_outlined),
                      title: Text(l.pomodoroLongBreakDuration),
                      trailing: _ValueDisclosure(
                        value: _minutesLabel(l, settings.longBreakMinutes),
                      ),
                      onTap: () {
                        _editLongBreak(context, settings);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.repeat_rounded),
                      title: Text(l.pomodoroSessionsPerCycle),
                      trailing: _ValueDisclosure(
                        value: l.pomodoroSessionsLabel(
                          settings.sessionsPerCycle,
                        ),
                      ),
                      onTap: () {
                        _editSessionsPerCycle(context, settings);
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _FocusSettingsSectionTitle(l.focusSettingsAutomation),
                    const SizedBox(height: AppSpacing.xs),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fast_forward_rounded),
                      title: Text(l.pomodoroAutoStartBreaks),
                      value: settings.autoStartBreaks,
                      onChanged: (value) {
                        context
                            .read<PomodoroSettingsCubit>()
                            .setAutoStartBreaks(value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.play_circle_outline_rounded),
                      title: Text(l.pomodoroAutoStartFocus),
                      value: settings.autoStartFocus,
                      onChanged: (value) {
                        context.read<PomodoroSettingsCubit>().setAutoStartFocus(
                          value,
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _FocusSettingsSectionTitle(l.focusSettingsFeedback),
                    const SizedBox(height: AppSpacing.xs),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.volume_up_outlined),
                      title: Text(l.pomodoroCompletionSound),
                      value: settings.completionSound,
                      onChanged: (value) {
                        context
                            .read<PomodoroSettingsCubit>()
                            .setCompletionSound(value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.vibration_rounded),
                      title: Text(l.pomodoroVibration),
                      value: settings.vibration,
                      onChanged: (value) {
                        context.read<PomodoroSettingsCubit>().setVibration(
                          value,
                        );
                      },
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

class _FocusSettingsSectionTitle extends StatelessWidget {
  const _FocusSettingsSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ValueDisclosure extends StatelessWidget {
  const _ValueDisclosure({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
      ],
    );
  }
}
