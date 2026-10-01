import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/services/diagnostic_recorder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/bug_report_environment_service.dart';
import '../../data/bug_report_submission_service.dart';
import '../../domain/models/bug_report_environment_info.dart';
import '../../domain/models/bug_report_payload.dart';
part 'bug_report_page_dialogs.dart';
part 'bug_report_page_widgets.dart';

typedef BugReportEnvironmentLoader =
    Future<BugReportEnvironmentInfo> Function();

class BugReportPage extends StatefulWidget {
  const BugReportPage({super.key, this.environmentLoader});

  final BugReportEnvironmentLoader? environmentLoader;

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
  static const int _titleMaxLength = 250;
  static const int _descriptionMaxLength = 10000;
  static const int _stepsMaxLength = 10000;
  static const int _expectedMaxLength = 5000;
  static const int _contactMaxLength = 500;

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _contactController = TextEditingController();

  bool _diagnosticsLoaded = false;
  bool _includeDiagnostics = true;
  bool _isSubmitting = false;

  String? _appVersion;
  String? _platform;
  String? _osVersion;
  String? _deviceModel;
  String? _locale;

  List<DiagnosticEntry> _diagnostics = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _locale ??= Localizations.localeOf(context).toLanguageTag();
    _platform ??= BugReportEnvironmentService.platformName(
      defaultTargetPlatform,
    );

    if (_diagnosticsLoaded) {
      return;
    }

    _diagnosticsLoaded = true;
    _loadDiagnostics();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _contactController.dispose();

