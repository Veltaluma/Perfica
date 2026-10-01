import 'task.dart';
import 'task_extras.dart';

class TaskCompletionResult {
  const TaskCompletionResult({
    required this.taskBefore,
    required this.extrasBefore,
  });

  final Task taskBefore;
  final TaskExtras extrasBefore;

  bool get wasRecurring => extrasBefore.recurrence != null;
}
