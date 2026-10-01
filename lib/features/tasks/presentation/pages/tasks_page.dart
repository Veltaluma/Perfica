import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/widgets/settings_action_button.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/task_workflow_status.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/task_board_view.dart';
import '../widgets/task_list_item.dart';

part 'tasks_page_sections.dart';

enum _TaskListMode { active, completed }

enum _TaskViewMode { list, board }

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  static const double _listMaxContentWidth = 900;
  static const double _boardMaxContentWidth = 1200;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  bool _searchVisible = false;

  _TaskListMode _mode = _TaskListMode.active;

  _TaskViewMode _viewMode = _TaskViewMode.list;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;

      if (!_searchVisible) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == _TaskViewMode.list
          ? _TaskViewMode.board
          : _TaskViewMode.list;
    });
  }

  Future<void> _setTaskCompleted(int taskId, bool completed) async {
    final cubit = context.read<TasksCubit>();

    final result = await cubit.setTaskCompleted(
      id: taskId,
      completed: completed,
    );

    if (!mounted || !completed || result == null) {
      return;
    }

    final l = AppLocalizations.of(context);

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          persist: false,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          content: Text(l.taskCompletedFeedback),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () async {
              await cubit.undoTaskCompletion(result);

              if (mounted) {
                messenger.hideCurrentSnackBar();
              }
            },
          ),
        ),
      );
  }

  Future<void> _completeAllActive() async {
    final l = AppLocalizations.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l.completeAllActiveTitle),
              content: Text(l.completeAllActiveMessage),
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
                  child: Text(l.complete),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await context.read<TasksCubit>().completeAllActive();
  }

  Future<void> _clearCompleted() async {
    final l = AppLocalizations.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l.clearCompletedTitle),
              content: Text(l.clearCompletedMessage),
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
                  child: Text(l.clear),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await context.read<TasksCubit>().clearCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final boardMode = _viewMode == _TaskViewMode.board;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tasksTitle),
        actions: [
          IconButton(
            tooltip: l.searchTasks,
            isSelected: _searchVisible,
            selectedIcon: const Icon(Icons.close_rounded),
            icon: const Icon(Icons.search_rounded),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: boardMode ? l.switchToListView : l.switchToBoardView,
            icon: Icon(
              boardMode ? Icons.view_list_rounded : Icons.view_kanban_outlined,
            ),
            onPressed: _toggleViewMode,
          ),
          if (!boardMode)
            if (_mode == _TaskListMode.active)
              IconButton(
                tooltip: l.completeAllActive,
                onPressed: _completeAllActive,
                icon: const Icon(Icons.done_all_rounded),
              )
            else
              IconButton(
                tooltip: l.clearCompleted,
                onPressed: _clearCompleted,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
          const SettingsActionButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: boardMode || _mode == _TaskListMode.active
          ? FloatingActionButton(
              tooltip: l.newTaskTooltip,
              onPressed: () {
                context.pushNamed(RouteNames.newTask);
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: boardMode
                  ? _boardMaxContentWidth
                  : _listMaxContentWidth,
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: !_searchVisible
                      ? const SizedBox.shrink(key: ValueKey('search-hidden'))
                      : Padding(
                          key: const ValueKey('search-visible'),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: SearchBar(
                            controller: _searchController,
                            autoFocus: true,
                            hintText: l.searchTasks,
                            leading: const Icon(Icons.search_rounded),
                            trailing: [
                              if (_query.isNotEmpty)
                                IconButton(
                                  tooltip: l.clear,
                                  onPressed: () {
                                    _searchController.clear();

                                    setState(() {
                                      _query = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _query = value.trim().toLowerCase();
                              });
                            },
                          ),
                        ),
                ),

                if (!boardMode)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      _searchVisible ? AppSpacing.xs : AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_TaskListMode>(
                        segments: [
                          ButtonSegment(
                            value: _TaskListMode.active,
                            icon: const Icon(
                              Icons.radio_button_unchecked_rounded,
                            ),
                            label: Text(l.activeTasks),
                          ),
                          ButtonSegment(
                            value: _TaskListMode.completed,
                            icon: const Icon(Icons.task_alt_rounded),
                            label: Text(l.completedTasks),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _mode = selection.first;
                          });
                        },
                      ),
                    ),
                  ),

                Expanded(
                  child: boardMode
                      ? TaskBoardView(query: _query)
                      : _TaskListBody(
                          mode: _mode,
                          query: _query,
                          onCompletedChanged: _setTaskCompleted,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
