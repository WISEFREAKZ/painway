# Physio & Mobility App

A 100% free physical therapy, mobility, and habit-tracking Android app.
Flutter frontend, Supabase free-tier backend (read-only content), and a
fully local notification engine so there are **zero ongoing server
costs**.

## Project layout

```
supabase_schema.sql              # Run this in the Supabase SQL Editor
pubspec.yaml                     # Flutter dependencies
lib/
  main.dart                      # App entry point
  theme.dart                     # Medical-wellness color palette & ThemeData
  models/
    models.dart                  # CategoryModel, ExerciseModel (null-safe)
  services/
    supabase_config.dart         # Supabase init + read-only queries
    notification_service.dart    # Local water & stretch reminder engine
  widgets/
    circular_countdown.dart      # Reusable countdown timer w/ haptic alert
  screens/
    dashboard_screen.dart        # Screen A — habit tracker + settings + grid
    exercise_list_screen.dart    # Screen B — exercises for a category
    exercise_guide_screen.dart   # Screen C — media, steps, countdown
```

## Setup

### 1. Supabase

1. Create a free project at supabase.com.
2. Open **SQL Editor**, paste in `supabase_schema.sql`, and run it. This
   creates `categories` and `exercises`, enables RLS with public
   **read-only** policies, and seeds the two required categories
   (Plantar Fasciitis, Hip & Pelvic Pain) with sample exercises.
3. Copy your **Project URL** and **anon public key** from
   Project Settings > API.
4. Paste them into `lib/services/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'https://YOUR-PROJECT-REF.supabase.co';
   static const String supabaseAnonKey = 'YOUR-PUBLIC-ANON-KEY';
   ```
5. Swap the placeholder `media_url` values in the seed data for real
   open-source GIF/image URLs (e.g. pulled from Wger's public exercise
   media or another open-source fitness dataset with a permissive
   license). You can also add more categories/exercises any time —
   the app pulls them dynamically, no rebuild required.

### 2. Flutter

```bash
flutter pub get
flutter run
```

### 3. Android manifest — already configured

`android/app/src/main/AndroidManifest.xml` is included in this project,
fully pre-configured with everything `flutter_local_notifications`
needs: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`,
`RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `INTERNET`, `WAKE_LOCK`, plus the
`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`,
and `ForegroundService` entries so reminders survive a reboot. Nothing
to add manually — just drop this file in if you're merging into an
existing Flutter project (`flutter create` generates the surrounding
`android/` scaffold; replace its manifest with this one).

Minimum SDK: set `minSdkVersion` to at least 23 in
`android/app/build.gradle` for reliable exact-alarm scheduling.

### 4. Media assets

The seed data now covers **8 categories and 133 exercises**: Foot & Heel
(Plantar Fasciitis), Hip & Pelvic Pain, Lower Back, Knee, Shoulder, Neck,
Arms, and Legs. Every `media_url` points to a real, HTTP-verified
(200 OK) image hosted on GitHub's raw CDN from
[`free-exercise-db`](https://github.com/yuhonas/free-exercise-db), an
open, Unlicense/public-domain exercise dataset — no API key or auth
required. See the comment block at the top of the seed data in
`supabase_schema.sql` for exactly which source exercise each image
came from.

**On GIFs vs static images:** true animated GIF demonstrations for
these specific therapeutic exercise variations aren't available from a
source with a genuinely verifiable open license. Datasets that do
offer exercise GIFs are generally repackaging content from ExerciseDB,
a commercial/closed API — a third-party repo slapping an MIT license
on someone else's paid dataset doesn't make that redistribution
legitimate, so using them would carry real copyright risk. `free-exercise-db`'s
Unlicense (public-domain) status is directly confirmed by the
maintainer's own repo, which is why it's used here despite being
static images. If you later find or license real GIFs, swapping them
in is a one-line change per row — `Image.network()` renders GIFs and
static images identically, no app code changes needed.

Swap in your own images any time by updating the `exercises` table —
no app rebuild needed. If your Supabase project was seeded from an
earlier version of this file, uncomment the two `truncate` lines near
the top of the seed data section before re-running, so you don't end
up with duplicate rows.

## Building the APK

This chat environment can write and check code, but it cannot compile
Android apps — there's no Flutter SDK, no Android SDK, and no network
access to the hosts that provide them (`storage.googleapis.com`,
`dl.google.com`, `services.gradle.org` are all unreachable from here).
So there is no way for me to hand you a compiled `.apk` file directly —
what follows gets you one in about two minutes on your own machine or
in CI.

**On a machine with Flutter installed** (this is the fastest, safest
path — it lets Flutter's own tooling fill in the one binary piece this
project can't include: the Gradle wrapper jar):

```bash
cd physio_app
flutter pub get
flutter build apk --release
```

The finished file appears at
`build/app/outputs/flutter-apk/app-release.apk`. Install it on a
connected device/emulator with:

```bash
flutter install
```

Everything else — `AndroidManifest.xml`, both `build.gradle` files,
`settings.gradle`, `gradle-wrapper.properties`, `MainActivity.kt`,
`styles.xml`, launch background, and launcher icons at every mipmap
density — is already in this project. `flutter build apk` will
auto-generate the two files it always regenerates on first run
(`android/local.properties` and the `gradlew`/`gradlew.bat` wrapper
scripts + wrapper jar), so you don't need to touch anything else.

**If you don't have Flutter installed locally**, the no-local-setup
options are:
- **GitHub Actions**: push this project to a repo and add a workflow
  that runs `subosito/flutter-action` then `flutter build apk`; the
  APK comes out as a build artifact you download.
- **Codemagic** (free tier for open-source/personal projects): connect
  the repo and use its default Flutter Android workflow.

Before building for real use, remember to:
1. Add your Supabase URL/anon key in `lib/services/supabase_config.dart`.
2. Change `applicationId` in `android/app/build.gradle` away from
   `com.example.physio_app` if you intend to publish it.
3. Replace the debug-signed release build in `android/app/build.gradle`
   with your own signing config before publishing to the Play Store —
   debug signing is fine for personal installs/sideloading only.

## Notes on cost & maintenance

- **Backend**: Supabase free tier (500MB DB, 1GB storage, no credit
  card) — read-only, no auth, no server functions. Nothing to
  maintain beyond occasionally adding rows via the SQL editor or
  Table Editor UI.
- **Notifications**: 100% on-device via `flutter_local_notifications`
  + `timezone`. No push service, no server pings, no cost — reminders
  keep firing even if Supabase is ever unreachable.
- **Media**: `Image.network()` streams GIFs/images directly from
  whatever open-source dataset URL is stored in `media_url` — no
  storage cost to this project beyond the DB row itself.
