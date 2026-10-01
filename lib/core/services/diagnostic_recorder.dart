import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef DiagnosticDirectoryProvider = Future<Directory> Function();
typedef DiagnosticClock = DateTime Function();

class DiagnosticEntry {
  const DiagnosticEntry({
    required this.recordedAt,
    required this.errorType,
    required this.message,
    required this.stackTrace,
    this.context,
  });

  final DateTime recordedAt;
  final String errorType;
  final String message;
  final String stackTrace;
  final String? context;

  Map<String, dynamic> toJson() {
    return {
      'recordedAt': recordedAt.toUtc().toIso8601String(),
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      if (context != null) 'context': context,
    };
  }

  factory DiagnosticEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosticEntry(
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      errorType: json['errorType'] as String,
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String,
      context: json['context'] as String?,
    );
  }
}

class DiagnosticRecorder {
  DiagnosticRecorder({
    DiagnosticDirectoryProvider? directoryProvider,
    DiagnosticClock? now,
    this.maxEntries = 25,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _now = now ?? DateTime.now {
    if (maxEntries < 1) {
      throw ArgumentError.value(
        maxEntries,
        'maxEntries',
        'Must be at least 1.',
      );
    }
  }

  static const String _fileName = 'diagnostics_v1.json';

  static const int _maxMessageLength = 2000;
  static const int _maxStackLength = 6000;
  static const int _maxContextLength = 300;

  final DiagnosticDirectoryProvider _directoryProvider;

  final DiagnosticClock _now;

  final int maxEntries;

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) async {
    final entries = await readRecent();

    final sanitizedContext = context == null
        ? null
        : _truncate(_sanitize(context), _maxContextLength);

    entries.add(
      DiagnosticEntry(
        recordedAt: _now().toUtc(),
        errorType: _truncate(_sanitize(error.runtimeType.toString()), 200),
        message: _truncate(_sanitize(error.toString()), _maxMessageLength),
        stackTrace: _truncate(
          _sanitize(stackTrace?.toString() ?? ''),
          _maxStackLength,
        ),
        context: sanitizedContext?.isEmpty ?? true ? null : sanitizedContext,
      ),
    );

    final firstIndex = entries.length > maxEntries
        ? entries.length - maxEntries
        : 0;

    final bounded = entries.sublist(firstIndex);

    await _writeEntries(bounded);
  }

  Future<List<DiagnosticEntry>> readRecent() async {
    final file = await _diagnosticFile();

    if (!await file.exists()) {
      return <DiagnosticEntry>[];
    }

    try {
      final raw = await file.readAsString();

      final decoded = jsonDecode(raw);

      if (decoded is! List<dynamic>) {
        return <DiagnosticEntry>[];
      }

      final entries = <DiagnosticEntry>[];

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        try {
          entries.add(DiagnosticEntry.fromJson(item));
        } catch (_) {
          // Ignore malformed individual entries.
        }
      }

      return entries;
    } catch (_) {
      return <DiagnosticEntry>[];
    }
  }

  Future<DiagnosticEntry?> readLatest() async {
    final entries = await readRecent();

    if (entries.isEmpty) {
      return null;
    }

    return entries.last;
  }

  Future<void> clear() async {
    final file = await _diagnosticFile();

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _diagnosticFile() async {
    final root = await _directoryProvider();

    final directory = Directory(p.join(root.path, 'diagnostics'));

    await directory.create(recursive: true);

    return File(p.join(directory.path, _fileName));
  }

  Future<void> _writeEntries(List<DiagnosticEntry> entries) async {
    final file = await _diagnosticFile();

    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await file.writeAsString(encoded, flush: true);
  }

  String _sanitize(String input) {
    var value = input;

    value = value.replaceAll(
      RegExp(r'bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
      'Bearer <redacted>',
    );

    value = value.replaceAllMapped(
      RegExp(
        r'\b(api[_-]?key|access[_-]?token|token|password|secret|authorization)\b\s*[:=]\s*([^\s,;]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=<redacted>',
    );

    value = value.replaceAll(
      RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
      '<redacted-email>',
    );

    value = value.replaceAll(
      RegExp(r'[A-Z]:\\Users\\[^\x5C\s]+\\', caseSensitive: false),
      'C:\\Users\\<redacted>\\',
    );

    value = value.replaceAll(RegExp(r'/Users/[^/\s]+/'), '/Users/<redacted>/');

    value = value.replaceAll(RegExp(r'/home/[^/\s]+/'), '/home/<redacted>/');

    return value;
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}â€¦';
  }
}
