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

The app will stay free, so these are all candidates for the free app. They
respect the F-Droid rules in `AGENTS.md`: offline-first, no Google services, no
accounts or tracking.

Higher impact:

1. **Word-by-word follow-along:** highlight the current word during audio, with
   tap-for-meaning. Check the data licence first.
2. **Hifz test mode:** hide words or ayahs and reveal on tap, plus a mistakes
   heatmap feeding the existing spaced-repetition scheduling.
3. **A-B repeat and sleep timer** for audio, plus auto-scroll while listening.
4. **Prayer tracker:** log each prayer (on time / late / missed), streaks,
   qada counter. Fits the existing prayer module and stats.
5. **Ramadan mode:** suhoor/iftar countdown, fasting tracker, khatam planner
   that builds on reading plans.
6. **Ayah notes and collections:** private notes, tagged or coloured bookmarks,
   all local, exportable through the existing backup service.
7. **Better sharing:** more ayah-card templates and themes on top of the
   existing share image.

Smaller wins:

- Daily ayah and Friday al-Kahf reminders using local notifications only, and a
  daily-ayah home-screen widget (the widget plumbing already exists).
- Adhkar completion tracking for morning/evening duas.
- Tasbih history and custom dhikr sets.
- Fasting reminders for Mondays/Thursdays and the White Days, and Islamic
  calendar event reminders.
- Automatic backup to a user-chosen folder (works with Syncthing-style sync, no
  cloud).
- Offline topic and transliteration search.
- A tajweed legend, a large-text/low-vision reading mode and a simple kids mode.
