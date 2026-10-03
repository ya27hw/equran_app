# POLISH_EQ3_REPORT.md — EQ-3 focused repair, iteration 2

Branch: `lane/eq3-polish` (rebased onto `0faaccc`). No flutter/dart run (not installed; orchestrator verifies). All edits are **no-behavior-change-except-the-fix**; each is documented below.

## 1. Dashboard: Daily Dua unavailable-state + retry (already in-progress, kept as-is)

File: `lib/home_dashboard/home_dashboard_page.dart`

- `_retryDailyDua()` — `home_dashboard_page.dart:1927` — re-issues `_dailyDuaRepository.getDailyDua(widget.date)` into `_dailyDuaFuture` via `setState` (existing ValueNotifier/setState-only constraint respected).
- `_buildUnavailableState(context)` — `home_dashboard_page.dart:2048` — replaces the previous silent `SizedBox.shrink()` on error (was `home_dashboard_page.dart:1950` in the `hasError || !hasData` branch) with a visible card: `EquranSectionHeader` (reused, `lib/widgets/common/equran_components.dart:111`), `_HomePremiumCard` with `_duaAsset` (`home_dashboard_page.dart:42`), and a `Retry` `TextButton` wired to `_retryDailyDua` (`home_dashboard_page.dart:2105`).
- l10n keys all pre-existing in `lib/l10n/app_en.arb`: `dailyDua` (:98), `seeAll` (:99), `duasUnavailable` (:742), `hisnAlMuslimNotLoaded` (:743), `retryAction` (:744). No new strings.
- Behavior change (intended): users now see why the Dua section is missing and can retry; prior behavior was an invisible collapse. Otherwise no layout/business-rule changes.

## 2. Frame-rate policy: dead-code removal (already in-progress, kept as-is)

File: `lib/services/frame_rate_policy_manager.dart`

- Removed `_AppliedFrameRateHint.interactive60` enum member (`frame_rate_policy_manager.dart:6`).
- Removed `_applyInteractive60()` (was `:308`) and `preferInteractive60Temporarily()` (was `:366`).
- Verified zero callers across `lib/` + `test/` (grep for `preferInteractive60Temporarily`, `_applyInteractive60`, `interactive60` → none).
- Behavior change: none — dead private API only; `_activeBlockers` (`:311`), `_clear` (`:296`), `audioIdle30` (`:275`) untouched.

## 3. Share-image sanity guard (NEW this iteration)

File: `lib/home/read.dart`, share-image functions only.

- `_renderShareImagePng()` — `read.dart:6876` — now throws `StateError` if `quranVerseText(_currentChapter, _currentVerse).trim().isEmpty` (`read.dart:6877-6881`).
- `_captureShareImagePng()` — `read.dart:6916` — after `toImage(pixelRatio:1)` + `toByteData(png)`, the existing null check already throws `StateError('Unable to encode share image.')`; added an explicit empty-bytes check throwing `StateError` when the PNG byte list is empty (`read.dart:6937-6942`).
- Both exceptions flow through the pre-existing `try/catch` in `_shareCurrentAyahImage()` (`read.dart:6733-6787`) → `FlutterError.reportError` + existing SnackBar (`kDebugMode` detail / `'Unable to share ayah image.'` release string). No new strings invented, no layout changes, no new deps.
- Behavior change: previously empty text or empty/corrupt capture would still attempt `File.writeAsBytes` + open the share sheet with a broken PNG; now it surfaces the existing error path instead. Otherwise identical.

## 4. Issue #88 — Muhammad Al-Luhaidan reciter — DEFER (live-verified)

Live network verification (2026-09-09, everyayah.com reachable, HTTP/2 200). Full trace in `POLISH_EQ3_NOTES.md:5-13`:

1. `lib/utils/reciter.dart` catalog has no Luhaidan profile; `ReciterProfile.everyAyahFolder` must match the CDN tree exactly.
2. `https://everyayah.com/data/recitations.js` (official registry, 79 recitations) — no Luhaidan/luhaydan entry.
3. `recitations_ayat.html` + `recitations_pages.html` — no match.
4. `https://everyayah.com/data/` live directory index (83 top-level folders) — NO folder matching `luhaidan|luhaydan|al-luhaidan|haidan`.

Adding a `ReciterProfile` now would point at a non-existent CDN folder → 404s for streaming and ZIP shards.

**Recheck steps** (if the CDN later adds him):
- Re-verify `https://everyayah.com/data/` for a new folder matching `luhaidan|luhaydan|al-luhaidan|haidan`.
- Re-verify `recitations.js` for a new entry with an `alLuhaidan`-style id.
- If present, add a `ReciterProfile(id, englishName, arabicName, everyAyahFolder, fallbackSurahUrl)` entry in `lib/utils/reciter.dart` with `everyAyahFolder` = the exact CDN folder name, then run the app's reciter picker + streaming/offline ZIP flow.

## 5. Explicitly NOT attempted (out of scope for this focused repair)

- **Player Page retirement** — not attempted; large UI-surface removal, needs its own feature task + QA.
- **Zakat redesign** — not attempted; design/spec task, not a repair.
- **Calendar overhaul** — not attempted; not part of EQ-3 defects.

Each of these remains a separate follow-up; nothing in this commit precludes them.

## 6. Verification summary

- `git status --short` before edits: only the two expected modified files + untracked notes (`POLISH_EQ3_NOTES.md`, `TASK_EQ3.md`, `TASK_EQ3_REPAIR.md`). Nothing reverted or reformatted.
- Grep-verified zero callers for removed frame-rate API.
- Grep-verified l10n keys, `_duaAsset`, and `EquranSectionHeader` exist.
- Constraint compliance: only `~/equran_lane_eq3` touched; no merge/push/secrets; no GMS/Firebase; `pubspec.lock` untouched; ValueNotifier + setState/Hive only.