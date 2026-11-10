# Project status / Stato del progetto

*Last updated: 2026-11-05*

## Decisions
- Stack: Flutter (Android + iOS), no backend; credentials only on device (secure storage).
- Licence: **BSD-3-Clause** (chosen over GPL to allow App Store). CI blocks GPL/LGPL/AGPL deps.
- Repo: `github.com/alessandrocipriani/snappress` (SSH). Bundle id: `io.github.alessandrocipriani.snappress`.
- Meta (phase 3): "bring your own Meta app" in development mode → no App Review.
- Instagram image hosting: reuse the image URL uploaded to WordPress (JPEG only).
- AI (phase 2): pluggable `AiProvider` — cloud with user's own key, self-hosted OpenAI-compatible, on-device later.
- Apple Developer account: not yet; buy it only at phase 5. Developer has a Mac.

## Done
- **Phase 0** — skeleton, i18n IT/EN, licence, README, CONTRIBUTING, SECURITY, privacy draft, WordPress guide, CI. ✅ verified by the developer.
- **Phase 1** — delivered as `snappress-fase1.zip`, **not yet verified** (written without a local Flutter SDK):
  - app lock: password (PBKDF2-HMAC-SHA256, 210k iter.) + biometrics, lock-out after 5 failures, auto-lock after 2 min in background;
  - WordPress: Application Password, test & save, `?rest_route=` fallback, in-app guide;
  - composer: gallery/camera, alt text, title, body, hashtags, draft or publish, result link;
  - tests: auth, WordPress client (MockClient), content builder, widgets + accessibility.

## Next steps
1. Developer: unzip phase 1 over the repo, apply `docs/development/native-setup.md`, run `flutter analyze` / `flutter test`, report errors.
2. Fix any errors, then **phase 2 (AI)**: provider settings + key in secure storage, prompt returning JSON (title, WP body, FB text, IG caption, hashtags, alt text), "Generate with AI" button in the composer.
3. Phase 3: Facebook Pages + Instagram; phase 4: scheduling, history, a11y audit; phase 5: stores.
