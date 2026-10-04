# Follow-up for the coding agent

Review fixes already made are in PR #101 (Prayer, Duas, Saved) and branch `redesign/stats-fixes` (Statistics).
This file lists what is **still open**. Give the agent **one item at a time**, same rules as `CODEX_PROMPT.md`
(presentation only, no hardcoded colours, `dart format`, `flutter analyze --fatal-infos`, `flutter test`).
For every item: verify at 390 px in emerald-dark, emerald-light, AMOLED black and red-dark, at text scale 1.3, and in Arabic (RTL),
and compare against `docs/redesign/previews/*.html`. The preview HTML wins over this brief.
Use `DesignIcon` (`lib/widgets/redesign/design_icon.dart`) for icons, never Material icons, where the design has one.

## Needs a product decision first (ask the owner, do not start)
1. **Floating dock.** `FloatingDock` exists (`lib/widgets/redesign/floating_dock.dart`) but the app still shows the old solid bottom bar.
   Ship it (wire into `lib/home/main_page.dart`) or drop it. Dock icons in the design: home, quran, clock, arch, grid.
2. **Saved note label.** Design says "NOTE", app says "PRIVATE NOTE" (`privateNote`). Keep or match.
3. **Statistics "Memorized" stat.** Design shows "5 Surahs mastered"; the app shows memorized ayahs (real data, label "Memorized · Ayahs", wraps to two lines). Keep the data or change the metric.

## Open work
4. **Quran header and tabs on all four tabs.** Only Saved has the serif "Quran" header with underline tabs (`SavedQuranHeader`,
   `lib/widgets/favourites_list.dart`). Surahs, Juz and Pages still show the old centred header and pill tabs, so the chrome changes
   when you switch tabs. Use the new header and tabs for all four. Keep the search button behaviour.
5. **Fonts add about 2.1 MB (about 7% of the APK).** Newsreader plus Inter (856 KB) and Noto Naskh (300 KB). Subset to Latin,
   drop unused weights/axes, and report the before/after APK size. Check `pubspec.yaml` licences stay bundled.
6. **App text looks about 9% wider than the design.** Examples: the Saved search hint truncates, Duas "Saved for quick access"
   wraps in a tile where the design fits on one line. Check that the bundled Inter matches the design's Inter (optical size axis,
   static vs variable, letter spacing) before shrinking any text.
7. **Statistics number format and glyphs.** Large counts need a locale thousands separator (1840 next to 196.4K, use
   `NumberFormat.decimalPattern`). Check in the real app (not the preview clock) that future prayers show the dashed "not yet"
   glyph and the legend lists it only when used.
8. **Saved medallion at text scale 1.3.** The verse number overflows its star. Scale it down (FittedBox) or grow the medallion.
   See the medallion in `_BookmarkRow` in `lib/widgets/favourites_list.dart`.
9. **Right-to-left text.** `#hope` renders as `hope#`: force LTR for hashtags. English translation and note text take the UI
   direction, so full stops land on the wrong side: set direction from the text's own script.
10. **Prayer: first run and edit sheet.** Not yet checked: Prayer with no location (setup state) and the Saved edit sheet in all
    palettes. Check them against the design and fix differences.
11. **Translations.** `prayerNextIn`, `showMore`, `prayersCount` are machine-drafted in ar, bn, de, fa, id, tr, ur.
    Duas captions changed in English only ("Saved for quick access", "Counted today"); other languages keep their old captions.
    Have native speakers review.

## Design file
The Prayer hero in the canvas still has the Sunrise/Maghrib labels touching the arc end (fixed in the app, not in the design).
