# Change record: endurance track, track fixes, Explore library and splits

This file records what changed, where, and how to prove each claim still
holds. Every claim has an ID. The ID points to an automated check, a named
test or a manual step. When you change any of these areas, re-run the checks
and update this file in the same commit.

## Verify everything

```bash
tool/verify_changes.sh                    # data checks, analyzer, named tests, full suite
tool/verify_changes.sh --regen            # + rebuild the Explore assets and diff them
tool/verify_changes.sh --screens          # + render Explore in dark and light to build/screens/
tool/verify_changes.sh --apk              # + build a release APK and report its size
tool/verify_changes.sh --regen --screens --apk   # everything
```

| Stage | What it proves | Run it alone |
|---|---|---|
| 1. Data checks | IDs `E*`, `L*`, `S*` below. Written in Python, separate from the Dart code, so one catches the other's mistakes | `python3 tool/verify_assets.py` |
| 2. Regeneration (`--regen`) | Rebuilding from `tool/` with a random hash seed reproduces the current assets byte for byte | `python3 tool/build_library.py`, then `git diff assets/` |
| 3. Analyzer | No errors or warnings. The 10 existing `info` lints are allowed | `flutter analyze` |
| 4. Named tests | The Dart tests listed in this file | see the script |
| 5. Full suite | Nothing else regressed | `flutter test` |
| `--screens` | Explore renders in dark and light with real fonts, icons and photos, and with no overflow or exception | `flutter test tool/screens/render_screens_test.dart` |
| `--apk` | The app builds for Android; prints the APK size and the library's share | `flutter build apk --release` |

Requirements:
- **Always:** Flutter 3.47.x and Python 3.
- **`--regen` only:** Pillow, plus network access to `raw.githubusercontent.com`. Instead of network access, set `FEDB_DATASET` and `FEDB_CACHE` to a local copy of free-exercise-db. Byte-identical output also assumes the same Pillow/libwebp version (12.3 was used); another version can encode the photos slightly differently.
- **`--apk` only:** an Android SDK (`flutter config --android-sdk <path>`). The first build also downloads the NDK and CMake.

Last verified: 2026-11-22. Results:
- 59 data checks pass.
- Regenerated assets are identical across Python hash seeds.
- Analyzer: 0 errors and 0 warnings.
- 206 tests pass.
- 12 Explore screens render cleanly (6 dark, 6 light).
- The Android release build succeeds (see §7).

---

## 1. Endurance track
*Commit `0d8b8c4`, merged in PR #3.*

New file: `assets/programs/endurance_run_8wk.json`. It is hand-authored, so
the JSON itself is the source. It is registered in
`ProgramRepository.bundledProgramAssets` and `pubspec.yaml`.

| ID | Claim | Verified by |
|---|---|---|
| E1 | An 8-week track with id `endurance-run-8wk` ships with the app | `verify_assets.py`; test *is bundled and selectable* |
| E2 | Each week has 7 days: 5 sessions and 2 rest days | `verify_assets.py`; test *has eight weeks of five sessions and two rest days* |
| E3 | Volume runs about 23 km to a week-7 peak above 40 km, with lighter weeks 4 and 8 | `verify_assets.py`; test *builds volume to a week-7 peak…* |
| E4 | No build week rises 25% or more over the week before | `verify_assets.py` |
| E5 | The block ends with a 10K time trial | `verify_assets.py`; test *ends with a 10K time trial* |
| E6 | Only the log modes `distance`, `time` and `reps` are used | `verify_assets.py`; test *uses only supported log modes…* |
| E7 | Exercise ids are unique | `verify_assets.py` |

Dart tests live in `test/features/endurance_track_test.dart`.

## 2. Fixes to the existing tracks and the app
*Same commit.*

