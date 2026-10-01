# Perfica Architecture

## Overview

Perfica is a Flutter application organized around feature ownership and a shared
core layer.

The architecture separates UI, application state, persistence, platform
integration, and compatibility logic so they can be tested and maintained
independently.

## Structure

```text
lib/
├── app/
│   ├── router/
│   ├── shell/
│   ├── widgets/
│   ├── bootstrap.dart
│   ├── dependencies.dart
│   └── perfica_app.dart
├── core/
│   ├── constants/
│   ├── database/
│   ├── design_system/
│   └── services/
├── features/
│   ├── bug_report/
│   ├── focus/
│   ├── insights/
│   ├── settings/
│   └── tasks/
├── l10n/
└── main.dart
```

## Bootstrap

`main.dart` enters application bootstrap.

Bootstrap prepares application-level dependencies and starts Flutter.

Feature business logic should not be placed directly in the entry point.

## Dependency injection

Perfica intentionally uses two mechanisms.

### Provider

Used for services and repositories, including database, notifications,
attachments, task repositories, focus repository, backup facade, update service,
and bug-report services.

### BlocProvider / Cubit

Used for application state, including theme, tasks, focus, Pomodoro settings,
and insights.

Do not use service Providers as ad-hoc mutable UI state containers.

## Routing

Routing uses `go_router`.

Central files:

```text
lib/app/router/app_router.dart
lib/app/router/route_names.dart
lib/app/router/route_paths.dart
```

Primary shell destinations:

```text
Tasks
Focus
Progress
```

Additional routes include task editing, settings, and bug reporting.

## Tasks

Tasks is the largest feature area.

Its responsibilities include:

- CRUD;
- completion behavior;
- recurrence;
- reminders;
- task metadata;
- subtasks;
- tags;
- attachments;
- workflow status;
- task board;
- Android widget coordination.

### Board ownership

The task board is part of Tasks:

```text
lib/features/tasks/presentation/widgets/task_board_view.dart
```

It is not a separate domain feature.

## Focus

Focus includes:

- focus-session persistence;
- runtime snapshots;
- duration validation;
- Pomodoro phase/domain models;
- focus Cubit;
- Pomodoro settings Cubit;
- focus screen;
- focus settings.

Focus history is consumed by Progress.

## Progress / Insights

The `insights` feature derives productivity summaries from local task-completion
and focus-session records.

It should not own task or focus persistence.

## Settings

Settings is split into focused pages such as:

- appearance;
- notifications;
- data and backup;
- help and feedback;
- about.

Persistent settings belong in data/preference abstractions rather than widgets.

## Bug reporting

Bug reporting contains:

- environment collection;
- payload models;
- submission service;
- reviewable presentation flow.

Diagnostics are local until the user chooses to submit them.

## Database

Perfica uses Drift over SQLite.

Important files:

```text
lib/core/database/app_database.dart
lib/core/database/app_database.g.dart
lib/core/database/database_connection.dart
```

`app_database.g.dart` is generated and must not be edited manually.

## Database history

Schema snapshots live under:

```text
drift_schemas/
```

The repository currently contains historical schema versions through v6.

Migration behavior is part of compatibility.

## Backup subsystem

The backup subsystem intentionally has multiple services:

### BackupService

Historical JSON compatibility.

### DataBackupService

Application-facing import/export facade and format routing.

### PortableBackupBuilder

Current portable archive creation.

### PortableBackupRestorer

Portable backup validation/restoration, attachments, migrations, and
normalization.

These are not duplicate implementations.

## Attachments

Attachment files are managed separately from database rows.

Paths and archive extraction are security-sensitive input.

## Notifications

Notification handling covers both focus/Pomodoro notifications and task
reminders, including task actions.

## Android-native components

Perfica contains Android Kotlin components for the home-screen task widget and
background actions.

Native code must not be treated as dead merely because Dart does not import it.

## Design system

Shared design definitions live under:

```text
lib/core/design_system/
```

New presentation code should reuse project tokens before introducing local magic
values.

## Localization

Source localization:

```text
lib/l10n/app_en.arb
```

Generated localizations:

```text
lib/l10n/app_localizations.dart
lib/l10n/app_localizations_en.dart
```

Generated files must not be hand-edited.

## Offline-first boundary

Normal task, focus, progress, settings, and backup workflows operate from local
application data.

Network-dependent operations are explicit, including release checking and
user-initiated bug-report submission.

## Testing

Tests cover multiple layers, including:

- repositories;
- domain logic;
- Cubits;
- widgets;
- backup and restore;
- attachment safety;
- diagnostics;
- database migrations;
- recurrence;
- reminder lifecycle;
- focus logic;
- settings.

Architecture changes should preserve testability rather than pushing behavior
into large presentation widgets.
