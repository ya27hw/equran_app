# Follow-up for the coding agent

Review fixes already made are in PR #101 (Prayer, Duas, Saved) and branch `redesign/stats-fixes` (Statistics).
This file lists what is **still open**. Give the agent **one item at a time**, same rules as `CODEX_PROMPT.md`
(presentation only, no hardcoded colours, `dart format`, `flutter analyze --fatal-infos`, `flutter test`).
For every item: verify at 390 px in emerald-dark, emerald-light, AMOLED black and red-dark, at text scale 1.3, and in Arabic (RTL),
and compare against `docs/redesign/previews/*.html`. The preview HTML wins over this brief.
Use `DesignIcon` (`lib/widgets/redesign/design_icon.dart`) for icons, never Material icons, where the design has one.

## Decided by the owner
1. ~~**Floating dock ships.**~~ Done in `af5c865`.
2. ~~**Saved note label is "Note".**~~ Done in `af5c865` for the verse card and the Saved editor. The reader's own note editor in
   `lib/home/read.dart` now uses `note` too and the unused `privateNote` key is removed from all 8 ARBs (2026-10-04 round).
3. ~~**Statistics "Memorized" keeps the real data.**~~ Done in `af5c865`.

## Open work
4. ~~Quran header and tabs on all four tabs.~~ Done in the Home, Quran and More PR (one `SavedQuranHeader` for all tabs).
5. ~~**Fonts add about 2.1 MB.**~~ **Partly done (2026-10-04).** Inter and both Newsreader files are glyph-subset to Latin and
   transliteration ranges: 1,823,000 B to 1,461,000 B, about 363 KB saved (Inter 877 KB to 529 KB; the Newsreader masters barely shrink
   because they were already Latin-only). All 367 tests pass with no golden change. APK size was **not** measured.
   Commands, ranges and the `--no-layout-closure` trap are in `assets/media/fonts/*/README.md`.
   The rest of the weight is the variable axes. They cannot simply be pruned: Inter is used at weights up to 900 (registered
   400/500/600, but Flutter applies `wght` per `FontWeight`), and Newsreader's `opsz` is set per size. Only pin axes after listing every
   weight/size used. Noto Naskh (300 KB) is untouched.
6. **App text looks about 9% wider than the design.** Investigated, **not changed**.
   - The bundled Inter is the right font. At 12 px "Saved for quick access" is 131.947 px in Flutter and in a browser using Inter, identical.
   - The design's `font-family` is `'Inter', system-ui` with no `@font-face`, so the HTML only shows Inter where Inter is installed.
   - Cause of the gap at larger sizes: Inter has an `opsz` axis (14 to 32). Browsers apply `font-optical-sizing: auto` (opsz = font size),
     Flutter keeps opsz at 14. The same string at opsz 32 is 120.19 px against 131.95 px (about 9% narrower). Newsreader already sets `opsz`
     per size in code; Inter does not.
   - Likely fix: a shared helper that adds `FontVariation('opsz', fontSize.clamp(14, 32))` to Inter styles. It re-renders almost every
     golden, so do it as its own PR.
   - It does **not** explain the Duas "Saved for quick access" wrap at 12 px (identical metrics). That is tile padding or the 0.94 chrome factor.
7. ~~**Statistics number format and glyphs.**~~ Done (2026-10-04). Counts use `formatGroupedCount` (locale separator, always Western digits to
   match the rest of the app); Home "5,400 letters" too. Legend only lists glyph states on screen, and the stats grid now uses its injected
   clock for "not yet" instead of the wall clock. With a location, "Not yet" shows whenever a prayer has not begun; the day rolls over at
   Maghrib, so it is nearly always present. Without a location nothing is locked and the legend drops it.
8. ~~**Saved medallion at text scale 1.3.**~~ Done (2026-10-04): the number sits in an 18 px `FittedBox`.
9. ~~**Right-to-left text.**~~ Done (2026-10-04) for the screens listed here: `scriptDirectionIn` (`lib/utils/text_direction.dart`) sets the
   direction from the text's first strong letter on the Home ayah and dua previews, Saved translations and notes, Dua card
   translation and transliteration, and every `PillTag` / `ChipButton` label (`#hope` stays `#hope`). **Not done:** the reader's own verse
   card (`ReadQuranCard`) and its share image, which are off limits for polish work.
