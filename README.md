# 🏋️ Fitness Tracker

A Flutter (Android) fitness tracking app for running a structured workout program,
logging sets and reps live during a session, tracking nutrition with AI-assisted
food-photo analysis, monitoring body progress, and backing everything up to
Google Drive.

## Features

- **Workout programs** — browse a multi-week training program (weeks, days,
  exercise blocks) and drill into exercise detail, sourced from bundled or
  custom-imported JSON programs.
- **Live workout logging** — start a session, log sets/reps/weight as you train,
  with a rest timer and a persistent active-workout banner that survives
  navigating away or the screen turning off.
- **Workout history & progress charts** — review past sessions and visualize
  training progress over time.
- **Nutrition tracking** — snap food photos, get AI-assisted nutrition analysis
  (Google Gemini), and manage a weekly shopping list.
- **Body progress & supplements** — log weekly weight/body-fat check-ins with
  progress photos, and track daily supplement intake.
- **Settings** — manage nutrition preferences, supplements, and data.
- **Google Drive backup & restore** — back up the full local database,
  preferences, and photos to Google Drive with one tap from Settings; on a
  fresh install, an automatic first-launch prompt offers to restore the most
  recent backup.

## Tech stack

- **Flutter** (Dart) targeting Android
- **Riverpod** for state management
- **Drift** (SQLite) for local persistence
- **GoRouter** for navigation
- **Google Sign-In + Drive API** (`googleapis`, `extension_google_sign_in_as_googleapis_auth`)
  for cloud backup, storing archives in Drive's hidden `appDataFolder`
- **Google Gemini** (`google_generative_ai`) for nutrition photo analysis

## Project structure

```
lib/
  core/       shared theme, utils, widgets
  data/       Drift database, models, repositories (single shared data layer)
  features/   per-feature UI (home, program, workout, history, nutrition,
              progress, settings, onboarding)
  services/   standalone plugin-backed services (notifications, Drive backup)
  main.dart   app entrypoint and top-level Riverpod providers
  app.dart    root widget / routing entrypoint
  router.dart GoRouter route table
```

The full phased build plan and task history live in
[`plans/implementation-plan.html`](plans/implementation-plan.html).

## Getting started

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # Drift codegen
flutter run
```

### Google Drive backup setup (one-time, manual)

The backup feature needs a Google Cloud OAuth client before it will work
end-to-end:

1. In [Google Cloud Console](https://console.cloud.google.com/), enable the
   **Google Drive API** on a project.
2. Configure the **OAuth consent screen** (External, Testing mode is fine for
   personal use — add your own Google account as a test user).
3. Create an **OAuth 2.0 Android client ID** for package
   `com.fourandhalf.fitness_tracker`, with your debug keystore's SHA-1
   fingerprint registered (get it via
   `keytool -list -v -keystore ~/.android/debug.keystore`), and later your
   release keystore's SHA-1 before a release build.

Without this setup, sign-in will fail — everything else in the app works
normally.

## Testing

```bash
flutter analyze
flutter test
```

Every `lib/` file with logic has a corresponding test under `test/`, and
widget-heavy features have at least one widget test covering rendering and
interaction.
