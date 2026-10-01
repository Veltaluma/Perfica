import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models/bug_report_payload.dart';

class BugReportSubmissionResult {
  const BugReportSubmissionResult({this.reportId, this.issueUrl});

  final String? reportId;
  final Uri? issueUrl;
}

class BugReportSubmissionException implements Exception {
  const BugReportSubmissionException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'BugReportSubmissionException: $message';
    }

    return 'BugReportSubmissionException($statusCode): $message';
  }
}

class BugReportSubmissionService {
  BugReportSubmissionService({
    required this.endpoint,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final Uri endpoint;
  final http.Client _client;
  final Duration requestTimeout;

  Future<BugReportSubmissionResult> submit(BugReportPayload payload) async {
    late http.Response response;

    try {
      response = await _client
          .post(
            endpoint,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(payload.toJson()),
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const BugReportSubmissionException(
        'Bug report submission timed out.',
      );
    } on http.ClientException {
      throw const BugReportSubmissionException(
        'Bug report submission failed due to a network error.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BugReportSubmissionException(
        'Bug report submission was rejected.',
        statusCode: response.statusCode,
      );
    }

    if (response.body.trim().isEmpty) {
      return const BugReportSubmissionResult();
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return const BugReportSubmissionResult();
      }

      final nestedIssue = decoded['issue'];

      final issueMap = nestedIssue is Map<String, dynamic> ? nestedIssue : null;

      final issueUrl =
          _parseUri(decoded['issueUrl']) ??
          _parseUri(decoded['html_url']) ??
          _parseUri(decoded['url']) ??
          _parseUri(issueMap?['html_url']) ??
          _parseUri(issueMap?['url']);

      final reportId =
          _nonEmptyString(decoded['reportId']) ??
          _nonEmptyString(decoded['issueNumber']) ??
          _nonEmptyString(decoded['number']) ??
          _nonEmptyString(issueMap?['number']) ??
          _issueNumberFromUrl(issueUrl);

      return BugReportSubmissionResult(reportId: reportId, issueUrl: issueUrl);
    } on FormatException {
      return const BugReportSubmissionResult();
    }
  }

  static String? _nonEmptyString(Object? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static Uri? _parseUri(Object? value) {
    final normalized = _nonEmptyString(value);

    if (normalized == null) {
      return null;
    }

    return Uri.tryParse(normalized);
  }

  static String? _issueNumberFromUrl(Uri? uri) {
    if (uri == null || uri.pathSegments.isEmpty) {
      return null;
    }

    final candidate = uri.pathSegments.last.trim();

    if (candidate.isEmpty || int.tryParse(candidate) == null) {
      return null;
    }

    return candidate;
  }

  void dispose() => _client.close();
}
