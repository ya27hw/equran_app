# Privacy and security

## Defaults and data flows

All core features are account-free and offline-first. Settings, reading activity, Hifz records, predictions, capsules, and session data stay in app-local storage. Raw recitation audio and personal recordings are never uploaded by default. Analytics, telemetry, advertising identifiers, and hidden behavioral tracking are not used; any future opt-in is explicit and separately stored.

Roadmap data flows are local: Hifz signals -> versioned Memory Twin features/model -> risk/explanation records -> local rescue UI; verified pack -> validator -> local Constellation graph; local Halaqah pairing -> authenticated bounded messages -> expiring session store; capsule -> local encrypted/unencrypted store -> user-selected backup/export. No remote AI dependency is required for baseline predictions.

## Controls and threat model

- Export/delete/reset controls exist for Memory Twin, capsules, and Halaqah data.
- Halaqah foundations use secure random IDs, an ephemeral pairing secret, bounded message-size/type/shape validation, and expiry. Transport authentication and encrypted export are intentionally not exposed until the local transport is implemented.
- Local service discovery stops at expiry and is never silently enabled outside the active session.
- Imported backups/packs enforce size/type/path limits, integrity validation, safe deserialization, and zip-slip/symlink rejection.
- Roadmap logs use categorized step names and avoid private payloads; Flutter error reporting remains local diagnostics until a privacy-reviewed reporting policy exists.
- Microphone processing is not part of the current core; future recording paths must be opt-in, local, separately explained, and deletable. Core Hifz/Memory Twin never requires it.
