# Perfica Development Guide

## Validated baseline

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

Android compile SDK, target SDK, and minimum SDK follow the Flutter/Android
project configuration.

## Dependencies

For a clean checkout:

```bash
flutter pub get --enforce-lockfile
```

`pubspec.lock` is part of the reproducible application dependency state.

## Run Perfica

```bash
flutter devices
flutter run -d <device-id>
```

## Localization generation

When ARB files change:

```bash
flutter gen-l10n
```

Do not manually edit generated localization files.

## Drift generation

When Drift source definitions require regeneration:

```bash
dart run build_runner build
```

Review generated output afterward.

Do not use obsolete build-runner flags from old documentation.

## Static analysis

```bash
flutter analyze --no-pub
```

Expected result: zero analyzer issues.

## Tests

```bash
flutter test --no-pub
```

The documentation baseline contained 205 passing tests.

The count can legitimately increase as the project evolves.

## Formatting

Format:

```bash
dart format lib test
```

Verify no formatting changes are required:

```bash
dart format --output=none --set-exit-if-changed lib test
```

## Full local validation

```bash
flutter pub get --enforce-lockfile
flutter test --no-pub
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib test
```

## Android build

```bash
flutter build apk --release --no-pub
```

Local release signing can differ from official distribution signing.

Never commit private signing keys or credentials.

## Android toolchain files

```text
android/settings.gradle.kts
android/app/build.gradle.kts
android/gradle.properties
android/gradle/wrapper/gradle-wrapper.properties
```

Do not remove compatibility flags merely because they look unusual.

## NDK

The application project currently pins:

```text
30.0.16248370
```

Some dependency subprojects can use their own or Flutter-provided native
configuration.

Native dependency changes require actual build validation.

## F-Droid considerations

F-Droid builds should be reproducible from source.

Important principles:

- keep `pubspec.lock`;
- pin the Flutter revision in F-Droid build metadata;
- avoid unexplained prebuilt binaries;
- review native dependency behavior;
- do not add `scanignore` only to silence an unexplained finding;
- keep caches and generated build output out of the source tree.

## Generated files

Do not manually edit:

```text
lib/core/database/app_database.g.dart
lib/l10n/app_localizations.dart
lib/l10n/app_localizations_en.dart
```

## Database changes

Schema changes should include:

- schema version changes when required;
- migration implementation;
- a new schema snapshot;
- migration tests;
- data-preservation validation.

Historical schema files should not be rewritten to make current tests easier.

## Backup changes

Read:

```text
docs/BACKUP_FORMAT.md
```

before modifying backup services.

## Android widget changes

The task widget includes Kotlin under the Android source tree.

Flutter-only tests are not sufficient for all widget changes.

Validate relevant Android behavior on an emulator or device.

## Source language

Code identifiers, technical comments, and project documentation are maintained
in English unless a localization resource intentionally provides another
user-facing language.

## Lints

Perfica uses:

```text
flutter_lints
```

Do not introduce an unrelated lint framework in an ordinary contribution.

## Temporary files

Do not commit:

- `.dart_tool/`;
- `build/`;
- Android local Gradle state;
- IDE state;
- heap dumps;
- temporary audit reports;
- local backup files;
- secrets.
