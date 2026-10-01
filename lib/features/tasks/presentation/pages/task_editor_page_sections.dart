part of 'task_editor_page.dart';

class _TaskCoreFieldsSection extends StatelessWidget {
  const _TaskCoreFieldsSection({
    required this.titleController,
    required this.descriptionController,
    required this.priority,
    required this.autofocusTitle,
    required this.onPriorityChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TaskPriority priority;
  final bool autofocusTitle;
  final ValueChanged<TaskPriority> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return _SectionCard(
      title: l.taskDetails,
      children: [
        _FieldLabel(l.title),
        TextFormField(
          controller: titleController,
          autofocus: autofocusTitle,
          maxLength: 500,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(hintText: l.taskTitleHint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l.taskTitleRequired;
            }

            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _FieldLabel(l.description),
        TextFormField(
          controller: descriptionController,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l.taskDescriptionHint),
        ),
        const SizedBox(height: AppSpacing.md),
        _FieldLabel(l.priority),
        DropdownButtonFormField<TaskPriority>(
          initialValue: priority,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: [
            DropdownMenuItem(
              value: TaskPriority.none,
              child: Text(l.priorityNone),
            ),
            DropdownMenuItem(
              value: TaskPriority.low,
              child: Text(l.priorityLow),
            ),
            DropdownMenuItem(
              value: TaskPriority.medium,
              child: Text(l.priorityMedium),
            ),
            DropdownMenuItem(
              value: TaskPriority.high,
              child: Text(l.priorityHigh),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onPriorityChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _TaskDueDateSection extends StatelessWidget {
  const _TaskDueDateSection({
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return _SectionCard(
      title: l.schedule,
      children: [
        _DateTimeRow(
          icon: Icons.event_rounded,
          title: l.dueDate,
          value: value,
          onPick: onPick,
          onClear: onClear,
        ),
      ],
    );
  }
}

class _TaskStatusSection extends StatelessWidget {
  const _TaskStatusSection({required this.status, required this.onChanged});

  final TaskWorkflowStatus status;
  final ValueChanged<TaskWorkflowStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return _AdvancedSection(
      title: l.taskStatus,
      children: [
        _FieldLabel(l.workflowStatus),
        DropdownButtonFormField<TaskWorkflowStatus>(
          initialValue: status,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: [
            DropdownMenuItem(
              value: TaskWorkflowStatus.todo,
              child: Text(l.statusTodo),
            ),
            DropdownMenuItem(
              value: TaskWorkflowStatus.inProgress,
              child: Text(l.statusInProgress),
            ),
            DropdownMenuItem(
              value: TaskWorkflowStatus.done,
              child: Text(l.statusDone),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _TaskAutomationSection extends StatelessWidget {
  const _TaskAutomationSection({
    required this.recurrence,
    required this.reminderValue,
    required this.hasReminder,
    required this.reminderRepeatMinutes,
    required this.onRecurrenceChanged,
    required this.onPickReminder,
    required this.onClearReminder,
    required this.onReminderRepeatChanged,
  });

  final String? recurrence;
  final String reminderValue;
  final bool hasReminder;
  final int reminderRepeatMinutes;

  final ValueChanged<String?> onRecurrenceChanged;
  final VoidCallback onPickReminder;
  final VoidCallback onClearReminder;
  final ValueChanged<int> onReminderRepeatChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return _AdvancedSection(
      title: l.automation,
      children: [
        _FieldLabel(l.recurrence),
        DropdownButtonFormField<String>(
          initialValue: recurrence ?? 'none',
          isExpanded: true,
          decoration: const InputDecoration(),
          items: [
            DropdownMenuItem(value: 'none', child: Text(l.repeatNone)),
            DropdownMenuItem(value: 'daily', child: Text(l.repeatDaily)),
            DropdownMenuItem(value: 'weekly', child: Text(l.repeatWeekly)),
            DropdownMenuItem(value: 'monthly', child: Text(l.repeatMonthly)),
          ],
          onChanged: (value) {
            onRecurrenceChanged(value == 'none' ? null : value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _DateTimeRow(
          icon: Icons.notifications_outlined,
          title: l.reminder,
          value: reminderValue,
          onPick: onPickReminder,
          onClear: hasReminder ? onClearReminder : null,
        ),
        const Divider(),
        _FieldLabel(l.reminderRepeat),
        DropdownButtonFormField<int>(
          initialValue: reminderRepeatMinutes,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: [
            DropdownMenuItem(value: 0, child: Text(l.reminderRepeatOnce)),
            DropdownMenuItem(
              value: 5,
              child: Text(l.reminderRepeatEvery5Minutes),
            ),
            DropdownMenuItem(
              value: 10,
              child: Text(l.reminderRepeatEvery10Minutes),
            ),
            DropdownMenuItem(
              value: 15,
              child: Text(l.reminderRepeatEvery15Minutes),
            ),
            DropdownMenuItem(
              value: 30,
              child: Text(l.reminderRepeatEvery30Minutes),
            ),
          ],
          onChanged: !hasReminder
              ? null
              : (value) {
                  if (value != null) {
                    onReminderRepeatChanged(value);
                  }
                },
        ),
        if (hasReminder && reminderRepeatMinutes > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.reminderRepeatFiveAlertsDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _TaskOrganizationSection extends StatelessWidget {
  const _TaskOrganizationSection({
    required this.tagsController,
    required this.attachments,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  final TextEditingController tagsController;
  final List<String> attachments;

  final Future<void> Function() onAddAttachment;
  final Future<void> Function(String path) onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return _AdvancedSection(
      title: l.organization,
      children: [
        _FieldLabel(l.tags),
        TextFormField(
          controller: tagsController,
          decoration: InputDecoration(
            hintText: l.tagsHint,
            prefixIcon: const Icon(Icons.tag_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _FieldLabel(l.attachments),
        if (attachments.isNotEmpty)
          ...attachments.map(
            (path) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(
                File(path).uri.pathSegments.last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: l.removeAttachment,
                onPressed: () async {
                  await onRemoveAttachment(path);
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            await onAddAttachment();
          },
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(l.addAttachment),
        ),
      ],
    );
  }
}

class _TaskSubtasksSection extends StatelessWidget {
  const _TaskSubtasksSection({
    required this.existingTaskId,
    required this.draftSubtasks,
    required this.controller,
    required this.onRemoveDraftSubtask,
    required this.onAddSubtask,
  });

  final int? existingTaskId;
  final List<String> draftSubtasks;
  final TextEditingController controller;

  final ValueChanged<int> onRemoveDraftSubtask;
  final VoidCallback onAddSubtask;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return _AdvancedSection(
      title: l.subtasks,
      children: [
        if (existingTaskId != null)
          _ExistingSubtasks(taskId: existingTaskId!)
        else
          ...draftSubtasks.asMap().entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_unchecked_rounded),
              title: Text(entry.value),
              trailing: IconButton(
                tooltip: l.deleteSubtask,
                onPressed: () {
                  onRemoveDraftSubtask(entry.key);
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(hintText: l.addSubtask),
                onSubmitted: (_) {
                  onAddSubtask();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: l.addSubtask,
              onPressed: onAddSubtask,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
