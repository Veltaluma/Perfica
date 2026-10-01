import '../../../../core/services/diagnostic_recorder.dart';

class BugReportPayload {
  const BugReportPayload({
    required this.title,
    required this.description,
    required this.stepsToReproduce,
    required this.createdAt,
    this.expectedBehavior,
    this.contact,
    this.appVersion,
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.locale,
    this.diagnostics = const [],
  });

  static const int schemaVersion = 1;
  static const int _maxMetadataLength = 7800;

  final String title;
  final String description;
  final String stepsToReproduce;
  final String? expectedBehavior;
  final String? contact;
  final DateTime createdAt;

  final String? appVersion;
  final String? platform;
  final String? osVersion;
  final String? deviceModel;
  final String? locale;

  final List<DiagnosticEntry> diagnostics;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'title': title.trim(),
      'description': description.trim(),
      'stepsToReproduce': stepsToReproduce.trim(),
      'expectedBehavior': _nullableTrimmed(expectedBehavior),
      'contact': _nullableTrimmed(contact),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'appVersion': _nullableTrimmed(appVersion),
      'platform': _nullableTrimmed(platform),
      'osVersion': _nullableTrimmed(osVersion),
      'deviceModel': _nullableTrimmed(deviceModel),
      'locale': _nullableTrimmed(locale),
      'metadata': _buildMetadata(),
      'diagnostics': diagnostics
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }

  String _buildMetadata() {
    final buffer = StringBuffer()
      ..writeln('Submitted at: ${createdAt.toUtc().toIso8601String()}')
      ..writeln('App version: ${_nullableTrimmed(appVersion) ?? 'Unknown'}')
      ..writeln('Platform: ${_nullableTrimmed(platform) ?? 'Unknown'}')
      ..writeln('OS version: ${_nullableTrimmed(osVersion) ?? 'Unknown'}')
      ..writeln('Device: ${_nullableTrimmed(deviceModel) ?? 'Unknown'}')
      ..writeln('Locale: ${_nullableTrimmed(locale) ?? 'Unknown'}');

    final normalizedContact = _nullableTrimmed(contact);

    buffer.writeln('Contact: ${normalizedContact ?? 'Not provided'}');

    buffer.writeln('Recent errors: ${diagnostics.length}');

    for (var index = 0; index < diagnostics.length; index++) {
      final entry = diagnostics[index];

      buffer
        ..writeln()
        ..writeln('--- Recent error ${index + 1} ---')
        ..writeln('Recorded at: ${entry.recordedAt.toUtc().toIso8601String()}')
        ..writeln('Type: ${entry.errorType}')
        ..writeln('Message: ${entry.message}');

      final diagnosticContext = _nullableTrimmed(entry.context);

      if (diagnosticContext != null) {
        buffer.writeln('Context: $diagnosticContext');
      }

      if (entry.stackTrace.trim().isNotEmpty) {
        buffer
          ..writeln('Stack trace:')
          ..writeln(entry.stackTrace.trim());
      }
    }

    final metadata = buffer.toString().trim();

    if (metadata.length <= _maxMetadataLength) {
      return metadata;
    }

    const suffix = '\n\n[Diagnostic metadata truncated]';

    return '${metadata.substring(0, _maxMetadataLength - suffix.length)}$suffix';
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
