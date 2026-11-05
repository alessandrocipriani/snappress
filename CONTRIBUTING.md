# Contributing to SnapPress

Thanks for your interest! Contributions in English or Italian are welcome.

## Before you start

- For anything larger than a small fix, open an issue first so we can agree on the approach.
- Check the [roadmap](docs/ROADMAP.md) to see what is planned.

## Workflow

1. Fork the repository and create a branch: `feature/short-description` or `fix/short-description`.
2. Make your changes, then run:
   ```bash
   dart format .
   flutter analyze
   flutter test
   dart run tool/check_licenses.dart
   ```
3. Open a pull request describing **what** changes and **why**. Link the related issue.

## Rules

- **Licence.** By contributing you agree that your code is released under the [BSD-3-Clause](LICENSE) licence. New files start with:
  ```dart
  // SPDX-License-Identifier: BSD-3-Clause
  // Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.
  ```
- **Dependencies.** Only permissive licences (MIT, BSD, Apache-2.0, ISC, Zlib). No GPL, LGPL or AGPL. Avoid proprietary SDKs (Firebase, analytics, ads): use plain HTTP calls to external APIs.
- **No hard-coded text.** Every user-visible string goes in `lib/l10n/app_en.arb` (with an `@description`) and `lib/l10n/app_it.arb`.
- **Accessibility.** Interactive widgets need a label (`tooltip`, `Semantics` or visible text), tap targets of at least 48×48 dp, and must work with large fonts. Test with TalkBack or VoiceOver when you touch the UI.
- **Secrets.** Never log or commit credentials or tokens. Store them only through the secure storage layer.
- **Tests.** New logic comes with unit tests; new screens with at least a widget test.

## Adding a destination

New platforms (Mastodon, Bluesky, …) implement the `Publisher` interface in `lib/publishers/` and come with a setup guide in `docs/setup/`.
