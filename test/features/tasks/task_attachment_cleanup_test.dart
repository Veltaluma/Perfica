import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/core/services/attachment_service.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_extras_repository.dart';
import 'package:perfica/features/tasks/data/repositories/drift_task_repository.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';
import 'package:perfica/features/tasks/presentation/cubit/tasks_cubit.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;
  late DriftTaskExtrasRepository extrasRepository;
  late FakeNotificationService notifications;
  late FakeAttachmentService attachments;
  late TasksCubit cubit;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = DriftTaskRepository(database);

    extrasRepository = DriftTaskExtrasRepository(database);

    notifications = FakeNotificationService();

    attachments = FakeAttachmentService();

    cubit = TasksCubit(
      repository,
      extrasRepository,
      notifications,
      attachments,
    );
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('editing task deletes only detached attachments', () async {
    final id = await cubit.saveTask(
      title: 'Files',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
      attachments: const ['/managed/keep.txt', '/managed/remove.txt'],
    );

    attachments.deleted.clear();

    await cubit.saveTask(
      taskId: id,
      title: 'Files',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
      attachments: const ['/managed/keep.txt', '/managed/new.txt'],
    );

    final extras = await extrasRepository.getExtras(id);

    expect(extras.attachments, const ['/managed/keep.txt', '/managed/new.txt']);

    expect(attachments.deleted, const ['/managed/remove.txt']);
  });

  test('deleting task cleans every attachment', () async {
    final id = await cubit.saveTask(
      title: 'Delete files',
      priority: TaskPriority.low,
      workflowStatus: TaskWorkflowStatus.todo,
      attachments: const ['/managed/a.txt', '/managed/b.txt'],
    );

    attachments.deleted.clear();

    await cubit.deleteTask(id);

    expect(await repository.getTask(id), isNull);

    final extras = await extrasRepository.getExtras(id);

    expect(extras.attachments, isEmpty);

    expect(
      attachments.deleted,
      containsAll(const ['/managed/a.txt', '/managed/b.txt']),
    );
  });

  test('save normalizes tags and attachments', () async {
    final id = await cubit.saveTask(
      title: 'Normalize',
      priority: TaskPriority.none,
      workflowStatus: TaskWorkflowStatus.todo,
      tags: const [' work ', '', 'work', 'study'],
      attachments: const [
        ' /managed/a.txt ',
        '',
        '/managed/a.txt',
        '/managed/b.txt',
      ],
    );

    final extras = await extrasRepository.getExtras(id);

    expect(extras.tags, const ['work', 'study']);

    expect(extras.attachments, const ['/managed/a.txt', '/managed/b.txt']);
  });
}

class FakeNotificationService extends NotificationService {
  @override
  Future<void> cancelTask(int taskId) async {}

  @override
  Future<void> scheduleTask({
    required int taskId,
    required String title,
    required DateTime when,
  }) async {}
}

class FakeAttachmentService extends AttachmentService {
  final List<String> deleted = [];

  @override
  Future<void> deleteStored(String path) async {
    deleted.add(path);
  }
}
