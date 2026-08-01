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
| 0 | Repository audit, baseline, records, budgets | None | Completed | Baseline records committed in `161ece9`; branch and remote checkpoint established |
| 1 | Correctness, backup, migration, Zakat, structured errors | 0 | Core implemented | Versioned validated backup, rollback snapshot, independent metal rates, non-destructive Hifz init, bounds-safe migration/error paths |
| 2 | CI quality gates and deterministic unit/widget/integration foundation | 1 | Core implemented | Format, fatal analysis, tests/coverage, localization generation/drift, dependency policy, Android debug build gates |
| 3 | Staged startup coordinator | 2 | Implemented | Blocking/deferred idempotent coordinator; startup trace/profile evidence remains to be measured |
| 4 | Reader responsibility decomposition | 2 | Foundation implemented | Pure reader controllers and generation-token tests; full `read.dart` extraction remains follow-up |
| 5 | Fonts, archive extraction, search, translations, scans, dashboard performance | 3, 4 | Core mitigations implemented | Active-theme bounded fonts, streamed ZIP input, incremental search; profiling/worker extraction evidence remains |
| 6 | Device capability profiles, frame policy, Android size/profile work, audio interface | 5 | Foundation implemented | Lite/Balanced/Enhanced profile and policy tests; audio consolidation/profiles/size report remain |
| 7 | Mushaf Memory Map | 1, 4, 5, 6 | Foundation implemented (flag closed) | Verified 604-page mapping, virtualized page UI, derived state persistence, boundary tests |
| 8 | Local Memory Twin | 1, 2, 5, 7 | Foundation implemented (flag closed) | Interpretable local model, versioned predictions, explanations, reset/storage tests |
| 9 | Source-verified Quran Constellations packs and UI | 1, 2, 6 | Schema/validator implemented (flag closed) | Provenance/range/order validator and disabled-unreviewed tests; reviewed packs/UI remain |
| 10 | Offline private Halaqah | 1, 2, 6 | Security foundation implemented (flag closed) | Secure IDs, pairing metadata, bounded message validation, expiry tests; local transport/UI remain |
| 11 | Reciter Lens | 4, 5, 6 | Synchronizer implemented (flag closed) | Deterministic ayah alignment tests; audio/recording UI remains |
| 12 | Private Journey Capsules | 1, 2, 6 | Local model/storage implemented (flag closed) | Validated capsule persistence, due lookup, voice-path exclusion from JSON backup; reminder/UI remains |
| Final | Cross-platform validation, release evidence, draft PR | All completed phases | Pending | `FINAL_VALIDATION_REPORT.md`, pushed branch, draft PR |

## Explicit non-substitutes and blockers

No generic chatbot, generated religious interpretation, fake AI score, public leaderboard, or hard-coded content substitutes for the approved roadmap. Scholarly review or licensed source packs that are not present locally remain disabled behind their feature flags; missing approval is documented rather than fabricated. GitHub CLI authentication was invalid during the baseline (`gh auth status`), but the branch can be pushed with the configured Git credential; draft-PR creation still requires a usable GitHub connector/CLI session.
