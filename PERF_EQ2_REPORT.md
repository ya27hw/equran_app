# PERF EQ-2 Report — Low-End Perf Audit + Optimization (eQuran v3.4.1+102)

Branch: `lane/eq2-perf` (base `beta` 97e1b74). Scope: perf only, no behavior
changes. ValueNotifier+setState, Hive only. No new deps (F-Droid safe),
`pubspec.lock` untouched. `flutter`/`dart` are not installed on this machine,
so nothing below was executed here; verification runs on the Flutter host
(orchestrator: `flutter analyze` zero warnings, tests, web smoke,
before/after numbers).

## 1. Hotspot table (audited)

| # | Hotspot | Finding | Disposition |
|---|---------|---------|-------------|
| H1 | Resource ZIP install (`resource_download_service._extractZip`) | `decodeBytes(await zipFile.readAsBytes())` holds raw bytes + inflated archive (~2x, ~140MB transient for the 69MB QPC font pack) on the UI isolate | FIXED: file-backed `decodeStream`, entry count/size guards, `freeMemory: true` |
| H2 | QPC font load (`qpc_v4_font_service`) | Variant-blind `_loadedPages: Set<int>` skips dark-family registration after light load (dark glyphs fall back); `Uint8List.fromList` duplicates every dark file before in-place patch | FIXED: `Set<String>` page:variant cache, patch `readAsBytes` buffer directly |
| H3 | Cold start (`startup_coordinator._initializeStorage`) | 11 independent Hive box opens awaited sequentially (blocking stage itself is already minimal: settings box only) | FIXED: `Future.wait` over the independent opens; step order unchanged |
| H4 | Reader inline QPC span (`read._buildInlineSurahTextSpan`) | Per build x up to 286 verses: 2x Hive reads + string alloc + fresh `TextStyle` + uncached segment (each incl. a `RegExp` construction in `quranVerseText`); non-QPC path was already chapter-cached | FIXED: chapter segment cache, hoisted style/dark/page lookups, per-page style reuse, hoisted RegExp/digits map |
| H5 | Reader font preload (`_loadFontsForCurrentSurah`) | Up to 3 full-page `setState` per navigation (each rebuilds the whole RichText) | FIXED: coalesced single post-frame refresh |
| H6 | Ayah temp cache (`audio_downloads._enforceTempAyahCacheLimit`) | `listSync`/`lastModifiedSync` block the UI isolate on every cache touch (cap-10 LRU retained) | FIXED: async `list()` + `stat()` |
| H7 | Dashboard (`home_dashboard_page`) | 7-deep nested VLBs rebuild everything on any box write; full-box sorts for single max rows; 3x adhan `calculateDay` per build; `SettingsDB.put` during build on day rollover cascades a second rebuild | FIXED: merged listener, single-pass max, single-entry day memo, post-frame defer of day-rollover puts |
| H8 | Assets | Root `flutter_01.png` is 0 bytes, unreferenced | FIXED: deleted. Bundled images already `.webp` 10–155KB; quran text/translation JSON lazily per-surah — left alone |
| H9 | Frame-rate governor (`frame_rate_policy_manager`) | Sane: 500ms debounce, deduped hints, capped 33ms progress ticker gated on foreground/route/seek; Android-only by platform limitation | NO CHANGE (documented) |

Out of scope / left alone: `preferInteractive60*` is currently uncalled
(dead but harmless); translation-manifest remote fetch during startup
(behavior-adjacent, flag for follow-up); bookmark-service full sort (shared
API, dashboard only needs top 3 — noted, not touched for minimal diff).

## 2. Measurement basis

No on-device numbers were collectable here. Basis for each change is static
reasoning (complexity class, allocation counts, rebuild counts) as mandated
by the task; the orchestrator supplies web-build before/after metrics on the
Flutter host. Suggested checks: cold-start time to first frame (H3),
install peak RSS for the 69MB font pack (H1), reader frame times while
playing Al-Baqarah in QPC mode with profiler (H4/H5), scroll jank during
ayah streaming (H6), dashboard rebuild count per box write via
`debugPrintRebuildDirtyWidgets` or timeline (H7).

## 3. Change list (all on `lane/eq2-perf`)

