@AGENTS.md

# CLAUDE.md

`AGENTS.md` (imported above) is the architecture map and the hard guardrails. This file adds the day-to-day workflow. Where they overlap, `AGENTS.md` wins.

## Toolchain

- Flutter **>= 3.44.0** (pinned in `.fvmrc`, enforced in `pubspec.yaml`). The code uses 3.44 APIs (`ScrollCacheExtent`, `onReorderItem`), so `flutter analyze` fails on older SDKs.
- CI uses `subosito/flutter-action` with `channel: stable` (unpinned), so it runs the newest stable release, not necessarily the `.fvmrc` version.
- Do not commit incidental changes that a different SDK makes to `pubspec.lock` or `analysis_options.yaml`. `pubspec.lock` must stay tracked (see `AGENTS.md`).

## Quality gates (mirror `.github/workflows/deploy.yml`)

Run these before declaring work done; CI runs the same steps on every PR to `main`:

```bash
dart run tool/verify_dependency_policy.dart   # no GMS/Firebase tokens
dart run tool/verify_localizations.dart       # every ARB has every template key
flutter gen-l10n && git diff --exit-code -- lib/l10n   # generated l10n is committed and in sync
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

`dart format .` and `flutter analyze` must finish with zero findings (infos included).

## Localization

- `lib/l10n/app_en.arb` is the template. Add placeholders/metadata (`@key`) only there.
- Any new key must be added to **all** ARB files (`ar bn de en fa id tr ur`), otherwise `verify_localizations` fails CI. Run `flutter gen-l10n` and commit the regenerated `lib/l10n/app_localizations*.dart`.
- Prefer `AppLocalizations.of(context)!` over hard-coded user-facing strings (a few legacy messages, e.g. in `backup_service.dart`, are still English-only). Machine-drafted translations should be called out in the commit message for native-speaker review.

## Conventions worth knowing

- **Images:** use `EquranAssetImage` (`lib/widgets/common/equran_asset_image.dart`) instead of `Image.asset`. Several bundled illustrations are 1000-1254 px square and must be decoded at display size to keep memory low on low-end devices.
- **Device capability:** `DeviceCapabilityService.instance.profile` (detected once during blocking startup) exposes `allowsDecorativeEffects`, `allowsAdjacentPrefetch`, etc. Gate expensive decoration (blurs, particles, endless animations) on it.
- **Startup:** `StartupCoordinator` has a blocking stage (settings, capability detection) and a deferred stage (boxes, Quran data, audio, prayer, widgets). Keep new initialization in the deferred stage unless the first frame needs it.
- **Web is a shipped target** (`deploy-web.yml` publishes to GitHub Pages). `dart:io` `Platform` getters throw on web, so guard with `kIsWeb` first.
- **Roadmap features** (`lib/features/`, `lib/hifz/memory_*`, `reader_controllers`) are fail-closed behind `FeatureFlagStore` and not yet reachable from the UI. Do not enable a flag by default.
- **Word by word** (`lib/word_by_word/`, `docs/word_by_word.md`): optional downloaded pack; `alignWordRanges` returns null unless word counts match exactly, so unexplained ayahs stay plain text. Never relax that to a best-effort match.
- **Backup/restore** (`lib/backend/backup_service.dart`) validates everything, snapshots all boxes, and rolls back on failure. A new Hive box that holds user data must be added to the export, `_snapshotStores`, `_restoreStores` and the restore sections together.

## Running the app

- Android/Linux/Windows are release targets; web is a demo built with `flutter build web --release --base-href=/app/`.
- Release signing is enforced in CI (`-PrequireReleaseSigning`); local release builds fall back to debug signing.
