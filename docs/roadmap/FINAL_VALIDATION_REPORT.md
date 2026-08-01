# Final validation report

This report remains gate-controlled: the current branch contains the core stabilization checkpoint and guarded product foundations, while profiling, hardware journeys, and unfinished feature UI/transport remain open.

## Required evidence

| Gate | Current evidence | Status |
| --- | --- | --- |
| Branch/checkpoint/remote | `1b46652` pushed to `origin/codex/equran-roadmap`; baseline `161ece9` | Pass |
| Format/analyze/tests | Full format, `flutter analyze --fatal-infos`, 27 deterministic tests | Pass |
| Localization/dependency policy | ARB parity, `flutter gen-l10n` consistency, no GMS/Firebase tokens | Pass |
| Android | Fresh debug, profile split, release split ABI, and release app bundle builds; release signing guard | Pass (local non-CI release) |
| Linux | Fresh release bundle | Pass |
| Core product safety | Backup validation/rollback foundations, independent metal rates, local flags | Pass for implemented scope |
| Integration/device/profiling | Hardware journeys, startup/frame/memory/search/extraction benchmarks, Windows/Chrome | Unknown/open |
| Manual plan/draft PR | Manual device plan and GitHub draft PR | Open |

## Known unavailable evidence at baseline

GitHub CLI credentials are invalid for draft-PR creation, Android hardware is not attached, Chrome and Windows are unavailable on the host, `apkanalyzer` is unavailable, and no manual device plan has been executed. These are recorded as open rather than inferred passes.
