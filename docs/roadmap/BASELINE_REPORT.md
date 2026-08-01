# Baseline report

Baseline captured on the dedicated branch before roadmap implementation. Host: EndeavourOS 7.0.13, Linux 7.0.13-arch1-1, x86_64, 16 logical CPUs, 15 GiB RAM, NVIDIA RTX 3060 Ti. Repository base: `9274a497e722eda1a5e5ce37a44a9fb740b6f9`.

## Repository and toolchain

| Check | Result |
| --- | --- |
| Branch/worktree | Clean `codex/equran-roadmap`; `main` matched `origin/main` before branch creation |
| Flutter/Dart | Flutter 3.44.0, Dart 3.12.0 from `/opt/flutter`; `.fvmrc` says 3.22.1 |
| Android | SDK 36.1.0, build tools 36.1.0, JDK 21 via Flutter doctor; Gradle wrapper 8.14 |
| Linux | clang 22.1.6, CMake 4.3.4, Ninja 1.13.2, GTK 3.24.52, GStreamer 1.28.4 |
| Windows | Not runnable on this Linux host |
| Chrome/Web | Chrome executable unavailable |
| Devices | Linux desktop only; no Android device/emulator attached |
| Tracked source size | Approximately 9.86 MiB in Git; app assets approximately 13 MiB |

## Commands and results

```text
dart format --output=none --set-exit-if-changed .  PASS (185 files, 0 changed)
flutter pub get                                      PASS (lockfile unchanged; 76 constrained updates)
flutter analyze                                      PASS (no issues)
flutter test                                         FAIL (test directory not found)
flutter build apk --debug                            PASS (187,703,855 bytes)
flutter build apk --release --split-per-abi           INCOMPLETE BASELINE (R8 outputs generated; no fresh split APK)
flutter build linux --release                         NOT RUN YET
flutter build windows --release                       UNAVAILABLE ON HOST
flutter test integration_test                         NOT AVAILABLE (directory absent)
```

The release artifact currently under `build/` is dated before this baseline and is excluded from the pass count. A fresh release-compatible build is required after the first correctness checkpoint.

## Startup and performance baseline

No trace was claimed before instrumentation. Static inspection identifies a blocking critical path in `lib/main.dart`: both audio engines, all current Hive boxes, migrations, Quran data, selected translation preload, timezone configuration, prayer rescheduling, and Android widget setup happen before `runApp()`. Search constructs all 6,236 ayah entries and selected translation entries in memory on first query. QPC fonts register two engine font families per visited page. ZIP extraction calls `readAsBytes()` and decodes synchronously. These are baseline risks, not measured timings; Phase 3–5 must add measurements before claiming improvement.

## Known baseline defects and limitations

See `DEFECT_REGISTER.md`. The most consequential verified findings are incomplete backup coverage/rollback, derived silver rates presented as live, no automated test suite or CI quality gates, blocking startup, full in-memory search construction, dual unbounded font registration, and UI-isolate archive decoding.

