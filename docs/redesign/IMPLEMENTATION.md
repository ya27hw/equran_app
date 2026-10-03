# Premium redesign: implementation brief

Scope: the **Quran › Saved tab**, **Duas**, **Prayer** and **Statistics** pages, in all 11 palettes.
This is a presentation-only change. Repositories, data models, services and business logic do not change.

Design canvas (private, owner can share): https://claude.ai/artifact/S6BCgUe7uedoyrPag7GPJa

## Source of truth, in priority order

1. [`tokens.json`](tokens.json): exact source colours and derived tokens for all 11 palettes. Your Dart must reproduce these.
2. [`previews/*.html`](previews/): static HTML of every screen (dark and light, emerald). Open in a browser at 390 px wide.
   The inline CSS holds the exact paddings, radii, font sizes and line heights. Read values from it; do not eyeball a screenshot.
   [`previews/theme-matrix.dark.html`](previews/theme-matrix.dark.html) shows the same components in every palette.
3. This document: structure, mapping to existing code, acceptance criteria.
4. The canvas link above, for the Tweaks (palette, dark/light, display font) if a human wants to flip them.

If the preview HTML and this document disagree, the preview HTML wins. If the preview and `tokens.json` disagree on a colour, `tokens.json` wins.

## Ground rules (from AGENTS.md, restated because they are easy to break)

- Run `dart format .` and `flutter analyze` before declaring done. Zero warnings.
- No Google Mobile Services, Firebase or proprietary SDKs. F-Droid compliance stays.
- Do not touch `pubspec.lock` except for a deliberate dependency change, and never untrack it.
- State stays on `ValueNotifier` / `ValueListenableBuilder`. No new state-management package.
- New strings go in `lib/l10n/app_en.arb`, then regenerate. Check for an existing key before adding one (many already exist, see below).
- Bundle fonts as assets. Do not fetch Newsreader at runtime.
- Do not hardcode any colour hex in a widget. Everything comes from `EquranColors` or `EquranTokens`.

## Phase 0: tokens (do this first, ship it alone)

Create `lib/theme/equran_tokens.dart`: a `ThemeExtension<EquranTokens>` built from the active `EquranColors`
by fixed rules. **There are no per-palette constants.** [`derive_tokens.py`](derive_tokens.py) is the reference
implementation (run `python3 docs/redesign/derive_tokens.py`; it reads `equran_colors.dart` and prints a contrast report).

Fields: `text2, muted, hair, hair2, filled, emText, emWash, gold, goldText, goldWash, danger, featA, featB, featText2,
glow, dock, scrim, shadow` (colour names in `tokens.json` are `em` = `filled`).

Helpers to port exactly:
- `mix(a, b, t)`: per-channel linear blend in sRGB, rounded. `Color.lerp` is equivalent.
- `contrast(a, b)`: WCAG ratio using `Color.computeLuminance()`.
- `ensure(color, against: [...], target, toward)`: step `color` toward `toward` in 40 equal steps and return the first
  step that meets `target` on every background in `against`.

Add to `equran_text_styles.dart`:
- Display face **Newsreader** (assets, weights 400/500/600 and 400 italic). Page title 36/39 w500 -0.015em, section title 24/28 w500,
  numerals 22/28/40 w500 with `FontFeature.liningFigures()` and `FontFeature.tabularFigures()`, translation 16/24 italic.
- Eyebrow: Inter w600 11 px, +0.14em, uppercase, colour `goldText`.
- Keep Inter for body and the existing Arabic reader fonts for Arabic.

Add radius 28 to `EquranRadii`.

**Tests (required to merge Phase 0):**
1. For every palette in `tokens.json`, build `EquranTokens` from the Dart `EquranColors` constant and assert each derived colour equals
   the JSON value within ±1 per channel. Parse `tokens.json` in the test; do not copy numbers into the test.
2. Assert the 13 contrast pairs from `derive_tokens.py` (`report()`) pass for all 11 palettes.

