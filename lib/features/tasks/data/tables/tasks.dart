import 'package:drift/drift.dart';

@TableIndex(name: 'tasks_completed_due_at', columns: {#isCompleted, #dueAt})
@TableIndex(name: 'tasks_sort_order', columns: {#sortOrder})
@TableIndex(name: 'tasks_workflow_due_at', columns: {#workflowStatus, #dueAt})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 500)();

  TextColumn get description => text().nullable()();

  BoolColumn get isCompleted => boolean().clientDefault(() => false)();

  IntColumn get priority => integer()
      .check(const CustomExpression<bool>('priority BETWEEN 0 AND 3'))
      .clientDefault(() => 0)();

  IntColumn get workflowStatus => integer()
      .check(const CustomExpression<bool>('workflow_status BETWEEN 0 AND 2'))
      .withDefault(const Constant(0))();

  DateTimeColumn get dueAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get completedAt => dateTime().nullable()();

  IntColumn get sortOrder => integer().clientDefault(() => 0)();
}
