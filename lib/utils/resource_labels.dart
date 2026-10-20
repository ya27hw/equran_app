import 'package:equran/backend/resource_download_service.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/l10n/app_localizations.dart';

/// Localized wording for the download and install state of a resource.
///
/// The backend enums carry English `label` getters for logs and tests; screens
/// use these functions instead so the text follows the app language.
String resourceTypeLabel(AppLocalizations l10n, DownloadableResource resource) {
  return switch (resource.type) {
    ResourceType.tafsir => l10n.tafsir,
    ResourceType.timings => l10n.audioTimings,
    ResourceType.quranFonts => l10n.quranFonts,
    ResourceType.translation => l10n.translation,
    ResourceType.wordByWord => l10n.wordByWord,
    ResourceType.unknown =>
      resource.rawType.isEmpty ? l10n.resourceTypeGeneric : resource.rawType,
  };
}

String resourceInstallStateLabel(
  AppLocalizations l10n,
  ResourceInstallState state,
) {
  return switch (state) {
    ResourceInstallState.notDownloaded => l10n.notDownloaded,
    ResourceInstallState.installed => l10n.installed,
    ResourceInstallState.updateAvailable => l10n.resourceStateUpdateAvailable,
    ResourceInstallState.downloading => l10n.downloading,
  };
}

String resourceDownloadPhaseLabel(
  AppLocalizations l10n,
  ResourceDownloadPhase phase,
) {
  return switch (phase) {
    ResourceDownloadPhase.queued => l10n.resourcePhaseStarting,
    ResourceDownloadPhase.downloading => l10n.downloading,
    ResourceDownloadPhase.verifying => l10n.resourcePhaseVerifying,
    ResourceDownloadPhase.extracting => l10n.resourcePhaseExtracting,
    ResourceDownloadPhase.installing => l10n.resourcePhaseInstalling,
    ResourceDownloadPhase.complete => l10n.installed,
    ResourceDownloadPhase.failed => l10n.resourcePhaseFailed,
  };
}