## Phase 1: shared widgets (`lib/widgets/redesign/` or the nearest existing folder)

Build these once; every page uses them. Each gets a golden test in emerald-dark, emerald-light, AMOLED black and red-light.

| Widget | Spec (see previews) |
| --- | --- |
| `HairlineCard` | surface fill, 1 px `hair` border, radius 24, no shadow |
| `EyebrowLabel` | eyebrow style above |
| `DisplayNumeral` | Newsreader numeral with lining + tabular figures |
| `PillTag` / `ChipButton` | 28 / 36 px high, radius 999; `on` state = `emWash` fill + `hair2` border + `emText` |
| `IconButton44` | 44 × 44, circle, surface fill + hairline, or ghost |
| `FloatingDock` | replaces the bottom bar: 14 px side margin, 72 px high, radius 28, `dock` fill with blur, `hair2` border, active item = `emWash` capsule. Solid surface fallback where blur is disabled |
| `HeroPanel` | radius 28, `featA → featB` gradient at 155°, 1 px gold hairline at ~22% alpha, text always #F3F7F4 / `featText2` |
| `OrnamentDivider` | hairline, 6 px gold diamond, hairline |
| `SalahGlyph` | disc + check (on time), half disc (late), ring + bar (missed), dot (not logged), dashed ring (not yet). **Shape carries meaning, never colour alone** |
| `ProgressRing` | exists in `lib/widgets/common/progress_ring.dart`; extend for two concentric rings |
| `PrayerArch` | reuse the existing prayer illustration PNGs clipped to the arch shape; do not redraw |

## Phases 2 to 5: pages (one change per page)

Open the matching preview side by side. Match section order, spacing and sizes. Keep every existing interaction.

### Phase 2: Saved tab
- Files: `lib/widgets/favourites_list.dart` (`_BookmarkLibraryHeader`, `_FilterChipButton`, `_FolderChipStrip`, `_TagChipStrip`, `_BookmarkRow`, `_BookmarkEmptyState`, edit sheet).
- Previews: `saved-library`, `saved-empty`, `saved-sheet`.
- Replace the green header block with: eyebrow + serif count heading, then a horizontal **collections rail** (128 × 96 tiles: All, Favourites, Notes, each folder, dashed New folder), then the tag chip row, then search, then the list.
- A tile selects the same filter state the current chips drive. Do not change filtering logic.
- Verse card: medallion, surah name and ayah, favourite + overflow (44 px targets), Arabic (right aligned), translation, optional note panel (`goldWash`), folder pill, tag pills, date.
- Overflow menu keeps: edit note, move to folder, edit tags, delete. The sheet keeps: favourite, private note, folder, tags, delete, save.
- Empty state keeps the existing copy (`saveAyahsNotesHere`, `savedAyahLibraryHint`), adds a "Browse surahs" action that switches to the Surahs tab.

### Phase 3: Duas
- Files: `lib/duas/duas_page.dart`, `lib/duas/duas_category_page.dart`.
- Previews: `duas-home`, `duas-category`.
- Replace the three stacked entry rows and the accordion (`_GroupedCategoriesList`) with: search, suggestion hero, Favourites + Tasbih tiles, and a 2-column **theme grid** (13 tiles; the last, General, spans both columns). A tile opens a category list filtered to that `DuaGroup`.
- Real counts come from the existing index and `DuaCategoryGroupMapper` (e.g. Daily Athkar 7 categories, 54 duas). Total 134 categories and 298 duas.
- **Needs a product rule:** the "For this evening" hero. Suggested: before noon show the morning-and-evening category as "For this morning", after Asr as "For this evening", otherwise the last-opened category. Confirm with the owner before building.
- Category list row: index, English title, Arabic title (secondary), dua count, chevron. Highlight the row matching the time-of-day rule.

