@AGENTS.md

# CLAUDE.md

`AGENTS.md` (imported above) is the architecture map and the hard guardrails. This file adds the day-to-day workflow. Where they overlap, `AGENTS.md` wins.

## Toolchain

- Flutter **>= 3.44.0** (pinned in `.fvmrc`, enforced in `pubspec.yaml`). The code uses 3.44 APIs (`ScrollCacheExtent`, `onReorderItem`), so `flutter analyze` fails on older SDKs.
- CI uses `subosito/flutter-action` with `channel: stable` (unpinned), so it runs the newest stable release, not necessarily the `.fvmrc` version.
- Do not commit incidental changes that a different SDK makes to `pubspec.lock` or `analysis_options.yaml`. `pubspec.lock` must stay tracked (see `AGENTS.md`). The one exception is the release lockfile regeneration described in "Releases and F-Droid" below.

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

## Releases and F-Droid

**How a release happens.** Releases are cut from `main`. A push to `main` runs `.github/workflows/deploy.yml`, which reads `version:` from `pubspec.yaml` and, if the tag `v<version>` does not exist yet, builds the APKs and the Linux bundle and creates that tag and GitHub release. If the tag already exists the build and release jobs are skipped. So a release needs a new version in `pubspec.yaml` (bump the build number after the `+` as well) and a `CHANGELOG.md` entry, merged to `main`. `main` is protected by a ruleset that requires the `quality` check, and auto-merge is enabled, so open a PR and let it merge.

**F-Droid builds from tags.** The F-Droid recipe (`com.app.equran` in `fdroiddata`) uses `UpdateCheckMode: Tags`, reads the version from `pubspec.yaml` at the tag, and sets versionCode to the build number times 10 plus the ABI index (build 107 gives 1071, 1072, 1073). Its prebuild step runs `flutter pub get --enforce-lockfile` with the Flutter version F-Droid picks from its own `versions` file (3.47.7 when this was written). That fails with "Would change N dependencies" if `pubspec.lock` does not match what that SDK resolves (issues #86 and #112).

**Before tagging a release**, regenerate `pubspec.lock` with the Flutter version F-Droid uses, not whichever SDK happens to be installed locally:

1. Get that SDK, for example `git clone --depth 1 --branch <version> https://github.com/flutter/flutter.git` into a scratch directory. Do not use the repo's `.fvmrc` version.
2. Run `flutter pub get` with it. Do not hand-edit the lockfile. Packages that the SDK pins (`intl`, `matcher`, `test_api`, `vector_math` and similar) change between SDK versions.
3. Run `flutter pub get --enforce-lockfile` with the same SDK. It must succeed.
4. Revert any incidental change the newer SDK makes to `analysis_options.yaml`.

Plain `flutter pub get` in CI does not enforce the lockfile, so CI will not catch a stale lockfile. A lockfile cannot satisfy two SDKs that pin different versions. If your local SDK is older than F-Droid's, `--enforce-lockfile` failing locally is expected.

**A published tag is not fixable in place.** F-Droid has already seen it, and the workflow skips existing tags. If a tagged release has a bad lockfile, fix `main` and bump the version to cut a new tag. Do not delete and re-push the tag.

**Local test caveat.** The golden images in `test/redesign/goldens/` are rendered on the Linux CI runner with the time zone pinned to `Asia/Muscat`. On macOS most golden tests fail on pixel differences. Treat CI as the reference for those.

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
