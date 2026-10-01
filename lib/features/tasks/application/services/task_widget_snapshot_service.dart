import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/task.dart';
import '../../domain/models/task_workflow_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/task_extras_repository.dart';
import 'task_widget_background.dart';
import 'task_widget_editor.dart';

const MethodChannel _taskWidgetChannel = MethodChannel(
  'com.veltaluma.perfica/task_widget',
);

const String _snapshotFileName = 'perfica_task_widget_snapshot.json';

const String _editorCallbackFileName =
    'perfica_task_widget_editor_callback.txt';

const String _backgroundCallbackFileName =
    'perfica_task_widget_background_callback.txt';

Map<String, dynamic> buildTaskWidgetPayload(List<Task> tasks) {
  final active = tasks
      .where((task) => task.workflowStatus != TaskWorkflowStatus.done)
      .map(_taskToJson)
      .toList(growable: false);

  final completedTasks =
      tasks
          .where((task) => task.workflowStatus == TaskWorkflowStatus.done)
          .toList(growable: false)
        ..sort((a, b) {
          final aTime = a.completedAt ?? a.updatedAt;
          final bTime = b.completedAt ?? b.updatedAt;

          return bTime.compareTo(aTime);
        });

  return <String, dynamic>{
    'version': 1,
    'generatedAt': DateTime.now().toIso8601String(),
    'active': active,
    'completed': completedTasks.map(_taskToJson).toList(growable: false),
  };
}

Map<String, dynamic> _taskToJson(Task task) {
  return <String, dynamic>{
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'priority': task.priority.name,
    'workflowStatus': task.workflowStatus.name,
    'dueAt': task.dueAt?.toIso8601String(),
    'completedAt': task.completedAt?.toIso8601String(),
  };
}

Future<void> _writeCallbackHandle(
  String fileName,
  Function callbackFunction,
) async {
  final callback = PluginUtilities.getCallbackHandle(callbackFunction);

  if (callback == null) {
    return;
  }

  final directory = await getApplicationSupportDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');

  await file.writeAsString(
    callback.toRawHandle().toString(),
    encoding: utf8,
    flush: true,
  );
}

Future<void> publishTaskWidgetCallbackHandles() async {
  try {
    await Future.wait<void>([
      _writeCallbackHandle(
        _editorCallbackFileName,
        taskWidgetEditorCallbackMain,
      ),
      _writeCallbackHandle(
        _backgroundCallbackFileName,
        taskWidgetBackgroundCallbackMain,
      ),
    ]);
  } catch (_) {
    // Widget data must remain usable even if callback registration is
    // temporarily unavailable. Opening Perfica again retries registration.
  }
}

class TaskWidgetSnapshotService {
  TaskWidgetSnapshotService(this._repository, [this._extrasRepository]) {
    unawaited(publishTaskWidgetCallbackHandles());

    if (!_supportedPlatform) {
      return;
    }

    _subscription = _repository.watchTasks().listen((tasks) {
      final extrasRepository = _extrasRepository;

      if (extrasRepository == null) {
        unawaited(publishTasks(tasks));
        return;
      }

      unawaited(
        publishRepository(
          _repository,
          extrasRepository: extrasRepository,
          tasks: tasks,
        ),
      );
    });
  }

  final TaskRepository _repository;
  final TaskExtrasRepository? _extrasRepository;

  StreamSubscription<List<Task>>? _subscription;

  static bool get _supportedPlatform {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<String> _resolveDirectoryPath({String? directoryPath}) async {
    if (directoryPath != null && directoryPath.isNotEmpty) {
      return directoryPath;
    }

    final directory = await getApplicationSupportDirectory();

    return directory.path;
  }

  static Future<void> publishTasks(
    List<Task> tasks, {
    String? directoryPath,
    Map<int, Map<String, dynamic>>? detailsByTaskId,
  }) async {
    if (!_supportedPlatform) {
      return;
    }

    final payloadData = buildTaskWidgetPayload(tasks);

    if (detailsByTaskId != null) {
      for (final listName in const <String>['active', 'completed']) {
        final rawItems = payloadData[listName];

        if (rawItems is! List) {
          continue;
        }

        for (final rawItem in rawItems) {
          if (rawItem is! Map<String, dynamic>) {
            continue;
          }

          final taskId = rawItem['id'];

          if (taskId is! int) {
            continue;
          }

          final details = detailsByTaskId[taskId];

          if (details != null) {
            rawItem.addAll(details);
          }
        }
      }
    }

    final payload = jsonEncode(payloadData);
    final directory = await _resolveDirectoryPath(directoryPath: directoryPath);

    final target = File(
      '$directory${Platform.pathSeparator}$_snapshotFileName',
    );

    final temp = File('${target.path}.tmp');

    await temp.writeAsString(payload, encoding: utf8, flush: true);

    if (await target.exists()) {
      await target.delete();
    }

    try {
      await temp.rename(target.path);
    } on FileSystemException {
      await target.writeAsString(payload, encoding: utf8, flush: true);

      if (await temp.exists()) {
        await temp.delete();
      }
    }

    try {
      await _taskWidgetChannel.invokeMethod<void>('refresh');
    } on MissingPluginException {
      // Headless callback has no UI Activity bridge. Native background runner
      // refreshes the widget after the Dart callback reports completion.
    } on PlatformException {
      // Snapshot persistence is authoritative. A later widget lifecycle event
      // can refresh from the persisted snapshot.
    }
  }

  static Future<void> publishRepository(
    TaskRepository repository, {
    TaskExtrasRepository? extrasRepository,
    String? directoryPath,
    List<Task>? tasks,
  }) async {
    if (!_supportedPlatform) {
      return;
    }

    final currentTasks = tasks ?? await repository.watchTasks().first;

    if (extrasRepository == null) {
      await publishTasks(currentTasks, directoryPath: directoryPath);
      return;
    }

    final detailsByTaskId = <int, Map<String, dynamic>>{};

    for (final task in currentTasks) {
      final extras = await extrasRepository.getExtras(task.id);

      final subtasks = await repository.watchSubtasks(task.id).first;

      detailsByTaskId[task.id] = <String, dynamic>{
        'recurrence': extras.recurrence,

        'monthlyAnchorDay': extras.monthlyAnchorDay,

        'reminderAt': extras.reminderAt?.toIso8601String(),

        'reminderRepeatMinutes': extras.reminderRepeatMinutes,

        'reminderSnoozedUntil': extras.reminderSnoozedUntil?.toIso8601String(),

        'tags': extras.tags,

        'attachments': extras.attachments,

        'subtasks': subtasks
            .map(
              (subtask) => <String, dynamic>{
                'id': subtask.id,
                'title': subtask.title,
                'isCompleted': subtask.isCompleted,
              },
            )
            .toList(growable: false),
      };
    }

    await publishTasks(
      currentTasks,
      directoryPath: directoryPath,
      detailsByTaskId: detailsByTaskId,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
