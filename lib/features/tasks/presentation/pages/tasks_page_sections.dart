part of 'tasks_page.dart';

class _TaskListBody extends StatelessWidget {
  const _TaskListBody({
    required this.mode,
    required this.query,
    required this.onCompletedChanged,
  });

  final _TaskListMode mode;
  final String query;
  final Future<void> Function(int taskId, bool completed) onCompletedChanged;

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

        final visibleTasks = state.tasks
            .where((task) {
              final modeMatches = mode == _TaskListMode.active
                  ? task.workflowStatus != TaskWorkflowStatus.done
                  : task.workflowStatus == TaskWorkflowStatus.done;

              if (!modeMatches) {
                return false;
              }

              if (query.isEmpty) {
                return true;
              }

              return task.title.toLowerCase().contains(query) ||
                  (task.description ?? '').toLowerCase().contains(query);
            })
            .toList(growable: false);

        if (visibleTasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode == _TaskListMode.active
                        ? Icons.task_alt_rounded
                        : Icons.history_rounded,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    mode == _TaskListMode.active
                        ? l.tasksEmptyTitle
                        : l.completedTasks,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (mode == _TaskListMode.active) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(l.tasksEmptyDescription, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 96),
          itemCount: visibleTasks.length,
          itemBuilder: (context, index) {
            final task = visibleTasks[index];

            return TaskListItem(
              key: ValueKey(task.id),
              task: task,
              onEdit: () {
                context.pushNamed(
                  RouteNames.task,
                  pathParameters: {'id': '${task.id}'},
                );
              },
              onDelete: () {
                return context.read<TasksCubit>().deleteTask(task.id);
              },
              onCompletedChanged: (completed) {
                return onCompletedChanged(task.id, completed);
              },
            );
          },
        );
      },
    );
  }
}
