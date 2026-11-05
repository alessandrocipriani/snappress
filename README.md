# SnapPress

[![CI](https://github.com/alessandrocipriani/snappress/actions/workflows/ci.yml/badge.svg)](https://github.com/alessandrocipriani/snappress/actions/workflows/ci.yml)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)

🇮🇹 [Leggi in italiano](README.it.md)

**SnapPress** is an open source mobile app (Android and iOS) that turns an image on your device into a post for **WordPress**, **Facebook** and **Instagram**, optionally with texts and alt text suggested by AI.

> ⚠️ Early development (phase 0). Nothing is published yet: see the [roadmap](docs/ROADMAP.md).

## Principles

- **No backend, no tracking.** The app talks directly to your WordPress site, Meta and the AI provider you choose. Credentials stay encrypted on your device.
- **Bring your own credentials.** You use your own WordPress Application Password, your own Meta app and your own AI key (or a self-hosted model).
- **Accessible.** Target: WCAG 2.2 AA, full support for TalkBack and VoiceOver, and alt text on every published image.
- **Multilingual.** Italian and English to start; translations are welcome.

## Planned features

- Lock with PIN/password and biometrics
- Pick an image from gallery or camera
- AI-generated title, texts per platform, hashtags and alt text
- Publish to WordPress (draft, published or scheduled), Facebook Pages and Instagram professional accounts
- Built-in step-by-step guides to configure each connection

## Setup guides

- [WordPress](docs/setup/wordpress.en.md)
- Facebook / Instagram: coming in phase 3
- AI providers: coming in phase 2

## Development

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) (stable channel), Xcode (for iOS, macOS only), Android Studio or the Android SDK.

```bash
git clone https://github.com/alessandrocipriani/snappress.git
cd snappress
flutter pub get        # also generates the localisation code
flutter run
```

Useful commands:

```bash
dart format .                      # format code
flutter analyze                    # static analysis
flutter test                       # tests, including accessibility checks
dart run tool/check_licenses.dart  # block GPL/LGPL/AGPL dependencies
```

Project layout:

```
lib/
  core/        theme, (soon) auth and secure storage
  features/    screens: home, settings, (soon) composer, history
  publishers/  common Publisher interface + WordPress, Facebook, Instagram
  ai/          common AiProvider interface + implementations
  l10n/        translations (ARB files)
docs/          roadmap, privacy policy, setup guides
tool/          maintenance scripts
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security issues: see [SECURITY.md](SECURITY.md).

## License

[BSD-3-Clause](LICENSE). Dependencies must use a compatible permissive licence (MIT, BSD, Apache-2.0, …): the CI rejects GPL, LGPL and AGPL packages so the app can be distributed on every store.
