# Execution state

## Current checkpoint

- Phase: 0 — repository audit and baseline.
- Objective: establish a reproducible evidence set before implementation.
- Branch: `codex/equran-roadmap`, based on `origin/main` at `9274a497e722eda1a5e5ce37a44a9fb740b6f9`.
- Checkpoint commit: not yet created.
- Remote push: blocked until GitHub credentials are re-authenticated; no push has been attempted.

## Completed work

- Read `AGENTS.md`, `README.md`, `pubspec.yaml`, `analysis_options.yaml`, and `l10n.yaml`.
- Fetched `origin --prune`; local `main` matched `origin/main` and was clean.
- Created the dedicated branch without absorbing unrelated work.
- Ran baseline formatting, dependency resolution, analysis, test discovery, toolchain checks, and Android debug/release build attempts.
- Created the roadmap record set in this directory.

## Baseline results

- `dart format --output=none --set-exit-if-changed .`: exit 0, 185 files unchanged; package-URI warnings were emitted while scanning third-party analyzer options.
- `flutter pub get`: exit 0; lockfile unchanged; 76 packages report newer versions outside current constraints.
- `flutter analyze`: exit 0, no issues.
- `flutter test`: exit 1 because the repository has no `test/` directory.
- Flutter SDK: 3.44.0 at `/opt/flutter`; Dart 3.12.0. The checked-in `.fvmrc` still says 3.22.1 while `pubspec.yaml` requires Flutter >=3.41.7.
- `flutter doctor -v`: Android and Linux toolchains pass; Chrome is unavailable; Flutter/Dart are not on PATH; no Android device is attached.
- Android debug APK: built successfully, 187,703,855 bytes (debug).
- Android release split attempt: Gradle/R8 progressed and generated mapping outputs, but no current split APK was available at the end of the baseline run; the existing 30,839,093-byte APK is dated before this run and must not be counted as a new pass.
- Linux, Windows, integration, startup, frame, memory, search, and extraction measurements: not yet run.

## Audit observations

- `lib/main.dart` performs audio-engine setup, Hive initialization, every current box initialization, migrations, Quran initialization, translation preload, timezone/prayer scheduling, and Android widget setup before `runApp()`.
- `BackupService` is schema version 1 and only exports settings, legacy favourites, and reading history; restore clears live boxes before writing and has no rollback transaction.
- `ZakatCalculatorPage` derives silver price from gold (`gold / 80`) while labeling the result synchronized live market data.
- `QuranTextSearchService` builds full Arabic/translation indexes in memory and uses `Future.microtask`, which does not move CPU work off the UI isolate.
- `QpcV4FontService` registers light and dark variants for every loaded page and waits by polling every 100 ms for duplicate loads.
- `AudioDownloadService` reads a complete ZIP into memory on the UI isolate during extraction.
- CI quality currently installs dependencies only; format, analysis, tests, localization, assets, and builds are not gates.

## Next action

Finish the evidence-backed defect inventory, create the Phase 0 checkpoint commit, and attempt the first remote push. Do not begin dependent implementation until the checkpoint is internally consistent.

