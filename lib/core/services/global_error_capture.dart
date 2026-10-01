import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'diagnostic_recorder.dart';

typedef FlutterErrorCallback = void Function(FlutterErrorDetails details);

class GlobalErrorCapture {
  GlobalErrorCapture(this._recorder);

  final DiagnosticRecorder _recorder;

  final Set<Future<void>> _pendingRecords = <Future<void>>{};

  void captureFlutterError(FlutterErrorDetails details) {
    _recordBestEffort(
      details.exception,
      details.stack,
      context: details.context?.toDescription(),
    );
  }

  bool capturePlatformError(Object error, StackTrace stackTrace) {
    _recordBestEffort(error, stackTrace, context: 'platform.unhandled');

    return false;
  }

  void _recordBestEffort(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    final operation = _safeRecord(error, stackTrace, context: context);

    _pendingRecords.add(operation);

    unawaited(operation.whenComplete(() => _pendingRecords.remove(operation)));
  }

  Future<void> flush() async {
    while (_pendingRecords.isNotEmpty) {
      final pending = List<Future<void>>.of(_pendingRecords);

      await Future.wait(pending);
    }
  }

  Future<void> _safeRecord(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) async {
    try {
      await _recorder.recordError(error, stackTrace, context: context);
    } catch (_) {
      // Diagnostic recording must never create a second failure.
    }
  }
}

class GlobalErrorCaptureRegistration {
  GlobalErrorCaptureRegistration._({
    required this.capture,
    this._previousFlutterHandler,
    this._previousPlatformHandler,
  });

  final GlobalErrorCapture capture;

  final FlutterErrorCallback? _previousFlutterHandler;

  final ErrorCallback? _previousPlatformHandler;

  bool _disposed = false;

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    FlutterError.onError = _previousFlutterHandler;

    PlatformDispatcher.instance.onError = _previousPlatformHandler;
  }
}

GlobalErrorCaptureRegistration installGlobalErrorCapture(
  DiagnosticRecorder recorder,
) {
  final capture = GlobalErrorCapture(recorder);

  final previousFlutterHandler = FlutterError.onError;

  final previousPlatformHandler = PlatformDispatcher.instance.onError;

  FlutterError.onError = (FlutterErrorDetails details) {
    capture.captureFlutterError(details);

    final previous = previousFlutterHandler;

    if (previous != null) {
      previous(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    capture.capturePlatformError(error, stackTrace);

    final previous = previousPlatformHandler;

    if (previous != null) {
      return previous(error, stackTrace);
    }

    return false;
  };

  return GlobalErrorCaptureRegistration._(
    capture: capture,
    previousFlutterHandler: previousFlutterHandler,
    previousPlatformHandler: previousPlatformHandler,
  );
}
