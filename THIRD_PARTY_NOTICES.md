# Third-Party Notices

Perfica depends on third-party open-source software and includes third-party
assets.

Those components remain subject to their own licenses.

This file supplements, but does not replace, license metadata distributed with
each dependency.

## Dart and Flutter dependencies

The authoritative dependency set for a Perfica revision is defined by:

```text
pubspec.yaml
pubspec.lock
```

Direct and transitive packages may use licenses different from Perfica's
GPL-3.0-or-later license.

Their copyright and license terms remain those of their respective upstream
projects.

When adding or updating a dependency, contributors must review license
compatibility and redistribution implications.

## Native dependencies

Some Flutter/Dart packages may build or bundle native components.

Native code remains subject to the license of its corresponding upstream package
or component.

Native dependency handling should also be reviewed for source-build and F-Droid
requirements where applicable.

## Inter

Perfica bundles the Inter typeface.

- Project: Inter
- Copyright: The Inter Project Authors
- License: SIL Open Font License 1.1
- Upstream: https://github.com/rsms/inter
- Bundled asset: `assets/fonts/InterVariable.ttf`
- Bundled license: `assets/fonts/OFL.txt`

The Inter font remains licensed separately under the SIL Open Font License 1.1.

Its inclusion does not change the GPL-3.0-or-later license applied to original
Perfica source code.

## Branding

Perfica repository branding files are stored under:

```text
branding/
```

The software license and copyright notices should not be interpreted as a
guarantee that trademark rights, endorsement rights, or third-party brand rights
are automatically granted beyond what applicable law and the relevant rights
holders permit.
