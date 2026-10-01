import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/features/tasks/domain/services/task_recurrence_calculator.dart';

void main() {
  group('TaskRecurrenceCalculator.next', () {
    test('daily advances one day', () {
      final base = DateTime(2099, 5, 10, 14, 25, 30);

      final result = TaskRecurrenceCalculator.next(
        base: base,
        recurrence: 'daily',
      );

      expect(result, DateTime(2099, 5, 11, 14, 25, 30));
    });

    test('weekly advances seven days', () {
      final base = DateTime(2099, 5, 10, 14, 25);

      final result = TaskRecurrenceCalculator.next(
        base: base,
        recurrence: 'weekly',
      );

      expect(result, DateTime(2099, 5, 17, 14, 25));
    });

    test('monthly clamps day for shorter month', () {
      final result = TaskRecurrenceCalculator.next(
        base: DateTime(2099, 1, 31, 9),
        recurrence: 'monthly',
        monthlyAnchorDay: 31,
      );

      expect(result, DateTime(2099, 2, 28, 9));
    });

    test('monthly anchor restores original day', () {
      final result = TaskRecurrenceCalculator.next(
        base: DateTime(2099, 2, 28, 9),
        recurrence: 'monthly',
        monthlyAnchorDay: 31,
      );

      expect(result, DateTime(2099, 3, 31, 9));
    });

    test('December rolls into next year', () {
      final result = TaskRecurrenceCalculator.next(
        base: DateTime(2099, 12, 31, 23, 30),
        recurrence: 'monthly',
        monthlyAnchorDay: 31,
      );

      expect(result, DateTime(2100, 1, 31, 23, 30));
    });

    test('unknown recurrence preserves base', () {
      final base = DateTime(2099, 5, 10, 8);

      final result = TaskRecurrenceCalculator.next(
        base: base,
        recurrence: 'unexpected',
      );

      expect(result, base);
    });
  });

  group('TaskRecurrenceCalculator.nextAfter', () {
    test('daily skips overdue occurrences', () {
      final result = TaskRecurrenceCalculator.nextAfter(
        base: DateTime(2099, 1, 1, 9),
        recurrence: 'daily',
        now: DateTime(2099, 1, 4, 12),
      );

      expect(result, DateTime(2099, 1, 5, 9));
    });

    test('weekly skips overdue occurrences', () {
      final result = TaskRecurrenceCalculator.nextAfter(
        base: DateTime(2099, 1, 1, 9),
        recurrence: 'weekly',
        now: DateTime(2099, 1, 20, 12),
      );

      expect(result, DateTime(2099, 1, 22, 9));
    });

    test('monthly skip preserves anchor', () {
      final result = TaskRecurrenceCalculator.nextAfter(
        base: DateTime(2099, 1, 31, 9),
        recurrence: 'monthly',
        now: DateTime(2099, 3, 15),
        monthlyAnchorDay: 31,
      );

      expect(result, DateTime(2099, 3, 31, 9));
    });

    test('invalid recurrence terminates safely', () {
      final base = DateTime(2099, 1, 1, 9);

      final result = TaskRecurrenceCalculator.nextAfter(
        base: base,
        recurrence: 'invalid',
        now: DateTime(2099, 5, 1),
      );

      expect(result, base);
    });
  });
}
