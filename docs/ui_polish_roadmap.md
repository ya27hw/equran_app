# UI polish roadmap and handoff

Read this first when asked to continue the UI/UX polish work ("do the next
polish steps", "finish the roadmap", and so on). It records what has been done,
the design language that was introduced, the rules that came out of doing it,
how to verify visual work, and the concrete next steps.

Project-wide rules still live in [`AGENTS.md`](../AGENTS.md) and take priority.

## 1. State of the work

Branch history of the first polish pass (all merged-ready, no PR was opened):

| Area | What changed | Main files |
| --- | --- | --- |
| Theme | Explicit page transitions per platform, floating rounded snackbars, token-driven switch / slider / progress / popup / tooltip / divider / list tile themes, pill nav indicator | `lib/theme/equran_theme.dart` |
| Navigation | Incoming tab fades and lifts in once, selection haptic, rounded top corners on the bottom bar | `lib/home/home.dart`, `lib/widgets/common/tab_entrance.dart` |
| Micro-interactions | Press-scale on cards | `lib/widgets/common/pressable_scale.dart`, `quran_card.dart`, `juz_card.dart`, `equran_components.dart` |
| Identity | Eight-pointed star motif: faded lattice on hero cards, star number badges, ornament divider | `lib/widgets/common/geometric_pattern.dart`, `lib/widgets/number_badge.dart` |
| Home | Greeting header + location pill, edge-to-edge prayer strip, Quran Journey progress ring, ornament section headings, flattened daily tools | `lib/home_dashboard/home_dashboard_page.dart`, `lib/widgets/common/progress_ring.dart` |
| Reader chrome | Surah banner contrast fix, star ayah marker on the verse card (share image unchanged) | `lib/home/read.dart`, `lib/widgets/read_quran_card.dart` |

Verification so far was a sandbox web build, not a device (see section 5).

## 2. Design language

Emerald and gold on the existing colour tokens, with the **eight-pointed star**
(Rub el Hizb) as the one recurring motif.

Shared building blocks, all in `lib/widgets/common/` unless noted:

- `GeometricPattern` - faded star lattice. It paints at `Size.infinite`, so use
  it only inside `Positioned.fill`. It clips itself. Anchor it away from
  artwork (hero art sits at the end side, so anchor to `bottomStart`). Never
  stack it on a card that already has the rosette asset, and never put it in
  the 114 list items.
- `OrnamentDivider` - hairline + star rule for section headings.
- `ProgressRing` - animates from empty on first build and then only when the
  value changes, so the once-a-minute dashboard rebuild does not replay it.
- `PressableScale` - tap-down scale that uses tap callbacks (not raw pointer
  events) so scrolling cancels it and the child's `InkWell` still wins.
- `TabEntrance` - one-shot fade/lift keyed by the selected tab index.
- `EquranGradientCard(showPattern: true)` - hero card with glow + lattice.
- `SurahNumberBadge` / `NumberBadge` (`lib/widgets/number_badge.dart`) - star
  badge, used for surahs, juz and the ayah marker.

Colour notes:

- Gold **text** must use `colors.warning` (dark gold-brown in light themes,
  soft gold in dark). `colors.accentGold` is for strokes and fills; as text it
  fails contrast on light backgrounds.
- `colors.onPrimary` only belongs on primary-coloured surfaces. Using it on a
  transparent bar made the Quran title invisible in light mode.
- Gradients that end in a pale tint (`primaryGradientEnd` in light themes) must
  not sit under white or gold text.

## 3. Guardrails learned the hard way

- **Flutter version:** CI builds on the latest *stable* (3.47.x at the time of
  writing), not `>=3.41.7`. Analyze and build with that, or you will chase
  errors that do not exist (and miss ones that do). `CupertinoPageTransitionsBuilder`
  needs `import 'package:flutter/cupertino.dart'` on 3.47.
- **Never put `Flexible` / `Expanded` in a `Wrap`.** `_JourneyStreakChip` and
  `_JourneyMetricChip` return `Flexible`; inside a `Wrap` they render as a grey
  error box in release builds. Use a `Row`.
- **A `Row` that shares space between a title and an `Expanded` ornament will
  truncate the title.** Cap the title with a `ConstrainedBox` computed from a
  `LayoutBuilder` (see `_CompanionSectionHeader`).
- **Frame-rate policy:** `_pushSecondaryPage` in `lib/home/home.dart` releases
  the route-transition low-refresh blocker after 450 ms. Keep new transitions
  at or under that, keep own animations around 200-350 ms, and add **no looping
  animations** (shimmer, pulse). They fight the policy and drain battery.
- **Reduce motion:** gate new animations on `MediaQuery.disableAnimationsOf`.
- **RTL (ar / ur / fa):** use directional alignments and offsets
  (`AlignmentDirectional`, `PositionedDirectional`, `EdgeInsetsDirectional`).
- **No new user-visible strings without translations:** each one needs all 8
  `.arb` files plus regeneration. Reuse existing keys where possible (for
  example `meccan` / `medinan` exist).
- **Do not touch** verse text layout, QPC/CPAL font handling
  (`qcf_cpal_patcher.dart`), audio logic or the Android widget code as part of
  UI polish. Reader *chrome* (banner, card header, bars, player bar) is fair
  game. `ReadQuranCard` also renders the share image (`shareImageMode`), so
  keep that branch visually unchanged unless asked.
- **Tool side effects:** recent `flutter analyze` / `flutter build` rewrite
  `analysis_options.yaml` and `flutter pub get` can bump `pubspec.lock`. Revert
  both (`git checkout analysis_options.yaml pubspec.lock`) before committing.
  `pubspec.lock` must stay tracked.
- **Formatting:** run `dart format` on the files you changed and confirm with
  `git status` that nothing else moved. Run `flutter analyze` and keep the
  warning count at the baseline or lower.
- **Push quickly but verify first.** One commit pushed without a visual check
  shipped a broken card. Always look at a screenshot before pushing UI work.

## 4. Next steps

Do these in order unless told otherwise. Each one: make the change, run the
visual checks in section 5 (dark, light, Arabic), then commit and push.

### 4.1 Staggered entrance for the first few list items

- Scope: first ~8 rows of the surah list (`lib/widgets/quran_card_list.dart`,
  `QuranCard`) and optionally the Home sections.
- One-shot only. Lazy slivers rebuild items while scrolling and the dashboard
  rebuilds every minute, so hold the "already played" flag in `State`, or use a
  tween whose target never changes. Cap the delay (for example 40 ms per item,
  at most 8 items) and the duration (about 250 ms).
- Honour reduce motion (render the final state immediately).
- Do not wrap all 114 items in an animated widget.
- Done when scrolling a long list shows no entrance replays and the first load
  looks smooth.

### 4.2 Restyle the reader's bottom bars and player

- Files: `_buildCardViewBottomBars()` and the page/list view bars in
  `lib/home/read.dart`, and `lib/widgets/read_verse_player_bar.dart`.
- Goals: prev/next pills that match the new card (star motif or gold hairline),
  a calmer player surface with the same border/shadow language as the cards,
  clear light-mode contrast.
- Chrome only. Do not change playback behaviour, the collapse animation maths
  (`_playerCollapseProgress`) or verse layout.
- Check the collapsed and expanded player, with and without a downloaded ayah.

### 4.3 Check the other palettes

- Palettes: default, fancyBlue, fancyPurple, sepia, black, red, each in light
  and dark (`lib/theme/equran_colors.dart`, switched in Settings / appearance).
- Look for: gold text using `warning` on every palette, the lattice alpha
  reading as texture rather than noise, the ring track being visible, hero
  gradients that end pale, the nav indicator on each primary colour.
- Note `blackLight()` currently builds from the dark tokens.
- Fix by adjusting tokens or per-widget alpha, not by special-casing palettes
  in pages.

### 4.4 Localise the dashboard date line

- `_formatDashboardDate` in `lib/home_dashboard/home_dashboard_page.dart`
  hard-codes English weekday and month names, so the Arabic UI shows
  "Saturday, October 3". Use `intl` `DateFormat` with the app locale (remember
  `initializeDateFormatting`) or add ARB keys.
- `HijriCalendar.toString()` (`lib/prayer/hijri_calendar.dart`) yields an
  English month name and renders the digits in the wrong order under RTL. Fix
  or localise it at the call site.
- The header greeting `السلام عليكم` is a fixed string, not in the ARB files.
  Ask whether to keep it fixed or move it into all 8 ARBs.

## 5. Verifying visual work

There is no emulator in the cloud sandbox, so use the web build plus
Playwright. The scripts are in [`tool/ui_preview/`](../tool/ui_preview/) (see its
README for exact commands). In short:

1. Install the current stable Flutter SDK, run `flutter pub get`, revert
   `pubspec.lock`.
2. `flutter build web --release --no-pub -o <dir>`.
3. `seed.js` once per fresh profile (location + a few verses read), then
   `capture.js` for the tabs, `reader.js` for the reader, `toggle_theme.js` to
   flip light/dark, and `sheet.js` for side-by-side comparisons.
4. Look at the screenshots. Always check: dark, light, an RTL locale
   (`ar-SA`), and a wide viewport (for example 1100x800) for the dashboard's
   wide branch.

Caveats to state when reporting: it is a web build (CanvasKit), prayer times
come from the sandbox clock, only the default palette is checked unless you
switch it, and nothing was seen on a device.

## 6. Known issues backlog

- Dashboard date and Hijri line are not localised (see 4.4).
- `unawaited_return_in_try_block` warnings remain in
  `lib/widgets/prayer_widget_worker.dart` (two). They predate this work.
- `docs/` plans for the calendar and zakat redesigns exist separately.

## 7. Feature ideas (not started)

The app stays free (no monetisation, no paywall, no accounts), so everything
below is meant for the free app. All of it must respect the F-Droid rules in
`AGENTS.md`: offline-first, no Google Mobile Services or Firebase, no analytics,
no proprietary SDKs. Notifications must be local only. Anything that needs a
third-party dataset needs its licence checked before it goes in the repo.

The codebase already does more than a first look suggests. **Check the
"already exists" list before building anything**, and extend rather than
duplicate.

### 7.1 Already exists (extend, do not rebuild)

| Capability | Where | Notes |
| --- | --- | --- |
| Sleep timer (duration or end of surah) | `lib/home/read.dart` (`_sleepTimer`, `_sleepTimerDurationMode`, `_sleepTimerEndSurahMode`) | |
| Repeat each ayah N times, A-B interval repeat, delay between ayahs | `lib/home/read.dart` (`repeatAyahCount`, `intervalRepeatCount`, `playbackInterval`, `PlaybackInterval`, `RepeatChoice`) | Only a nicer UI would be new |
| Playback speed | `lib/widgets/playback_rate.dart` | |
| Follow-along scrolling while audio plays | `lib/home/read.dart` (`_scrollToVerseIfNeeded`) | |
| Salah log (per day, per prayer, status) | `SalahLogEntry`, `SalahPrayer`, `SalahStatus`, logged and shown in `lib/home/quran_stats_page.dart`; storage in `lib/backend/companion_storage.dart` | Logging happens only from Statistics |
| Dhikr sessions | `DhikrSessionEntry`, `lib/duas/tasbih_page.dart`, shown in Statistics | |
| Khatam, streak and highlights | `lib/home/quran_stats_page.dart` | |
| Hifz with spaced repetition | `lib/hifz/` (`HifzScheduler` ease/interval logic, `HifzReviewLog`, `hifz_session_page.dart` with again/hard/good/easy ratings) | |
| Bookmarks with note, folder and tags | `QuranBookmarkEntry`, `lib/backend/quran_bookmark_service.dart` | Data layer is complete; check how much UI exposes folders and tags |
| Share image (story and other sizes) | `lib/home/read.dart` (`_ShareImageMode`, `_buildShareImageWidget`), `ReadQuranCard(shareImageMode: true)` | |
| Daily ayah and daily dua on Home | `lib/home_dashboard/home_dashboard_page.dart` (`_DailyAyahPreview`, `_DailyDuaPreview`), `lib/backend/daily_guidance_service.dart`, `lib/duas/daily_dua_repository.dart` | |
| Reading plans with presets | `lib/reading_plans/` | Presets exist; there is no Ramadan preset |
| Backup and restore | `lib/backend/backup_service.dart` | Manual only |
| Local notifications and home-screen widgets | `lib/prayer/prayer_notification_service.dart`, `lib/widgets/prayer_widget_*`, `home_widget` + `workmanager` | Prayer-only today; reusable plumbing |
| Hijri calendar with fasting info | `lib/prayer/hijri_calendar.dart`, `islamic_calendar_page.dart` | No reminders |

### 7.2 Features worth building

Effort: S = a day or less, M = a few days, L = a week or more.

1. **Quick prayer logging, streaks and qada counter** (M)
   - Gap: salah logging only lives in Statistics, so it is easy to forget.
   - Add a one-tap "mark prayed" on the Home prayer strip and the Prayer tab
     cards (`prayer_time_thumb_card.dart`, `prayer_times_page.dart`), a streak
     computed from `SalahLogEntry`, and a small qada counter (a new Hive entry).
   - Optional: a notification action ("Prayed") on the existing prayer reminders.
   - Pitfalls: day boundaries follow the Hijri/maghrib convention only if the
     user wants it, so default to the local calendar date like the current log.
     Keep the dashboard rebuild-per-minute in mind (do not replay animations).

2. **Hifz recall (test) mode** (M)
   - Gap: sessions show the ayah and ask for a rating; there is no
     "can you recite it" check.
   - In `hifz_session_page.dart`, add a mode that hides the text (or every Nth
     word, or everything after the first words) and reveals on tap, then feeds
     the existing again/hard/good/easy rating into `HifzScheduler`.
   - Add a mistakes view from `HifzReviewLog` (surahs/ayahs rated "again"
     most often).
   - Do not change scheduling maths without tests. The repo has no `test/`
     folder today, so add unit tests for `HifzScheduler` first if its logic
     needs to change.

3. **Daily ayah notification and home-screen widget** (M)
   - Gap: the daily ayah is only visible inside the app; the widget and
     notification plumbing is prayer-only.
   - Reuse `flutter_local_notifications` (local only, no FCM) and the
     `home_widget` + `workmanager` setup in `lib/widgets/prayer_widget_*`.
   - Add a setting for time of day, deterministic daily selection (the same
     logic as `_DailyAyahPreview`), and Android widget receiver(s) under
     `android/app/src/main/kotlin/com/app/equran/`.
   - Pitfalls: exact-alarm permission handling already exists for prayers; copy
     that approach. Follow the F-Droid rules for any new Android dependency.

4. **Ramadan mode** (M)
   - Suhoor (Imsak/Fajr) and iftar (Maghrib) countdown on Home during
     Ramadan, driven by `HijriCalendar` and the prayer times service. There is
     no Imsak calculation yet, so decide whether it is Fajr minus a user-set
     offset.
   - A Ramadan khatam preset in `lib/reading_plans/` (30 days, with a catch-up
     view), plus a simple fasting tracker (a day-level Hive entry, like the
     salah log).
   - Show the mode only when the Hijri month is Ramadan (respect the user's
     Hijri offset setting).

5. **Bookmark folders, tags and notes UI** (S-M)
   - Gap: the data layer supports `note`, `folder` and `tags`, but the UI
     appears to expose little of it. Verify in `lib/widgets/favourites_list.dart`
     and `read_quran_card.dart` first.
   - Add folder chips and a tag filter to the Saved tab, an edit-note sheet,
     and optional colours. Everything already round-trips through
     `backup_service.dart`.

6. **More ayah share templates** (M)
   - Build on `_ShareImageMode` / `ReadQuranCard(shareImageMode: true)`: add
     background themes (the star lattice from `GeometricPattern` fits well),
     optional translation and reference line, and a square format.
   - The share path renders through a manual `RenderView`; test it on device
     after any change (it cannot be exercised in the web preview).

7. **Adhkar completion tracking** (M)
   - Track whether the morning and evening adhkar (Hisn al-Muslim categories in
     `lib/duas/hisn_al_muslim_repository.dart`) were completed each day, with a
     streak, an optional local reminder after Fajr/Asr, and a small card on
     Home. New Hive entry modelled on `SalahLogEntry`.

8. **Fasting and calendar reminders** (S-M)
   - Local notifications the evening before Monday/Thursday fasts and the
     White Days (13-15 of each Hijri month), plus key events already listed in
     `hijri_calendar.dart`. Reuse the prayer notification channel setup.

9. **Tasbih history and custom dhikr sets** (S)
   - `DhikrSessionEntry` data already exists. Add a history list (per day and
     total), user-defined presets with their own targets, and an optional
     vibration/sound toggle.

10. **Automatic backup to a chosen folder** (M)
    - Extend `backup_service.dart` with a scheduled export to a folder picked
      through `file_picker`. This works with Syncthing-style sync and needs no
      cloud. On Android a persisted SAF permission is required; test Windows
      and Linux separately.
    - Keep restore tolerant of older schema versions
      (`schema_migration_service.dart`).

11. **Word-by-word follow-along** (L)
    - Highlight the current word while audio plays, with tap-for-meaning.
    - No word-level data exists in the repo today (`surah_timing_repository.dart`
      is ayah-level). Needs a word-timing and word-meaning dataset with a
      compatible licence, bundled or downloaded through the existing resource
      download service. Do not touch the QPC/CPAL font handling.

12. **Offline transliteration and topic search** (M-L)
    - `lib/search/quran_text_search_service.dart` and
      `lib/backend/transliteration_service.dart` exist. Add transliteration to
      the search index first (data is already local). Topic search needs a
      topic-to-ayah dataset; check licensing.

13. **Reading accessibility and learning aids** (S-M)
    - A tajweed colour legend for the QPC v4 style, a large-text reading mode
      (bigger spacing and tap targets) and a simple kids mode. These are mostly
      UI; keep verse layout rules from section 3 in mind.

### 7.3 Suggested order

Quick log and streaks (1), hifz recall mode (2) and the daily ayah
notification/widget (3) have the best value for the least risk because they
reuse storage and plumbing that already exist. Ramadan mode (4) is best started
a few weeks before Ramadan. Word-by-word (11) is the biggest and depends on a
data licence, so decide that first.
