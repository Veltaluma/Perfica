import 'package:flutter/widgets.dart';

import '../core/services/diagnostic_recorder.dart';
import '../core/services/global_error_capture.dart';
import 'dependencies.dart';

Future<void> bootstrap(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();

  final diagnostics = DiagnosticRecorder();

  installGlobalErrorCapture(diagnostics);

  final Widget appWithDependencies = await provideAppDependencies(
    child: app,
    diagnosticRecorder: diagnostics,
  );

  runApp(appWithDependencies);
}
