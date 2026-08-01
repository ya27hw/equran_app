# Execution state

## Current checkpoint

- Phase: 1–6 core implementation and Phase 7–12 guarded foundations.
- Objective: repair trust/performance defects, add safe startup/quality gates, and keep incomplete product features local and disabled.
- Branch: `codex/equran-roadmap`, based on `origin/main` at `9274a497e722eda1a5e5ce37a44a9fb740b6f9`.
- Baseline checkpoint: `161ece9` (pushed).
- Current implementation checkpoints: `1b46652` (core foundations), `8d9d94b` (CI/build gates), `fc6dedc` (Zakat/backup guidance), `ed3ceb3`/`547280b` (local assignments and guarded validators), `c1fdb1a` (validation counts), `08dee51` (Memory Twin metadata round-trip hardening), `8102e61` (PR quality trigger), `f51ddf7` (release-only signing guard), and `97a1baf` (evidence count correction), all pushed to `origin/codex/equran-roadmap`.
- Remote push: Git push is available with the configured credential; `gh auth status` still reports an invalid keyring token.
- Draft PR: https://github.com/ya27hw/equran_app/pull/90.

## Completed work

- Read `AGENTS.md`, `README.md`, `pubspec.yaml`, `analysis_options.yaml`, and `l10n.yaml`.
- Fetched `origin --prune`; local `main` matched `origin/main` and was clean.
- Created the dedicated branch without absorbing unrelated work.
- Ran baseline formatting, dependency resolution, analysis, test discovery, toolchain checks, and Android debug/release build attempts.
- Created the roadmap record set in this directory and committed it as `161ece9`.
- Added versioned backup sections, pre-write section validation, rollback snapshots, and independent Zakat metal-rate handling.
- Added staged startup, local feature flags, device capability policy, bounds-safe CPAL/ZIP handling, active-theme font loading, and incremental search.
- Added disabled-by-default Memory Map, Memory Twin, Constellations, Halaqah, Reciter Lens, and Journey Capsule foundations with deterministic tests.
- Added strict localization/dependency policy scripts and CI quality/build gates.

## Baseline results

- `dart format --output=none --set-exit-if-changed .`: exit 0, 207 files unchanged; package-URI warnings were emitted while scanning third-party analyzer options.
- `flutter pub get`: exit 0; lockfile unchanged; 76 packages report newer versions outside current constraints.
- `flutter analyze`: exit 0, no issues.
- `flutter test`: current suite passes (27 deterministic tests); the original baseline had no `test/` directory.
- Flutter SDK: 3.44.0 at `/opt/flutter`; Dart 3.12.0. The checked-in `.fvmrc` still says 3.22.1 while `pubspec.yaml` requires Flutter >=3.41.7.
- `flutter doctor -v`: Android and Linux toolchains pass; Chrome is unavailable; Flutter/Dart are not on PATH; no Android device is attached.
- Android debug APK: built successfully, 187,703,855 bytes (debug).
- Android release split attempt: Gradle/R8 progressed and generated mapping outputs, but no current split APK was available at the end of the baseline run; the existing 30,839,093-byte APK is dated before this run and must not be counted as a new pass.
- Fresh Android release split passed: armeabi-v7a 29,969,404 bytes, arm64-v8a 31,704,724 bytes, x86_64 33,227,376 bytes.
- Fresh Android profile split passed: armeabi-v7a 50,341,032 bytes, arm64-v8a 51,946,978 bytes, x86_64 53,421,523 bytes; debug APK also passed.
- Fresh Android release app bundle passed: `app-release.aab`, 78,709,337 bytes.
- Fresh Linux release passed (`build/linux/x64/release/bundle/eQuran`, bundle 147 MB).
- Hosted PR quality run 207 passed: dependency/localization checks, formatting, fatal analysis, tests, and debug Android build. Release/package jobs were skipped on the PR event by design; the first run 206 caught and motivated the release-only signing guard fix.
- Chrome, Windows, Android hardware, integration/startup/frame/memory/search/extraction measurements, and `apkanalyzer` evidence remain unavailable on this host.

## Audit observations

- `lib/main.dart` performs audio-engine setup, Hive initialization, every current box initialization, migrations, Quran initialization, translation preload, timezone/prayer scheduling, and Android widget setup before `runApp()`.
- `BackupService` is schema version 1 and only exports settings, legacy favourites, and reading history; restore clears live boxes before writing and has no rollback transaction.
- `ZakatCalculatorPage` derives silver price from gold (`gold / 80`) while labeling the result synchronized live market data.
- `QuranTextSearchService` builds full Arabic/translation indexes in memory and uses `Future.microtask`, which does not move CPU work off the UI isolate.
- `QpcV4FontService` registers light and dark variants for every loaded page and waits by polling every 100 ms for duplicate loads.
- `AudioDownloadService` reads a complete ZIP into memory on the UI isolate during extraction.
- CI quality now gates formatting, fatal analysis, tests/coverage, localization generation/drift, dependency policy, and Android debug; release jobs gate signed split APKs, app bundle, and F-Droid Play Core scan.

## Next action

Keep the draft PR on the pushed branch and complete the remaining host/device gates when the required hardware, Chrome/Windows runners, `apkanalyzer`, and profiling instrumentation are available. Record unavailable evidence as unknown rather than passing it by inference; keep product flags closed until their acceptance UI/content/transport work is complete.