    super.dispose();
  }

  Future<void> _loadDiagnostics() async {
    final diagnostics = await context.read<DiagnosticRecorder>().readRecent();

    if (!mounted) {
      return;
    }

    final firstIndex = diagnostics.length > 3 ? diagnostics.length - 3 : 0;

    setState(() {
      _diagnostics = diagnostics
          .sublist(firstIndex)
          .reversed
          .toList(growable: false);

      _includeDiagnostics = _diagnostics.isNotEmpty;
    });
  }

  Future<void> _loadEnvironmentInfo() async {
    if (_appVersion != null && _osVersion != null && _deviceModel != null) {
      return;
    }

    final environmentLoader = widget.environmentLoader;

    final environment = environmentLoader != null
        ? await environmentLoader()
        : await context.read<BugReportEnvironmentService>().load();

    if (!mounted) {
      return;
    }

    setState(() {
      _appVersion = environment.appVersion;
      _platform = environment.platform;
      _osVersion = environment.osVersion;
      _deviceModel = environment.deviceModel;
    });
  }

  String? _requiredValidator(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).bugReportRequired;
    }

    return null;
  }

  BugReportPayload _createPayload() {
    return BugReportPayload(
      title: _titleController.text,
      description: _descriptionController.text,
      stepsToReproduce: _stepsController.text,
      expectedBehavior: _expectedController.text,
      contact: _contactController.text,
      createdAt: DateTime.now(),
      appVersion: _appVersion,
      platform: _platform,
      osVersion: _osVersion,
      deviceModel: _deviceModel,
      locale: _locale,
      diagnostics: _includeDiagnostics ? _diagnostics : const [],
    );
  }

  String _environmentSummary(AppLocalizations l) {
    final unknown = l.bugReportUnknown;

    return [
      l.bugReportAppVersion(_appVersion ?? unknown),
      l.bugReportPlatform(_platform ?? unknown),
      l.bugReportOsVersion(_osVersion ?? unknown),
      l.bugReportDevice(_deviceModel ?? unknown),
      l.bugReportLocale(_locale ?? unknown),
      if (!_includeDiagnostics || _diagnostics.isEmpty)
        l.bugReportRecentErrorsNone
      else
        l.bugReportRecentErrorsIncluded(_diagnostics.length),
    ].join('\n');
  }

  Future<void> _reviewReport() async {
    if (_isSubmitting) {
      return;
    }

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    await _loadEnvironmentInfo();

    if (!mounted) {
      return;
    }

    final l = AppLocalizations.of(context);

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.bugReportReviewTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.bugReportReviewDescription),
                const SizedBox(height: AppSpacing.md),
                _ReviewField(
                  label: l.bugReportTitle,
                  value: _titleController.text.trim(),
                ),
                _ReviewField(
                  label: l.bugReportDescriptionLabel,
                  value: _descriptionController.text.trim(),
                ),
                _ReviewField(
                  label: l.bugReportSteps,
                  value: _stepsController.text.trim(),
                ),
                if (_expectedController.text.trim().isNotEmpty)
                  _ReviewField(
                    label: l.bugReportExpected,
                    value: _expectedController.text.trim(),
                  ),
                if (_contactController.text.trim().isNotEmpty)
                  _ReviewField(
                    label: l.bugReportContact,
                    value: _contactController.text.trim(),
                  ),
                _ReviewField(
                  label: l.bugReportDiagnosticInformation,
                  value: _environmentSummary(l),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(l.cancel),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.send_outlined),
              label: Text(l.bugReportSend),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true || !mounted) {
      return;
    }

    await _submitReport();
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await context.read<BugReportSubmissionService>().submit(
        _createPayload(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      await _showSubmissionSuccess(result);
    } on BugReportSubmissionException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      _showSubmissionError(error);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      _showSubmissionError(
        const BugReportSubmissionException('Unexpected submission error.'),
      );
    }
  }

  void _showSubmissionError(BugReportSubmissionException error) {
    final l = AppLocalizations.of(context);

    final messenger = ScaffoldMessenger.of(context);

    final statusCode = error.statusCode;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            statusCode == null
                ? l.bugReportSubmitFailed
                : l.bugReportSubmitFailedHttp(statusCode),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.reportBug)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.reportBugDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                enabled: !_isSubmitting,
                maxLength: _titleMaxLength,
                decoration: InputDecoration(
                  labelText: l.bugReportTitle,
                  hintText: l.bugReportTitleHint,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => _requiredValidator(context, value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                maxLength: _descriptionMaxLength,
                decoration: InputDecoration(
                  labelText: l.bugReportDescriptionLabel,
                  hintText: l.bugReportDescriptionHint,
                  alignLabelWithHint: true,
                ),
                minLines: 4,
                maxLines: 8,
                validator: (value) => _requiredValidator(context, value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _stepsController,
                enabled: !_isSubmitting,
                maxLength: _stepsMaxLength,
                decoration: InputDecoration(
                  labelText: l.bugReportSteps,
                  hintText: l.bugReportStepsHint,
                  alignLabelWithHint: true,
                ),
                minLines: 4,
                maxLines: 8,
                validator: (value) => _requiredValidator(context, value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _expectedController,
                enabled: !_isSubmitting,
                maxLength: _expectedMaxLength,
                decoration: InputDecoration(
                  labelText: l.bugReportExpected,
                  hintText: l.bugReportExpectedHint,
                  alignLabelWithHint: true,
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contactController,
                enabled: !_isSubmitting,
                maxLength: _contactMaxLength,
                decoration: InputDecoration(
                  labelText: l.bugReportContact,
                  hintText: l.bugReportContactHint,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l.bugReportDiagnostics,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.bugReportDiagnosticsPrivacy,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_diagnostics.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.bugReportNoDiagnostics),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l.bugReportEnvironmentStillIncluded),
                    ],
                  ),
                )
              else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.bugReportIncludeDiagnostics),
                  subtitle: Text(l.bugReportIncludeDiagnosticsDescription),
                  value: _includeDiagnostics,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _includeDiagnostics = value;
                          });
                        },
                ),
                if (_includeDiagnostics)
                  for (final entry in _diagnostics)
                    _buildDiagnosticEntry(context, entry),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _reviewReport,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.preview_outlined),
                label: Text(
                  _isSubmitting ? l.bugReportSending : l.bugReportReview,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
