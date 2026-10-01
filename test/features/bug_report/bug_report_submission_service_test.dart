import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:perfica/core/services/diagnostic_recorder.dart';
import 'package:perfica/features/bug_report/data/bug_report_submission_service.dart';
import 'package:perfica/features/bug_report/domain/models/bug_report_payload.dart';

void main() {
  BugReportPayload createPayload({
    List<DiagnosticEntry> diagnostics = const [],
  }) {
    return BugReportPayload(
      title: '  Task screen crashes  ',
      description: '  The task screen closed unexpectedly.  ',
      stepsToReproduce: '  Open Tasks, then open the item.  ',
      expectedBehavior: '  The task should open.  ',
      contact: '  reporter@example.com  ',
      createdAt: DateTime.utc(2026, 9, 26, 10, 30),
      diagnostics: diagnostics,
    );
  }

  test('payload serializes stable schema and trims values', () {
    final diagnostic = DiagnosticEntry(
      recordedAt: DateTime.utc(2026, 9, 26, 10),
      errorType: 'StateError',
      message: 'Bad state: example',
      stackTrace: 'frame one',
      context: 'tasks.page',
    );

    final json = createPayload(diagnostics: [diagnostic]).toJson();

    expect(json['schemaVersion'], BugReportPayload.schemaVersion);

    expect(json['title'], 'Task screen crashes');

    expect(json['description'], 'The task screen closed unexpectedly.');

    expect(json['stepsToReproduce'], 'Open Tasks, then open the item.');

    expect(json['expectedBehavior'], 'The task should open.');

    expect(json['contact'], 'reporter@example.com');

    expect(json['createdAt'], '2026-09-26T10:30:00.000Z');

    final diagnostics = json['diagnostics'] as List<dynamic>;

    expect(diagnostics, hasLength(1));

    expect(
      (diagnostics.single as Map<String, dynamic>)['errorType'],
      'StateError',
    );
  });

  test('payload converts blank optional values to null', () {
    final payload = BugReportPayload(
      title: 'Bug',
      description: 'Description',
      stepsToReproduce: 'Steps',
      expectedBehavior: '   ',
      contact: '',
      createdAt: DateTime.utc(2026, 9, 26),
    );

    final json = payload.toJson();

    expect(json['expectedBehavior'], isNull);

    expect(json['contact'], isNull);

    expect(json['diagnostics'], isEmpty);
  });

  test('submits JSON and parses backend result', () async {
    late http.Request capturedRequest;

    final client = MockClient((request) async {
      capturedRequest = request;

      return http.Response(
        jsonEncode({
          'reportId': 'report-123',
          'issueUrl': 'https://github.com/Veltaluma/Perfica/issues/42',
        }),
        201,
        headers: const {'content-type': 'application/json'},
      );
    });

    final service = BugReportSubmissionService(
      client: client,
      endpoint: Uri.parse('https://bugs.example.test/report'),
    );

    final result = await service.submit(createPayload());

    expect(capturedRequest.method, 'POST');

    expect(capturedRequest.url.toString(), 'https://bugs.example.test/report');

    expect(
      capturedRequest.headers['content-type'],
      'application/json; charset=utf-8',
    );

    final submitted = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

    expect(submitted['title'], 'Task screen crashes');

    expect(result.reportId, 'report-123');

    expect(
      result.issueUrl.toString(),
      'https://github.com/Veltaluma/Perfica/issues/42',
    );
  });

  test('accepts successful empty backend response', () async {
    final service = BugReportSubmissionService(
      client: MockClient((_) async => http.Response('', 204)),
      endpoint: Uri.parse('https://bugs.example.test/report'),
    );

    final result = await service.submit(createPayload());

    expect(result.reportId, isNull);

    expect(result.issueUrl, isNull);
  });

  test('converts non-success response into typed failure', () async {
    final service = BugReportSubmissionService(
      client: MockClient(
        (_) async => http.Response('{"error":"rate limited"}', 429),
      ),
      endpoint: Uri.parse('https://bugs.example.test/report'),
    );

    await expectLater(
      service.submit(createPayload()),
      throwsA(
        isA<BugReportSubmissionException>()
            .having((error) => error.statusCode, 'statusCode', 429)
            .having((error) => error.message, 'message', contains('rejected')),
      ),
    );
  });

  test('converts request timeout into typed failure', () async {
    final completer = Completer<http.Response>();

    final service = BugReportSubmissionService(
      client: MockClient((_) => completer.future),
      endpoint: Uri.parse('https://bugs.example.test/report'),
      requestTimeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      service.submit(createPayload()),
      throwsA(
        isA<BugReportSubmissionException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });

  test('converts client exception into typed failure', () async {
    final service = BugReportSubmissionService(
      client: MockClient((_) async {
        throw http.ClientException('network unavailable');
      }),
      endpoint: Uri.parse('https://bugs.example.test/report'),
    );

    await expectLater(
      service.submit(createPayload()),
      throwsA(
        isA<BugReportSubmissionException>().having(
          (error) => error.message,
          'message',
          contains('network error'),
        ),
      ),
    );
  });
}
