# Performance budgets

Budgets are targets for the available low-end reference profile and are refined after instrumentation. A missing measurement is reported as unknown, never as a pass.

| Area | Budget / gate | Measurement |
| --- | --- | --- |
| First frame | No network or optional feature blocks the first frame; target at least 25% improvement over baseline | Startup trace spans in coordinator and DevTools timeline |
| First usable dashboard | Target <= 2.0 s on low-end reference profile after process start | Trace marker around dashboard-ready state |
| Interactive frames | No sustained build/raster jank; aim for <16.7 ms at 60 Hz and respect native 90/120 Hz | Frame timing during dashboard, reader, player, Hifz, Memory Map |
| QPC memory | No unbounded Dart growth; only active page plus bounded adjacent window | Memory snapshots after 20/100/300 pages |
| Search | First page <=250 ms after index is installed; no full index build at startup | `SearchBenchmark` fixture with Arabic and translation queries |
| ZIP extraction | UI isolate remains responsive; bounded worker memory; progress/cancel visible | Archive fixture benchmark and memory trace |
| Translation | Current Surah plus adjacent cache only; no 114-file sequential startup parse | Decode timing and cache counters |
| Storage scans | No synchronous large directory scan in interaction path | Download manifest/reconciliation timing |
| APK | Report debug, profile, release and split ABI sizes; fail growth >10% without decision | `flutter build ... --analyze-size`, `du`, APK analyzer |
| Network | Explicit timeout, cancellation, bounded retry; offline fallback on every resource path | Mock HTTP fixtures |
