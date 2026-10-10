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
6. ~~**App text looks about 9% wider than the design.**~~ Done (2026-10-07, `polish/inter-opsz`): `lib/theme/inter_optical_size.dart` sets `opsz` = font size (clamped 14 to 32) on the theme slots and on every Inter style above 14 px (`withInterOpticalSize()`, or `fontVariations: const [FontVariation('opsz', N)]` next to a literal size). `wght` still follows `fontWeight`. Measured: "Saved for quick access" at 32 px is 8.9% narrower (351.86 to 320.52), 3% at 20 px, unchanged at 14 px and below. **New Inter text above 14 px must set `opsz` too.** Original investigation:
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
    - ~~Saved edit sheet against `saved-sheet.dark.html`~~ (aligned in `80e43d2`; the list below is the original diff): wording differs ("Folders"/"Manage" vs "Folder"/"Manage folders", "Favourites" vs
      "Favourite"), the "New folder" chip should have a dashed border, the tags row should be one inline field with a placeholder instead
      of chips plus a second text field, and Save has a check icon the design lacks. Not checked in every palette.
11. **Translations.** `prayerNextIn`, `showMore`, `prayersCount`, `note` are machine-drafted in ar, bn, de, fa, id, tr, ur.
    `enterPaidAmountInCurrency`, `zakatNisabNeedsRates`, `zakatDeleteRecordQuestion`, `zakatDeleteRecordBody` and `unitTola` (Zakat) are
  machine-drafted in the same seven languages too.
  `saveDuasHere` ("Saved for quick access") was drafted in the same seven languages this round to match the new English caption
    (it is only used as the Duas tile caption). `loggedToday` ("Counted today") keeps its existing translations, which read as
    "recorded today". Have native speakers review all of them.
    `polish/strings` added 88 more keys, machine-drafted in ar, bn, de, fa, id, tr, ur (English in brackets where short): `hifzRatingFail`,
    `hifzRatingPass`, `shareImageFormat`, `shareFormatStory`, `shareFormatSquare`, `shareFormatClassic`, `unableToShareAyahImage`,
    `reciterGroupDownloaded`, `reciterShowAlphabetical`, `audioConnectionInterrupted`, `offlineDownloadAyahOrReconnect`,
    `unableToPlayAyahAudio`, `repeatOnce`, `repeatTimes` (Arabic plural forms), `repeatInfinite`, `halfSecond`,
    `resourceStateUpdateAvailable`, `resourcePhaseStarting`, `resourcePhaseVerifying`, `resourcePhaseExtracting`,
    `resourcePhaseInstalling`, `resourcePhaseFailed`, `resourceTypeGeneric`, `translationBundled`, `translationDownloadUnavailable`,
    `navigationSettingsHint`, `navigationActiveSlots`, `navigationAvailableItems`, `navigationSlot`, `navigationSlotLocked`,
    `navigationSwapped`, `navigationRemoved`, `navigationPinned`, `navigationPinnedDisplaced`, `navSubtitleHome`, `navSubtitleQuran`,
    `navSubtitlePrayer`, `navSubtitleSettings`, `dockZakat`, `dockCalendar`, `downloadsReciterCount`, `downloadsItemCount`,
    `downloadsDeleteReciterBody`, `downloadsAllSurahs`, `downloadsFilterTitle`, `downloadsFilterSubtitle`, `downloadsFilterSearchHint`,
    `downloadsGroupBy`, `downloadsSortBy`, `downloadsCategory`, `downloadsContentType`, `downloadsSortReciterAsc`,
    `downloadsSortReciterDesc`, `downloadsSortSizeDesc`, `downloadsSortSizeAsc`, `downloadsSortSurahAsc`, `downloadsSortSurahDesc`
    (Arabic, Persian and Urdu use a left arrow so it points in reading direction), `offsetSetPositive`, `offsetSetNegative`,
    `notificationPermissionCheckTimedOut`, `notificationPermissionCheckFailed`, `exactAlarmPermissionCheckTimedOut`,
    `exactAlarmPermissionCheckFailed`, `asrMethodHanafi`, `highLatitudeRuleAutoTitle`, `highLatitudeRuleNoneTitle`,
    `highLatitudeRuleMiddleOfTheNightTitle`, `highLatitudeRuleOneSeventhTitle`, `highLatitudeRuleAngleBasedTitle`,
    `prayerMethodAuto`, `prayerMethodMuslimWorldLeague`, `prayerMethodEgyptian`, `prayerMethodUmmAlQura`, `prayerMethodDubai`,
    `prayerMethodKuwait`, `prayerMethodQatar`, `prayerMethodKarachi`, `prayerMethodMoonsighting`, `prayerMethodMorocco`,
    `prayerMethodSingapore`, `prayerMethodTehran`, `prayerMethodTurkey`, `prayerMethodShortAuto`, `prayerMethodShortMwl`,
    `prayerMethodShortDubai`, `prayerMethodShortMoonsighting`, `prayerMethodShortTurkey`, `dailyToolsKeepOnePinned` (ar and fa reuse the
    wording that was already inline). Existing translations that look weak and were reused: `reciter` in Indonesian ("Tukang
    deklamasi"), `cancel` in German ("Stornieren"), `clear` in German/Indonesian, `worshipTrendsAndStreaks` in German/Indonesian/Bengali.
    Wording that shifted in English: Navigation subtitles now reuse existing keys ("Duas & Azkar", "Compass and direction",
    "Wealth & Nisab evaluations"...), the Downloads filter shows "Meccan"/"Medinan" instead of "Makki"/"Madani", and "Word by Word" is
    "Word by word".

## Parked until the hero round
The Home, Quran and More PR left every hero card as it was. Status after the approved Quran landscape hero (`060a2c4`) and the
Home hero update (2026-10-04):
- ~~Home continue-reading card, Quran last-read card, Prayer hero on Home.~~ Done: Home uses `QuranReadingHero` and the redesigned
  `PrayerArcHero`.
- ~~`EquranResumeImageCard` (`lib/widgets/last_read_cards.dart`) and the default branch of `LastReadCard`.~~ Deleted in the cleanup
  commit (`LastReadCard.cardBuilder` is now required). `AppSelectionDialog` went with them; `AppSelectionOption` stays because
  Settings, Prayer settings and the reader still use it. `lib/widgets/holographic_card.dart` was unreferenced and is now deleted.
- **More hero** (`_MoreHero`): still the old one; needs an approved design. (Owner-blocked, see Open items.)
- **Prayer page no-location setup screen** (`_buildSetupState`): still the old design (the Home/Prayer hero card is done, see item 10).
  (Owner-blocked, see Open items.)
- Token change for brighter heroes (`featA`/`featB`, `onFeat`, `featGold`, `featRule`, `onGold`, `onFeatGold`, stronger `glow`):
  still not in code; it re-renders every hero golden.
- ~~More title in the AppBar~~ Done in `d8ffc80`.
- **Surah list sort control:** still the round floating button. The design wants a flat "A to Z" chip, but the control reverses surah
  *order* (1 to 114), so the label and any new strings need a decision first.
- **Juz and Pages rows** are restyled cards, not the single grouped card in the design; no spec in the repo.

## Pages not yet redesigned (2026-10-04), status after the polish branches
The stack of `polish/*` branches restyled almost everything that was listed here. Each line is struck through only where a commit
in `git log 9f00137..HEAD` shows the work. Goldens live under `test/redesign/goldens/` and the per-screen test folders.

**Done**
- ~~Reader chrome in `lib/home/read.dart`: top bar, nav pills, reading options hub, go to ayah, sleep timer, share format chooser,
  ayah actions, reciter picker, note editor, new-folder, choice and confirm dialogs.~~ `0a07dfe`.
- ~~Reader interval, ayah details, tafsir and tafsir sources sheets, translation download dialog, favourite note dialog, play button
  delete confirm, ayah card header icons.~~ `d059bb0`. (Verse layout, fonts, audio, `ReadQuranCard` and the share image were not
  touched.)
- ~~Saved edit sheet aligned with `saved-sheet.dark.html` (item 10).~~ `80e43d2`.
- ~~Hifz session and Hifz complete.~~ `ee8933c`; Scaffold kept on the session and only the tag x removes a tag, `a9fe823`.
- ~~Quran text search results, recents and empty states.~~ `8cb1bc1`.
- ~~Daily tools edit sheet.~~ `9a36a56`.
- ~~Word by word: Settings download card and the word meaning sheet.~~ `934311d`.
- ~~Splash colours and subtitle font on the redesign tokens.~~ `9d6264c` (the looping splash animations stay, see Open items).
- ~~Settings landing rows, sliders and its dialogs.~~ `f6edd94`.
- ~~Appearance and Navigation settings.~~ `3654cb8`.
- ~~Downloads page, filter sheet and confirmations.~~ `107e75e`.
- ~~Prayer settings rows, banners and dialogs.~~ `dfc8efb`.
- ~~Manual and map location pickers.~~ `397917d`.
- ~~Zakat calculator and history.~~ `d4e5a4a` (leftovers under Open items).
- ~~Reading plans.~~ `93fd6d1`.
- ~~Islamic calendar.~~ `aab058e`. ~~Hijri calendar page.~~ `3d10ed2`.
- ~~Asma ul-Husna.~~ `3cbe1ab`. ~~Favourite duas and the shared dua card.~~ `73c9fb7`.
- ~~Tasbih counter and sessions sheet.~~ `0aa52eb`.
- ~~Hifz home.~~ `7895541`.
- ~~Dead-code cleanup (`EquranResumeImageCard`, `LastReadCard` default branch, `AppSelectionDialog`).~~ `b7833e0`.

**Still untouched**
- Memory map (`lib/hifz/memory_map.dart`, behind a feature flag, not reachable).
- `read_quran_card.dart` share and options branch stays off limits.

**Done earlier, with goldens:** Home, Quran tabs (Surahs, Juz, Pages, Saved), Prayer, Qibla, Duas home and category, More, Statistics,
Settings landing, floating dock, player bar, playback options sheet.

## Open items after the polish stack

### Blocked on the owner
- ~~**More hero** (`_MoreHero`)~~ Done (owner delegated): `HeroPanel` + display title, `featText2` subtitle, gold "Open routine" action with `DesignIcon('chev')`; same copy, same `onOpenReadingPlans`, artwork still decoded via `EquranAssetImage`. No pill or progress bar (there is no data for them).
- ~~**Prayer page full setup screen** (`_buildSetupState`, no location)~~ Done (`polish/design-completions`, owner delegated the design): page frame + `PrayerArcSetupHero` + one hairline card (why a location is needed, privacy notice, the single "Set up location" action) + the "calculated locally" caption. Device location and manual entry live inside the map picker, as before. Goldens: `test/redesign/goldens/prayer_setup/`.
- ~~**Surah list sort chip label**~~ Done (owner delegated): flat `ChipButton` showing the order as numerals (1-114 / 114-1, 1-30 for Juz, 1-604 for Pages, pinned LTR), tooltip `reverseOrder` (new key, machine-drafted in 7 languages). It stays in the floating-button slot; to move it into the list header, relocate `_buildOrderChip` in `lib/home/main_page.dart`.
- ~~**Juz and Pages grouped card**~~ Done (owner delegated): one hairline card per juz (heading above it) and one card for Pages, via the shared `GroupedCardSliver`. Wide screens cap the card at 760 px; the Surahs tab still switches to a card grid from 700 px.
- **Bright hero tokens** (`featA`/`featB`, `onFeat`, `featGold`, `featRule`, `onGold`, `onFeatGold`, stronger `glow`): not in code; it
  re-renders every hero golden.
- **Native review of machine-drafted translations:** `prayerNextIn`, `showMore`, `prayersCount`, `note`, `saveDuasHere`, and in the
  polish stack `savedFolderLabel` and `savedManageFolders` (plus any other keys those branches added in ar, bn, de, fa, id, tr, ur).
  `polish/strings` adds the 88 keys listed under item 11.

### New findings
- ~~**(a) Wrong Hijri dates.**~~ Done in `9c3f556`. The duplicate `HijriCalendar` in `lib/home/hijri_calendar_page.dart` is gone; the page
  uses `lib/prayer/hijri_calendar.dart` (new `firstGregorianDayOf`, `daysInMonth`, `monthNameFor`) and honours `hijri_offset`. 7 Oct 2026 is
  now 24 Rabi' al-Thani 1448 (month 14 Sep to 12 Oct 2026). The offset is applied as whole calendar days (it used a 24 h `Duration`, which
  is wrong across a DST change). Unit tests in `test/hijri_calendar_test.dart`; the six Hijri calendar goldens are regenerated. The
  algorithm is the approximate civil one and can differ from Umm al-Qura by a day (for example 1 Muharram 1447); the moon-sighting offset
  covers that.
