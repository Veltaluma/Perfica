part of 'focus_page.dart';

class _FocusTimerBody extends StatelessWidget {
  const _FocusTimerBody({required this.onCustomDuration});

  final Future<void> Function(BuildContext context, int currentMinutes)
  onCustomDuration;

  String _phaseTitle(AppLocalizations l, PomodoroPhase phase) {
    return switch (phase) {
      PomodoroPhase.focus => l.pomodoroFocus,
      PomodoroPhase.shortBreak => l.pomodoroShortBreak,
      PomodoroPhase.longBreak => l.pomodoroLongBreak,
    };
  }

  String _statusLabel(AppLocalizations l, FocusState state) {
    if (state.isRunning) {
      return l.pomodoroRunning;
    }

    if (state.remainingSeconds < state.phaseTotalSeconds) {
      return l.pomodoroPaused;
    }

    return l.pomodoroReady;
  }

  String _primaryActionLabel(AppLocalizations l, FocusState state) {
    if (state.isRunning) {
      return l.focusPause;
    }

    if (state.remainingSeconds < state.phaseTotalSeconds) {
      return l.focusResume;
    }

    return l.focusStart;
  }

  String _durationLabel(AppLocalizations l, int minutes) {
    if (minutes == 1) {
      return '1 ${l.minuteLabel}';
    }

    return '$minutes ${l.minutesLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return BlocBuilder<FocusCubit, FocusState>(
      builder: (context, state) {
        final minutes = state.remainingSeconds ~/ 60;
        final seconds = state.remainingSeconds % 60;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              120,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Text(
                    l.pomodoroTechnique,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _phaseTitle(l, state.phase),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.phase == PomodoroPhase.focus)
                    Text(
                      l.pomodoroSession(
                        state.currentSession,
                        state.sessionsPerCycle,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else if (state.phase == PomodoroPhase.shortBreak)
                    Text(
                      state.breakWasSkipped
                          ? l.pomodoroFocusSkipped
                          : l.pomodoroBreakAfterSession(
                              state.completedInCycle,
                              state.sessionsPerCycle,
                            ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: AppSpacing.md),
                  _CycleIndicator(
                    completed: state.completedInCycle,
                    total: state.sessionsPerCycle,
                    phase: state.phase,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox.square(
                    dimension: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: state.progress,
                            strokeWidth: 10,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$minutes:'
                              '${seconds.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _statusLabel(l, state),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (state.phase == PomodoroPhase.focus) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final preset in const [25, 50, 90])
                          ChoiceChip(
                            label: Text('$preset min'),
                            selected: state.focusMinutes == preset,
                            onSelected: state.isRunning
                                ? null
                                : (_) async {
                                    await context
                                        .read<PomodoroSettingsCubit>()
                                        .setFocusMinutes(preset);
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(_durationLabel(l, state.focusMinutes)),
                      onPressed: state.isRunning
                          ? null
                          : () {
                              onCustomDuration(context, state.focusMinutes);
                            },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          context.read<FocusCubit>().toggle();
                        },
                        icon: Icon(
                          state.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(_primaryActionLabel(l, state)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<FocusCubit>().skipPhase();
                        },
                        icon: const Icon(Icons.skip_next_rounded),
                        label: Text(l.pomodoroSkipPhase),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () {
                      context.read<FocusCubit>().resetCycle();
                    },
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l.pomodoroResetCycle),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CycleIndicator extends StatelessWidget {
  const _CycleIndicator({
    required this.completed,
    required this.total,
    required this.phase,
  });

  final int completed;
  final int total;
  final PomodoroPhase phase;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final done = index < completed;

        final current =
            phase == PomodoroPhase.focus &&
            index == completed.clamp(0, total - 1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: current ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: done
                  ? colors.primary
                  : current
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
