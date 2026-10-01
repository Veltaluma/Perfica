import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:perfica/core/services/diagnostic_recorder.dart';
import 'package:perfica/features/bug_report/data/bug_report_submission_service.dart';
import 'package:perfica/features/bug_report/domain/models/bug_report_environment_info.dart';
import 'package:perfica/features/bug_report/presentation/pages/bug_report_page.dart';
import 'package:perfica/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _FakeDiagnosticRecorder extends DiagnosticRecorder {
  _FakeDiagnosticRecorder({required this.entries})
    : super(directoryProvider: _unusedDirectoryProvider);

  final List<DiagnosticEntry> entries;

  static Future<Directory> _unusedDirectoryProvider() {
    throw StateError('FakeDiagnosticRecorder must not access the filesystem.');
  }

  @override
  Future<List<DiagnosticEntry>> readRecent() async {
    return List<DiagnosticEntry>.unmodifiable(entries);
  }
}

Future<BugReportEnvironmentInfo> _loadTestEnvironment() async {
  return const BugReportEnvironmentInfo(
    appVersion: '0.1.0 (build 1)',
    platform: 'Android',
    osVersion: 'Android 17 (API 37)',
    deviceModel: 'Google sdk_gphone64_x86_64 (emulator)',
  );
}

void main() {
  BugReportSubmissionService createService(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return BugReportSubmissionService(
      client: MockClient(handler),
      endpoint: Uri.parse('https://bugs.example.test/v1/bug-reports'),
    );
  }

  Widget buildApp({
    List<DiagnosticEntry> diagnostics = const [],
    BugReportSubmissionService? service,
  }) {
    final recorder = _FakeDiagnosticRecorder(entries: diagnostics);

    final submissionService =
        service ??
        createService(
          (_) async => http.Response(
            jsonEncode({'reportId': '1', 'issueUrl': null}),
            201,
            headers: const {'content-type': 'application/json'},
          ),
        );

    return MultiProvider(
      providers: [
        Provider<DiagnosticRecorder>.value(value: recorder),
        Provider<BugReportSubmissionService>.value(value: submissionService),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BugReportPage(environmentLoader: _loadTestEnvironment),
      ),
    );
  }

  Future<void> settleInitialLoad(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  Future<void> fillRequiredFields(WidgetTester tester) async {
    final fields = find.byType(TextFormField);

    expect(fields, findsNWidgets(5));

    await tester.enterText(fields.at(0), 'Test bug title');

    await tester.enterText(
      fields.at(1),
      'Something went wrong while using Perfica.',
    );

    await tester.enterText(
      fields.at(2),
      'Open the page and reproduce the problem.',
    );
  }

  Future<void> scrollToReviewButton(WidgetTester tester) async {
    final reviewButton = find.widgetWithText(FilledButton, 'Review report');

    expect(reviewButton, findsOneWidget);

    await tester.scrollUntilVisible(
      reviewButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();
  }

  Future<void> openReviewDialog(WidgetTester tester) async {
    await fillRequiredFields(tester);
    await scrollToReviewButton(tester);

    final reviewButton = find.widgetWithText(FilledButton, 'Review report');

    expect(reviewButton, findsOneWidget);

    await tester.ensureVisible(reviewButton);
    await tester.pumpAndSettle();

    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Review bug report'), findsOneWidget);
  }

  testWidgets('renders bug report form and empty diagnostic state', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await settleInitialLoad(tester);

    expect(find.text('Report a bug'), findsOneWidget);

    expect(find.text('Bug title'), findsOneWidget);

    expect(find.text('What happened?'), findsOneWidget);

    expect(find.text('Steps to reproduce'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );

    await tester.pump();

    expect(
      find.text('No recent diagnostic errors were recorded.'),
      findsOneWidget,
    );

    expect(
      find.text('App, OS, and device information will still be included.'),
      findsOneWidget,
    );
  });

  testWidgets('shows recent diagnostic and privacy toggle', (tester) async {
    final diagnostic = DiagnosticEntry(
      recordedAt: DateTime.utc(2026, 9, 25, 18),
      errorType: 'StateError',
      message: 'Bad state: Saved diagnostic',
      stackTrace: 'diagnostic frame',
      context: 'widget.test',
    );

    await tester.pumpWidget(buildApp(diagnostics: [diagnostic]));

    await settleInitialLoad(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );

    await tester.pump();

    expect(find.text('Include recent diagnostics'), findsOneWidget);

    expect(find.textContaining('Saved diagnostic'), findsOneWidget);
  });

  testWidgets('requires title description and reproduction steps', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await settleInitialLoad(tester);
    await scrollToReviewButton(tester);

    final reviewButton = find.widgetWithText(FilledButton, 'Review report');

    expect(reviewButton, findsOneWidget);

    await tester.tap(reviewButton);

    await tester.pump();

    expect(find.text('This field is required.'), findsNWidgets(3));
  });

  testWidgets('submits report and shows report number and issue action', (
    tester,
  ) async {
    var submissionCount = 0;

    final service = createService((request) async {
      submissionCount += 1;

      expect(request.method, 'POST');

      final submitted = jsonDecode(request.body) as Map<String, dynamic>;

      expect(submitted['title'], 'Test bug title');

      expect(
        submitted['description'],
        'Something went wrong while using Perfica.',
      );

      expect(
        submitted['stepsToReproduce'],
        'Open the page and reproduce the problem.',
      );

      expect(submitted['platform'], isNotNull);

      return http.Response(
        jsonEncode({
          'reportId': '77',
          'issueUrl': 'https://github.com/Veltaluma/Perfica/issues/77',
        }),
        201,
        headers: const {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(buildApp(service: service));

    await settleInitialLoad(tester);
    await openReviewDialog(tester);

    expect(find.text('Diagnostic information'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Send report'));

    await tester.pumpAndSettle();

    expect(submissionCount, 1);

    expect(find.text('Bug report sent'), findsOneWidget);

    expect(find.text('Report #77'), findsOneWidget);

    expect(find.text('Open issue'), findsOneWidget);
  });

  testWidgets('shows failure message when backend rejects report', (
    tester,
  ) async {
    final service = createService(
      (_) async => http.Response(
        jsonEncode({'error': 'submission_failed'}),
        502,
        headers: const {'content-type': 'application/json'},
      ),
    );

    await tester.pumpWidget(buildApp(service: service));

    await settleInitialLoad(tester);
    await openReviewDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Send report'));

    await tester.pumpAndSettle();

    expect(
      find.text('Could not send the bug report (HTTP 502). Please try again.'),
      findsOneWidget,
    );

    expect(find.text('Bug report sent'), findsNothing);
  });

  testWidgets('disables another submission while request is in progress', (
    tester,
  ) async {
    final responseCompleter = Completer<http.Response>();

    var submissionCount = 0;

    final service = createService((_) {
      submissionCount += 1;
      return responseCompleter.future;
    });

    await tester.pumpWidget(buildApp(service: service));

    await settleInitialLoad(tester);
    await openReviewDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Send report'));

    await tester.pump();

    expect(submissionCount, 1);

    expect(find.text('Sending report...'), findsOneWidget);

    final sendingButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Sending report...'),
        matching: find.byType(FilledButton),
      ),
    );

    expect(sendingButton.onPressed, isNull);

    responseCompleter.complete(
      http.Response(
        jsonEncode({'reportId': '88', 'issueUrl': null}),
        201,
        headers: const {'content-type': 'application/json'},
      ),
    );

    await tester.pumpAndSettle();

    expect(submissionCount, 1);

    expect(find.text('Report #88'), findsOneWidget);
  });
}
