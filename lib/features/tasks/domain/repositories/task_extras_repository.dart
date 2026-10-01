import '../models/task_extras.dart';

abstract interface class TaskExtrasRepository {
  Future<TaskExtras> getExtras(int taskId);
  Future<void> saveExtras(int taskId, TaskExtras extras);
  Future<void> deleteExtras(int taskId);
}
