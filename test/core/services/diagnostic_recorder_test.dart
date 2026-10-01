import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/services/diagnostic_recorder.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('perfica_diagnostics_test_');
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  DiagnosticRecorder createRecorder({int maxEntries = 25, DateTime? now}) {
    return DiagnosticRecorder(
      directoryProvider: () async => root,
      maxEntries: maxEntries,
      now: () => now ?? DateTime.utc(2026, 9, 25, 12),
    );
  }

  test('records diagnostics and survives a new recorder instance', () async {
    final recorder = createRecorder();

    await recorder.recordError(
      StateError('Example failure'),
      StackTrace.fromString('frame one\nframe two'),
      context: 'settings.bootstrap',
    );

    final secondRecorder = createRecorder();

    final entries = await secondRecorder.readRecent();

    expect(entries, hasLength(1));

    expect(entries.single.errorType, 'StateError');

    expect(entries.single.message, contains('Example failure'));

    expect(entries.single.stackTrace, contains('frame one'));

    expect(entries.single.context, 'settings.bootstrap');
  });

  test('keeps only the newest configured number of entries', () async {
    final recorder = createRecorder(maxEntries: 2);

    await recorder.recordError(Exception('first'), StackTrace.empty);

    await recorder.recordError(Exception('second'), StackTrace.empty);

    await recorder.recordError(Exception('third'), StackTrace.empty);

    final entries = await recorder.readRecent();

    expect(entries, hasLength(2));

    expect(entries.first.message, contains('second'));

    expect(entries.last.message, contains('third'));
  });

  test('redacts common sensitive values before persistence', () async {
    final recorder = createRecorder();

    await recorder.recordError(
      Exception(
        'email=user@example.com '
        'api_key=abc123 '
        'Bearer very-secret-token '
        r'C:\Users\Isa\project\main.dart',
      ),
      StackTrace.fromString('/home/isa/project/main.dart:1'),
    );

    final entry = (await recorder.readRecent()).single;

    expect(entry.message, isNot(contains('user@example.com')));

    expect(entry.message, isNot(contains('abc123')));

    expect(entry.message, isNot(contains('very-secret-token')));

    expect(entry.message, contains(r'C:\Users\<redacted>\'));

    expect(entry.stackTrace, contains('/home/<redacted>/'));
  });

  test('returns an empty list when stored diagnostics are malformed', () async {
    final diagnosticsDirectory = Directory(
      '${root.path}'
      '${Platform.pathSeparator}'
      'diagnostics',
    );

    await diagnosticsDirectory.create(recursive: true);

    final file = File(
      '${diagnosticsDirectory.path}'
      '${Platform.pathSeparator}'
      'diagnostics_v1.json',
    );

    await file.writeAsString('{not-json');

    final recorder = createRecorder();

    expect(await recorder.readRecent(), isEmpty);
  });
}
