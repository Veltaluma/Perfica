// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Perfica';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navFocus => 'Focus';

  @override
  String get navInsights => 'Progress';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksEmptyTitle => 'No tasks yet';

  @override
  String get tasksEmptyDescription => 'Add your first task to get started.';

  @override
  String get quickAddHint => 'Add a task';

  @override
  String get quickAddAction => 'Add';

  @override
  String get taskDeleteTooltip => 'Delete task';

  @override
  String get taskCompletedSemantics => 'Completed';

  @override
  String get taskPendingSemantics => 'Not completed';

  @override
  String get taskLoadFailure => 'Unable to load tasks.';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get save => 'Save';

  @override
  String get moreOptions => 'More options';

  @override
  String get taskStatus => 'Status';

  @override
  String get automation => 'Automation';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get taskTitleHint => 'What needs to be done?';

  @override
  String get taskDescriptionHint => 'Add notes or context';

  @override
  String get priority => 'Priority';

  @override
  String get priorityNone => 'None';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get dueDate => 'Due date';

  @override
  String get recurrence => 'Repeat';

  @override
  String get repeatNone => 'Does not repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get reminder => 'Reminder';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'work, personal, study';

  @override
  String get attachments => 'Attachments';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get subtasks => 'Subtasks';

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get deleteSubtask => 'Delete subtask';

  @override
  String get deleteSubtaskConfirmationTitle => 'Delete this subtask?';

  @override
  String get deleteSubtaskConfirmationMessage =>
      'This subtask will be permanently removed.';

  @override
  String get saveTaskFirst => 'Save the task before adding subtasks.';

  @override
  String get taskSaveFailed => 'Unable to save the task.';

  @override
  String get switchToBoardView => 'Switch to board view';

  @override
  String get switchToListView => 'Switch to list view';

  @override
  String get boardTodo => 'To do';

  @override
  String get boardDone => 'Done';

  @override
  String get focusTitle => 'Focus';

  @override
  String get focusStart => 'Start';

  @override
  String get focusPause => 'Pause';

  @override
  String get focusReset => 'Reset';

  @override
  String get focusComplete => 'Focus session complete.';

  @override
  String get insightsTitle => 'Progress';

  @override
  String get insightsLoadFailure => 'Unable to load progress.';

  @override
  String get progressToday => 'Today';

  @override
  String get progressConsistency => 'Consistency';

  @override
  String get progressRecentActivity => 'Recent activity';

  @override
  String get progressMoreDetails => 'More details';

  @override
  String get progressLifetime => 'Lifetime';

  @override
  String get currentStreak => 'Current streak';

  @override
  String streakDays(int days) {
    return '$days days';
  }

  @override
  String get bestDay => 'Best day';

  @override
  String get noBestDayYet => 'No completed tasks in the last 7 days';

  @override
  String bestDayValue(String day, int count) {
    return '$day Â· $count tasks';
  }

  @override
  String get dailyAverage => 'Daily average';

  @override
  String dailyAverageValue(String tasks, String minutes) {
    return '$tasks tasks Â· $minutes min focus';
  }

  @override
  String get weekOverWeek => 'Week over week';

  @override
  String get tasksChange => 'Tasks';

  @override
  String get focusChange => 'Focus';

  @override
  String get noPreviousWeekData => 'No previous week data';

  @override
  String get thisWeek => 'This week';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get thisMonth => 'This month';

  @override
  String tasksCompletedValue(int count) {
    return '$count tasks completed';
  }

  @override
  String focusMinutesValue(int minutes) {
    return '$minutes minutes focused';
  }

  @override
  String get tasksCompletedTrend => 'Tasks completed';

  @override
  String get focusMinutesTrend => 'Focus minutes';

  @override
  String get focusTime => 'Focus time';

  @override
  String focusTimeMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceDescription => 'Theme and display preferences';

  @override
  String get settingsNotificationsDescription =>
      'Permissions, reminder sound, and vibration';

  @override
  String get settingsDataBackupTitle => 'Data & backup';

  @override
  String get settingsDataBackupDescription =>
      'Export or restore your local data';

  @override
  String get settingsHelpFeedbackTitle => 'Help & feedback';

  @override
  String get settingsHelpFeedbackDescription =>
      'Report problems and send feedback';

  @override
  String get settingsAboutDescription =>
      'Version, updates, and app information';

  @override
  String get settingsThemeDescription =>
      'Choose how Perfica follows your device appearance.';

  @override
  String get settingsExportBackupDescription =>
      'Save a portable copy of your Perfica data.';

  @override
  String get settingsRestoreBackupDescription =>
      'Restore Perfica data from a backup file.';

  @override
  String get settingsCheckUpdatesDescription =>
      'Check for a newer official release.';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get dataSection => 'Data';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get backupRestored =>
      'Backup restored. Restart Perfica to refresh all screens.';

  @override
  String get backupFailed => 'Backup operation failed.';

  @override
  String get updateSection => 'Updates';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get upToDate => 'No newer official release was found.';

  @override
  String get updateAvailable => 'A newer release is available.';

  @override
  String get updateUnavailable =>
      'Update check is unavailable until the official GitHub repository has releases.';

  @override
  String get notifications => 'Notifications';

  @override
  String get requestNotificationPermission => 'Enable notifications';

  @override
  String get notificationsRequested =>
      'Notification permission request completed.';

  @override
  String get about => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get searchTasks => 'Search tasks';

  @override
  String get newTaskTooltip => 'Create detailed task';

  @override
  String get notSet => 'Not set';

  @override
  String get boardInProgress => 'In progress';

  @override
  String get customMinutes => 'Custom minutes';

  @override
  String get focusDuration => 'Focus duration';

  @override
  String get completedTasks => 'Completed';

  @override
  String get minutesLabel => 'minutes';

  @override
  String get apply => 'Apply';

  @override
  String get activeTasks => 'Active';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearCompletedMessage =>
      'Completed tasks will be removed from the task list. Productivity history will be kept.';

  @override
  String get clearCompletedTitle => 'Clear completed tasks?';

  @override
  String get statusDone => 'Done';

  @override
  String get focusDurationTooShort =>
      'Focus duration must be at least 1 minute.';

  @override
  String get clear => 'Clear';

  @override
  String get focusDurationInvalid => 'Enter a valid number of minutes.';

  @override
  String get customFocusDuration => 'Custom focus duration';

  @override
  String get focusDurationRange => 'Enter a duration from 1 to 720 minutes.';

  @override
  String get workflowStatus => 'Status';

  @override
  String get clearCompleted => 'Clear completed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get completeAllActive => 'Complete all active';

  @override
  String get taskActions => 'Task actions';

  @override
  String get stopRepeating => 'Stop repeating';

  @override
  String get completeForever => 'Complete forever';

  @override
  String get repeatingStoppedFeedback => 'Repeating stopped';

  @override
  String get completedForeverFeedback => 'Completed forever';

  @override
  String get completeForeverConfirmationTitle => 'Complete this task forever?';

  @override
  String get completeForeverConfirmationMessage =>
      'This ends the repeating task permanently. Its recurrence and remaining reminders will be removed.';

  @override
  String get statusTodo => 'To do';

  @override
  String get focusDurationTooLong => 'Maximum focus duration is 720 minutes.';

  @override
  String get taskTitleRequired => 'Title is required.';

  @override
  String get organization => 'Organization';

  @override
  String subtaskProgress(int completed, int total) {
    return '$completed of $total subtasks';
  }

  @override
  String get taskDetails => 'Task details';

  @override
  String get schedule => 'Schedule';

  @override
  String get pomodoroFocusNotificationTitle => 'Focus complete';

  @override
  String get pomodoroBreakNotificationBody =>
      'Your break is finished. Start the next focus session when you are ready.';

  @override
  String get pomodoroBreakNotificationTitle => 'Break complete';

  @override
  String get pomodoroLongBreak => 'Long break';

  @override
  String get pomodoroShortBreak => 'Short break';

  @override
  String pomodoroSession(int current, int total) {
    return 'Session $current of $total';
  }

  @override
  String get pomodoroFocusDone => 'Focus session complete. Time for a break.';

  @override
  String get pomodoroTechnique => 'Pomodoro';

  @override
  String get pomodoroFocus => 'Focus';

  @override
  String get pomodoroBreakDone => 'Break complete. Ready to focus?';

  @override
  String get pomodoroFocusNotificationBody =>
      'Your focus session is finished. Take a break.';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get notificationPermissionDenied =>
      'Notification permission is disabled. You can enable it in system settings.';

  @override
  String get openSystemSettings => 'Open system settings';

  @override
  String get developerBy => 'by Veltaluma';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get pomodoroSkipPhase => 'Skip';

  @override
  String get pomodoroRunning => 'Running';

  @override
  String get pomodoroLongBreakLength => 'Long break';

  @override
  String get pomodoroShortBreakLength => 'Short break';

  @override
  String pomodoroCycleProgress(int completed, int total) {
    return '$completed of $total focus sessions';
  }

  @override
  String get pomodoroReady => 'Ready';

  @override
  String get pomodoroResetCycle => 'Reset cycle';

  @override
  String get pomodoroPaused => 'Paused';

  @override
  String get pomodoroFocusLength => 'Focus';

  @override
  String get minuteLabel => 'minute';

  @override
  String get focusResume => 'Resume';

  @override
  String pomodoroBreakAfterSession(int current, int total) {
    return 'After focus $current of $total';
  }

  @override
  String get pomodoroFocusSkipped => 'Focus skipped';

  @override
  String get pomodoroSettings => 'Pomodoro';

  @override
  String get focusSettingsTitle => 'Focus settings';

  @override
  String get focusSettingsTooltip => 'Open focus settings';

  @override
  String get focusSettingsDurations => 'Durations';

  @override
  String get focusSettingsAutomation => 'Automation';

  @override
  String get focusSettingsFeedback => 'Feedback';

  @override
  String get pomodoroAutoStartFocus => 'Auto-start focus';

  @override
  String pomodoroSessionsLabel(int count) {
    return '$count sessions';
  }

  @override
  String get pomodoroCompletionSound => 'Completion sound';

  @override
  String get pomodoroVibration => 'Vibration';

  @override
  String get pomodoroFocusDuration => 'Focus duration';

  @override
  String get pomodoroInvalidValue => 'Enter a valid value.';

  @override
  String get pomodoroSessionsRange => 'Enter a value from 1 to 12.';

  @override
  String get pomodoroBreakMinutesRange =>
      'Enter a duration from 1 to 180 minutes.';

  @override
  String get pomodoroSessionsPerCycle => 'Focus sessions per cycle';

  @override
  String get pomodoroLongBreakDuration => 'Long break duration';

  @override
  String get pomodoroMinutesRange => 'Enter a duration from 1 to 720 minutes.';

  @override
  String get pomodoroSettingsDescription =>
      'Customize your focus and break cycle.';

  @override
  String get pomodoroShortBreakDuration => 'Short break duration';

  @override
  String get pomodoroAutoStartBreaks => 'Auto-start breaks';

  @override
  String get pomodoroNotificationsRequired =>
      'Enable notifications to use completion sound and vibration.';

  @override
  String moreSubtasks(int count) {
    return '+$count more';
  }

  @override
  String get complete => 'Complete';

  @override
  String get editTaskTooltip => 'Edit task';

  @override
  String get completeAllActiveMessage =>
      'All active tasks will be marked as completed.';

  @override
  String get recurringOccurrenceCompleted =>
      'Completed. Next occurrence scheduled.';

  @override
  String get deleteTaskConfirmationTitle => 'Delete this task?';

  @override
  String get deleteTaskConfirmationMessage =>
      'This task will be removed from Perfica.';

  @override
  String get completeAllActiveTitle => 'Complete all active tasks?';

  @override
  String get deleteTask => 'Delete';

  @override
  String get taskRemindersDescription => 'Choose how task reminders alert you.';

  @override
  String get taskReminderSoundDescription =>
      'Play a sound when a task reminder arrives.';

  @override
  String get taskReminderVibrationDescription =>
      'Vibrate for task reminders on Android. On iOS, vibration follows system notification settings.';

  @override
  String get taskReminderVibration => 'Vibration';

  @override
  String get taskReminders => 'Task reminders';

  @override
  String get taskReminderSound => 'Sound';

  @override
  String get reminderRepeat => 'Repeat reminder';

  @override
  String get reminderRepeatOnce => 'Once';

  @override
  String get reminderRepeatEvery5Minutes => 'Every 5 minutes';

  @override
  String get reminderRepeatEvery10Minutes => 'Every 10 minutes';

  @override
  String get reminderRepeatEvery15Minutes => 'Every 15 minutes';

  @override
  String get reminderRepeatEvery30Minutes => 'Every 30 minutes';

  @override
  String get reminderRepeatFiveAlertsDescription =>
      'Perfica will alert up to 5 times for this occurrence.';

  @override
  String get taskReminderDoneAction => 'Done';

  @override
  String get taskReminderSnooze10Action => 'Snooze 10m';

  @override
  String get taskCompletedFeedback => 'Completed';

  @override
  String get undo => 'Undo';

  @override
  String get openAction => 'Open';

  @override
  String get settingsLoadFailure => 'Some settings could not be loaded.';

  @override
  String get support => 'Support';

  @override
  String get reportBug => 'Report a bug';

  @override
  String get reportBugDescription =>
      'Tell us what went wrong and review diagnostics before sending.';

  @override
  String get bugReportTitle => 'Bug title';

  @override
  String get bugReportTitleHint => 'Briefly describe the problem';

  @override
  String get bugReportDescriptionLabel => 'What happened?';

  @override
  String get bugReportDescriptionHint =>
      'Describe what you saw and why it was a problem.';

  @override
  String get bugReportSteps => 'Steps to reproduce';

  @override
  String get bugReportStepsHint => 'List the steps that caused the problem.';

  @override
  String get bugReportExpected => 'Expected behavior';

  @override
  String get bugReportExpectedHint => 'What did you expect Perfica to do?';

  @override
  String get bugReportContact => 'Contact (optional)';

  @override
  String get bugReportContactHint => 'Email or another contact method';

  @override
  String get bugReportDiagnostics => 'Diagnostics';

  @override
  String get bugReportDiagnosticsPrivacy =>
      'Diagnostics stay on this device until you choose to send a report. Review them before submission.';

  @override
  String get bugReportNoDiagnostics =>
      'No recent diagnostic errors were recorded.';

  @override
  String get bugReportIncludeDiagnostics => 'Include recent diagnostics';

  @override
  String get bugReportIncludeDiagnosticsDescription =>
      'Attach up to the three most recent locally recorded errors.';

  @override
  String get bugReportRequired => 'This field is required.';

  @override
  String get bugReportReview => 'Review report';

  @override
  String get bugReportReviewTitle => 'Review bug report';

  @override
  String get bugReportReviewDescription =>
      'Check the information below before sending the report.';

  @override
  String get bugReportDiagnosticsExcluded => 'Not included';

  @override
  String get bugReportDiagnosticContext => 'Context';

  @override
  String get close => 'Close';

  @override
  String bugReportDiagnosticsIncluded(int count) {
    return '$count diagnostic entries included';
  }

  @override
  String bugReportDiagnosticRecordedAt(String time) {
    return 'Recorded: $time';
  }

  @override
  String get bugReportDiagnosticInformation => 'Diagnostic information';

  @override
  String get bugReportEnvironmentStillIncluded =>
      'App, OS, and device information will still be included.';

  @override
  String get bugReportSend => 'Send report';

  @override
  String get bugReportSending => 'Sending report...';

  @override
  String get bugReportSentTitle => 'Bug report sent';

  @override
  String get bugReportSentDescription =>
      'Thank you. Your report was submitted successfully.';

  @override
  String get bugReportOpenIssue => 'Open issue';

  @override
  String get bugReportUnknown => 'Unknown';

  @override
  String bugReportAppVersion(String value) {
    return 'App version: $value';
  }

  @override
  String bugReportPlatform(String value) {
    return 'Platform: $value';
  }

  @override
  String bugReportOsVersion(String value) {
    return 'OS version: $value';
  }

  @override
  String bugReportDevice(String value) {
    return 'Device: $value';
  }

  @override
  String bugReportLocale(String value) {
    return 'Locale: $value';
  }

  @override
  String get bugReportRecentErrorsNone => 'Recent errors: None included';

  @override
  String bugReportRecentErrorsIncluded(int count) {
    return 'Recent errors: $count included';
  }

  @override
  String bugReportReportNumber(String id) {
    return 'Report #$id';
  }

  @override
  String get bugReportSubmitFailed =>
      'Could not send the bug report. Please try again.';

  @override
  String bugReportSubmitFailedHttp(int status) {
    return 'Could not send the bug report (HTTP $status). Please try again.';
  }
}