1. `lib/backend/resource_download_service.dart` — `_extractZip` decodes via
   `InputFileStream` + `ZipDecoder().decodeStream` (mirrors the ayah-audio
   path), 4096-entry cap, 64MB per-entry cap, `writeContent(..., freeMemory:
   true)`. Error strings for corrupt/oversized archives preserved.
2. `lib/backend/qpc_v4_font_service.dart` — `_loadedPages: Set<String>`
   keyed `page:variant` (check + insert consistent); dark patch applied to
   the `readAsBytes()` buffer in place.
3. `lib/backend/startup_coordinator.dart` — box opens in one `Future.wait`
   (all `Future<void>`; verified `BaseDB.initBox`, `HifzDB.init`,
   `ZakatHistoryDB.initialize`, `initCompanionStorageBoxes` signatures);
   frontier check + migrations still ordered after.
4. `lib/theme/equran_text_styles.dart` — new `qpcV4FontFamilyForPage(page,
   darkMode:)` and `qpcV4PageNumber(chapter, verse)` helpers;
   `fontFamilyForPage` delegates (identical output).
5. `lib/home/read.dart` — `_qpcInlineSegments()` chapter cache (cleared in
   `_clearVerseTextMetrics`, which only runs on chapter change);
   `_scheduleFontsRefresh()` coalescing; QPC span loop uses cached segments,
   one brightness read, per-page style reuse.
6. `lib/utils/quran_text.dart` — `quranBasmalaPrefixPattern` (top-level
   `final`) and `arabicDigitGlyphs` (top-level `const`); call sites
   unchanged in behavior.
7. `lib/backend/audio_downloads.dart` — async enforcement with per-file
   stat guards; cap (10), `.part` cleanup, and best-effort semantics
   preserved.
8. `lib/home_dashboard/home_dashboard_page.dart` — `ListenableBuilder` +
   `Listenable.merge` (identical rebuild semantics); single-pass newest
   active plan / latest resume / legacy resume; single-entry `_CachedPrayerDays`
   memo keyed by date + 4dp coords + tz + mode + full settings JSON
   (current/next period still derived live from `now`); day-rollover
   `dailyAyah` puts deferred one frame with re-check (same-day corrupt path
   keeps the original synchronous write).
9. Deleted `flutter_01.png` (0 bytes, unreferenced).

## 4. Expected gains (low-end: 2GB Android Go / SE-class iPhone)

- H1: install peak RSS down ~one full-archive copy (~70MB for the font
  pack) + progressive release per written entry; removes the likeliest
  OOM kill during first-run font install.
- H2: -1 full-file allocation per dark page load; fixes missing dark
  families after theme toggle (fewer fallback-layout passes); toggle-back
  hits cache instead of reloading.
- H3: storage phase wall time from sum-of-opens to slowest-open.
- H4: per reader rebuild in QPC mode: 286x Hive reads + 286x string-alloc
  page lookups + 286x `TextStyle` allocs + 286x segment rebuilds (each with
  a RegExp compile) collapse to ~48 page-style allocs (Al-Baqarah) + cache
  hits. Fewer GC pauses during playback-tick rebuilds.
- H5: up to 3 full-page rebuilds per surah navigation become 1.
- H6: removes synchronous FS stat storms from the playback path.
- H7: box scans O(n log n)->O(n); repeat dashboard builds skip 3x adhan
  trig recalculation (minute/hour ticker, fav toggles, progress writes);
  day rollover no longer double-rebuilds.
- H8: trivial (dead weight removed).

## 5. Risks and why they are contained

- Streaming ZIP decode uses the same `archive` APIs as the existing audio
  path; corrupt-ZIP error mapping preserved; new caps (4096 entries, 64MB
  per entry) are orders of magnitude above legit packs (604 TTFs, small
  JSON/TXT/MP3).
- Font variant cache only ADDS registrations that were previously skipped;
  family-name strings byte-identical via the delegated helper.
- `Future.wait` over independent same-type box opens; failure semantics
  unchanged (first error still throws, still caught per-step by `_runStep`).
- Reader/daily-ayah/prayer-memo outputs are value-identical: caches keyed
  on all inputs (chapter; date+coords+tz+mode+full settings JSON); deferred
  writes re-checked before persisting.
- Dashboard merge preserves rebuild semantics (every box change already
  rebuilt the full content through the nesting).
- No layout, string, navigation, or persistence-schema changes; smallest
  diffs; unrelated files untouched.