| ID | Claim | Where | Verified by |
|---|---|---|---|
| F1 | Distance logging. `exercise_logs.distance_meters` is added by a schema v3→v4 migration that keeps old rows | `app_database.dart`, `tables/exercise_logs.dart` | test *distance column is added when upgrading from schema 3* |
| F2 | A run logs distance and time and shows the pace, e.g. 5 km in 27:30 shows 5:30 /km | `exercise_tile.dart` | test *a run logs distance and time and shows the pace* |
| F3 | Rest days (`type: "rest"`) are listed but can't be started, and they don't hold a week open | `program_model.dart` (`isRestDay`, `trainingDays`), `program_providers.dart` | tests *rest days never hold a week open*, *a rest day cannot be started* |
| E8 | The badminton track's 12 empty days are typed `rest`, so the track advances past week 1 | `badminton_mobility_strength.json` | `verify_assets.py`; test *badminton weeks advance without logging the rest day* |
| F4 | The rest timer uses each block's `restSeconds`; `0` skips it | `active_workout_provider.dart` | tests *a block with zero rest skips the timer*, *an interval block rests for its own recovery* |
| F5 | Week focus, day type, instructions and duration, and exercise instructions and side, are parsed and shown instead of being dropped | `program_model.dart`, `day_detail_screen.dart` | test *new model fields survive a JSON round trip* |
| F6 | Time estimates prefer an authored duration and size distance, timed and bodyweight work separately | `flux_widget_service.dart` | tests in group *estimateWorkoutMinutes* |
| F7 | Session detail shows DIST/TIME for runs and no longer labels weighted sets as timed | `session_detail_screen.dart` | test *runs show distance, time and pace; lifts keep KG and REPS* |
| F8 | The Progress tab charts weekly distance and average pace | `progress_screen.dart`, `WorkoutRepository.getWeeklyEndurance` | tests *weekly endurance totals distance…*, *weekly distance card…* |
| F9 | A real version-3 database **file** upgrades to version 4 and keeps its sessions and sets | `app_database.dart` | test *an on-disk version 3 database upgrades without losing data* |

## 3. Explore: muscle library
*Commits `96cb9ae` and `2d529cd`, PR #4.*

Sources, written for this app:
- `tool/library_muscles.py`: the muscle map, the picks, and a note per part.
- `tool/library_cues.py`: the form cues.

`tool/build_library.py` turns these, plus free-exercise-db, into:
- `assets/library/library.json`
- `assets/library/img/*.jpg`

**Edit the sources, never the generated JSON.**

| ID | Claim | Verified by |
|---|---|---|
| L1 | 14 muscle groups and at least 150 exercises (currently 181) | `verify_assets.py`; test *covers the main muscle groups…* |
| L2 | Every pick resolves to an exercise | `verify_assets.py`; test *every pick points at a real exercise…* |
| L3 | Every part has at least 2 gym picks and at least 2 home picks | `verify_assets.py`; test *every muscle has picks for both gym and home* |
| L4 | Rep ranges are formatted `lo–hi`, with timed holds marked `s` | `verify_assets.py` |
| L5 | Every exercise has photos on disk | `verify_assets.py` |
| L6 | Every exercise has a cue and steps | `verify_assets.py` |
| L7 | Home picks avoid barbells, cables, machines and EZ-bars | `verify_assets.py`; test *home picks avoid…* |
| L8 | Photos are credited as public domain, and at least 8 studies are cited over https | `verify_assets.py`; test *credits the photo source and cites studies* |
| L9 | Photos are WebP (quality 76) and stay under a 7 MB budget (currently 5.7 MB, down from 8.4 MB as JPEG) | `verify_assets.py` |
| L10 | Assets regenerate byte-identically, independent of the hash seed | `verify_changes.sh --regen` |
| U1 | Picking a muscle and part updates the picks; the evidence note opens from the Latin name | tests *opens on Chest…*, *a part of the muscle shows its own picks…* |
| U2 | Gym/Home swaps the picks | test *switching to Home swaps in equipment-free picks* |
| U3 | An opened card shows start/finish photos, the cue, steps and a video link | test *opening a card shows photos, the cue, steps and muscles* |
| U4 | Search matches exercise names and equipment | tests *search finds exercises…*, *search matches names and equipment* |
| U5 | The body figure draws every muscle and part, flips to the side where a part shows, and tapping selects the muscle under the finger | tests *every muscle and part can be found on the figure*, *tapping the body figure…*, *choosing a muscle that lives on the back flips the figure* |
| U6 | The library sheet opens from a workout (the info button on split exercises) | test *the exercise sheet opens from anywhere in the app* |
| U7 | The bottom navigation has 5 tabs, including Explore | test *bottom nav has 5 tabs…* |

