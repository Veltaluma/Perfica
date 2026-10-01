import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    this.latestVersion,
    this.releaseUrl,
  });

  final String currentVersion;
  final String? latestVersion;
  final Uri? releaseUrl;

  bool get hasUpdate {
    final latest = latestVersion;

    if (latest == null || latest.trim().isEmpty) {
      return false;
    }

    final currentParsed = _tryParseVersion(currentVersion);
    final latestParsed = _tryParseVersion(latest);

    if (currentParsed == null || latestParsed == null) {
      return false;
    }

    return latestParsed > currentParsed;
  }

  static Version? _tryParseVersion(String raw) {
    var normalized = raw.trim();

    if (normalized.startsWith('v') || normalized.startsWith('V')) {
      normalized = normalized.substring(1);
    }

    if (normalized.isEmpty) {
      return null;
    }

    try {
      return Version.parse(normalized);
    } on FormatException {
      return null;
    }
  }
}

enum UpdateFailure {
  networkTimeout,
  networkUnavailable,
  httpError,
  malformedResponse,
}

class UpdateException implements Exception {
  const UpdateException(
    this.failure,
    this.message, {
    this.cause,
    this.statusCode,
  });

  final UpdateFailure failure;
  final String message;
  final Object? cause;
  final int? statusCode;

  @override
  String toString() => 'UpdateException($failure): $message';
}

class UpdateService {
  UpdateService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  static final Uri _latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/Veltaluma/Perfica/releases/latest',
  );

  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2026-03-10',
  };

  final http.Client _client;
  final Duration requestTimeout;

  Future<UpdateCheckResult> check() async {
    final info = await PackageInfo.fromPlatform();

    final currentVersion = info.version;

    try {
      final response = await _client
          .get(_latestReleaseUri, headers: _headers)
          .timeout(requestTimeout);

      if (response.statusCode == HttpStatus.notFound) {
        return UpdateCheckResult(currentVersion: currentVersion);
      }

      if (response.statusCode != HttpStatus.ok) {
        throw UpdateException(
          UpdateFailure.httpError,
          'GitHub returned HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const UpdateException(
          UpdateFailure.malformedResponse,
          'GitHub release response root is invalid.',
        );
      }

      final rawTag = decoded['tag_name'];

      if (rawTag is! String || rawTag.trim().isEmpty) {
        throw const UpdateException(
          UpdateFailure.malformedResponse,
          'GitHub release response does not contain a valid tag_name.',
        );
      }

      final latestVersion = rawTag.trim();

      final rawUrl = decoded['html_url'];

      Uri? releaseUrl;

      if (rawUrl is String && rawUrl.trim().isNotEmpty) {
        final candidate = Uri.tryParse(rawUrl.trim());

        if (candidate != null &&
            candidate.hasScheme &&
            candidate.host == 'github.com') {
          releaseUrl = candidate;
        }
      }

      return UpdateCheckResult(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
      );
    } on TimeoutException catch (error) {
      throw UpdateException(
        UpdateFailure.networkTimeout,
        'Update request timed out.',
        cause: error,
      );
    } on SocketException catch (error) {
      throw UpdateException(
        UpdateFailure.networkUnavailable,
        'Update network connection failed.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw UpdateException(
        UpdateFailure.networkUnavailable,
        'Update network request failed.',
        cause: error,
      );
    } on FormatException catch (error) {
      throw UpdateException(
        UpdateFailure.malformedResponse,
        'GitHub release response could not be decoded.',
        cause: error,
      );
    }
  }

  void dispose() => _client.close();
}
