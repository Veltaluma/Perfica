import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/services/diagnostic_recorder.dart';
import 'package:perfica/core/services/global_error_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late DiagnosticRecorder recorder;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('perfica_global_errors_test_');

    recorder = DiagnosticRecorder(
      directoryProvider: () async => root,
      now: () => DateTime.utc(2026, 9, 25, 15),
    );
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('captures Flutter framework errors', () async {
    final capture = GlobalErrorCapture(recorder);

    capture.captureFlutterError(
      FlutterErrorDetails(
        exception: StateError('widget failed'),
        stack: StackTrace.fromString('widget frame'),
        context: ErrorDescription('building report page'),
      ),
    );

    await capture.flush();

    final latest = await recorder.readLatest();

    expect(latest, isNotNull);

    expect(latest!.message, contains('widget failed'));

    expect(latest.stackTrace, contains('widget frame'));

    expect(latest.context, contains('building report page'));
  });

  test('captures platform errors without marking them handled', () async {
    final capture = GlobalErrorCapture(recorder);

    final handled = capture.capturePlatformError(
      Exception('async failed'),
      StackTrace.fromString('async frame'),
    );

    expect(handled, isFalse);

    await capture.flush();

    final latest = await recorder.readLatest();

    expect(latest, isNotNull);

    expect(latest!.message, contains('async failed'));

    expect(latest.context, 'platform.unhandled');
  });

  test('installation can restore previous global handlers', () {
    final originalFlutter = FlutterError.onError;

    final registration = installGlobalErrorCapture(recorder);

    expect(FlutterError.onError, isNot(same(originalFlutter)));

    registration.dispose();

    expect(FlutterError.onError, same(originalFlutter));
  });
}
