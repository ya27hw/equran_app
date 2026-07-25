# Codebase Architecture Map (AGENTS.md)

Welcome to the `equran-app` codebase. This document serves as a dense, clear, structural onboarding guide and system map for developers and AI agents. It maps the directories, architectural paradigms, subsystem designs, and coding guardrails that must be strictly followed.

---

## 🏗️ Architectural Paradigm

### Feature-First Modular Structure
This codebase does not follow a strict traditional horizontal layered layout (e.g. `/lib/src/models`, `/lib/src/repositories`, etc.). Instead, it uses a **Feature-First Modular Architecture**:
- Each self-contained feature is co-located in its own top-level directory directly under `/lib/` (e.g., `lib/prayer/`, `lib/duas/`, `lib/hifz/`).
- Within a feature directory, you will find co-located files including pages/views, repositories, services, local models, and specialized widgets (e.g., `lib/hifz/pages/` and `lib/hifz/models/`).
- Global and shared layers live in centralized utility directories:
  - `lib/backend/`: Core databases, app settings, and network/caching logic.
  - `lib/theme/`: Global typography and multi-theme styling configurations.
  - `lib/widgets/`: Shared reusable UI elements.
  - `lib/utils/`: Raw calculations, parsing, and formatting logic.

### State Management & Reactive UI
- **ValueNotifier Pattern:** This project does not use state management libraries like `flutter_bloc` or `riverpod`. Instead, it is built on native Flutter `ValueNotifier`, `ChangeNotifier`, and `ValueListenableBuilder` widgets.
- **Custom Reactive Streams ("Blocs"):** Core global state is managed via lightweight classes that extend or use `ValueNotifier` to stream state updates (e.g., `NavigationBloc` inside [navigation_bloc.dart](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/backend/navigation_bloc.dart) extends `ValueNotifier<NavigationState>`).
- **UI Consumption:** Views subscribe to updates reactively using `ValueListenableBuilder` or custom state streams to rebuild only the atomic components that depend on changed variables, keeping rendering overhead minimal.

---

## 📁 Codebase Directory Map

### Shared Core & Shared Utilities
- **[lib/backend/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/backend/)** -> Core databases, repository layers, and background services:
  - Database helpers (Hive/SQLite-based) such as `bookmark_db.dart`, `favourites_db.dart`, `dua_favourites_db.dart`, `hifz_db.dart`, `settings_db.dart`, `surah_db.dart`.
  - Global app settings and backup services (`settings_db.dart`, `backup_service.dart`).
  - Font loading engines (`qpc_v4_font_service.dart`) and font patch utilities (`qcf_cpal_patcher.dart`).
  - Downloader services (`resource_download_service.dart`, `resource_install_store.dart`, `audio_downloads.dart`).
- **[lib/theme/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/theme/)** -> Global design tokens:
  - Colors, shapes, and theme mode listeners.
  - Typography map [equran_text_styles.dart](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/theme/equran_text_styles.dart) which resolves font families dynamically.
- **[lib/widgets/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/widgets/)** -> Reusable atomic UI components (e.g., progress indicators, selection dialogs, and main reading player sheets).
- **[lib/utils/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/utils/)** -> Formatting tools, recitation profile indices (`reciter.dart`), and shared validation logic.
- **[lib/services/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/services/)** -> Platform-level configurations and system handlers (e.g., frame rate policies).

### Feature Modules (Co-located Code)
- **[lib/prayer/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/prayer/)** -> Prayer times and Qibla module. Contains pages, timezone/notifications/location service logic, and regional calculators.
- **[lib/duas/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/duas/)** -> Supplications (Hisn al-Muslim), Asma ul-Husna page, Tasbih digital counter, and favorite bookmark lists.
- **[lib/hifz/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/hifz/)** -> Quran memorization tracker, containing scheduling models, logs, progress tracking algorithms, and session views.
- **[lib/reading_plans/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/reading_plans/)** -> Modular Quran reading plan generation, schedule logs, and tracking algorithms.
- **[lib/search/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/search/)** -> Quran text index searcher, pagination handlers, and search result views.
- **[lib/zakat/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/zakat/)** -> Interactive Zakat calculation utility.
- **[lib/home/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/home/)** & **[lib/home_dashboard/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/home_dashboard/)** -> Main navigation hubs, stats tracker screens, settings pages, and the primary Quran reading canvas (`read.dart`).
- **[lib/l10n/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/l10n/)** -> Translation Arb targets (`app_en.arb`, `app_ar.arb`, etc.) and generated localization scripts.
- **[lib/features/](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/features/)** -> General minor features, currently co-locating the app's `splash` screen module.

---

## ⚙️ Core Subsystem Execution Mechanics

