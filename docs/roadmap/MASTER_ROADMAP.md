# eQuran production roadmap

This is the ordered execution ledger for the stabilization and product roadmap in the attached specification. The source repository remains authoritative for existing behavior and canonical Quran data. A requirement is not complete until its implementation, tests, accessibility/localization review, offline/error behavior, privacy review, performance evidence, documentation, and checkpoint commit are recorded.

## Branch and gates

- Base: `origin/main` at `9274a497e722eda1a5e5ce37a44a9fb740b6f9`.
- Working branch: `codex/equran-roadmap`.
- No roadmap work is performed on `main`.
- Every phase has a validation gate and a focused checkpoint commit. A failed gate stops dependent phases.

## Ordered phases

| Phase | Scope | Dependency | Status | Acceptance evidence |
| --- | --- | --- | --- | --- |
| 0 | Repository audit, baseline, records, budgets | None | In progress | `BASELINE_REPORT.md`, `DEFECT_REGISTER.md`, all records present, baseline checkpoint |
| 1 | Correctness, backup, migration, Zakat, structured errors | 0 | Pending | Round-trip/corruption/migration/Zakat tests and safe restore |
| 2 | CI quality gates and deterministic unit/widget/integration foundation | 1 | Pending | Format, analysis, localization, tests, asset/dependency/build jobs |
| 3 | Staged startup coordinator | 2 | Pending | First-frame trace and lifecycle/idempotence tests |
| 4 | Reader responsibility decomposition | 2 | Pending | Controller tests and rebuild/lifecycle evidence |
| 5 | Fonts, archive extraction, search, translations, scans, dashboard performance | 3, 4 | Pending | Memory/CPU/latency benchmarks and bounded caches |
| 6 | Device capability profiles, frame policy, Android size/profile work, audio interface | 5 | Pending | Lite/Balanced/Enhanced tests and platform reports |
| 7 | Mushaf Memory Map | 1, 4, 5, 6 | Pending | Verified 604-page mapping and incremental rendering tests |
| 8 | Local Memory Twin | 1, 2, 5, 7 | Pending | Calibration/explanation/privacy/reset tests |
| 9 | Source-verified Quran Constellations packs and UI | 1, 2, 6 | Pending | Provenance validation and offline/linear accessibility tests |
| 10 | Offline private Halaqah | 1, 2, 6 | Pending | Pairing/message validation/expiry/deletion tests |
| 11 | Reciter Lens | 4, 5, 6 | Pending | Deterministic A/B synchronization and local recording tests |
| 12 | Private Journey Capsules | 1, 2, 6 | Pending | Persistence, backup, reminder, deletion/privacy tests |
| Final | Cross-platform validation, release evidence, draft PR | All completed phases | Pending | `FINAL_VALIDATION_REPORT.md`, pushed branch, draft PR |

## Explicit non-substitutes and blockers

No generic chatbot, generated religious interpretation, fake AI score, public leaderboard, or hard-coded content substitutes for the approved roadmap. Scholarly review or licensed source packs that are not present locally remain disabled behind their feature flags; missing approval is documented rather than fabricated. GitHub CLI authentication was invalid during the baseline (`gh auth status`), so pushes and draft-PR creation remain an external blocker while local work continues.

