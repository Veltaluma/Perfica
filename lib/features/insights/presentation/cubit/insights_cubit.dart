import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../focus/data/focus_repository.dart';
import '../../../focus/data/focus_session.dart';
import '../../../tasks/domain/models/task_completion.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import 'insights_state.dart';

part 'insights_cubit_calculations.dart';

class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit(
    this._taskRepository,
    this._focusRepository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const InsightsState.initial()) {
    _completionSubscription = _taskRepository.watchCompletionHistory().listen(
      _onCompletions,
      onError: _onError,
    );

    _focusSubscription = _focusRepository.watchSessions().listen(
      _onFocusSessions,
      onError: _onError,
    );

    _scheduleDayRollover();
  }

  final TaskRepository _taskRepository;
  final FocusRepository _focusRepository;

  final DateTime Function() _now;

  StreamSubscription<List<TaskCompletion>>? _completionSubscription;

  StreamSubscription<List<FocusSession>>? _focusSubscription;

  Timer? _dayRolloverTimer;

  List<TaskCompletion> _completions = const [];

  List<FocusSession> _focusSessions = const [];

  bool _hasCompletionData = false;
  bool _hasFocusData = false;

  void _onCompletions(List<TaskCompletion> completions) {
    _completions = completions;
    _hasCompletionData = true;

    _recalculate();
  }

  void _onFocusSessions(List<FocusSession> sessions) {
    _focusSessions = sessions;
    _hasFocusData = true;

    _recalculate();
  }

  void _onError(Object error, StackTrace stackTrace) {
    emit(state.copyWith(status: InsightsStatus.failure));
  }

  void refreshForCurrentTime() {
    _recalculate();
  }

  void _scheduleDayRollover() {
    _dayRolloverTimer?.cancel();

    final now = _now();

    final nextDay = DateTime(now.year, now.month, now.day + 1);

    var delay = nextDay.difference(now);

    if (delay <= Duration.zero) {
      delay = const Duration(seconds: 1);
    }

    _dayRolloverTimer = Timer(delay, () {
      if (isClosed) {
        return;
      }

      _recalculate();
      _scheduleDayRollover();
    });
  }

  void _recalculate() {
    if (!_hasCompletionData || !_hasFocusData) {
      return;
    }

    emit(
      _buildInsightsState(
        completions: _completions,
        focusSessions: _focusSessions,
        now: _now(),
      ),
    );
  }

  @override
  Future<void> close() async {
    _dayRolloverTimer?.cancel();

    await _completionSubscription?.cancel();
    await _focusSubscription?.cancel();

    return super.close();
  }
}
