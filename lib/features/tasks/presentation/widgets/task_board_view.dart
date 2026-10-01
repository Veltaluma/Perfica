import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_workflow_status.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';

class TaskBoardView extends StatelessWidget {
  const TaskBoardView({this.query = '', super.key});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.status == TasksStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == TasksStatus.failure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l.taskLoadFailure, textAlign: TextAlign.center),
            ),
          );
        }

        final normalizedQuery = query.trim().toLowerCase();

        final matchingTasks = state.tasks
            .where((task) {
              if (normalizedQuery.isEmpty) {
                return true;
              }

              return task.title.toLowerCase().contains(normalizedQuery) ||
                  (task.description ?? '').toLowerCase().contains(
                    normalizedQuery,
                  );
            })
            .toList(growable: false);

        final todo = matchingTasks
            .where((task) => task.workflowStatus == TaskWorkflowStatus.todo)
            .toList(growable: false);

        final inProgress = matchingTasks
            .where(
              (task) => task.workflowStatus == TaskWorkflowStatus.inProgress,
            )
            .toList(growable: false);

        final done = matchingTasks
            .where((task) => task.workflowStatus == TaskWorkflowStatus.done)
            .toList(growable: false);

        return LayoutBuilder(
          builder: (context, constraints) {
            final laneWidth = constraints.maxWidth >= 1000
                ? (constraints.maxWidth - AppSpacing.md * 4) / 3
                : 300.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: laneWidth,
                      child: _BoardLane(
                        title: l.boardTodo,
                        tasks: todo,
                        status: TaskWorkflowStatus.todo,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: laneWidth,
                      child: _BoardLane(
                        title: l.boardInProgress,
                        tasks: inProgress,
                        status: TaskWorkflowStatus.inProgress,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: laneWidth,
                      child: _BoardLane(
                        title: l.boardDone,
                        tasks: done,
                        status: TaskWorkflowStatus.done,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BoardLane extends StatelessWidget {
  const _BoardLane({
    required this.title,
    required this.tasks,
    required this.status,
  });

  final String title;
  final List<Task> tasks;
  final TaskWorkflowStatus status;

  IconData get _emptyIcon {
    return switch (status) {
      TaskWorkflowStatus.todo => Icons.inbox_outlined,
      TaskWorkflowStatus.inProgress => Icons.timelapse_rounded,
      TaskWorkflowStatus.done => Icons.task_alt_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tasks.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Icon(_emptyIcon, color: colors.outline, size: 32),
              ),
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _BoardCard(task: task),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () {
          context.pushNamed(
            RouteNames.task,
            pathParameters: {'id': '${task.id}'},
          );
        },
        leading: Icon(switch (task.workflowStatus) {
          TaskWorkflowStatus.todo => Icons.radio_button_unchecked_rounded,
          TaskWorkflowStatus.inProgress => Icons.timelapse_rounded,
          TaskWorkflowStatus.done => Icons.check_circle_rounded,
        }),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: task.workflowStatus == TaskWorkflowStatus.done
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: (task.description ?? '').trim().isEmpty
            ? null
            : Text(
                task.description!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: PopupMenuButton<TaskWorkflowStatus>(
          tooltip: l.workflowStatus,
          initialValue: task.workflowStatus,
          onSelected: (status) {
            context.read<TasksCubit>().setWorkflowStatus(
              id: task.id,
              status: status,
            );
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: TaskWorkflowStatus.todo,
              child: Text(l.statusTodo),
            ),
            PopupMenuItem(
              value: TaskWorkflowStatus.inProgress,
              child: Text(l.statusInProgress),
            ),
            PopupMenuItem(
              value: TaskWorkflowStatus.done,
              child: Text(l.statusDone),
            ),
          ],
        ),
      ),
    );
  }
}
