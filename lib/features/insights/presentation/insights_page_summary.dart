part of 'insights_page.dart';

class _PrimaryProgressSection extends StatelessWidget {
  const _PrimaryProgressSection({
    required this.todayTasks,
    required this.todayFocusMinutes,
    required this.week,
  });

  final int todayTasks;
  final int todayFocusMinutes;
  final InsightsPeriodSummary week;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final today = _ProgressSummaryCard(
          title: l.progressToday,
          icon: Icons.today_rounded,
          tasks: todayTasks,
          focusMinutes: todayFocusMinutes,
          emphasized: true,
        );

        final thisWeek = _ProgressSummaryCard(
          title: l.thisWeek,
          icon: Icons.date_range_rounded,
          tasks: week.completedTasks,
          focusMinutes: week.focusMinutes,
        );

        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              today,
              const SizedBox(height: AppSpacing.sm),
              thisWeek,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: today),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: thisWeek),
          ],
        );
      },
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.title,
    required this.icon,
    required this.tasks,
    required this.focusMinutes,
    this.emphasized = false,
  });

  final String title;
  final IconData icon;
  final int tasks;
  final int focusMinutes;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final tasksText = l.tasksCompletedValue(tasks);

    final focusText = l.focusMinutesValue(focusMinutes);

    return Semantics(
      container: true,
      label: '$title. $tasksText. $focusText',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: emphasized
                ? colors.primaryContainer.withValues(alpha: 0.42)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: emphasized
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _LargeMetric(value: '$tasks', label: l.tasksChange),
              const SizedBox(height: AppSpacing.md),
              _LargeMetric(value: '$focusMinutes min', label: l.focusChange),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeMetric extends StatelessWidget {
  const _LargeMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: theme.textTheme.headlineMedium),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final value = l.streakDays(streak);

    return Semantics(
      container: true,
      label: '${l.progressConsistency}. $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(l.currentStreak, style: theme.textTheme.bodyLarge),
              ),
              Text(value, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.days});

  final List<InsightsDaySummary> days;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (days.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          l.noBestDayYet,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final maxTasks = math.max(
      1,
      days.map((day) => day.completedTasks).reduce(math.max),
    );

    final maxFocus = math.max(
      1,
      days.map((day) => day.focusMinutes).reduce(math.max),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LegendItem(
                icon: Icons.task_alt_rounded,
                label: l.tasksCompletedTrend,
              ),
              const SizedBox(width: AppSpacing.lg),
              _LegendItem(
                icon: Icons.timer_outlined,
                label: l.focusMinutesTrend,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final day in days)
                  Expanded(
                    child: _ActivityDay(
                      day: day,
                      maxTasks: maxTasks,
                      maxFocus: maxFocus,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 17, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityDay extends StatelessWidget {
  const _ActivityDay({
    required this.day,
    required this.maxTasks,
    required this.maxFocus,
  });

  final InsightsDaySummary day;
  final int maxTasks;
  final int maxFocus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final locale = Localizations.localeOf(context).toLanguageTag();

    final dayLabel = DateFormat.E(locale).format(day.date);

    final taskRatio = day.completedTasks / maxTasks;

    final focusRatio = day.focusMinutes / maxFocus;

    final semanticLabel =
        '$dayLabel. '
        '${l.tasksCompletedValue(day.completedTasks)}. '
        '${l.focusMinutesValue(day.focusMinutes)}.';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActivityBar(
                      ratio: taskRatio,
                      icon: Icons.task_alt_rounded,
                    ),
                    const SizedBox(width: 3),
                    _ActivityBar(ratio: focusRatio, icon: Icons.timer_outlined),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.ratio, required this.icon});

  final double ratio;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final normalized = ratio.clamp(0.0, 1.0);

          final height = normalized <= 0
              ? 2.0
              : math.max(6.0, constraints.maxHeight * normalized);

          final isTask = icon == Icons.task_alt_rounded;

          return Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: double.infinity,
              height: height,
              constraints: const BoxConstraints(maxWidth: 14),
              decoration: BoxDecoration(
                color: isTask ? colors.primary : colors.tertiaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
