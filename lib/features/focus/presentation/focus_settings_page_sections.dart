part of 'focus_settings_page.dart';

String _minutesLabel(AppLocalizations l, int value) {
  if (value == 1) {
    return '1 ${l.minuteLabel}';
  }

  return '$value ${l.minutesLabel}';
}

Future<int?> _showNumberDialog(
  BuildContext context, {
  required String title,
  required int initialValue,
  required int min,
  required int max,
  required String helperText,
}) {
  var raw = '$initialValue';
  String? error;

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final l = AppLocalizations.of(context);

          void submit() {
            final parsed = int.tryParse(raw.trim());

            if (parsed == null || parsed < min || parsed > max) {
              setDialogState(() {
                error = l.pomodoroInvalidValue;
              });
              return;
            }

            Navigator.of(dialogContext).pop(parsed);
          }

          return AlertDialog(
            title: Text(title),
            content: TextFormField(
              initialValue: raw,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                helperText: helperText,
                errorText: error,
              ),
              onChanged: (value) {
                raw = value;

                if (error != null) {
                  setDialogState(() {
                    error = null;
                  });
                }
              },
              onFieldSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(l.cancel),
              ),
              FilledButton(onPressed: submit, child: Text(l.apply)),
            ],
          );
        },
      );
    },
  );
}

Future<void> _editFocusDuration(
  BuildContext context,
  PomodoroSettings settings,
) async {
  final l = AppLocalizations.of(context);

  final value = await _showNumberDialog(
    context,
    title: l.pomodoroFocusDuration,
    initialValue: settings.focusMinutes,
    min: 1,
    max: 720,
    helperText: l.pomodoroMinutesRange,
  );

  if (value != null && context.mounted) {
    await context.read<PomodoroSettingsCubit>().setFocusMinutes(value);
  }
}

Future<void> _editShortBreak(
  BuildContext context,
  PomodoroSettings settings,
) async {
  final l = AppLocalizations.of(context);

  final value = await _showNumberDialog(
    context,
    title: l.pomodoroShortBreakDuration,
    initialValue: settings.shortBreakMinutes,
    min: 1,
    max: 180,
    helperText: l.pomodoroBreakMinutesRange,
  );

  if (value != null && context.mounted) {
    await context.read<PomodoroSettingsCubit>().setShortBreakMinutes(value);
  }
}

Future<void> _editLongBreak(
  BuildContext context,
  PomodoroSettings settings,
) async {
  final l = AppLocalizations.of(context);

  final value = await _showNumberDialog(
    context,
    title: l.pomodoroLongBreakDuration,
    initialValue: settings.longBreakMinutes,
    min: 1,
    max: 180,
    helperText: l.pomodoroBreakMinutesRange,
  );

  if (value != null && context.mounted) {
    await context.read<PomodoroSettingsCubit>().setLongBreakMinutes(value);
  }
}

Future<void> _editSessionsPerCycle(
  BuildContext context,
  PomodoroSettings settings,
) async {
  final l = AppLocalizations.of(context);

  final value = await _showNumberDialog(
    context,
    title: l.pomodoroSessionsPerCycle,
    initialValue: settings.sessionsPerCycle,
    min: 1,
    max: 12,
    helperText: l.pomodoroSessionsRange,
  );

  if (value != null && context.mounted) {
    await context.read<PomodoroSettingsCubit>().setSessionsPerCycle(value);
  }
}