### Phase 4: Prayer
- Files: `lib/prayer/prayer_times_page.dart`, `prayer_hero_card.dart`, `prayer_time_thumb_card.dart`.
- Preview: `prayer`.
- Header with title and `location · hijri date`. Week strip (7 days centred on the selected day) replaces the prev / next bar; it drives the same date state.
- **Sun arc hero:** geometry is in the preview SVG (centre 171,150, radius 140). The arc spans sunrise to Maghrib. The gold arc is elapsed daylight, the sun sits at `(now − sunrise) / (maghrib − sunrise)`, dots mark Dhuhr and Asr. After Maghrib and before sunrise show the night state: reuse the arc with the moon and Maghrib→Fajr span (design this variant with the owner; it is not in the canvas).
- Prayer list is one grouped card; current row = `emWash` gradient + NOW tag; past rows use `text2`.
- "The night" card uses existing middle-of-night and last-third values.
- Respect reduce motion: draw the final state at once.

### Phase 5: Statistics
- File: `lib/home/quran_stats_page.dart` (large; edit section builders, not the repository).
- Preview: `statistics`.
- Order: title, range control (keeps `StatRange`), today card (two rings: outer gold = Quran goal, inner = salah of 5; streak pill; dhikr, duas, mastered row; mini salah row), then sections Prayer, Quran, Hifz, Tasbih and duas, Activity history, Streaks.
- Remove the sticky section headers; use the in-flow `sechead` pattern.
- Prayer: on-time ring, four stats, 7 × 5 glyph matrix with legend, Fajr callout (`fajrGettingStronger` etc. already exist).
- Quran: bar chart with dashed goal line (today bar gold), 2 × 2 lifetime tiles, most-read surah row, Khatm bar, 114-cell surah map (4 levels).
- Data classes (`OverviewStats`, `SalahSectionData`, ...) are unchanged.

## Verification loop (do this for every page, not at the end)

1. Run on a simulator or the web preview (`tool/ui_preview`). Screenshot the page at **390 logical px** width.
2. Compare against the matching preview, section by section: spacing, type sizes, radii, colours.
3. Repeat in **emerald-light, AMOLED black and red-dark** at minimum. Wrong colour in any palette means a hardcoded hex somewhere.
4. Repeat at **text scale 1.3** and with the **Arabic locale** (RTL). Nothing may clip or overlap.
5. `dart format .`, `flutter analyze`, `flutter test`.

## Known gaps and decisions for a human

- **RTL:** the canvas is LTR only. Arabic, Urdu and Persian locales exist in the app. Use `EdgeInsetsDirectional`, `AlignmentDirectional` and `TextDirection`-aware icons (chevrons, back arrow) throughout, and mirror the arc / bar direction.
- **Night state** of the Prayer hero is not designed yet.
- **Evening suggestion rule** (Phase 3) needs sign-off.
- **Dock restyle** touches every page. It can ship last or be dropped.
- **Red theme:** `danger` and the brand colour are both red. Missed vs on-time is told apart by shape (ring + bar vs filled disc), which is why shapes matter.
- **Source palette issues the derivation corrects:** `textMuted` is about 3.4:1 on white in all five light palettes, and white text on `primary` is below 4.5:1 in blue-dark and AMOLED. Do not "fix" these by editing `equran_colors.dart`; the derived tokens handle it. Existing screens that use `textMuted` directly keep their current look until migrated.
- **Sample data:** counts like 12 favourites or the Statistics figures are placeholders. Counts for Duas themes and category names are real.
- **New strings** will be needed (check `app_en.arb` first): "For this evening/morning", "Browse by theme", "Begin", "{count} categories", "Surah map", "Tap a cell to open", "Less" / "More", "Khatm progress", "Next review", "Review", "The night", "Collections".

## Definition of done per page

- Matches its preview in emerald dark and light to within 2 px on spacing and exact on type size.
- Looks correct in every palette in `theme-matrix` with no hardcoded colours (`grep -n "Color(0x" <changed files>` returns nothing new).
- Existing behaviour preserved: navigation, filters, favourites, notes, folders, tags, tracking, date switching.
- Goldens added for new shared widgets; token tests green.
- `dart format .` and `flutter analyze` clean.
