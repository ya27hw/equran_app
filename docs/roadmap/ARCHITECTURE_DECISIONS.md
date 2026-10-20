# Architecture decisions

## ADR-001: preserve feature-first native reactive state

Use the existing `ValueNotifier`, `ChangeNotifier`, Hive repositories, and feature-local controllers. Do not add a global state framework. New controllers expose small immutable snapshots and own cancellation/disposal.

## ADR-002: account-free local defaults

Core reading, Hifz, plans, prayer, search, and roadmap features run offline with local storage. Network is an optional resource/update path and never a startup prerequisite.

## ADR-003: canonical content provenance

Quran text and verified metadata come only from repository/canonical packs. Journey and tafsir content use versioned packs with source/license metadata. Machine-generated religious conclusions are prohibited.

## ADR-004: staged startup

Only binding, safe settings/storage bootstrap, and first-screen metadata may block before `runApp()`. Remaining initialization is idempotent and owned by a cancellable coordinator after the first frame or on demand.

## ADR-005: feature flags are local and fail closed

Each major roadmap feature has a persisted local flag and an explicit availability state. Incomplete or unreviewed content remains disabled and has no broken navigation destination.

## ADR-006: dependency discipline

Prefer existing packages and Dart/Flutter primitives. Any new dependency must document license, platform, binary, maintenance, F-Droid, and permission impact before addition.
