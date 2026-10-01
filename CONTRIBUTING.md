# Contributing to Perfica

Thank you for considering a contribution to Perfica.

This guide describes the expected workflow from preparing a development
environment through opening, updating, and completing a pull request.

Perfica is maintained under the Veltaluma organization and is licensed under
GPL-3.0-or-later.

## 1. Read before contributing

Please read:

- `README.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `docs/ARCHITECTURE.md`
- `docs/DEVELOPMENT.md`

If your work affects data, migrations, import/export, or restore behavior, also
read:

- `docs/BACKUP_FORMAT.md`

## 2. Useful contribution types

Contributions can include:

- bug fixes;
- accessibility improvements;
- tests;
- documentation improvements;
- UI/UX improvements consistent with the existing design language;
- performance improvements;
- carefully scoped refactors;
- task-management improvements;
- focus/Pomodoro improvements;
- progress improvements;
- localization work;
- Android widget improvements;
- backup compatibility work;
- database migration work.

Large architectural rewrites should normally be discussed before substantial
implementation begins.

## 3. Code of Conduct

Participation in Perfica community spaces requires compliance with
`CODE_OF_CONDUCT.md`.

Technical disagreement is welcome. Personal attacks, harassment, intimidation,
or disclosure of private information are not.

## 4. Contribution license

Perfica is licensed under GPL-3.0-or-later.

Unless explicitly agreed otherwise before submission, an original contribution
intentionally submitted for inclusion in Perfica is expected to be distributed
as part of Perfica under GPL-3.0-or-later.

Contributing does not automatically transfer your copyright ownership to
Veltaluma.

You are responsible for having the right to contribute the material you submit.

Do not submit:

- copied proprietary source code;
- incompatible-licensed code;
- assets with unclear redistribution rights;
- credentials or private keys;
- confidential employer material;
- private user data.

## 5. Portfolio and resume use

Contributors may reference accepted Perfica contributions in:

- resumes;
- CVs;
- professional portfolios;
- personal websites;
- GitHub profiles;
- LinkedIn or similar professional profiles.

When practical, link to the canonical Perfica repository or relevant merged pull
request so the contribution can be verified in context.

## 6. Validated development baseline

```text
Flutter                 3.47.5 stable
Flutter revision        6a19cca564
Dart                    3.13.4
Android Gradle Plugin   9.4.0
Kotlin Gradle Plugin    2.4.20
Gradle                  9.8.0
Java source/target      17
Android NDK             30.0.16248370
```

Do not mix a toolchain upgrade into an unrelated feature or bug-fix pull
request.

## 7. Fork the repository

Fork:

```text
https://github.com/Veltaluma/Perfica
```

into your own GitHub account or organization.

## 8. Clone your fork

```bash
git clone https://github.com/<your-account>/Perfica.git
cd Perfica
```

## 9. Add canonical upstream

```bash
git remote add upstream https://github.com/Veltaluma/Perfica.git
git remote -v
```

The examples below assume the default branch is `main`. If upstream uses another
default branch, substitute that branch name.

## 10. Synchronize before starting

```bash
git fetch upstream
git checkout main
git merge --ff-only upstream/main
git push origin main
```

## 11. Create a focused branch

Examples:

```bash
git checkout -b fix/reminder-reschedule
git checkout -b feat/task-filter
git checkout -b docs/contributor-guide
```

Keep one logical change per branch.

Avoid combining unrelated formatting, dependency upgrades, refactors, and
feature work in one pull request.

## 12. Install dependencies

Perfica commits `pubspec.lock`.

For normal work:

```bash
flutter pub get --enforce-lockfile
```

Do not delete `pubspec.lock` merely to fix a local setup problem.

If your change intentionally updates dependencies, explain why in the pull
request.

## 13. Run the application

List devices:

```bash
flutter devices
```

Run on a selected device:

```bash
flutter run -d <device-id>
```

Android contributors should test on a real device or emulator appropriate to the
change.

## 14. Architecture overview

Perfica uses a feature-first structure:

```text
lib/
├── app/
├── core/
├── features/
│   ├── bug_report/
│   ├── focus/
│   ├── insights/
│   ├── settings/
│   └── tasks/
└── l10n/
```

See `docs/ARCHITECTURE.md` for detailed responsibilities.

## 15. Dependency injection and state ownership

Perfica deliberately separates service/repository injection from application
state.

Use:

- `Provider` / `MultiProvider` for services and repositories;
- `BlocProvider` and Cubit for application state.

Do not migrate the entire project to another state-management system as part of
an unrelated change.

## 16. Routing

Perfica uses `go_router`.

Central route files:

```text
lib/app/router/route_names.dart
lib/app/router/route_paths.dart
```

Do not scatter literal route strings across unrelated widgets.

## 17. Main navigation

The main application shell currently contains:

- Tasks
- Focus
- Progress

Settings and editor flows are separate routes.

A new feature does not automatically require a new primary navigation
destination.

## 18. Tasks architecture

Task functionality lives under:

```text
lib/features/tasks/
```

It covers:

- CRUD;
- priorities;
- workflow status;
- search;
- list presentation;
- board presentation;
- recurrence;
- reminders;
- reminder repetition;
- notification actions;
- subtasks;
- tags;
- attachments;
- completion history;
- Android widget coordination.

The board is a presentation mode within Tasks. Do not create a duplicate
`features/board` domain unless the architecture is intentionally redesigned and
reviewed.

## 19. Recurrence changes

Recurrence changes must consider:

- normal completion;
- next-occurrence calculation;
- overdue occurrences;
- tasks without due dates;
- stopping recurrence;
- permanent completion;
- scheduled reminders;
- notification lifecycle.

Add or update recurrence tests when changing this area.

## 20. Reminder changes

Reminder behavior must consider:

- scheduling;
- cancellation;
- recurrence;
- repeated alerts;
- snooze;
- completion from notifications;
- sound;
- vibration;
- permission state;
- timezone handling;
- Android boot behavior where relevant.

## 21. Android task widget

The Android widget has both Flutter and native Kotlin components.

Changes to task persistence or task actions may affect:

- widget snapshots;
- refresh behavior;
- action receivers;
- background execution;
- widget editor activity;
- native widget services.

Do not remove native entry points merely because they are not imported from
Dart.

## 22. Focus and Pomodoro architecture

Focus logic lives under:

```text
lib/features/focus/
```

The feature includes:

- focus-session persistence;
- runtime snapshots;
- duration validation;
- Pomodoro phases;
- focus Cubit;
- Pomodoro settings Cubit;
- focus screen;
- focus settings.

Changes must preserve runtime restoration behavior.

## 23. Progress

Progress lives under:

```text
lib/features/insights/
```

Metrics are derived from stored task and focus activity.

Avoid adding remote analytics requirements to calculations that currently work
from local data.

## 24. Settings

Settings is divided by concern, including:

- appearance;
- notifications;
- data and backup;
- help and feedback;
- about.

Persistent settings should go through the appropriate data/preference layer.

## 25. Design system

Shared design definitions live under:

```text
lib/core/design_system/
```

Prefer existing spacing, radius, duration, color, typography, theme, and
breakpoint definitions before introducing local magic values.

## 26. Responsive behavior

Do not assume a phone-sized viewport.

Perfica already adapts navigation behavior for larger widths.

Test responsive UI changes at materially different viewport sizes.

## 27. Localization

English source strings are maintained in:

```text
lib/l10n/app_en.arb
```

Generated localization files must not be edited manually.

After changing ARB resources, regenerate localization output when needed.

Keep code identifiers and technical comments in English.

## 28. Generated files

Never manually edit:

```text
lib/core/database/app_database.g.dart
lib/l10n/app_localizations.dart
lib/l10n/app_localizations_en.dart
```

Generated changes must come from source definitions.

## 29. Drift generation

When required:

```bash
dart run build_runner build
```

Review generated output before submission.

Do not use obsolete build-runner flags copied from old documentation.

## 30. Database schema changes

Perfica maintains explicit Drift schema history under:

```text
drift_schemas/
```

A schema change must preserve existing installations through migration behavior.

Never rewrite an old schema snapshot just to make a new test pass.

Add a new schema version instead.

## 31. Migration testing

Migration tests are mandatory for meaningful schema changes.

Test:

- schema correctness;
- old user data;
- new columns/tables;
- backfill logic;
- cleanup of superseded storage where applicable.

## 32. Backup compatibility

Before changing backup code, read:

```text
docs/BACKUP_FORMAT.md
```

Backup services have intentionally separate responsibilities.

Do not merge them merely because their names overlap.

## 33. Backup services

### `BackupService`

Historical JSON compatibility.

### `DataBackupService`

Application-facing import/export facade and format routing.

### `PortableBackupBuilder`

Current portable archive creation.

### `PortableBackupRestorer`

Validation and restoration of portable backups, attachments, migrations, and
normalization.

## 34. Backup safety

Restore changes must consider:

- corrupted input;
- unsupported versions;
- path traversal;
- attachment extraction;
- database replacement;
- rollback/atomic behavior;
- historical compatibility.

A failed restore must not casually destroy a valid current database.

## 35. Bug-report privacy

The bug-report feature may include local diagnostics.

Do not add silent transmission of diagnostics.

Users must be able to review relevant report information before submission.

Avoid storing secrets in diagnostics.

## 36. New dependencies

Before adding a package:

1. confirm it is necessary;
2. check existing functionality first;
3. review maintenance status;
4. review license compatibility;
5. consider F-Droid implications;
6. consider native/prebuilt binary behavior;
7. avoid dependencies that only replace a few lines of simple code.

Explain dependency changes in the pull request.

## 37. Formatting

Format:

```bash
dart format lib test
```

Verify clean formatting:

```bash
dart format --output=none --set-exit-if-changed lib test
```

Do not submit unrelated repository-wide formatting changes.

## 38. Static analysis

```bash
flutter analyze --no-pub
```

Expected result: zero analyzer issues.

## 39. Tests

```bash
flutter test --no-pub
```

Perfica uses:

- unit tests;
- widget tests;
- repository tests;
- Cubit/state tests;
- migration tests;
- backup/restore tests;
- domain-service tests.

## 40. Required pre-PR validation

```bash
flutter pub get --enforce-lockfile
flutter test --no-pub
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib test
```

All commands must succeed.

If your change affects Android-native behavior, also build or run an Android
target appropriate to the change.

## 41. UI changes

A UI pull request should include screenshots when the visual result changes.

For responsive changes, include more than one relevant viewport where useful.

## 42. Accessibility

Do not remove useful semantics for visual convenience.

Interactive controls should have understandable labels or tooltips where
appropriate.

Test larger text where relevant.

## 43. Keep the pull request focused

A good pull request should explain:

- what problem it solves;
- why this approach is appropriate;
- what changed;
- how it was tested;
- whether storage or backup compatibility changed;
- whether Android native behavior changed;
- whether localization changed;
- whether dependencies changed.

## 44. Review your diff

Before pushing:

```bash
git status
git diff
```

Do not include:

- build outputs;
- IDE metadata;
- local caches;
- temporary audit files;
- credentials;
- unrelated files.

## 45. Commit your work

Use concise commit messages.

Good examples:

```text
Fix recurring task reminder scheduling
Add task filter accessibility labels
```

Avoid meaningless messages such as:

```text
update
fix
changes
final
```

## 46. Synchronize before opening the PR

```bash
git fetch upstream
git rebase upstream/main
```

Resolve conflicts carefully and rerun validation.

Do not force-push branches owned by another contributor.

## 47. Push your branch

```bash
git push -u origin <your-branch>
```

If you rebased your own published contribution branch and need to update it,
prefer:

```bash
git push --force-with-lease
```

## 48. Open the pull request

Open a pull request from your contribution branch to the canonical repository.

The PR template asks for:

- summary;
- motivation;
- implementation;
- testing;
- screenshots for UI changes;
- database/backup impact;
- dependency impact;
- checklist.

Complete it accurately.

## 49. Pull-request title

Use a title that describes the outcome.

Good:

```text
Fix reminder state after recurring task completion
```

Avoid vague titles such as:

```text
Various fixes
```

## 50. CI and automated checks

A pull request may be checked automatically.

A green CI result does not replace local understanding or code review.

## 51. Responding to review

When changes are requested:

1. understand the concern;
2. update the same contribution branch;
3. rerun relevant validation;
4. push the additional commits;
5. reply when addressed.

Do not open a new PR just to respond to normal review feedback.

## 52. Updating an existing PR

Additional pushes to the same source branch update the pull request
automatically.

Maintainers may squash or otherwise normalize history when merging according to
repository policy.

## 53. Merge expectations

Opening a pull request does not guarantee merge.

A contribution can be declined for reasons including:

- correctness;
- missing tests;
- architectural conflict;
- security risk;
- licensing concerns;
- maintenance burden;
- duplicate functionality;
- project direction.

## 54. Contributor recognition

Accepted contributions remain visible in repository and pull-request history.

Contributors retain copyright in their own original contributions unless they
separately assign it in writing.

## 55. Security issues

Do not publish exploit details in a normal issue.

Follow `SECURITY.md`.

## 56. Questions

For non-security contribution questions, use the communication facilities
available on the canonical Perfica repository.

Thank you for helping improve Perfica.
