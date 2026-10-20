# Reading Wrapped: Spec

Status: draft for review
Owner: TBD
Related: [docs/word_by_word.md](word_by_word.md) (optional pack pattern), `lib/home/quran_stats_page.dart`, `lib/home/statistics_redesign.dart`

## 1. Goal

Give readers a personal, shareable recap of their Quran reading built entirely from data the app already keeps on the device. The recap is a styled image the user shares outside the app. Each share is a download channel. The card ends with a short feedback prompt, so shares also produce feedback.

Success signals (measured without analytics, since the app ships no tracking):

- Downloads: F-Droid install counts and GitHub release download counts, compared before and after each Wrapped season.
- Feedback: GitHub issues with the `wrapped-feedback` label.
- Shares: not measured directly. Treat as an unknown unless the user opts in to a counter.

## 2. Scope

### v1 (this spec)

- A year-in-review card for the current Gregorian calendar year, with a Dec 1 to Jan 31 entry window plus an always-available preview from the stats page.
- Two formats: a 1080x1920 story card and a 1080x1080 square card.
- Light and dark variants following the app theme.
- Arabic (RTL) and English layouts, with all strings localized.
- A feedback step after sharing.

### Out of scope for v1

- Hijri-year or Ramadan-only recaps (candidate for v2, reuses the same engine).
- Any network call, account, leaderboard, or cloud share link.
- Recitation or tajweed scoring.
- Per-ayah "most returned to" statistics (see section 4, not derivable today).

## 3. Data: what exists and what does not

All inputs come from `QuranActivityDB` (box `quran_activity`, typed `QuranActivityDay`, defined in `lib/backend/companion_storage_models.dart`). Fields per local day:

| Field | Written today? | Notes |
| --- | --- | --- |
| `readAyahKeys` (`"surah:ayah"` strings) | Yes | Distinct ayahs read that day. Basis for ayahs and surah progress. |
| `ayahsRead` | Yes | Count of new keys that day. Summing across days double-counts ayahs re-read on another day, so do not use it for the yearly total. |
| `readingSeconds` | Yes | Written by `_recordReadingTime` in `lib/home/read.dart`. |
| `listeningSeconds` | **No** | Declared and backed up, but nothing increments it. Always 0. |
| `pagesRead` | **No** | Declared, but nothing increments it. Always 0. |

Derived values:

- **Ayahs read in the year:** size of the union of all `readAyahKeys` for days in the year. This is the honest distinct count.
- **Surahs completed:** a surah counts when every ayah key for that surah is in the union. Use `quran.getVerseCount(surah)`, already used in `lib/home/statistics_redesign.dart`.
- **Reading time:** sum of `readingSeconds` for the year.
- **Longest streak:** the stats repository already computes a highest streak (see `highestStreak` in `lib/home/quran_stats_page.dart` around lines 526 to 543). Reuse it, filtered to the year, or compute it from `hasQuranReadingActivity` days. Do not reuse `_currentStreak`, which only returns the streak ending today.
- **Favourite surah:** the surah with the most distinct ayahs read in the year. Ties break toward the lower surah number.
- **Active days:** count of days where `hasQuranReadingActivity` is true.

### Prerequisite: listening time

Listening time is a headline number for an audio-capable app, but nothing records it. Two options:

1. **Recommended:** instrument the existing audio paths in `lib/home/read.dart` to add listened seconds to `listeningSeconds`, using the same write pattern as `_recordReadingTime`. This is a behavior change to existing data, so it needs its own change and its own tests.
2. Omit listening time from v1 and ship reading only.

Pages read is out of scope unless someone instruments it. Do not show it.

### Dropped: "ayah you returned to most"

It needs a per-ayah visit counter. The current model stores only a per-day set. Adding it means a new field and a Hive adapter change. Defer it to v2.

## 4. Eligibility and empty states

- A card is generated only if the year has at least **7 active days**. Below that, show an empty state: "Your recap appears once you have read on 7 days this year."
- If the user has no data at all, hide the entry point.
- Show a preview on the stats page at any time, labelled as "so far this year". Share is enabled after the threshold.

## 5. Architecture

### New module

`lib/wrapped/`, following the feature-first layout in `AGENTS.md`:

- `wrapped_summary.dart`: pure model (`WrappedSummary`) and the computation. It takes `List<QuranActivityDay>`, the year, and a surah-verse-count function. It has no Flutter or Hive dependency so it can be unit-tested directly.
- `wrapped_card.dart`: the card widget. It takes a `WrappedSummary` and a `WrappedFormat` (story or square) and renders from props only.
- `wrapped_page.dart`: preview, format picker, share button, feedback step.

Keep the computation out of widget build methods. Compute once per open, not per frame.

### Reuse: share-image renderer