10. **Prayer: first run and edit sheet.** Checked, **not fixed**: there is no design to match.
    - The Home test "fresh" state never exercised the no-location case (it deleted the wrong settings key, `prayer_location` instead of
      `prayerLocation`). Fixed; the Home fresh goldens now show it. With no location Home now shows `PrayerArcSetupHero`: the
      sky card held at the peak of sunrise (`PrayerSkyScene.sunrisePeak`) with the default "Prayer Times" / "Choose a location..." / "Set up
      location" copy. The Prayer page's full setup screen (`_buildSetupState`) is still the old design.
    - Saved edit sheet against `saved-sheet.dark.html`: wording differs ("Folders"/"Manage" vs "Folder"/"Manage folders", "Favourites" vs
      "Favourite"), the "New folder" chip should have a dashed border, the tags row should be one inline field with a placeholder instead
      of chips plus a second text field, and Save has a check icon the design lacks. Not checked in every palette.
11. **Translations.** `prayerNextIn`, `showMore`, `prayersCount`, `note` are machine-drafted in ar, bn, de, fa, id, tr, ur.
    `saveDuasHere` ("Saved for quick access") was drafted in the same seven languages this round to match the new English caption
    (it is only used as the Duas tile caption). `loggedToday` ("Counted today") keeps its existing translations, which read as
    "recorded today". Have native speakers review all of them.

## Parked until the hero round
The Home, Quran and More PR left every hero card as it was. Status after the approved Quran landscape hero (`060a2c4`) and the
Home hero update (2026-10-04):
- ~~Home continue-reading card, Quran last-read card, Prayer hero on Home.~~ Done: Home uses `QuranReadingHero` and the redesigned
  `PrayerArcHero`.
- `EquranResumeImageCard` (`lib/widgets/last_read_cards.dart`) and the default branch of `LastReadCard` are now dead code (the fresh
  install overflow at 1.3 is gone with the new hero). Delete them in a cleanup.
- **More hero** (`_MoreHero`): still the old one; needs an approved design.
- **Prayer page no-location setup screen** (`_buildSetupState`): still the old design (the Home/Prayer hero card is done, see item 10).
- Token change for brighter heroes (`featA`/`featB`, `onFeat`, `featGold`, `featRule`, `onGold`, `onFeatGold`, stronger `glow`):
  still not in code; it re-renders every hero golden.
- ~~More title in the AppBar~~ Done in `d8ffc80`.
- **Surah list sort control:** still the round floating button. The design wants a flat "A to Z" chip, but the control reverses surah
  *order* (1 to 114), so the label and any new strings need a decision first.
- **Juz and Pages rows** are restyled cards, not the single grouped card in the design; no spec in the repo.

## Pages not yet redesigned (2026-10-04)
Roughly in the order worth doing. "Frame only" means `RedesignSubpage` (`d8ffc80`) is applied but the content, icons and cards are the old
design and there are no goldens.

**Untouched (old look)**
- Reader page body (`lib/home/read.dart`, 23 sheets and dialogs, stock AppBar, about 55 Material icons). Only the player bar and playback options
  sheet are redesigned. Chrome only: verse layout, fonts, audio and `ReadQuranCard` / share image stay as they are.
- Hifz session (`lib/hifz/pages/hifz_session_page.dart`) and Hifz complete (`hifz_complete_screen.dart`).
- Quran text search results (`lib/search/quran_text_search_results.dart`).
- Splash screen (fonts only were fixed).
- Reader bottom sheets and dialogs in `read.dart`, `read_quran_card.dart` (share/options) and `play_button.dart`.
- Daily tools edit sheet (`lib/home_dashboard/daily_tools_edit_sheet.dart`).
- Word by word: the download card in Settings and the word sheet (`lib/word_by_word/word_by_word_text.dart`).
- Memory map (`lib/hifz/memory_map.dart`, behind a feature flag, not reachable).

**Frame only**
- Zakat (`lib/zakat/zakat_page.dart`, the richer calculator: live metal prices, history, livestock, categories). The simpler
  `lib/home/zakah_calculator_page.dart` was deleted and the Home Zakah tool now opens `ZakatCalculatorPage`. Still needs the redesign;
  `docs/zakat_calculator_redesign_plan.md` exists.
- Reading plans (`lib/reading_plans/reading_plans_page.dart`).
- Islamic calendar (`lib/prayer/islamic_calendar_page.dart`) and Hijri calendar (`lib/home/hijri_calendar_page.dart`).
- Downloads (`lib/home/downloads.dart`, 7 sheets and dialogs).
- Prayer settings (`lib/prayer/prayer_times_settings_page.dart`, 7 sheets and dialogs) and both location pickers (manual and map).
- Appearance and Navigation settings, Settings (`lib/home/settings.dart`, 13 dialogs).
- Tasbih, Asma ul-Husna, Duas favourites, Hifz home: closer to done, not checked in detail.

**Done, with goldens:** Home, Quran tabs (Surahs, Juz, Pages, Saved), Prayer, Qibla, Duas home and category, More, Statistics,
Settings landing, floating dock, player bar, playback options sheet.

## Design file
The Prayer hero in the canvas still has the Sunrise/Maghrib labels touching the arc end (fixed in the app, not in the design).
