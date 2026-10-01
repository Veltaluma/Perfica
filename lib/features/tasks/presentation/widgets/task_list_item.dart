import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_extras.dart';
import '../../domain/models/task_priority.dart';
import '../../domain/models/task_workflow_status.dart';
import '../../domain/repositories/task_extras_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../cubit/tasks_cubit.dart';
part 'task_list_item_details.dart';

enum _RecurringTaskAction { stopRepeating, completeForever }

class TaskListItem extends StatefulWidget {
  const TaskListItem({
    required this.task,
    required this.onCompletedChanged,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Task task;

  final Future<void> Function(bool completed) onCompletedChanged;

  final VoidCallback onEdit;

  final Future<void> Function() onDelete;

  @override
  State<TaskListItem> createState() {
    return _TaskListItemState();
  }
}

class _TaskListItemState extends State<TaskListItem> {
  bool _expanded = false;
  bool _dataInitialized = false;

  late TaskExtrasRepository _extrasRepository;
  late TaskRepository _taskRepository;
  late Future<TaskExtras> _extrasFuture;
  late Stream<List<Subtask>> _subtasksStream;

  Task get task => widget.task;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dataInitialized) {
      return;
    }

    _extrasRepository = context.read<TaskExtrasRepository>();
    _taskRepository = context.read<TaskRepository>();

    _initializeTaskData();

    _dataInitialized = true;
  }

  @override
  void didUpdateWidget(covariant TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.task.id != widget.task.id && _dataInitialized) {
      _initializeTaskData();
    }
  }

  void _initializeTaskData() {
    _extrasFuture = _extrasRepository.getExtras(task.id);
    _subtasksStream = _taskRepository.watchSubtasks(task.id);
  }

  void _reloadExtras() {
    setState(() {
      _extrasFuture = _extrasRepository.getExtras(task.id);
    });
  }

  String _statusLabel(AppLocalizations l) {
    return switch (task.workflowStatus) {
      TaskWorkflowStatus.todo => l.statusTodo,
      TaskWorkflowStatus.inProgress => l.statusInProgress,
      TaskWorkflowStatus.done => l.statusDone,
    };
  }

  String _priorityLabel(AppLocalizations l) {
    return switch (task.priority) {
      TaskPriority.none => l.priorityNone,
      TaskPriority.low => l.priorityLow,
      TaskPriority.medium => l.priorityMedium,
      TaskPriority.high => l.priorityHigh,
    };
  }

  String _fullDate(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }

  String _compactDate(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }

  Future<void> _setTaskCompleted({required bool completed}) {
    return widget.onCompletedChanged(completed);
  }

  Future<void> _stopRepeating() async {
    final l = AppLocalizations.of(context);
    final cubit = context.read<TasksCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final extrasBefore = await cubit.stopRepeating(task.id);

    if (extrasBefore == null || !mounted) {
      return;
    }

    _reloadExtras();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          persist: false,
          behavior: SnackBarBehavior.floating,
          content: Text(l.repeatingStoppedFeedback),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () async {
              await cubit.undoStopRepeating(
                id: task.id,
                extrasBefore: extrasBefore,
              );

              if (mounted) {
                _reloadExtras();
              }

              messenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
  }

  Future<void> _completeForever() async {
    final l = AppLocalizations.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l.completeForeverConfirmationTitle),
              content: Text(l.completeForeverConfirmationMessage),
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
                  child: Text(l.completeForever),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    final cubit = context.read<TasksCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await cubit.completeTaskForever(task.id);

    if (result == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          persist: false,
          behavior: SnackBarBehavior.floating,
          content: Text(l.completedForeverFeedback),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () async {
              await cubit.undoTaskCompletion(result);

              messenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
  }

  Future<void> _handleRecurringAction(_RecurringTaskAction action) async {
    switch (action) {
      case _RecurringTaskAction.stopRepeating:
        await _stopRepeating();
      case _RecurringTaskAction.completeForever:
        await _completeForever();
    }
  }

  Future<void> _confirmDelete() async {
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

    await widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return FutureBuilder<TaskExtras>(
      future: _extrasFuture,
      builder: (context, extrasSnapshot) {
        final extras = extrasSnapshot.data ?? const TaskExtras();

        return StreamBuilder<List<Subtask>>(
          stream: _subtasksStream,
          builder: (context, subtasksSnapshot) {
            final subtasks = subtasksSnapshot.data ?? const <Subtask>[];

            final completedSubtasks = subtasks
                .where((item) => item.isCompleted)
                .length;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: task.isCompleted
                              ? l.taskCompletedSemantics
                              : l.taskPendingSemantics,
                          child: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) async {
                              if (value == null) {
                                return;
                              }

                              await _setTaskCompleted(completed: value);
                            },
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                                if ((task.description ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    task.description!.trim(),
                                    maxLines: _expanded ? 3 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l.editTaskTooltip,
                              onPressed: widget.onEdit,
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            if (extras.recurrence != null &&
                                task.workflowStatus != TaskWorkflowStatus.done)
                              PopupMenuButton<_RecurringTaskAction>(
                                tooltip: l.taskActions,
                                icon: const Icon(Icons.more_vert_rounded),
                                onSelected: _handleRecurringAction,
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _RecurringTaskAction.stopRepeating,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.repeat_on_rounded,
                                      ),
                                      title: Text(l.stopRepeating),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _RecurringTaskAction.completeForever,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.check_circle_outline_rounded,
                                      ),
                                      title: Text(l.completeForever),
                                    ),
                                  ),
                                ],
                              ),
                            IconButton(
                              tooltip: l.taskDeleteTooltip,
                              onPressed: _confirmDelete,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: _expanded
                        ? _ExpandedTaskDetails(
                            task: task,
                            extras: extras,
                            subtasks: subtasks,
                            completedSubtasks: completedSubtasks,
                            statusLabel: _statusLabel(l),
                            priorityLabel: _priorityLabel(l),
                            formatDate: _fullDate,
                          )
                        : _CollapsedTaskDetails(
                            task: task,
                            statusLabel: _statusLabel(l),
                            priorityLabel: _priorityLabel(l),
                            compactDueDate: task.dueAt == null
                                ? null
                                : _compactDate(task.dueAt!),
                          ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: l.taskDetails,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                      icon: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
