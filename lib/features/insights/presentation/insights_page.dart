import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/widgets/settings_action_button.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import 'cubit/insights_cubit.dart';
import 'cubit/insights_state.dart';
part 'insights_page_summary.dart';
part 'insights_page_details.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.insightsTitle),
        actions: const [SettingsActionButton()],
      ),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          if (state.status == InsightsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == InsightsStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l.insightsLoadFailure, textAlign: TextAlign.center),
              ),
            );
          }

          return ProgressView(state: state);
        },
      ),
    );
  }
}

/// User-facing Progress presentation.
///
/// The existing InsightsCubit / InsightsState names intentionally remain
/// internal so the UI redesign does not create unnecessary domain churn.
class ProgressView extends StatelessWidget {
  const ProgressView({required this.state, super.key});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final todayFocusMinutes = state.last7Days.isEmpty
        ? 0
        : state.last7Days.last.focusMinutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PrimaryProgressSection(
                  todayTasks: state.completedToday,
                  todayFocusMinutes: todayFocusMinutes,
                  week: state.thisWeek,
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(l.progressConsistency),
                const SizedBox(height: AppSpacing.sm),
                _ConsistencyCard(streak: state.currentStreak),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(l.progressRecentActivity),
                const SizedBox(height: AppSpacing.sm),
                _ActivityCard(days: state.last7Days),
                const SizedBox(height: AppSpacing.xl),
                _MoreDetails(state: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
