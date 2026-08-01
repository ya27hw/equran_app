# Data migration and rollback plan

## Current stores

The application uses Hive boxes for settings, legacy favourites, bookmarks/reading history, Hifz entries/logs/units, companion bookmarks/folders/activity, reading plans and day progress, resume state, recent searches, dhikr, prayer logs, statistics, downloads, resource manifests, and Zakat history. Adapter IDs and existing boxes must never be deleted or recreated as a migration shortcut.

## Backup schema

The current export is schema version 1 and covers only settings, legacy favourites, and reading history. Schema version 2 will use named sections and an integrity record for every supported dataset, tolerate unknown optional fields, and retain backward import of version 1. Large downloaded resources remain references/installation preferences unless the user explicitly selects them.

## Restore protocol

1. Enforce file size/type limits and parse into typed validated temporary structures.
2. Validate schema version, canonical ayah ranges, adapter-compatible values, and integrity before touching live boxes.
3. Write a staging snapshot to temporary boxes/files.
4. Commit replacement in a deterministic order while retaining a rollback snapshot.
5. Reopen/verify every affected box and only then remove the previous snapshot.
6. On any failure, restore the snapshot and report a user-safe categorized error.

Migrations are idempotent, versioned in `schema_migrations`, and log only identifiers/status—not private content. Fixtures cover representative historical data, unknown optional fields, corruption, interrupted restore, and large datasets.

