import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/services/attachment_service.dart';
import 'package:perfica/core/services/notification_service.dart';
import 'package:perfica/features/tasks/domain/models/task.dart';
import 'package:perfica/features/tasks/domain/models/task_priority.dart';
import 'package:perfica/features/tasks/domain/models/task_workflow_status.dart';
import 'package:perfica/features/tasks/domain/repositories/task_extras_repository.dart';
import 'package:perfica/features/tasks/domain/repositories/task_repository.dart';
import 'package:perfica/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:perfica/features/tasks/presentation/pages/task_editor_page.dart';
import 'package:perfica/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  late FakeTaskRepository repository;
  late FakeTaskExtrasRepository extrasRepository;
  late FakeNotificationService notifications;
  late FakeAttachmentService attachments;
  late RecordingTasksCubit cubit;

  setUp(() {
    repository = FakeTaskRepository();
    extrasRepository = FakeTaskExtrasRepository();
    notifications = FakeNotificationService();
    attachments = FakeAttachmentService();

    cubit = RecordingTasksCubit(
      repository,
      extrasRepository,
      notifications,
      attachments,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        Provider<AttachmentService>.value(value: attachments),
        Provider<NotificationService>.value(value: notifications),
        Provider<TaskRepository>.value(value: repository),
        Provider<TaskExtrasRepository>.value(value: extrasRepository),
      ],
      child: BlocProvider<TasksCubit>.value(
        value: cubit,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TaskEditorPage(),
        ),
      ),
    );
  }

  Finder primaryScrollable() {
    return find.byType(Scrollable).first;
  }

  Future<void> openMoreOptions(WidgetTester tester) async {
    final moreOptions = find.byKey(const ValueKey('task-editor-more-options'));

    await tester.scrollUntilVisible(
      moreOptions,
      300,
      scrollable: primaryScrollable(),
    );

    await tester.pumpAndSettle();

    expect(moreOptions, findsOneWidget);

    await tester.tap(moreOptions);
    await tester.pumpAndSettle();

    final addAttachmentButton = find.widgetWithText(
      OutlinedButton,
      'Add attachment',
    );

    await tester.scrollUntilVisible(
      addAttachmentButton,
      300,
      scrollable: primaryScrollable(),
    );

    await tester.pumpAndSettle();

    expect(addAttachmentButton, findsOneWidget);
  }

  Future<void> addAttachment(WidgetTester tester, String path) async {
    attachments.nextPickedPath = path;

    final button = find.widgetWithText(OutlinedButton, 'Add attachment');

    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: primaryScrollable(),
    );

    await tester.pumpAndSettle();

    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> disposeEditor(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('unsaved session attachment is deleted when editor is disposed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await openMoreOptions(tester);

    const path = '/managed/session-unsaved.txt';

    await addAttachment(tester, path);

    expect(find.text('session-unsaved.txt'), findsOneWidget);
    expect(attachments.deleted, isEmpty);

    await disposeEditor(tester);

    expect(attachments.deleted, const [path]);
  });

  testWidgets(
    'successful save transfers session attachment ownership away from editor',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final titleField = find.byType(TextFormField).first;

      await tester.enterText(titleField, 'Saved attachment task');

      await openMoreOptions(tester);

      const path = '/managed/session-saved.txt';

      await addAttachment(tester, path);

      expect(find.text('session-saved.txt'), findsOneWidget);

      final saveButton = find.widgetWithText(TextButton, 'Save');

      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);

      await tester.pump();
      await tester.pump();

      expect(cubit.saveCalls, 1);
      expect(cubit.savedTitle, 'Saved attachment task');
      expect(cubit.savedAttachments, const [path]);

      await disposeEditor(tester);

      expect(attachments.deleted, isEmpty);
    },
  );

  testWidgets(
    'removing session attachment deletes it once and dispose does not delete again',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await openMoreOptions(tester);

      const path = '/managed/session-removed.txt';

      await addAttachment(tester, path);

      expect(find.text('session-removed.txt'), findsOneWidget);

      final removeButton = find.byTooltip('Remove attachment');

      await tester.scrollUntilVisible(
        removeButton,
        200,
        scrollable: primaryScrollable(),
      );

      await tester.pumpAndSettle();

      expect(removeButton, findsOneWidget);

      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(find.text('session-removed.txt'), findsNothing);
      expect(attachments.deleted, const [path]);

      await disposeEditor(tester);

      expect(attachments.deleted, const [path]);
    },
  );
}

class RecordingTasksCubit extends TasksCubit {
  RecordingTasksCubit(
    super.repository,
    super.extrasRepository,
    super.notificationService,
    super.attachmentService,
  );

  int saveCalls = 0;
  String? savedTitle;
  List<String> savedAttachments = const [];

  @override
  Future<int> saveTask({
    int? taskId,
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskWorkflowStatus workflowStatus,
    DateTime? dueAt,
    String? recurrence,
    DateTime? reminderAt,
    int? reminderRepeatMinutes,
    List<String> tags = const [],
    List<String> attachments = const [],
  }) async {
    saveCalls += 1;
    savedTitle = title.trim();
    savedAttachments = List<String>.unmodifiable(attachments);

    return 1;
  }
}

class FakeTaskRepository extends Fake implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks() {
    return Stream<List<Task>>.value(const <Task>[]);
  }
}

class FakeTaskExtrasRepository extends Fake implements TaskExtrasRepository {}

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
  String? nextPickedPath;

  final List<String> deleted = <String>[];

  @override
  Future<String?> pickAndStore() async {
    final path = nextPickedPath;
    nextPickedPath = null;

    return path;
  }

  @override
  Future<void> deleteStored(String path) async {
    deleted.add(path);
  }
}
