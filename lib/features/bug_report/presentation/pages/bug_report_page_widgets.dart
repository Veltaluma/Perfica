part of 'bug_report_page.dart';

extension _BugReportWidgets on _BugReportPageState {
  Widget _buildDiagnosticEntry(BuildContext context, DiagnosticEntry entry) {
    final l = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        title: Text(entry.errorType),
        subtitle: Text(
          entry.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.bugReportDiagnosticRecordedAt(
              entry.recordedAt.toLocal().toString(),
            ),
          ),
          if (entry.context != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('${l.bugReportDiagnosticContext}: ${entry.context}'),
          ],
          if (entry.stackTrace.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              entry.stackTrace,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(value),
        ],
      ),
    );
  }
}