The off-screen capture logic (`_renderShareImagePng` and `_captureShareImagePng`) lives privately in `lib/home/read.dart` around lines 6085 to 6160. Extract it to a shared helper, for example `lib/widgets/common/share_image_renderer.dart`, with the same retry loop. Then update the ayah share flow to call it. The extraction is a pure refactor and must not change ayah share behavior. Verify by sharing an ayah before and after.

### Entry points

- Stats page: a "Share your year" card near the top, shown in the preview state.
- Home dashboard: a single banner from Dec 1 to Jan 31 that opens the Wrapped page. Gate it behind the device capability and startup rules in `CLAUDE.md`, and do not add initialization to the blocking startup stage.

### Feature flag

Ship v1 behind a `FeatureFlagStore` flag, default off, then enable it for a release once the rendering checks pass. `CLAUDE.md` says roadmap features are fail-closed and must not be enabled by default. This is a shipped feature, so the flag is a release gate, not a roadmap gate. Decide which applies before implementation.

## 6. Rendering

- Render with the shared renderer at pixel ratio 1 to a PNG in the temp directory, then share with `SharePlus` (same as the ayah share).
- Typography: use `equran_text_styles.dart` so the card follows the app's font choice. Quran text on the card uses the Uthmanic or IndoPak style the reader uses, not a generic font.
- Any illustration: `EquranAssetImage` decoded at display size, never `Image.asset`.
- Layout: no fixed-width text. Use `FittedBox` for numbers and `Directionality` so Arabic lays out right-to-left.
- Dark mode: pull all colours from theme tokens. Test both themes.

### Card content (story format, top to bottom)

1. App name and year.
2. Headline number: ayahs read in the year.
3. Surahs completed (count plus the last one completed).
4. Reading time (formatted as hours and minutes).
5. Longest streak in days.
6. Favourite surah.
7. Active days out of days elapsed.
8. One ayah from the year. Use the user's most recently read ayah in the year, not a random one, so the card reflects their reading. Show its translation only if the user's translation language has text available.
9. Footer: app name and the store or repo link. Add nothing else.

The square format drops items 7 and 8.

## 7. Feedback

After the user taps Share, show a bottom sheet:

- "How did this recap feel?" with five stars.
- An optional text field.
- A "Send feedback" button that opens a prefilled GitHub issue in the browser: title "Reading Wrapped feedback", label `wrapped-feedback`, body containing the star rating, the text, the app version, and the locale.

Rules:

- Nothing is sent automatically. The user taps and reviews the issue before submitting it on GitHub.
- The body does not include any reading statistics. Only the rating, the typed text, the app version, and the locale.
- Do not use Google Play in-app review or any GMS-based prompt. That breaks F-Droid policy in `AGENTS.md`.
- Do not store feedback locally in a new Hive box. If you need local state, use `SettingsDB` for a "rated this season" flag. A new box would need export, snapshot, and restore wiring in `lib/backend/backup_service.dart`.

## 8. Localization

- Add every new key to `lib/l10n/app_en.arb` first, then to all seven other ARB files: `ar bn de en fa id tr ur`.
- Run `flutter gen-l10n` and commit the regenerated `lib/l10n/app_localizations*.dart`.
- Machine-drafted translations must be called out in the commit message for native-speaker review.

## 9. Testing

Unit tests for `wrapped_summary.dart`:

- Empty input.
- One day with one ayah.
- The same ayah read on two days (counts once).
- Surah completion: all ayahs in the union, and a surah with one missing ayah (not completed).
- Year boundaries using local dates, including a read at 23:59 on Dec 31 and at 00:01 on Jan 1.
- Streak across a gap, and a streak that spans the start of the year (only in-year days count).
- Favourite-surah ties.
- Corrupted or default-valued entries, which should not crash the computation.

Widget and golden tests:

- Story and square cards, light and dark, English and Arabic, on a phone-size viewport. Check for overflow with long Arabic text and large system font scale.
- The empty state and the threshold boundary (6 days vs 7 days).

Regression:

- Ayah share still produces a PNG after the renderer extraction.

Quality gates from `CLAUDE.md` before declaring done: the verify scripts, `flutter gen-l10n` with a clean diff, `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test`.

## 10. Milestones

1. Decide the listening-time question (section 3) and the flag question (section 5).
2. Pure computation plus unit tests.
3. Extract the shared renderer, with ayah share regression checked.
4. Card widget, both formats, both themes, both languages, golden tests.
5. Preview on the stats page and the Dec 1 to Jan 31 banner, behind the flag.
6. Feedback sheet with the prefilled GitHub issue.
7. Localization, quality gates, and a release with the flag enabled.

## 11. Open questions for the owner

1. Should listening time be instrumented for v1, or should the card ship with reading only?
2. Should the feature ship behind a flag and be turned on for a release, or be visible immediately?
3. Is it acceptable that the feedback step opens a GitHub issue, which requires a GitHub account, or would you prefer a different feedback path?
4. Which translation should the card's ayah use, and does its licence allow reproduction on a shared image? Check the licence before shipping.