## 4. Explore: gym and home splits
*Same commits. The source is `tool/library_splits.py`; the output is `assets/programs/split_*.json`.*

| ID | Claim | Verified by |
|---|---|---|
| S1, S7 | 8 splits: 4 gym and 4 home | `verify_assets.py`; test *there are four gym and four home splits* |
| S2 | Gym splits use only gym picks; home splits use only home picks | `verify_assets.py` (per split); test *…is a four-week block built from library exercises* |
| S3 | Each split is 4 weeks with unique exercise ids | `verify_assets.py` |
| S4 | Sets per week run: same, same, more (week 3), then a deload below 75% (week 4) | `verify_assets.py`; test *…progresses through the block and deloads in week 4* |
| S5 | The stored weekly sets per muscle match a fresh recount from week 1 | `verify_assets.py` |
| S6 | Effective sets = direct + indirect × ½, or × ¼ for shoulders (only the front head is helped by pressing) | `verify_assets.py` |
| S8 | The upper/lower and push/pull/legs splits give chest, back, quads, hamstrings, biceps and triceps 10–25 effective sets a week | test *push/pull/legs and upper/lower reach 10-20 sets…* |
| S9 | "Use this split" makes the split the active program and opens it in Programs; the Programs switcher links back to the splits | tests *a split shows its week, volume and can be started*, *the Programs switcher links back to the splits* |
| S10 | End to end: pick a split in Explore, start day A from Programs, log all 19 sets through the UI (straight sets, a superset and three timed planks), finish. Every set is stored against the split, Programs moves on to day B, and History lists the session | test *a split can be started and a full session logged* (`test/features/split_session_test.dart`) |

## 5. Visual design (Explore)
*Commit `2d529cd`.*

These items are judged by eye. The behaviour behind them is pinned by the U* tests.

| ID | Claim | Manual check |
|---|---|---|
| V1 | The body figure is drawn from scratch: spline outlines, detail lines, a coral glow and crosshair guides that aim at one side of paired muscles | Open Explore and choose Shoulders → Side delts. The glow sits on the outer delts and the crosshair targets the left one |
| V2 | Coral is the only extra accent, used only in Explore (see `design/DESIGN.md`) | No coral appears on other tabs |
| V3 | Layout: the figure on the left; the title and FRONT/BACK-tagged part rows on the right; GYM/HOME beside "Recommended" | Compare against the reference screenshots at 390 px wide |
| V4 | Cards show a thumbnail, a TOP PICK tag and a focus meter (3 bars = primary, 2 = assists) | Look at any muscle's picks |
| V5 | No layout overflow at 390 px wide | `--screens` fails on any overflow or exception |
| V6 | Light and dark themes both look right | `--screens` writes `dark_*.png` and `light_*.png` to `build/screens/`; compare them side by side |
| V7 | Wrapped muscle labels on a split day never start a line with "·" | `build/screens/*_5_split_detail.png` |

## 6. Research claims shown in the app

Each note in the app paraphrases one of these sources. To verify a note,
open its source.

