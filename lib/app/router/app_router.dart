import 'package:go_router/go_router.dart';

import '../../features/bug_report/presentation/pages/bug_report_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/tasks/presentation/pages/task_editor_page.dart';
import '../shell/app_shell_page.dart';
import 'route_names.dart';
import 'route_paths.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      builder: (_, _) => const AppShellPage(),
    ),
    GoRoute(
      path: RoutePaths.focus,
      name: RouteNames.focus,
      builder: (_, _) => const AppShellPage(initialIndex: 1),
    ),
    GoRoute(
      path: RoutePaths.progress,
      name: RouteNames.progress,
      builder: (_, _) => const AppShellPage(initialIndex: 2),
    ),
    GoRoute(
      path: RoutePaths.newTask,
      name: RouteNames.newTask,
      builder: (_, _) => const TaskEditorPage(),
    ),
    GoRoute(
      path: RoutePaths.task,
      name: RouteNames.task,
      builder: (_, state) => TaskEditorPage(
        taskId: int.tryParse(state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: RoutePaths.bugReport,
      name: RouteNames.bugReport,
      builder: (_, _) => const BugReportPage(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      builder: (_, _) => const SettingsPage(),
    ),
  ],
);
