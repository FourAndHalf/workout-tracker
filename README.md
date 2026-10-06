# 🏋️ Fitness Tracker

A personal, Android-first fitness companion for following structured training,
logging workouts while I train, keeping a lightweight nutrition and supplement
record, and reviewing progress over time. The app is local-first: my workout,
nutrition, progress, and preferences are stored on the device and can be
backed up to my Google Drive.

## Use case: how I use it

I use the app to turn my training plan into a repeatable daily routine:

1. I open **Home** to see the next workout, my current streak, daily summary,
   and quick access back to an unfinished session.
2. I open **Programs** and follow the current week and day. The bundled plans
   cover a 4-week strength program, a 12-week badminton strength/mobility
   program, and a 10-minute daily mobility routine.
3. During a workout, I start the session and log each set as I go. Depending on
   the exercise, I can record weight and reps, reps only, time, distance, or
   cumulative/rest-pause reps. The workout view shows elapsed session time,
   starts a rest countdown after logged sets or rounds, and shows a start/pause
   countdown for timed exercises such as mobility holds. The app keeps the
   active session visible while I move between screens, prevents the phone from
   sleeping, and provides an ongoing lock-screen notification.
4. After training, I use **Progress → History** to review the session, add a
   note, and compare strength, volume, workout frequency, streaks, and estimated
   calories over time.
5. Once a week, I add a body check-in with weight, body-fat percentage, and an
   optional progress photo.
6. In **Nutrition**, I photograph and label meals, review the planned meals and
   macro totals for the day, maintain the weekly shopping list, and mark
   supplements as taken. The **Settings** screen is where I maintain the meal
   plan, supplements, daily calorie-burn estimate, and app theme.
7. I place the Kinetic Flux launcher widgets on my Android home screen for a
   quick view of calorie balance, workout status, and streak. The widget's
   **Start** action deep-links directly to the next workout; the nutrition
   camera shortcut can open the camera from the launcher.
8. I use **Settings → Back up to Google Drive** to save the local database,
   preferences, and photos. On a fresh install, the app checks for the latest
   backup before opening the main experience so I can restore my data.

This makes the app a single personal loop: plan the session, complete and log
it, capture supporting nutrition/body data, then use the history and dashboard
to decide what to do next.

## Features

- **Structured workout programs** — browse weeks, days, blocks, prescriptions,
  exercise instructions, and optional exercise video links. Programs are loaded
  from bundled JSON and persisted locally.
- **Live workout logging** — track sets, reps, weight, duration, distance,
  failure, and rest-pause/cumulative work. Pause and resume an active workout,
  use elapsed, rest, and timed-exercise countdowns, and return to it from the
  persistent workout banner.
- **Workout history and progress** — view a calendar and completed sessions,
  add session notes, and see strength, volume, frequency, streak, workout-type,
  duration, and estimated-calorie summaries.
- **Body progress** — record weekly weight and body-fat check-ins with optional
  photos.
- **Nutrition and meal planning** — capture and label meal photos, view daily
  meals, maintain calorie/macro-based meal plans, and generate/edit a weekly
  shopping list.
- **Supplements** — configure supplements, optionally attach a reference photo,
  and record daily intake.
- **Android launcher widgets** — show Kinetic Flux calorie/streak/workout
  information and provide shortcuts into the app.
- **Backup and restore** — archive the local database, preferences, and photos
  to Google Drive's private `appDataFolder`, then restore the latest archive on
  a new install.

> Note: the project currently includes the `google_generative_ai` dependency,
> but there is no active Gemini request in the app code. Food-photo capture and
> meal labeling are implemented; AI nutrition analysis is not currently part of
> the working user flow.

## Tech stack

- **Flutter/Dart** targeting Android
- **Riverpod** for state management
- **Drift/SQLite** for local persistence
- **GoRouter** for navigation
- **Google Sign-In + Drive API** for cloud backup
- **Flutter Local Notifications** for the active workout notification
- **Home Widget** for Android launcher widgets
- **fl_chart** for progress visualizations

## Project structure

```
lib/
  core/       shared theme, utils, and widgets
  data/       Drift database, models, and repositories
  features/   home, programs, workouts, history, progress, nutrition,
              settings, and onboarding UI
  services/   notifications, widgets, archive, and Google Drive services
  main.dart   app entrypoint and top-level providers
  app.dart    root widget and restore gate
  router.dart GoRouter route table
assets/
  programs/   bundled JSON training programs
test/         unit, repository, service, and widget tests
```

The full phased build plan and task history live in
[`plans/implementation-plan.html`](plans/implementation-plan.html).

## Getting started

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # Drift codegen
flutter run
```

### Google Drive backup setup

The backup feature needs a Google Cloud OAuth client before it will work
end-to-end:

1. In [Google Cloud Console](https://console.cloud.google.com/), enable the
   **Google Drive API** on a project.
2. Configure the **OAuth consent screen**. Testing mode is sufficient for
   personal use; add the Google account used for backup as a test user.
3. Create an **OAuth 2.0 Android client ID** for package
   `com.fourandhalf.fitness_tracker`, registering the debug keystore SHA-1 and,
   before release builds, the release keystore SHA-1.

Without this setup, Google sign-in and backup/restore will fail; the local
workout, nutrition, progress, and settings features continue to work.

## Testing

```bash
flutter analyze
flutter test
```

The repository includes tests for repositories, services, data models, theme
and shared widgets, onboarding/restore, workout logging, program navigation,
nutrition, progress, settings, and the home dashboard.
