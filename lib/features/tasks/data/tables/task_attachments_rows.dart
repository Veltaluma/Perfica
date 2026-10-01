import 'package:drift/drift.dart';

import 'tasks.dart';

class TaskAttachmentsRows extends Table {
  @override
  String get tableName => 'task_attachments';

  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  IntColumn get position => integer()();

  TextColumn get path => text()();

  @override
  Set<Column<Object>> get primaryKey => {taskId, position};
}
