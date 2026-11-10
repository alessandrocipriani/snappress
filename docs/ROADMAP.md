# Roadmap

| Phase | Content | Status |
|---|---|---|
| **0 – Setup** | Repository, BSD-3-Clause licence, README, CI (analysis, tests, licence check, Android and iOS builds), IT/EN localisation, base architecture | ✅ Done |
| **1 – MVP** | App lock (password + biometrics), image picker, post editor, WordPress connection with in-app guide, publish as draft or live | 🚧 In progress |
| **2 – AI** | Configurable providers (cloud with user key, self-hosted OpenAI-compatible endpoint), generated texts and alt text | ⏳ |
| **3 – Meta** | "Bring your own Meta app" guide, Facebook Pages, Instagram via the WordPress image URL | ⏳ |
| **4 – Polish** | Scheduled posts, history, retry of failed destinations, accessibility audit with TalkBack/VoiceOver, more languages | ⏳ |
| **5 – Distribution** | F-Droid, Google Play, App Store | ⏳ |

## Key design decisions

- **No backend.** All calls go directly from the device to WordPress, Meta and the AI provider.
- **Bring your own Meta app.** Each user creates a free Meta app in development mode and adds themself as admin. This avoids Meta App Review and Business Verification for personal use.
- **WordPress as image host.** The image is uploaded to the WordPress media library first; its public URL is then used for Instagram, which only accepts images by public URL (JPEG only).
- **Accessible content.** The AI-generated alt text is sent to WordPress (`alt_text` of the media item) and Instagram (`alt_text`).
- **Permissive licence.** BSD-3-Clause, so the app can be published on every store including the App Store.
