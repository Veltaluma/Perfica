import 'package:drift/drift.dart';

class FocusSessionRows extends Table {
  @override
  String get tableName => 'focus_sessions';

  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get completedAt => dateTime()();

  IntColumn get durationMinutes => integer()();
}
