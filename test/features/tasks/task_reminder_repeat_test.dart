import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_extras_repository.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_extras.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository taskRepository;
  late DriftTaskExtrasRepository extrasRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    taskRepository = DriftTaskRepository(database);

    extrasRepository = DriftTaskExtrasRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createTask(String title) {
    return taskRepository.createTask(title: title);
  }

  test('persists reminder repeat interval', () async {
    final taskId = await createTask('Repeating reminder');

    final reminderAt = DateTime(2099, 6, 10, 8, 30);

    await extrasRepository.saveExtras(
      taskId,
      TaskExtras(
        recurrence: 'weekly',
        reminderAt: reminderAt,
        reminderRepeatMinutes: 10,
        tags: const ['work'],
      ),
    );

    final restored = await extrasRepository.getExtras(taskId);

    expect(restored.recurrence, 'weekly');

    expect(restored.reminderAt, reminderAt);

    expect(restored.reminderRepeatMinutes, 10);

    expect(restored.tags, const ['work']);
  });

  test('one-time reminder remains the backward-compatible default', () async {
    final taskId = await createTask('One-time reminder');

    await extrasRepository.saveExtras(
      taskId,
      TaskExtras(reminderAt: DateTime(2099, 1, 1, 9)),
    );

    final restored = await extrasRepository.getExtras(taskId);

    expect(restored.reminderRepeatMinutes, isNull);
  });
}
