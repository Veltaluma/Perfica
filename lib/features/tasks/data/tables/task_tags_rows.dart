import 'package:drift/drift.dart';

import 'tasks.dart';

class TaskTagsRows extends Table {
  @override
  String get tableName => 'task_tags';

  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  IntColumn get position => integer()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {taskId, position};
}
