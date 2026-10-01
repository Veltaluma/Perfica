import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String readTaskEditorSources() {
  final mainSource = File(
    'lib/features/tasks/presentation/pages/task_editor_page.dart',
  ).readAsStringSync();

  final supportSource = File(
    'lib/features/tasks/presentation/pages/task_editor_page_support.dart',
  ).readAsStringSync();

  final sectionsSource = File(
    'lib/features/tasks/presentation/pages/task_editor_page_sections.dart',
  ).readAsStringSync();

  return '$mainSource\n$supportSource\n$sectionsSource';
}

void main() {
  test('task editor keeps core fields visible and advanced fields behind more options', () {
    final source = readTaskEditorSources();

    expect(source, contains('title: l.moreOptions'));

    expect(source, contains("'task-editor-more-options'"));

    expect(source, contains('title: l.dueDate'));

    expect(source, contains('_FieldLabel(l.priority)'));

    expect(source, contains('_FieldLabel(l.workflowStatus)'));

    expect(source, contains('_FieldLabel(l.recurrence)'));

    expect(source, contains('title: l.reminder'));

    expect(source, contains('_FieldLabel(l.tags)'));

    expect(source, contains('_FieldLabel(l.attachments)'));

    expect(source, contains('title: l.subtasks'));
  });

  test('existing advanced task data expands more options', () {
    final source = readTaskEditorSources();

    expect(source, contains('_workflowStatus != TaskWorkflowStatus.todo'));

    expect(source, contains('_reminderAt != null'));

    expect(source, contains('_reminderRepeatMinutes > 0'));

    expect(source, contains('_recurrence != null'));

    expect(source, contains('_tagsController.text.trim().isNotEmpty'));

    expect(source, contains('_attachments.isNotEmpty'));
  });

  test('task editor presentation parts remain in the same Dart library', () {
    final mainSource = File(
      'lib/features/tasks/presentation/pages/task_editor_page.dart',
    ).readAsStringSync();

    final supportSource = File(
      'lib/features/tasks/presentation/pages/task_editor_page_support.dart',
    ).readAsStringSync();

    final sectionsSource = File(
      'lib/features/tasks/presentation/pages/task_editor_page_sections.dart',
    ).readAsStringSync();

    expect(mainSource, contains("part 'task_editor_page_support.dart';"));

    expect(mainSource, contains("part 'task_editor_page_sections.dart';"));

    expect(supportSource, contains("part of 'task_editor_page.dart';"));

    expect(sectionsSource, contains("part of 'task_editor_page.dart';"));

    for (final widget in <String>[
      '_ExistingSubtasks',
      '_MoreOptionsCard',
      '_AdvancedSection',
      '_FieldLabel',
      '_SectionCard',
      '_DateTimeRow',
    ]) {
      expect(
        supportSource,
        contains('class $widget '),
        reason: '$widget must remain in the support part.',
      );
    }

    for (final widget in <String>[
      '_TaskCoreFieldsSection',
      '_TaskDueDateSection',
      '_TaskStatusSection',
      '_TaskAutomationSection',
      '_TaskOrganizationSection',
      '_TaskSubtasksSection',
    ]) {
      expect(
        sectionsSource,
        contains('class $widget '),
        reason: '$widget must remain in the sections part.',
      );
    }
  });
}
