import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/settings_action_button.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/focus_duration_validator.dart';
import '../domain/pomodoro_phase.dart';
import '../domain/pomodoro_settings.dart';
import 'cubit/focus_cubit.dart';
import 'cubit/focus_state.dart';
import 'cubit/pomodoro_settings_cubit.dart';
import 'focus_settings_page.dart';

part 'focus_page_sections.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PomodoroSettingsCubit, PomodoroSettings>(
      listener: (context, settings) {
        context.read<FocusCubit>().applySettings(settings);
      },
      child: const _FocusView(),
    );
  }
}

class _FocusView extends StatefulWidget {
  const _FocusView();

  @override
  State<_FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<_FocusView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FocusCubit>().syncClock();
    }
  }

  String _validationMessage(AppLocalizations l, FocusDurationError error) {
    return switch (error) {
      FocusDurationError.invalid => l.focusDurationInvalid,
      FocusDurationError.tooShort => l.focusDurationTooShort,
      FocusDurationError.tooLong => l.focusDurationTooLong,
    };
  }

  Future<void> _showCustomDurationDialog(
    BuildContext context,
    int currentMinutes,
  ) async {
    var rawValue = '$currentMinutes';

    String? errorText;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final l = AppLocalizations.of(context);

            void submit() {
              final error = FocusDurationValidator.validate(rawValue);

              if (error != null) {
                setDialogState(() {
                  errorText = _validationMessage(l, error);
                });

                return;
              }

              Navigator.of(dialogContext)
                  .pop(FocusDurationValidator.parse(rawValue));
            }

            return AlertDialog(
              title: Text(l.customFocusDuration),
              content: TextFormField(
                initialValue: rawValue,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  helperText: l.focusDurationRange,
                  errorText: errorText,
                  suffixText: l.minutesLabel,
                ),
                onChanged: (value) {
                  rawValue = value;

                  if (errorText != null) {
                    setDialogState(() {
                      errorText = null;
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

    if (result != null && context.mounted) {
      await context.read<PomodoroSettingsCubit>().setFocusMinutes(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.focusTitle),
        actions: [
          IconButton(
            tooltip: l.focusSettingsTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<PomodoroSettingsCubit>(),
                    child: const FocusSettingsPage(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          const SettingsActionButton(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _FocusTimerBody(onCustomDuration: _showCustomDurationDialog),
      ),
    );
  }
}
