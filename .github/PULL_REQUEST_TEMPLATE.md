## Summary

Describe what this pull request changes.

## Motivation

What problem does this solve, or what capability does it add?

## Implementation

Explain the important technical decisions.

## Testing

List validation performed.

```text
flutter pub get --enforce-lockfile
flutter test --no-pub
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib test
```

Add Android/device validation when relevant.

## UI changes

If the visual UI changed, include screenshots or recordings.

## Data / database impact

- [ ] No database/schema impact
- [ ] Database/schema impact is documented and migration-tested

Explain if applicable:

## Backup compatibility

- [ ] No backup-format impact
- [ ] Backup behavior changed and compatibility tests/documentation were updated

Explain if applicable:

## Android native/widget impact

- [ ] No Android native/widget impact
- [ ] Android native/widget behavior was reviewed and validated

Explain if applicable:

## Dependencies

- [ ] No dependency changes
- [ ] Dependency changes are intentional and explained below

Dependency rationale:

## Checklist

- [ ] I read `CONTRIBUTING.md`.
- [ ] My change is focused and contains no unrelated refactoring.
- [ ] Tests pass.
- [ ] Static analysis passes.
- [ ] Dart formatting is clean.
- [ ] I did not manually edit generated files.
- [ ] I added or updated tests where behavior changed.
- [ ] I considered localization for user-facing text.
- [ ] I considered data migration and backup compatibility where relevant.
- [ ] I did not add credentials, private keys, or sensitive user data.
- [ ] I have the right to submit this contribution under GPL-3.0-or-later.
