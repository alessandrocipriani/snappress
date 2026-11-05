# SnapPress

🇬🇧 [Read in English](README.md)

**SnapPress** è un'app mobile open source (Android e iOS) che trasforma un'immagine presente sul dispositivo in un post per **WordPress**, **Facebook** e **Instagram**, con testi e testo alternativo suggeriti dall'AI se lo desideri.

> ⚠️ Sviluppo iniziale (fase 0). Non è ancora pubblicata: vedi la [roadmap](docs/ROADMAP.md).

## Principi

- **Nessun server, nessun tracciamento.** L'app parla direttamente con il tuo sito WordPress, con Meta e con il provider AI che scegli. Le credenziali restano cifrate sul dispositivo.
- **Credenziali tue.** Usi la tua Application Password di WordPress, la tua app Meta e la tua chiave AI (o un modello self-hosted).
- **Accessibile.** Obiettivo WCAG 2.2 AA, pieno supporto a TalkBack e VoiceOver, testo alternativo su ogni immagine pubblicata.
- **Multilingua.** Italiano e inglese per iniziare; le traduzioni sono benvenute.

## Funzionalità previste

- Sblocco con PIN/password e biometria
- Scelta dell'immagine da galleria o fotocamera
- Titolo, testi per piattaforma, hashtag e alt text generati dall'AI
- Pubblicazione su WordPress (bozza, pubblicato o programmato), Pagine Facebook e account Instagram professionali
- Guide passo-passo integrate per configurare ogni connessione

## Guide di configurazione

- [WordPress](docs/setup/wordpress.it.md)
- Facebook / Instagram: in arrivo nella fase 3
- Provider AI: in arrivo nella fase 2

## Sviluppo

Requisiti: [Flutter](https://docs.flutter.dev/get-started/install) (canale stable), Xcode (per iOS, solo macOS), Android Studio o l'Android SDK.

```bash
git clone https://github.com/alessandrocipriani/snappress.git
cd snappress
flutter pub get        # genera anche il codice delle traduzioni
flutter run
```

Comandi utili:

```bash
dart format .                      # formatta il codice
flutter analyze                    # analisi statica
flutter test                       # test, compresi i controlli di accessibilità
dart run tool/check_licenses.dart  # blocca dipendenze GPL/LGPL/AGPL
```

Per aggiungere una lingua: copia `lib/l10n/app_en.arb` in `lib/l10n/app_<codice>.arb` (es. `app_es.arb`), traduci i valori ed esegui `flutter pub get`.

## Contribuire

Vedi [CONTRIBUTING.md](CONTRIBUTING.md). Problemi di sicurezza: vedi [SECURITY.md](SECURITY.md).

## Licenza

[BSD-3-Clause](LICENSE). Le dipendenze devono avere una licenza permissiva compatibile (MIT, BSD, Apache-2.0, …): la CI rifiuta i pacchetti GPL, LGPL e AGPL, così l'app può essere distribuita su tutti gli store.
