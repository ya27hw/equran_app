# Data migration and rollback plan

## Current stores

The application uses Hive boxes for settings, legacy favourites, bookmarks/reading history, Hifz entries/logs/units, companion bookmarks/folders/activity, reading plans and day progress, resume state, recent searches, dhikr, prayer logs, statistics, downloads, resource manifests, and Zakat history. Adapter IDs and existing boxes must never be deleted or recreated as a migration shortcut.

## Backup schema

The export now uses schema version 2 with named sections and an integrity record for every supported dataset, tolerates unknown optional fields, and retains backward import of version 1. Large downloaded resources remain references/installation preferences unless the user explicitly selects them. Journey Capsule voice paths are omitted from the JSON backup by default.

## Restore protocol

1. Enforce file size/type limits and parse into typed validated temporary structures.
2. Validate schema version, canonical ayah ranges, section shapes, adapter-compatible values, and integrity before touching live boxes.
3. Snapshot every affected open box in memory before replacement.
4. Commit replacement in a deterministic order while retaining the snapshot.
5. On any failure, restore the snapshot and report a user-safe categorized error.

Migrations are idempotent, versioned in `schema_migrations`, and log only identifiers/status—not private content. Current deterministic fixtures cover unknown fields, invalid settings/favourites, integrity ordering, and malformed sections; full Hive round-trip/large-dataset fixtures remain a validation task.
