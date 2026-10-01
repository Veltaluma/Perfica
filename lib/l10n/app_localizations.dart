import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Perfica'**
  String get appName;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get navFocus;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navInsights;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @tasksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmptyTitle;

  /// No description provided for @tasksEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first task to get started.'**
  String get tasksEmptyDescription;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get quickAddHint;

  /// No description provided for @quickAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get quickAddAction;

  /// No description provided for @taskDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get taskDeleteTooltip;

  /// No description provided for @taskCompletedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskCompletedSemantics;

  /// No description provided for @taskPendingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get taskPendingSemantics;

  /// No description provided for @taskLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tasks.'**
  String get taskLoadFailure;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @taskStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get taskStatus;

  /// No description provided for @automation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get automation;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskTitleHint;

  /// No description provided for @taskDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes or context'**
  String get taskDescriptionHint;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get priorityNone;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurrence;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'work, personal, study'**
  String get tagsHint;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get addSubtask;

  /// No description provided for @deleteSubtask.
  ///
  /// In en, this message translates to:
  /// **'Delete subtask'**
  String get deleteSubtask;

  /// No description provided for @deleteSubtaskConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this subtask?'**
  String get deleteSubtaskConfirmationTitle;

  /// No description provided for @deleteSubtaskConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'This subtask will be permanently removed.'**
  String get deleteSubtaskConfirmationMessage;

  /// No description provided for @saveTaskFirst.
  ///
  /// In en, this message translates to:
  /// **'Save the task before adding subtasks.'**
  String get saveTaskFirst;

  /// No description provided for @taskSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the task.'**
  String get taskSaveFailed;

  /// No description provided for @switchToBoardView.
  ///
  /// In en, this message translates to:
  /// **'Switch to board view'**
  String get switchToBoardView;

  /// No description provided for @switchToListView.
  ///
  /// In en, this message translates to:
  /// **'Switch to list view'**
  String get switchToListView;

  /// No description provided for @boardTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get boardTodo;

  /// No description provided for @boardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get boardDone;

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// No description provided for @focusStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get focusStart;

  /// No description provided for @focusPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get focusPause;

  /// No description provided for @focusReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get focusReset;

  /// No description provided for @focusComplete.
  ///
  /// In en, this message translates to:
  /// **'Focus session complete.'**
  String get focusComplete;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get insightsTitle;

  /// No description provided for @insightsLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to load progress.'**
  String get insightsLoadFailure;

  /// No description provided for @progressToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get progressToday;

  /// No description provided for @progressConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get progressConsistency;

  /// No description provided for @progressRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get progressRecentActivity;

  /// No description provided for @progressMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get progressMoreDetails;

  /// No description provided for @progressLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get progressLifetime;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String streakDays(int days);

  /// No description provided for @bestDay.
  ///
  /// In en, this message translates to:
  /// **'Best day'**
  String get bestDay;

  /// No description provided for @noBestDayYet.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks in the last 7 days'**
  String get noBestDayYet;

  /// No description provided for @bestDayValue.
  ///
  /// In en, this message translates to:
  /// **'{day} Â· {count} tasks'**
  String bestDayValue(String day, int count);

  /// No description provided for @dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily average'**
  String get dailyAverage;

  /// No description provided for @dailyAverageValue.
  ///
  /// In en, this message translates to:
  /// **'{tasks} tasks Â· {minutes} min focus'**
  String dailyAverageValue(String tasks, String minutes);

  /// No description provided for @weekOverWeek.
  ///
  /// In en, this message translates to:
  /// **'Week over week'**
  String get weekOverWeek;

  /// No description provided for @tasksChange.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksChange;

  /// No description provided for @focusChange.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusChange;

  /// No description provided for @noPreviousWeekData.
  ///
  /// In en, this message translates to:
  /// **'No previous week data'**
  String get noPreviousWeekData;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @tasksCompletedValue.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks completed'**
  String tasksCompletedValue(int count);

  /// No description provided for @focusMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes focused'**
  String focusMinutesValue(int minutes);

  /// No description provided for @tasksCompletedTrend.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed'**
  String get tasksCompletedTrend;

  /// No description provided for @focusMinutesTrend.
  ///
  /// In en, this message translates to:
  /// **'Focus minutes'**
  String get focusMinutesTrend;

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get focusTime;

  /// No description provided for @focusTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String focusTimeMinutes(int minutes);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Theme and display preferences'**
  String get settingsAppearanceDescription;

  /// No description provided for @settingsNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Permissions, reminder sound, and vibration'**
  String get settingsNotificationsDescription;

  /// No description provided for @settingsDataBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & backup'**
  String get settingsDataBackupTitle;

  /// No description provided for @settingsDataBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Export or restore your local data'**
  String get settingsDataBackupDescription;

  /// No description provided for @settingsHelpFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get settingsHelpFeedbackTitle;

  /// No description provided for @settingsHelpFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Report problems and send feedback'**
  String get settingsHelpFeedbackDescription;

  /// No description provided for @settingsAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Version, updates, and app information'**
  String get settingsAboutDescription;

  /// No description provided for @settingsThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how Perfica follows your device appearance.'**
  String get settingsThemeDescription;

  /// No description provided for @settingsExportBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Save a portable copy of your Perfica data.'**
  String get settingsExportBackupDescription;

  /// No description provided for @settingsRestoreBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Restore Perfica data from a backup file.'**
  String get settingsRestoreBackupDescription;

  /// No description provided for @settingsCheckUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Check for a newer official release.'**
  String get settingsCheckUpdatesDescription;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Restart Perfica to refresh all screens.'**
  String get backupRestored;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup operation failed.'**
  String get backupFailed;

  /// No description provided for @updateSection.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updateSection;

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'No newer official release was found.'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A newer release is available.'**
  String get updateAvailable;

  /// No description provided for @updateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Update check is unavailable until the official GitHub repository has releases.'**
  String get updateUnavailable;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @requestNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get requestNotificationPermission;

  /// No description provided for @notificationsRequested.
  ///
  /// In en, this message translates to:
  /// **'Notification permission request completed.'**
  String get notificationsRequested;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @newTaskTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create detailed task'**
  String get newTaskTooltip;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @boardInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get boardInProgress;

  /// No description provided for @customMinutes.
  ///
  /// In en, this message translates to:
  /// **'Custom minutes'**
  String get customMinutes;

  /// No description provided for @focusDuration.
  ///
  /// In en, this message translates to:
  /// **'Focus duration'**
  String get focusDuration;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesLabel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @activeTasks.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTasks;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clearCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks will be removed from the task list. Productivity history will be kept.'**
  String get clearCompletedMessage;

  /// No description provided for @clearCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear completed tasks?'**
  String get clearCompletedTitle;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @focusDurationTooShort.
  ///
  /// In en, this message translates to:
  /// **'Focus duration must be at least 1 minute.'**
  String get focusDurationTooShort;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @focusDurationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number of minutes.'**
  String get focusDurationInvalid;

  /// No description provided for @customFocusDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom focus duration'**
  String get customFocusDuration;

  /// No description provided for @focusDurationRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a duration from 1 to 720 minutes.'**
  String get focusDurationRange;

  /// No description provided for @workflowStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get workflowStatus;

  /// No description provided for @clearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get clearCompleted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @completeAllActive.
  ///
  /// In en, this message translates to:
  /// **'Complete all active'**
  String get completeAllActive;

  /// No description provided for @taskActions.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get taskActions;

  /// No description provided for @stopRepeating.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get stopRepeating;

  /// No description provided for @completeForever.
  ///
  /// In en, this message translates to:
  /// **'Complete forever'**
  String get completeForever;

  /// No description provided for @repeatingStoppedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Repeating stopped'**
  String get repeatingStoppedFeedback;

  /// No description provided for @completedForeverFeedback.
  ///
  /// In en, this message translates to:
  /// **'Completed forever'**
  String get completedForeverFeedback;

  /// No description provided for @completeForeverConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete this task forever?'**
  String get completeForeverConfirmationTitle;

  /// No description provided for @completeForeverConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'This ends the repeating task permanently. Its recurrence and remaining reminders will be removed.'**
  String get completeForeverConfirmationMessage;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// No description provided for @focusDurationTooLong.
  ///
  /// In en, this message translates to:
  /// **'Maximum focus duration is 720 minutes.'**
  String get focusDurationTooLong;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get taskTitleRequired;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @subtaskProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} subtasks'**
  String subtaskProgress(int completed, int total);

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get taskDetails;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @pomodoroFocusNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus complete'**
  String get pomodoroFocusNotificationTitle;

  /// No description provided for @pomodoroBreakNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your break is finished. Start the next focus session when you are ready.'**
  String get pomodoroBreakNotificationBody;

  /// No description provided for @pomodoroBreakNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Break complete'**
  String get pomodoroBreakNotificationTitle;

  /// No description provided for @pomodoroLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get pomodoroLongBreak;

  /// No description provided for @pomodoroShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get pomodoroShortBreak;

  /// No description provided for @pomodoroSession.
  ///
  /// In en, this message translates to:
  /// **'Session {current} of {total}'**
  String pomodoroSession(int current, int total);

  /// No description provided for @pomodoroFocusDone.
  ///
  /// In en, this message translates to:
  /// **'Focus session complete. Time for a break.'**
  String get pomodoroFocusDone;

  /// No description provided for @pomodoroTechnique.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoroTechnique;

  /// No description provided for @pomodoroFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get pomodoroFocus;

  /// No description provided for @pomodoroBreakDone.
  ///
  /// In en, this message translates to:
  /// **'Break complete. Ready to focus?'**
  String get pomodoroBreakDone;

  /// No description provided for @pomodoroFocusNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your focus session is finished. Take a break.'**
  String get pomodoroFocusNotificationBody;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is disabled. You can enable it in system settings.'**
  String get notificationPermissionDenied;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get openSystemSettings;

  /// No description provided for @developerBy.
  ///
  /// In en, this message translates to:
  /// **'by Veltaluma'**
  String get developerBy;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @pomodoroSkipPhase.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get pomodoroSkipPhase;

  /// No description provided for @pomodoroRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get pomodoroRunning;

  /// No description provided for @pomodoroLongBreakLength.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get pomodoroLongBreakLength;

  /// No description provided for @pomodoroShortBreakLength.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get pomodoroShortBreakLength;

  /// No description provided for @pomodoroCycleProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} focus sessions'**
  String pomodoroCycleProgress(int completed, int total);

  /// No description provided for @pomodoroReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get pomodoroReady;

  /// No description provided for @pomodoroResetCycle.
  ///
  /// In en, this message translates to:
  /// **'Reset cycle'**
  String get pomodoroResetCycle;

  /// No description provided for @pomodoroPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pomodoroPaused;

  /// No description provided for @pomodoroFocusLength.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get pomodoroFocusLength;

  /// No description provided for @minuteLabel.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minuteLabel;

  /// No description provided for @focusResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get focusResume;

  /// No description provided for @pomodoroBreakAfterSession.
  ///
  /// In en, this message translates to:
  /// **'After focus {current} of {total}'**
  String pomodoroBreakAfterSession(int current, int total);

  /// No description provided for @pomodoroFocusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Focus skipped'**
  String get pomodoroFocusSkipped;

  /// No description provided for @pomodoroSettings.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoroSettings;

  /// No description provided for @focusSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus settings'**
  String get focusSettingsTitle;

  /// No description provided for @focusSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open focus settings'**
  String get focusSettingsTooltip;

  /// No description provided for @focusSettingsDurations.
  ///
  /// In en, this message translates to:
  /// **'Durations'**
  String get focusSettingsDurations;

  /// No description provided for @focusSettingsAutomation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get focusSettingsAutomation;

  /// No description provided for @focusSettingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get focusSettingsFeedback;

  /// No description provided for @pomodoroAutoStartFocus.
  ///
  /// In en, this message translates to:
  /// **'Auto-start focus'**
  String get pomodoroAutoStartFocus;

  /// No description provided for @pomodoroSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String pomodoroSessionsLabel(int count);

  /// No description provided for @pomodoroCompletionSound.
  ///
  /// In en, this message translates to:
  /// **'Completion sound'**
  String get pomodoroCompletionSound;

  /// No description provided for @pomodoroVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get pomodoroVibration;

  /// No description provided for @pomodoroFocusDuration.
  ///
  /// In en, this message translates to:
  /// **'Focus duration'**
  String get pomodoroFocusDuration;

  /// No description provided for @pomodoroInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value.'**
  String get pomodoroInvalidValue;

  /// No description provided for @pomodoroSessionsRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from 1 to 12.'**
  String get pomodoroSessionsRange;

  /// No description provided for @pomodoroBreakMinutesRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a duration from 1 to 180 minutes.'**
  String get pomodoroBreakMinutesRange;

  /// No description provided for @pomodoroSessionsPerCycle.
  ///
  /// In en, this message translates to:
  /// **'Focus sessions per cycle'**
  String get pomodoroSessionsPerCycle;

  /// No description provided for @pomodoroLongBreakDuration.
  ///
  /// In en, this message translates to:
  /// **'Long break duration'**
  String get pomodoroLongBreakDuration;

  /// No description provided for @pomodoroMinutesRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a duration from 1 to 720 minutes.'**
  String get pomodoroMinutesRange;

  /// No description provided for @pomodoroSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize your focus and break cycle.'**
  String get pomodoroSettingsDescription;

  /// No description provided for @pomodoroShortBreakDuration.
  ///
  /// In en, this message translates to:
  /// **'Short break duration'**
  String get pomodoroShortBreakDuration;

  /// No description provided for @pomodoroAutoStartBreaks.
  ///
  /// In en, this message translates to:
  /// **'Auto-start breaks'**
  String get pomodoroAutoStartBreaks;

  /// No description provided for @pomodoroNotificationsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to use completion sound and vibration.'**
  String get pomodoroNotificationsRequired;

  /// No description provided for @moreSubtasks.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreSubtasks(int count);

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @editTaskTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTaskTooltip;

  /// No description provided for @completeAllActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'All active tasks will be marked as completed.'**
  String get completeAllActiveMessage;

  /// No description provided for @recurringOccurrenceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed. Next occurrence scheduled.'**
  String get recurringOccurrenceCompleted;

  /// No description provided for @deleteTaskConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get deleteTaskConfirmationTitle;

  /// No description provided for @deleteTaskConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'This task will be removed from Perfica.'**
  String get deleteTaskConfirmationMessage;

  /// No description provided for @completeAllActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete all active tasks?'**
  String get completeAllActiveTitle;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTask;

  /// No description provided for @taskRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how task reminders alert you.'**
  String get taskRemindersDescription;

  /// No description provided for @taskReminderSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when a task reminder arrives.'**
  String get taskReminderSoundDescription;

  /// No description provided for @taskReminderVibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate for task reminders on Android. On iOS, vibration follows system notification settings.'**
  String get taskReminderVibrationDescription;

  /// No description provided for @taskReminderVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get taskReminderVibration;

  /// No description provided for @taskReminders.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get taskReminders;

  /// No description provided for @taskReminderSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get taskReminderSound;

  /// No description provided for @reminderRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat reminder'**
  String get reminderRepeat;

  /// No description provided for @reminderRepeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get reminderRepeatOnce;

  /// No description provided for @reminderRepeatEvery5Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 5 minutes'**
  String get reminderRepeatEvery5Minutes;

  /// No description provided for @reminderRepeatEvery10Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 10 minutes'**
  String get reminderRepeatEvery10Minutes;

  /// No description provided for @reminderRepeatEvery15Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 15 minutes'**
  String get reminderRepeatEvery15Minutes;

  /// No description provided for @reminderRepeatEvery30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 30 minutes'**
  String get reminderRepeatEvery30Minutes;

  /// No description provided for @reminderRepeatFiveAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Perfica will alert up to 5 times for this occurrence.'**
  String get reminderRepeatFiveAlertsDescription;

  /// No description provided for @taskReminderDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskReminderDoneAction;

  /// No description provided for @taskReminderSnooze10Action.
  ///
  /// In en, this message translates to:
  /// **'Snooze 10m'**
  String get taskReminderSnooze10Action;

  /// No description provided for @taskCompletedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskCompletedFeedback;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @settingsLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Some settings could not be loaded.'**
  String get settingsLoadFailure;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBug;

  /// No description provided for @reportBugDescription.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong and review diagnostics before sending.'**
  String get reportBugDescription;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Bug title'**
  String get bugReportTitle;

  /// No description provided for @bugReportTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the problem'**
  String get bugReportTitleHint;

  /// No description provided for @bugReportDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get bugReportDescriptionLabel;

  /// No description provided for @bugReportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you saw and why it was a problem.'**
  String get bugReportDescriptionHint;

  /// No description provided for @bugReportSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps to reproduce'**
  String get bugReportSteps;

  /// No description provided for @bugReportStepsHint.
  ///
  /// In en, this message translates to:
  /// **'List the steps that caused the problem.'**
  String get bugReportStepsHint;

  /// No description provided for @bugReportExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected behavior'**
  String get bugReportExpected;

  /// No description provided for @bugReportExpectedHint.
  ///
  /// In en, this message translates to:
  /// **'What did you expect Perfica to do?'**
  String get bugReportExpectedHint;

  /// No description provided for @bugReportContact.
  ///
  /// In en, this message translates to:
  /// **'Contact (optional)'**
  String get bugReportContact;

  /// No description provided for @bugReportContactHint.
  ///
  /// In en, this message translates to:
  /// **'Email or another contact method'**
  String get bugReportContactHint;

  /// No description provided for @bugReportDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get bugReportDiagnostics;

  /// No description provided for @bugReportDiagnosticsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics stay on this device until you choose to send a report. Review them before submission.'**
  String get bugReportDiagnosticsPrivacy;

  /// No description provided for @bugReportNoDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'No recent diagnostic errors were recorded.'**
  String get bugReportNoDiagnostics;

  /// No description provided for @bugReportIncludeDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Include recent diagnostics'**
  String get bugReportIncludeDiagnostics;

  /// No description provided for @bugReportIncludeDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Attach up to the three most recent locally recorded errors.'**
  String get bugReportIncludeDiagnosticsDescription;

  /// No description provided for @bugReportRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get bugReportRequired;

  /// No description provided for @bugReportReview.
  ///
  /// In en, this message translates to:
  /// **'Review report'**
  String get bugReportReview;

  /// No description provided for @bugReportReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review bug report'**
  String get bugReportReviewTitle;

  /// No description provided for @bugReportReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Check the information below before sending the report.'**
  String get bugReportReviewDescription;

  /// No description provided for @bugReportDiagnosticsExcluded.
  ///
  /// In en, this message translates to:
  /// **'Not included'**
  String get bugReportDiagnosticsExcluded;

  /// No description provided for @bugReportDiagnosticContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get bugReportDiagnosticContext;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @bugReportDiagnosticsIncluded.
  ///
  /// In en, this message translates to:
  /// **'{count} diagnostic entries included'**
  String bugReportDiagnosticsIncluded(int count);

  /// No description provided for @bugReportDiagnosticRecordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded: {time}'**
  String bugReportDiagnosticRecordedAt(String time);

  /// No description provided for @bugReportDiagnosticInformation.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic information'**
  String get bugReportDiagnosticInformation;

  /// No description provided for @bugReportEnvironmentStillIncluded.
  ///
  /// In en, this message translates to:
  /// **'App, OS, and device information will still be included.'**
  String get bugReportEnvironmentStillIncluded;

  /// No description provided for @bugReportSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get bugReportSend;

  /// No description provided for @bugReportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending report...'**
  String get bugReportSending;

  /// No description provided for @bugReportSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Bug report sent'**
  String get bugReportSentTitle;

  /// No description provided for @bugReportSentDescription.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your report was submitted successfully.'**
  String get bugReportSentDescription;

  /// No description provided for @bugReportOpenIssue.
  ///
  /// In en, this message translates to:
  /// **'Open issue'**
  String get bugReportOpenIssue;

  /// No description provided for @bugReportUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get bugReportUnknown;

  /// No description provided for @bugReportAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version: {value}'**
  String bugReportAppVersion(String value);

  /// No description provided for @bugReportPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform: {value}'**
  String bugReportPlatform(String value);

  /// No description provided for @bugReportOsVersion.
  ///
  /// In en, this message translates to:
  /// **'OS version: {value}'**
  String bugReportOsVersion(String value);

  /// No description provided for @bugReportDevice.
  ///
  /// In en, this message translates to:
  /// **'Device: {value}'**
  String bugReportDevice(String value);

  /// No description provided for @bugReportLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale: {value}'**
  String bugReportLocale(String value);

  /// No description provided for @bugReportRecentErrorsNone.
  ///
  /// In en, this message translates to:
  /// **'Recent errors: None included'**
  String get bugReportRecentErrorsNone;

  /// No description provided for @bugReportRecentErrorsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Recent errors: {count} included'**
  String bugReportRecentErrorsIncluded(int count);

  /// No description provided for @bugReportReportNumber.
  ///
  /// In en, this message translates to:
  /// **'Report #{id}'**
  String bugReportReportNumber(String id);

  /// No description provided for @bugReportSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the bug report. Please try again.'**
  String get bugReportSubmitFailed;

  /// No description provided for @bugReportSubmitFailedHttp.
  ///
  /// In en, this message translates to:
  /// **'Could not send the bug report (HTTP {status}). Please try again.'**
  String bugReportSubmitFailedHttp(int status);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
