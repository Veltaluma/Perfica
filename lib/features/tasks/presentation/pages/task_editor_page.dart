import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/services/attachment_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_priority.dart';
import '../../domain/models/task_workflow_status.dart';
import '../../domain/repositories/task_extras_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../cubit/tasks_cubit.dart';

part 'task_editor_page_support.dart';
part 'task_editor_page_sections.dart';

class TaskEditorPage extends StatefulWidget {
  const TaskEditorPage({this.taskId, super.key});

  final int? taskId;

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  static const double _maxContentWidth = 720;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _subtaskController = TextEditingController();

  final List<String> _draftSubtasks = [];

  Task? _task;
  TaskPriority _priority = TaskPriority.none;
  TaskWorkflowStatus _workflowStatus = TaskWorkflowStatus.todo;
  DateTime? _dueAt;
  DateTime? _reminderAt;
  int _reminderRepeatMinutes = 0;
  String? _recurrence;
  List<String> _attachments = const [];

  final Set<String> _sessionAttachments = {};

  AttachmentService? _attachmentService;

  bool _loading = true;
  bool _saving = false;
  bool _moreOptionsExpanded = false;

  int? _savedTaskId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _attachmentService ??= context.read<AttachmentService>();
  }

  @override
  void dispose() {
    final attachmentService = _attachmentService;

    if (attachmentService != null && _sessionAttachments.isNotEmpty) {
      for (final path in _sessionAttachments) {
        unawaited(attachmentService.deleteStored(path));
      }
    }

    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.taskId;
    if (id == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final taskRepository = context.read<TaskRepository>();
    final extrasRepository = context.read<TaskExtrasRepository>();

    final loadedTask = await taskRepository.getTask(id);
    if (loadedTask == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final extras = await extrasRepository.getExtras(id);

    if (!mounted) {
      return;
    }

    _task = loadedTask;
    _titleController.text = loadedTask.title;
    _descriptionController.text = loadedTask.description ?? '';
    _tagsController.text = extras.tags.join(', ');
    _priority = loadedTask.priority;
    _workflowStatus = loadedTask.workflowStatus;
    _dueAt = loadedTask.dueAt;
    _reminderAt = extras.reminderAt;
    _reminderRepeatMinutes = extras.reminderRepeatMinutes ?? 0;
    _recurrence = extras.recurrence;
    _attachments = extras.attachments;

    _moreOptionsExpanded =
        _workflowStatus != TaskWorkflowStatus.todo ||
        _reminderAt != null ||
        _reminderRepeatMinutes > 0 ||
        _recurrence != null ||
        _tagsController.text.trim().isNotEmpty ||
        _attachments.isNotEmpty;

    setState(() => _loading = false);
  }

  String _formatDateTime(BuildContext context, DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context).notSet;
    }

    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final base = initial ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _addAttachment() async {
    final path = await context.read<AttachmentService>().pickAndStore();
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _attachments = [..._attachments, path];
      _sessionAttachments.add(path);
    });
  }

  Future<void> _removeAttachment(String path) async {
    setState(() {
      _attachments = _attachments
          .where((item) => item != path)
          .toList(growable: false);
    });

    if (_sessionAttachments.remove(path)) {
      await _attachmentService?.deleteStored(path);
    }
  }

  void _addDraftSubtask() {
    final value = _subtaskController.text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() {
      _draftSubtasks.add(value);
      _subtaskController.clear();
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final cubit = context.read<TasksCubit>();

      final taskId = await cubit.saveTask(
        taskId: _task?.id ?? _savedTaskId,
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        workflowStatus: _workflowStatus,
        dueAt: _dueAt,
        recurrence: _recurrence,
        reminderAt: _reminderAt,
        reminderRepeatMinutes: _reminderRepeatMinutes == 0
            ? null
            : _reminderRepeatMinutes,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(growable: false),
        attachments: _attachments,
      );

      // saveTask() now owns every attachment currently in this session.
      // Clear session ownership immediately so dispose() can never delete
      // files already persisted by the task.
      _savedTaskId = taskId;
      _sessionAttachments.clear();

      // Remove each successfully created draft immediately. If a later
      // subtask fails, retrying Save continues from the first unfinished
      // draft instead of cloning subtasks or creating another parent task.
      while (_draftSubtasks.isNotEmpty) {
        final draft = _draftSubtasks.first;

        await cubit.createSubtask(taskId: taskId, title: draft);

        _draftSubtasks.removeAt(0);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).taskSaveFailed)),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    // Successful navigation is deliberately the final State-related action.
    // Do not call setState() after requesting this route to be removed.
    Navigator.of(context).pop();
  }

  Future<void> _deleteTask() async {
    final task = _task;

    if (task == null || _saving) {
      return;
    }

    final l = AppLocalizations.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l.deleteTaskConfirmationTitle),
              content: Text(l.deleteTaskConfirmationMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(l.deleteTask),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<TasksCubit>().deleteTask(task.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }

      rethrow;
    }

    if (!mounted) {
      return;
    }

    // As with Save, route removal must be the final State-related action.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_task == null ? l.newTask : l.editTask),
        actions: [
          if (_task != null)
            IconButton(
              tooltip: l.taskDeleteTooltip,
              onPressed: _saving ? null : _deleteTask,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  _TaskCoreFieldsSection(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    priority: _priority,
                    autofocusTitle: _task == null,
                    onPriorityChanged: (value) {
                      setState(() {
                        _priority = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TaskDueDateSection(
                    value: _formatDateTime(context, _dueAt),
                    onPick: () async {
                      final value = await _pickDateTime(_dueAt);

                      if (value != null && mounted) {
                        setState(() {
                          _dueAt = value;
                        });
                      }
                    },
                    onClear: _dueAt == null
                        ? null
                        : () {
                            setState(() {
                              _dueAt = null;
                            });
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MoreOptionsCard(
                    expanded: _moreOptionsExpanded,
                    title: l.moreOptions,
                    onExpansionChanged: (value) {
                      setState(() {
                        _moreOptionsExpanded = value;
                      });
                    },
                    children: [
                      _TaskStatusSection(
                        status: _workflowStatus,
                        onChanged: (value) {
                          setState(() {
                            _workflowStatus = value;
                          });
                        },
                      ),
                      const Divider(),
                      _TaskAutomationSection(
                        recurrence: _recurrence,
                        reminderValue: _formatDateTime(context, _reminderAt),
                        hasReminder: _reminderAt != null,
                        reminderRepeatMinutes: _reminderRepeatMinutes,
                        onRecurrenceChanged: (value) {
                          setState(() {
                            _recurrence = value;
                          });
                        },
                        onPickReminder: () async {
                          final notifications = context
                              .read<NotificationService>();

                          await notifications.requestPermission();

                          if (!mounted) {
                            return;
                          }

                          final value = await _pickDateTime(_reminderAt);

                          if (value != null && mounted) {
                            setState(() {
                              _reminderAt = value;
                            });
                          }
                        },
                        onClearReminder: () {
                          setState(() {
                            _reminderAt = null;
                            _reminderRepeatMinutes = 0;
                          });
                        },
                        onReminderRepeatChanged: (value) {
                          setState(() {
                            _reminderRepeatMinutes = value;
                          });
                        },
                      ),
                      const Divider(),
                      _TaskOrganizationSection(
                        tagsController: _tagsController,
                        attachments: _attachments,
                        onAddAttachment: _addAttachment,
                        onRemoveAttachment: _removeAttachment,
                      ),
                      const Divider(),
                      _TaskSubtasksSection(
                        existingTaskId: _task?.id,
                        draftSubtasks: _draftSubtasks,
                        controller: _subtaskController,
                        onRemoveDraftSubtask: (index) {
                          setState(() {
                            _draftSubtasks.removeAt(index);
                          });
                        },
                        onAddSubtask: () {
                          if (_task == null) {
                            _addDraftSubtask();
                          } else {
                            unawaited(_addExistingSubtask());
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addExistingSubtask() async {
    final task = _task;
    final value = _subtaskController.text.trim();
    if (task == null || value.isEmpty) {
      return;
    }

    await context.read<TasksCubit>().createSubtask(
      taskId: task.id,
      title: value,
    );

    _subtaskController.clear();
  }
}
