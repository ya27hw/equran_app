# Defect register

Only evidence-backed findings are listed as verified defects. Hypotheses remain risks until a test or profile confirms them.

| ID | Classification | Severity | Evidence / reproduction | Affected files | Resolution / coverage | Commit |
| --- | --- | --- | --- | --- | --- | --- |
| D-001 | Data-loss risk | Critical | `BackupService.restoreFromPickedFile()` validates payload, then clears settings/favourites/bookmarks before writing; a write failure leaves live data partially replaced. | `lib/backend/backup_service.dart` | Implement staged validation, snapshot/atomic replacement, rollback, and corruption tests. | Pending |
| D-002 | Correctness / financial integrity | High | `_fetchLiveMetalPrices()` requests PAXG and calculates silver as `goldGramPrice / 80`, then reports synchronized live rates. | `lib/zakat/zakat_page.dart` | Independent source fields for gold/silver, timestamps/units/currency, stale/manual/offline states, and calculation tests. | Pending |
| D-003 | Maintainability / quality gate | High | `flutter test` exits 1 because no `test/` directory exists; CI quality only runs `flutter pub get`. | `.github/workflows/deploy.yml`, `test/` | Add deterministic unit/widget/integration foundation and CI gates. | Pending |
| D-004 | Performance defect | High | `QuranTextSearchService._buildIndex()` loops over every ayah and selected translation; `Future.microtask` leaves CPU work on the UI isolate. | `lib/search/quran_text_search_service.dart` | Indexed/paginated search with bounded cache and benchmarks. | Pending |
| D-005 | Performance / memory defect | High | `QpcV4FontService.ensureFontLoadedForPage()` loads and registers both light and dark font variants for every page, retaining `_loadedPages`. | `lib/backend/qpc_v4_font_service.dart` | Active-theme bounded window, duplicate futures, profiling, and explicit engine limitation. | Pending |
| D-006 | Performance / reliability | High | `AudioDownloadService` calls `zipFile.readAsBytes()` and `ZipDecoder().decodeBytes()` for full archives before extraction. | `lib/backend/audio_downloads.dart` | Worker/streaming extraction, path/file limits, atomic install, cancellation, malformed archive tests. | Pending |
| D-007 | Startup performance | High | `main()` awaits all storage, migration, translation, prayer, and widget work before `runApp()`. | `lib/main.dart` | Staged, idempotent startup coordinator with first-frame trace. | Pending |
| D-008 | Product/security configuration | Medium | Release signing falls back to debug signing when credentials are absent, so release-compatible local builds can be mistaken for production release output. | `android/app/build.gradle` | Fail closed for production signing; retain explicitly named local validation variant. | Pending |
| D-009 | Accessibility/localization risk | Medium | New roadmap UI does not yet exist and repository has no automated RTL, text-scaling, semantics, or ARB drift checks. | `test/`, `lib/l10n/`, CI | Add test fixtures and localization verification. | Pending |
| D-010 | Privacy risk | Medium | No centralized local feature-flag/data-retention policy exists for roadmap systems yet. | `lib/`, `docs/roadmap/` | Add local flags, storage ownership, export/delete controls, and privacy documentation before activation. | Pending |

