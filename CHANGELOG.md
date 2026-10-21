# Changelog

## 4.0.0-beta.3 (build 107)

Build-only update for F-Droid. There are no changes to the app itself.

- **F-Droid build fix.** `pubspec.lock` is regenerated with Flutter 3.47.7 so `flutter pub get --enforce-lockfile` passes in the F-Droid build.

## 4.0.0-beta.2 (build 106)

Follow-up to the beta with the redesigned screens that were still in progress:

- **Hifz session.** Redesigned session header and text-size controls, and the review and completion screens.
- **Quran.** Juz and surah card lists use the grouped card style, and the text-size slider is restyled.
- **Home.** Quick tools and the dashboard header are updated, and the Statistics page is restyled.
- **Prayer.** The prayer times sheet is restyled.
- **Duas.** The Asma ul-Husna page is updated, with a clearer empty-results state.
- **Settings.** Rows and dialogs are restyled.

Privacy: coordinates stay on the device. Labels come from you, or fall back to the coordinates.

## 4.0.0-beta.1 (build 105): the redesign beta

This is the first public beta of eQuran 4. It is a pre-release: the core reading,
listening, prayer and tracking features are in place, but the redesign is still
being tested with real users, and some translations are still awaiting review. Please
report anything that looks wrong on the issue tracker.

Compared with the last stable release (3.4.1), version 4 changes how the app looks
and moves through it, adds a few features, and fixes a long list of smaller problems.
Your data carries over: bookmarks, favourites, reading history, Hifz progress,
Zakat history and settings are all kept. Backups made in older versions still restore.

### What's new

- **Resources page.** Downloadable resources (Quran translations, tafsir, audio and
  word-by-word packs) now have their own page. You can filter it to see what is
  installed, what is bundled, and what has an update.
- **Word-by-word meanings.** Tap a word in the reader to see its meaning. This needs
  the optional word-by-word download in Settings, and a verse only shows meanings
  when every word lines up with the source data.
- **Startup animation setting.** A short splash plays once when the app opens. You
  can turn it off in Settings, and it is skipped automatically when reduce motion is on.
- **Support section in About.** Donation details now sit in the About dialog.

### Redesigned screens

Every main screen now shares one visual language: clearer headings, quieter cards,
and a consistent set of icons.

- **Home.** A new header and journey card, with a streak chip, daily tools, and
  "continue reading" cards.
- **Navigation.** A floating dock replaces the old bottom bar. Saved and Statistics
  have shorter labels so every item fits on narrow phones.
- **Quran.** The Surahs, Juz and Pages tabs share one header. Juz and Pages are shown
  as grouped cards, and the sort control is a simple numbered chip.
- **Reader.** A redesigned top bar and navigation pills, a player bar with a morphing
  play button, and a playback options sheet. On phones the options button now sits at
  the end of the progress row. Verse action buttons have larger touch targets.
- **Prayer.** A sky hero shows the arc of the sun through the day and the next prayer,
  with a night version after Isha. The location pickers and the "no location yet"
  setup screen are rebuilt on the same frame.
- **Qibla.** A new compass page with a spring-driven dial.
- **Duas and Tasbih.** Duas has a redesigned home and theme browser, favourite duas
  and the Asma ul-Husna page are restyled, and the Tasbih counter has a new sessions sheet.
- **Hifz.** The Hifz home page, review session and completion screens are restyled.
  Today and prayer logging still work if the Hifz data fails to load.
- **Saved and Statistics.** The Saved tab and the edit sheet are redesigned. Statistics
  is redesigned with the same counts, now formatted with locale-aware separators.
- **Calendars.** The Islamic and Hijri calendars are restyled.
- **Zakat.** The calculator and history are restyled, and the result card says
  "Nisab not checked" when no gold or silver rates are loaded, instead of "Below Nisab".
- **Reading routine, Downloads and Search.** Restyled to match the rest of the app.
- **Settings and More.** Settings rows, sliders, dialogs and the More page are
  restyled. More is now grouped into clear lists.
- **Themes.** Text in every colour theme gets better contrast, and Inter now scales its
  optical size with the font size, so text looks closer to the design at larger sizes.

### Improvements

- **Faster start and lighter memory use.** Startup is split into a blocking part and a
  deferred part, so the first screen appears sooner. Large illustrations are decoded at
  display size, and the app uses the device's capabilities to skip costly effects on
  low-end phones.
- **Smaller app.** Fonts are trimmed to the Latin and transliteration glyphs they use,
  and oversized images are re-encoded. This saves roughly 360 KB of font data alone.
- **Home screen widget.** The prayer widget now follows your saved dark-theme choice.
- **Localization.** Many labels that were English-only are now translated in all eight
  languages, including Turkish and Azeri-style upper case and the Downloads counts.
- **Right-to-left text.** Arabic, Persian and Urdu text is laid out right-to-left more
  consistently, including Saved translations and tags.
- **Backups.** Every data box is now included in backups, and a failed restore rolls
  back to the previous state.

### Fixes and hardening

- Security hardening: resource archives have decompression limits, the font patcher
  checks its byte offsets, and database reads validate their types.
- Animations stop after a short time instead of looping forever, and they are turned
  off when reduce motion is on.
- Prayer: Maghrib and Isha are no longer marked as passed when Fajr begins; the
  current prayer is highlighted correctly; a location is never set to the unselected
  map centre.
- Hijri dates: the Hijri calendar uses the shared conversion and honours your
  moon-sighting offset. The Home header date is localized.
- Zakat: units, currency labels on price overrides, and the metal-rate status line are
  corrected and localized.
- Widget and dark-mode fixes, a leaked controller in the Downloads dialog, and
  unawaited futures flagged by the newer analyzer.

### Removed

- **Holographic card setting** and its hidden easter egg in About. Old backups that
  contain the setting still restore; the setting is simply ignored.
- **Livestock in Zakat.** Livestock is hidden from the calculator and left out of the
  total until sourced count schedules are added. Existing Zakat history that includes
  livestock still displays.

### Known issues in this beta

- Most translations added in version 4 were drafted by machine and are waiting for a
  native-speaker review. Please tell us if a phrase reads wrongly in your language.
- Zakat does not include livestock yet (see Removed).
- The full-screen verse card in the reader keeps its earlier layout and is not yet
  part of the redesign.

## 3.4.1

Last stable release before version 4.
