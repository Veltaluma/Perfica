part of 'bug_report_page.dart';

extension _BugReportDialogs on _BugReportPageState {
  Future<void> _showSubmissionSuccess(BugReportSubmissionResult result) async {
    final l = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle_outline),
          title: Text(l.bugReportSentTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.bugReportSentDescription),
              if (result.reportId != null &&
                  result.reportId!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l.bugReportReportNumber(result.reportId!)),
              ],
            ],
          ),
          actions: [
            if (result.issueUrl != null)
              TextButton.icon(
                onPressed: () async {
                  final uri = result.issueUrl;

                  if (uri == null) {
                    return;
                  }

                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(l.bugReportOpenIssue),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }
}
