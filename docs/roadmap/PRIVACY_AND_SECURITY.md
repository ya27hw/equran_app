# Privacy and security

## Defaults and data flows

All core features are account-free and offline-first. Settings, reading activity, Hifz records, predictions, capsules, and session data stay in app-local storage. Raw recitation audio and personal recordings are never uploaded by default. Analytics, telemetry, advertising identifiers, and hidden behavioral tracking are not used; any future opt-in is explicit and separately stored.

Roadmap data flows are local: Hifz signals -> versioned Memory Twin features/model -> risk/explanation records -> local rescue UI; verified pack -> validator -> local Constellation graph; local Halaqah pairing -> authenticated bounded messages -> expiring session store; capsule -> local encrypted/unencrypted store -> user-selected backup/export. No remote AI dependency is required for baseline predictions.

## Controls and threat model

- Export/delete/reset controls exist for Memory Twin, capsules, and Halaqah data.
- Sensitive Halaqah session secrets use secure random IDs, ephemeral pairing secrets, message-size/type validation, authentication, expiry, and encrypted export.
- Local service discovery stops at expiry and is never silently enabled outside the active session.
- Imported backups/packs enforce size/type/path limits, integrity validation, safe deserialization, and zip-slip/symlink rejection.
- Logs and crash reports exclude secrets, private text, recordings, and personal identifiers.
- Microphone processing is opt-in, local, separately explained, and deletable; core Hifz/Mem­ory Twin never requires it.

