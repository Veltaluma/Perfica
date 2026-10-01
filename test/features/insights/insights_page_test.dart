import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/insights/presentation/cubit/insights_state.dart';
import 'package:perfica/features/insights/presentation/insights_page.dart';
import 'package:perfica/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Progress presents daily and weekly activity before advanced details',
    (tester) async {
      final days = List<InsightsDaySummary>.generate(
        7,
        (index) => InsightsDaySummary(
          date: DateTime(2099, 6, 4 + index),
          completedTasks: index,
          focusMinutes: index * 10,
        ),
      );

      final state = InsightsState(
        status: InsightsStatus.success,
        completedToday: 6,
        completedTotal: 42,
        currentStreak: 5,
        focusMinutes: 420,
        last7Days: days,
        thisWeek: const InsightsPeriodSummary(
          completedTasks: 18,
          focusMinutes: 210,
        ),
        previousWeek: const InsightsPeriodSummary(
          completedTasks: 14,
          focusMinutes: 180,
        ),
        thisMonth: const InsightsPeriodSummary(
          completedTasks: 42,
          focusMinutes: 420,
        ),
        bestDay: days.last,
        averageTasksPerDay: 3,
        averageFocusMinutesPerDay: 30,
        tasksWeekOverWeekPercent: 28.6,
        focusWeekOverWeekPercent: 16.7,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ProgressView(state: state)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);

      expect(find.text('This week'), findsOneWidget);

      expect(find.text('Consistency'), findsOneWidget);

      expect(find.text('Recent activity'), findsOneWidget);

      expect(find.text('More details'), findsOneWidget);

      expect(find.text('5 days'), findsOneWidget);
    },
  );
}