- ~~**(b) Home header Hijri date**~~ Done in `79aa5f6`: `toLocalizedDateString` for the app language, Western digits, no new keys.
- ~~**(c) Looping animations kept on purpose:**~~ Made finite (`polish/design-completions`). Splash: the glow/particle pulse runs one
  breath (2 x 2.4 s, same phase as before, so the splash goldens are unchanged) and then rests; with reduce motion it never starts
  and the glow sits at its resting size. The main intro controller (3.2 s, gates the hand-off to Home) is untouched. Map marker:
  `PrayerUserLocationMarker` pulses 3 x 2 s when it first appears and whenever the location changes, then rests (no ring); never
  with reduce motion. Tests: `test/redesign/looping_animations_test.dart`.
- ~~**(d) Pre-existing failures on `beta`:** 6 `home_page_test.dart` "Home rich" goldens fail.~~ Done in `3512d6c`. Root cause: the Journey
  card's streak chip used `DateTime.now()` instead of the page's injected clock, so against the real date the seeded 4 Oct 2026 activity
  counted as a broken streak and the chip vanished (a real wall-clock dependency, fixed in the app). The rest was stale Inter `opsz` text
  from `144ac99`, which regenerated only the fresh goldens.
- **(e) Zakat leftovers:** (`fix/followups`: with no usable gold/silver rates the result card now shows a neutral "Nisab not checked" pill, a dash for the due amount and the add-rates note, instead of "Below Nisab"; the maths is unchanged, new key `zakatNisabNotChecked`.) ~~`$Infinity` message~~, ~~USD wording in `enterPaidAmountUsd`~~, ~~no delete confirmation~~, ~~hard-coded
  "tola"~~ all done in `5e253a9` (the history tab has no streak suffix; there was no "d" to move). Still open, owner decision: the
  demo livestock constants (`_computeLivestockValue` in `lib/zakat/zakat_page.dart`: 180 / 850 / 1800 per sheep-goat / cow-buffalo /
  camel, in whatever currency is selected with no conversion, added as a wealth line item at a flat 2.5% instead of the Shari'a livestock
  schedule), and ~~`goldPriceGram` / `silverPriceGram` in the override dialog said "(USD)" in all 8 ARBs~~ (done in `fix/followups`: an override is saved in the selected currency with no conversion, `_ratesCurrency = _baseCurrency`, so both keys now take a `{currency}` placeholder).
