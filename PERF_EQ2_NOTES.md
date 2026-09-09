# PERF EQ-2 — incremental notes (low-end perf audit + optimization)

Target: low-end Android (2GB RAM, Android Go) + SE-class iPhones. Perf only,
no behavior changes. ValueNotifier+setState, Hive only. No flutter/dart runs
here — orchestrator verifies on Flutter host.

## Audit findings (with planned fix)

1. `resource_download_service._extractZip` loads the whole ZIP into RAM
   (`decodeBytes(await zipFile.readAsBytes())`). The QPC tajweed pack is
   ~69MB, so install transiently holds ~2x that (bytes + inflated archive).
   OOM/crash risk on 2GB Go devices. FIX: stream-decode from disk with
   `InputFileStream` + `ZipDecoder().decodeStream` (same pattern the audio
   service already uses), plus archive entry count + per-entry size guards,
   and `freeMemory: true` on `writeContent`.
   Expected: peak install RSS down ~one full-archive copy (~70MB for the
   font pack) plus progressive release as entries are written out.

2. `qpc_v4_font_service`:
   - `_loadedPages` is `Set<int>` but load keys are variant-qualified
     (`page:variant`). After loading light, a dark request short-circuits as
     "loaded" and never registers the dark family (falls back to Hafs).
     FIX: track `Set<String>` of `page:variant`; keep both variants cached.
   - `_loadVariant` copies the whole file (`Uint8List.fromList(bytes)`)
     before patching, although `readAsBytes()` already returns a fresh
     mutable buffer and the patcher works in place. FIX: patch `bytes`
     directly. Saves ~1x file size transient per dark page load.
   - `clearCache()` on brightness change nukes everything; with the
     variant-aware set, the just-loaded variant survives a toggle-back.

3. `startup_coordinator._initializeStorage` opens ~11 Hive boxes strictly
   sequentially (each is an independent local open). FIX: `Future.wait` the
   independent opens; keep frontier-check + migrations ordered after.
   Step order storage->quran->audio->prayer->widgets unchanged.

4. Reader `read.dart` QPC inline path (`_buildInlineSurahTextSpan`): per build,
   per verse (up to 286 for Al-Baqarah) it does 2x `SettingsDB` Hive reads
   (style + themeMode), a `'$chapter:$verse'` string alloc + map lookup in
   `getPageNumber`, a `fontFamilyForPage` string interp, a fresh `TextStyle`
   alloc, and `_inlineVerseTextSegment` (Hive read + `getVerse` + `RegExp`
   construction in `quranVerseText` + interp). Non-QPC path is already cached
   (`_inlineSurahTextCache`, chapter-scoped). FIX: chapter-scoped QPC segment
   cache (cleared in `_clearVerseTextMetrics`, which only runs on chapter
   change); hoist style/dark reads out of the loop via a new
   `EquranTextStyles.qpcV4FontFamilyForPage(page, darkMode)` helper keyed off
   `Theme.brightness`; per-build page->TextStyle map so repeated pages share
   one style object. Also hoist the basmala `RegExp` + `arabicDigits` map in
   `quran_text.dart` to top-level finals (built per call today).

5. Reader font preloading (`_loadFontsForCurrentSurah`) fires up to 3
   separate `setState((){})` (each rebuilds the whole page incl. RichText).
   FIX: coalesce into one post-frame `setState` via `_scheduleFontsRefresh`.

6. `audio_downloads._enforceTempAyahCacheLimit` uses `listSync`,
   `lastModifiedSync`, `lengthSync`/`existsSync` on the UI isolate on every
   cache insertion/hit path. FIX: async `list()` + `stat()`; keep cap 10 and
   `.part` cleanup semantics identical.

7. Dashboard `home_dashboard_page.dart`:
   - 7-deep nested `ValueListenableBuilder`s rebuild the entire
     `_DashboardContent` (incl. `_DashboardSummary.load`) when ANY of 7 boxes
     notifies. FIX: single `ListenableBuilder` over `Listenable.merge`
     (identical rebuild semantics, fewer layers).
   - `_DashboardSummary.load` sorts full boxes to find a max
     (`_latestResume`, `_legacyReadingResume`, active plan). FIX: single-pass
     max (O(n) vs O(n log n), no intermediate lists).
   - `_PrayerSummary.load` runs 3x full adhan `calculateDay` per build.
     FIX: single-entry memo of the 3 calculated days keyed by
     (date, coords, tz, full settings JSON); per-build derivation of
     current/next period from `now` stays live. Key includes the whole
     settings JSON so no calc-relevant field can go stale.
   - `_DailyAyah.forDate` writes to SettingsDB *during build* (day rollover),
     synchronously notifying the settings listener mid-build -> extra full
     rebuild cascade. FIX: defer the two puts to post-frame with a re-check;
     returned ayah unchanged. Same-day corrupt-value path keeps the original
     synchronous write so convergence semantics are identical.

8. Assets: root `flutter_01.png` is 0 bytes and unreferenced -> delete.
   Bundled images are already `.webp`, 10-155KB each (~2.3MB total);
   `assets/data` (~9.9MB, quran text/translation JSON) is lazily loaded per
   surah via `quran_lite` caches — no change. `quran.webp` (141KB) and
   `isha_banner.webp` (155KB) are the largest; already compressed, left alone.

9. Frame-rate governor (`frame_rate_policy_manager.dart`): sane — debounced
   restore (500ms), deduped hints (`_appliedHint` guards), mini-player static
   path skips hints, expanded-player progress ticker capped at 33ms and
   gated by foreground/route/seek state. No change. Note: governor is
   Android-only; iOS/SE relies on default cadence (no private API to do
   otherwise — correctly left alone).

10. No new deps, no GMS, pubspec.lock untouched. `preferInteractive60*` is
    currently uncalled (dead but harmless) — left as-is, smallest diff.
