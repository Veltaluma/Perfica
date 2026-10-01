import 'package:drift/drift.dart';

import 'tasks.dart';

class TaskExtrasRows extends Table {
  @override
  String get tableName => 'task_extras';

  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  TextColumn get recurrence => text().nullable()();

  IntColumn get monthlyAnchorDay => integer().nullable()();

  DateTimeColumn get reminderAt => dateTime().nullable()();

  IntColumn get reminderRepeatMinutes => integer().nullable()();

  DateTimeColumn get reminderSnoozedUntil => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {taskId};
}