- ~~**(f) Reader card header action buttons are 34 px,**~~ Done (`polish/design-completions`): each action (play, tafsir, favourite) now takes
  hits in a 44 x 44 layout box; the visible button is still 34 px (38 px wide). The header is still 44 px high (the badge). The visual
  gap between buttons grows from 6 to 10 px on phones (wide screens keep 10), so the action group is about 18 px wider. The favourite's
  real tap area used to be its 20 px icon (not 34); it now fills 44 px. The Material play/pause icons remain because the design has no
  matching icon. The `shareImageMode` branch is untouched (actions are not drawn there).
- ~~**(g) Legacy English-only strings:**~~ Done (`polish/strings`): Hifz Fail/Pass (`hifzRatingFail`/`hifzRatingPass`; "Try again"/"Got it" are
  different buttons on the same row), share-image format sheet, reciter picker tooltips, reader audio messages, repeat choices ("Once",
  "N times", "Infinite" were Arabic-only) and "0.5 seconds", Navigation settings (hint, headings, slot, snackbar and subtitle text), Downloads page and
  filter sheet (counts use ICU plurals, so "1 surah" is now correct), prayer settings (calculation method, Asr, high-latitude rule,
  prayer names, 12/24-hour, permission messages, offset sign tooltip), dock labels for Zakat and Calendar, the "keep one tool pinned"
  message, "Juz N" on the Hifz screens, and resource/translation status labels ("Verifying", "Bundled", "Update available"...).
  Backend enum labels (`ResourceInstallState.label`, `PrayerCalculationMethod.label`, `AudioDownloadEntry.title`...) stay English for logs;
  screens use `lib/utils/resource_labels.dart` and `lib/prayer/prayer_localizations.dart`. `test/localization_strings_test.dart` checks every
  key above in all 8 locales (present, same placeholders, not the English text). The Downloads filter sheet footer is now a `Wrap`
  because German at text scale 1.3 overflowed the old `Row`.
  **Deliberately left English** (not presentation, or no context): `ResumeStateEntry.subtitle` ("Ayah n", stored and backed up); the
  `'Default'`/`'Unsorted'` folder names and the `'Backup cancelled.'`/`'Restore cancelled.'` sentinels; `PrayerTimeKind.label` and other
  strings used by notifications and the widget worker; `prayer_location_service.dart` and `resource_download_service.dart` error messages
  (shown as-is by the map picker and download rows); `MediaItem` titles ("Ayah delay"); the share-image header `'Ayah n - Story 9:16'`
  (drawn into the image, share branch is off limits); the More page easter-egg snackbars; Tasbih `sequenceHint` (unused); the dead
  `home_dashboard_page.dart` cards ("Reading plan", "Bookmarks and notes"... no longer built); Arabic-only `_localizedDhikrStatsLabel`;
  the per-language inline maps in `daily_tools_config.dart`, `daily_tools_edit_sheet.dart` and `hijri_calendar_page.dart` (already
  translated into every language); AM/PM suffix switches; reciter names (`AppReciter.displayName`).
  Also noted, not changed: `RedesignEyebrow` upper-cases with `toUpperCase()`, which gives "I" for Turkish "i" (should be "İ").
- **(h) Arabic test goldens** show tofu for `ChipButton` text in places (test font fallback).
  Three Arabic goldens also fail on a clean checkout of the stack on the machine this round ran on (`reader_chrome_test` note editor
  `arabic-rtl`; `saved_tab_test` `arabic-rtl` and `arabic-text-1.3`), identical with and without the cleanup commit; likely the same font
  fallback, unconfirmed.
- **(i) Inter `opsz` (item 6)** remains open; it is being handled separately.
- ~~**(j) Unreferenced after the cleanup:** `lib/widgets/holographic_card.dart`~~ Deleted in `5297dca`. The `foil` dependency in
  `pubspec.yaml` (vendored in `third_party/foil`) is now unused, and the `holographicCardsEnabled` setting (More page easter egg, backup
  key) no longer has any effect; both were left alone.

## Design file
The Prayer hero in the canvas still has the Sunrise/Maghrib labels touching the arc end (fixed in the app, not in the design).
