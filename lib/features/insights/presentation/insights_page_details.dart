part of 'insights_page.dart';

class _MoreDetails extends StatelessWidget {
  const _MoreDetails({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final formatter = NumberFormat('0.#', locale);

    final bestDay = state.bestDay;

    final bestDayValue = bestDay == null
        ? l.noBestDayYet
        : l.bestDayValue(
            DateFormat.E(locale).format(bestDay.date),
            bestDay.completedTasks,
          );

    final averageValue = l.dailyAverageValue(
      formatter.format(state.averageTasksPerDay),
      formatter.format(state.averageFocusMinutesPerDay),
    );

    final tasksChange = _formatPercent(
      state.tasksWeekOverWeekPercent,
      formatter,
    );

    final focusChange = _formatPercent(
      state.focusWeekOverWeekPercent,
      formatter,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(l.progressMoreDetails),
        leading: const Icon(Icons.tune_rounded),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          _DetailPeriod(title: l.thisMonth, summary: state.thisMonth),
          const Divider(),
          _DetailPeriod(title: l.previousWeek, summary: state.previousWeek),
          const Divider(),
          _DetailTextRow(title: l.bestDay, value: bestDayValue),
          const Divider(),
          _DetailTextRow(title: l.dailyAverage, value: averageValue),
          const Divider(),
          _WeekChangeDetails(
            tasksChange: tasksChange,
            focusChange: focusChange,
          ),
          const Divider(),
          _DetailTextRow(
            title: l.progressLifetime,
            value: l.tasksCompletedValue(state.completedTotal),
          ),
          const Divider(),
          _DetailTextRow(
            title: l.focusTime,
            value: l.focusTimeMinutes(state.focusMinutes),
          ),
        ],
      ),
    );
  }

  String? _formatPercent(double? value, NumberFormat formatter) {
    if (value == null) {
      return null;
    }

    final prefix = value > 0 ? '+' : '';

    return '$prefix'
        '${formatter.format(value)}%';
  }
}

class _DetailPeriod extends StatelessWidget {
  const _DetailPeriod({required this.title, required this.summary});

  final String title;
  final InsightsPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Semantics(
      container: true,
      label:
          '$title. '
          '${l.tasksCompletedValue(summary.completedTasks)}. '
          '${l.focusMinutesValue(summary.focusMinutes)}.',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text('${summary.completedTasks} tasks'),
              const SizedBox(width: AppSpacing.md),
              Text('${summary.focusMinutes} min'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTextRow extends StatelessWidget {
  const _DetailTextRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: '$title. $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekChangeDetails extends StatelessWidget {
  const _WeekChangeDetails({
    required this.tasksChange,
    required this.focusChange,
  });

  final String? tasksChange;
  final String? focusChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final tasksValue = tasksChange ?? l.noPreviousWeekData;

    final focusValue = focusChange ?? l.noPreviousWeekData;

    return Semantics(
      container: true,
      label:
          '${l.weekOverWeek}. '
          '${l.tasksChange}: $tasksValue. '
          '${l.focusChange}: $focusValue.',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.weekOverWeek,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _MiniValueRow(label: l.tasksChange, value: tasksValue),
              _MiniValueRow(label: l.focusChange, value: focusValue),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniValueRow extends StatelessWidget {
  const _MiniValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
