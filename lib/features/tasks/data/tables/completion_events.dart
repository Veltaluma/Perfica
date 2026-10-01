import 'package:drift/drift.dart';

@TableIndex(name: 'completion_events_completed_at', columns: {#completedAt})
@TableIndex(name: 'completion_events_task_id', columns: {#taskId})
class CompletionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get taskId => integer().nullable()();

  TextColumn get taskTitle => text().withLength(min: 1, max: 500)();

  DateTimeColumn get completedAt => dateTime()();
}
