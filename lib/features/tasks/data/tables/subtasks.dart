import 'package:drift/drift.dart';

import 'tasks.dart';

@TableIndex(name: 'subtasks_task_sort_order', columns: {#taskId, #sortOrder})
class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  TextColumn get title => text().withLength(min: 1, max: 500)();

  BoolColumn get isCompleted => boolean().clientDefault(() => false)();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  IntColumn get sortOrder => integer().clientDefault(() => 0)();
}
