part of 'task_editor_page.dart';

class _ExistingSubtasks extends StatefulWidget {
  const _ExistingSubtasks({required this.taskId});

  final int taskId;

  @override
  State<_ExistingSubtasks> createState() => _ExistingSubtasksState();
}

class _ExistingSubtasksState extends State<_ExistingSubtasks> {
  late TaskRepository _repository;
  late Stream<List<Subtask>> _subtasksStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _repository = context.read<TaskRepository>();
    _subtasksStream = _repository.watchSubtasks(widget.taskId);
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant _ExistingSubtasks oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_initialized && oldWidget.taskId != widget.taskId) {
      _subtasksStream = _repository.watchSubtasks(widget.taskId);
    }
  }

  Future<void> _confirmDelete(BuildContext context, int subtaskId) async {
    final l = AppLocalizations.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l.deleteSubtaskConfirmationTitle),
              content: Text(l.deleteSubtaskConfirmationMessage),
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
                  child: Text(l.deleteSubtask),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<TasksCubit>().deleteSubtask(subtaskId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return StreamBuilder<List<Subtask>>(
      stream: _subtasksStream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Subtask>[];

        return Column(
          children: items
              .map(
                (item) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: item.isCompleted,
                  title: Text(item.title),
                  secondary: IconButton(
                    tooltip: l.deleteSubtask,
                    onPressed: () async {
                      await _confirmDelete(context, item.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }

                    await context.read<TasksCubit>().setSubtaskCompleted(
                      id: item.id,
                      completed: value,
                    );
                  },
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MoreOptionsCard extends StatelessWidget {
  const _MoreOptionsCard({
    required this.expanded,
    required this.title,
    required this.onExpansionChanged,
    required this.children,
  });

  final bool expanded;
  final String title;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        button: true,
        expanded: expanded,
        label: title,
        child: ExpansionTile(
          key: const ValueKey('task-editor-more-options'),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpansionChanged,
          leading: const Icon(Icons.tune_rounded),
          title: Text(title),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      onTap: onPick,
      trailing: onClear == null
          ? const Icon(Icons.chevron_right_rounded)
          : IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded),
            ),
    );
  }
}