### 1. Audio Subsystem
Audio playback is powered by a hybrid solution using the `just_audio` and `audioplayers` packages:
*   **Reading Playback Queue:** Powered by `just_audio` (`AudioPlayer` in [read.dart](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/home/read.dart)) which handles complex verse-by-verse playback sequences.
*   **Feature Sessions:** Features like Hifz sessions (`HifzSessionPage`) and play buttons (`PlayButton`) use `audioplayers` for discrete playback tracks.
*   **Streaming & Caching:**
    *   **Single-Ayah Caching:** Single ayah `.mp3` files are streamed using URLs resolved by `QuranAudioStreamResolver` (fetched from `everyayah.com`). The `AudioDownloadService` manages a temporary LRU cache in temporary directories, capping stored cache files to `_maxTempCachedAyahs = 10`.
    *   **Surah ZIP Shard Downloading:** To support offline mode, full chapters can be downloaded. `AudioDownloadService` pulls a packed ZIP archive of the surah (from `https://everyayah.com/data/.../zips/$surah.zip`), decodes it using `ZipDecoder`, parses the filenames to extract surah/ayah indicators, and moves the individual files into document directories for local offline playback.

### 2. Typography Layer & Dark Mode Font Patching
The Quran text rendering supports different styles including IndoPak, Uthmanic Hafs, and QPC V4 page-based Tajweed fonts:
*   **PUA Glyphs Mapping:** The QPC V4 style represents Quran pages via Private Use Area (PUA) Unicode glyphs. Text datasets containing these PUA runes are loaded from local JSON data files under `assets/data/quran/text/qpc-v4/$i.json` and matched to specific font styles on a per-page/per-verse basis.
*   **Runtime Page Font Loading:** QPC V4 font resources (pages 1 to 604) are downloaded as a packed zip of TTFs (`tajweed.zip`). The `QpcV4FontService` manages these files. When a user navigates to a page, `FontLoader` is invoked to load the TTF file at runtime.
*   **Dark Mode Color Swapping (`QcfCpalPatcher`):**
    *   Because the QPC V4 color fonts are pre-compiled with hardcoded colored glyphs (Palette 0 is designed for light mode backgrounds), standard text color attributes do not affect them.
    *   To support dark mode, when a font file is loaded, `QcfCpalPatcher.patchForDarkMode(bytes)` parses the TTF headers, crawls the table directory to locate the `CPAL` (Color Palette Table), and swaps Palette 0 indexes with Palette 1 (which contains the dark mode optimized color profiles) in-place.
    *   This patched font variant is then loaded and registered with a `_dark` suffix (e.g. `QPCV4_Page_${pageNumber}_dark`) so the text engine paints the dark-themed glyphs natively.

### 3. Internationalization (l10n)
*   **Translation Targets:** Localization assets live in `lib/l10n/` as `.arb` (Application Resource Bundle) JSON objects.
*   **Codegen:** Localizations are generated automatically by the Flutter compilation tools according to `l10n.yaml`.
*   **Usage:** Views dynamically consume variables using the standard `AppLocalizations` class:
    ```dart
    final localizations = AppLocalizations.of(context)!;
    String text = localizations.myKey;
    ```

### 4. Background Android Widget Subsystem
*   **Home Screen Widget:** Powered by the `home_widget` and `workmanager` packages, allowing users to place an interactive widget on their Android home screen displaying prayer times.
*   **Widget Updates & WorkManager:** Background updates are orchestrated by [PrayerWidgetWorker](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/widgets/prayer_widget_worker.dart) (running hourly and midnight recalculation tasks) which utilizes [PrayerWidgetService](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/widgets/prayer_widget_service.dart) to write widget data.
*   **Native Receivers:** The widget UI updates are handled by native Kotlin widget receivers under `/android/app/src/main/kotlin/com/app/equran/` (e.g. `PrayerTimesWidgetReceiver.kt`, `NextPrayerWidgetReceiver.kt`, `PrayerWidgetShared.kt`, and `PrayerAlarmReceiver.kt`).

---

## 📜 Explicit Agent Coding Guardrails & Verification Rules

Incoming agents and developers must strictly follow these rules when editing the codebase:

1.  **Isolate Mutations:**
    *   Do not alter presentation layout trees indiscriminately if a task belongs strictly inside a data provider, controller, BLoC (`ValueNotifier`), or native platform layer.
    *   Keep business rules isolated from layout/painting structures.
2.  **Binary Safety:**
    *   If you alter low-level binary array manipulation utilities (like [qcf_cpal_patcher.dart](file:///home/yousuf/Documents/Personal%20Projects/equran-app/lib/backend/qcf_cpal_patcher.dart) or byte-shifting tools), bounds checking must be bulletproof.
    *   Always verify offsets and lengths using defensive bounds checks (e.g., checking if the offset + index is within `data.lengthInBytes`) to avoid throwing uncaught out-of-range exceptions that cause app crashes.
3.  **Deployment & Quality Checks:**
    *   Before declaring a task done, format the modified files:
        ```bash
        dart format .
        ```
    *   Run static analysis and ensure there are **zero** compile warnings, deprecation notices, or static analysis defects:
        ```bash
        flutter analyze
        ```
4.  **Lockfile Retention:**
    *   Never delete, remove, or list `pubspec.lock` in `.gitignore`. It must always be tracked and committed to lock exact dependency versions.
5.  **F-Droid Compliance (No Google GMS/Firebase):**
    *   Do not integrate libraries or plugins that depend on Google Mobile Services (GMS), Firebase SDKs (such as analytics, crash reporting, or push notifications), or other proprietary non-free frameworks. The codebase must remain 100% compliant with F-Droid inclusion policies.
