# yaadley-flutter

Android companion app for **Yaadly** (WhatsApp assistant for Roman Urdu voice notes).
See [PRD.md](PRD.md) and [context.md](context.md).

- **App ID:** `com.mshiraz.yaadley` · **Display name:** Yaadly
- **Stack:** Flutter 3.47.8 · Riverpod 3 · go_router 18 · dio · google_fonts (Space Grotesk + Geist)
- **Builds:** Codemagic ([codemagic.yaml](codemagic.yaml)). Nothing is built locally.
- **Design source:** Figma Make export in [design/figma-make/](design/figma-make/). Tokens are ported to [lib/core/theme/](lib/core/theme/).

## Structure

```
lib/
  core/
    config/      build-time config (--dart-define API_BASE_URL)
    l10n/        Roman Urdu / English strings + language provider
    network/     dio client, health check
    router/      go_router with a 5-tab StatefulShellRoute
    theme/       colors, spacing, typography from the Figma tokens
    widgets/     HardBox (outline + hard shadow), YButton, YChip, VoicePill, ScreenHeader, icons
  features/      welcome, today, inbox, calendar, lists, more, shell
```

## Local checks (fast, no Gradle)

```bash
flutter pub get
flutter analyze
flutter test
```

Optional UI preview without Android tooling: `flutter run -d chrome` (after `flutter create --platforms web .`).

## Codemagic

1. Push this repo to GitHub.
2. In Codemagic: add the application, choose the `yaadley-flutter` repo, and pick **codemagic.yaml** as the configuration.
3. Replace the email placeholder in `codemagic.yaml`.
4. Every push to `main` builds a release APK, emails the link, and keeps it under Artifacts.

Release signing is wired in `android/app/build.gradle.kts` through Codemagic's `CM_KEYSTORE_*` variables. The setup steps follow once the app exists in Codemagic.