| Shown in | Claim | Source |
|---|---|---|
| Chest → Upper chest | Upper-chest EMG peaks at a bench angle around 30°; past about 45° the front delts take over | https://pmc.ncbi.nlm.nih.gov/articles/PMC7579505/ |
| Chest → Mid chest | Push-ups at a similar relative load gave hypertrophy similar to the bench press | https://pmc.ncbi.nlm.nih.gov/articles/PMC5812864/ |
| Shoulders | Front delts are highest in the overhead press; side delts in the lateral raise; the reverse pec deck beats the lateral raise for rear delts | https://pmc.ncbi.nlm.nih.gov/articles/PMC7706677/ |
| Hamstrings → Knee flexion | The seated leg curl gave about 1.5× the hypertrophy of the prone curl (14% vs 9%) | https://pmc.ncbi.nlm.nih.gov/articles/PMC7969179/ |
| Hamstrings → Hinge | Hinges bias the biceps femoris long head and semimembranosus; curls bias the semitendinosus | https://www.strongerbyscience.com/exercise-selection-hamstrings/ |
| Glutes → Glute max | Step-ups showed the highest glute max activation, ahead of hip thrusts, deadlifts, lunges and squats | https://pmc.ncbi.nlm.nih.gov/articles/PMC7039033/ |
| Core → Obliques | Side planks gave the highest oblique activity among planks | https://pmc.ncbi.nlm.nih.gov/articles/PMC7345922/ |
| Triceps → Long head | Overhead extensions grew more triceps than pushdowns over 12 weeks | https://brookbushinstitute.com/articles/exercise-range-of-motion-and-hypertrophy |
| Calves → Gastrocnemius | Lengthened partials grew more gastrocnemius than shortened partials | https://www.gymnoteplus.com/blog/stretch-mediated-hypertrophy (Kassiano et al. 2023) |
| Back → Lats | Grip width barely changes lat activation in pulldowns | https://www.shred.app/thinking/pull-up-grip-width-muscle-activation |
| Splits (10–20 sets, about twice a week) | Weekly volume and frequency recommendations | https://pmc.ncbi.nlm.nih.gov/articles/PMC8884877/, https://pubmed.ncbi.nlm.nih.gov/30558493/ |

The app also lists these sources under *Explore → How these picks were chosen*.

## 7. Android build and app size

The release build was run with `flutter build apk --release` on Flutter 3.47.4, Android SDK platform 36 and NDK r28c.

| Build | Size |
|---|---|
| Universal APK (all three CPU types) | 78.9 MB |
| arm64-v8a, what most phones get from the Play Store | 33.5 MB |
| armeabi-v7a | 31.5 MB |
| x86_64 | 35.1 MB |

About 68 MB of the universal APK is the Flutter engine and app code compiled once per CPU type, so publish an app bundle (`flutter build appbundle`) or split per ABI. The Explore library adds 5.7 MB of photos and 0.3 MB of JSON.

For comparison, `main` without Explore builds to 27.5 MB for arm64, so Explore costs a typical install **6.0 MB**: 5.7 MB of photos plus JSON and code. Both builds print the same Gradle notice asking some plugins to migrate to Built-in Kotlin. That notice comes from the plugins, not this app, and it doesn't block the build.

## 8. Not verified

These still need a person or a Mac:
- Installing and using the APK on a real phone (the build itself is verified above).
- An iOS build. This needs macOS and Xcode.
- Feel checks no test can make: whether the figure's tap targets are comfortable on a small screen, and whether the photos load quickly enough on a slow phone.

## Keeping this file honest

1. **A data or rule change** (picks, splits, endurance volume): edit the
   `tool/` sources or the JSON, then run `tool/verify_changes.sh --regen`.
   If a check fails on purpose, update the check and the row here in the
   same commit.
2. **A new behaviour:** add a row with a new ID. Point it at a test, or add
   a check to `tool/verify_assets.py`.
3. **Something deliberately removed:** strike through the row rather than
   deleting it, and say why.
