part of 'task_list_item.dart';

class _CollapsedTaskDetails extends StatelessWidget {
  const _CollapsedTaskDetails({
    required this.task,
    required this.statusLabel,
    required this.priorityLabel,
    required this.compactDueDate,
  });

  final Task task;
  final String statusLabel;
  final String priorityLabel;
  final String? compactDueDate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _InfoChip(
          icon: task.workflowStatus == TaskWorkflowStatus.inProgress
              ? Icons.timelapse_rounded
              : task.workflowStatus == TaskWorkflowStatus.done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          text: statusLabel,
        ),
        if (task.priority != TaskPriority.none)
          _InfoChip(icon: Icons.flag_outlined, text: priorityLabel),
        if (compactDueDate != null)
          _InfoChip(icon: Icons.event_outlined, text: compactDueDate!),
      ],
    );
  }
}

String _recurrenceLabel(AppLocalizations l, String recurrence) {
  return switch (recurrence) {
    'daily' => l.repeatDaily,
    'weekly' => l.repeatWeekly,
    'monthly' => l.repeatMonthly,
    _ => recurrence,
  };
}

class _ExpandedTaskDetails extends StatelessWidget {
  const _ExpandedTaskDetails({
    required this.task,
    required this.extras,
    required this.subtasks,
    required this.completedSubtasks,
    required this.statusLabel,
    required this.priorityLabel,
    required this.formatDate,
  });

  final Task task;
  final TaskExtras extras;
  final List<Subtask> subtasks;
  final int completedSubtasks;
  final String statusLabel;
  final String priorityLabel;

  final String Function(DateTime value) formatDate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _InfoChip(
              icon: task.workflowStatus == TaskWorkflowStatus.inProgress
                  ? Icons.timelapse_rounded
                  : task.workflowStatus == TaskWorkflowStatus.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              text: statusLabel,
            ),
            if (task.priority != TaskPriority.none)
              _InfoChip(icon: Icons.flag_outlined, text: priorityLabel),
            if (task.dueAt != null)
              _InfoChip(
                icon: Icons.event_outlined,
                text: formatDate(task.dueAt!),
              ),
            if (extras.reminderAt != null)
              _InfoChip(
                icon: Icons.notifications_outlined,
                text: formatDate(extras.reminderAt!),
              ),
            if (extras.recurrence != null)
              _InfoChip(
                icon: Icons.repeat_rounded,
                text: _recurrenceLabel(l, extras.recurrence!),
              ),
          ],
        ),
        if (subtasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.subtasks,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '$completedSubtasks/${subtasks.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...subtasks.map((subtask) => _SubtaskRow(subtask: subtask)),
        ],
        if (extras.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: extras.tags
                .map(
                  (tag) => Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.tag_rounded, size: 16),
                    label: Text(tag),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.subtask});

  final Subtask subtask;

  Future<void> _setCompleted(BuildContext context, bool completed) {
    return context.read<TasksCubit>().setSubtaskCompleted(
      id: subtask.id,
      completed: completed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        _setCompleted(context, !subtask.isCompleted);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: subtask.isCompleted,
              visualDensity: VisualDensity.compact,
              onChanged: (value) {
                if (value != null) {
                  _setCompleted(context, value);
                }
              },
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                subtask.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: subtask.isCompleted
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
