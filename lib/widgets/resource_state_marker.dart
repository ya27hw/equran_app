import 'package:equran/backend/quran_translation_service.dart';
import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

/// What a status icon shows for a resource: the icon, its name for tooltips and
/// screen readers, and whether the content can be used offline right now.
class ResourceMarker {
  const ResourceMarker({
    required this.icon,
    required this.label,
    required this.ready,
  });

  final IconData icon;
  final String label;
  final bool ready;
}

/// Maps an install state to its status icon. Text is kept out of the list and
/// moved into the tooltip and semantics label.
ResourceMarker resourceStateMarker(
  AppLocalizations l10n,
  ResourceInstallState state,
) {
  return switch (state) {
    ResourceInstallState.installed => ResourceMarker(
      icon: Icons.offline_pin_rounded,
      label: l10n.installed,
      ready: true,
    ),
    ResourceInstallState.updateAvailable => ResourceMarker(
      icon: Icons.system_update_alt_rounded,
      label: l10n.resourceStateUpdateAvailable,
      ready: true,
    ),
    ResourceInstallState.downloading => ResourceMarker(
      icon: Icons.downloading_rounded,
      label: l10n.downloading,
      ready: false,
    ),
    ResourceInstallState.notDownloaded => ResourceMarker(
      icon: Icons.download_rounded,
      label: l10n.notDownloaded,
      ready: false,
    ),
  };
}

/// The status icon for a reader translation: downloaded, not downloaded, or not
/// offered by the current manifest. Built-in translations are always available,
/// so they get no icon and the list stays uncluttered.
ResourceMarker? translationStatusMarker(
  AppLocalizations l10n,
  quran.Translation translation,
  ResourceManifest manifest,
) {
  if (translation.isBundled) return null;
  final DownloadableResource? resource = QuranTranslationService.instance
      .resourceForTranslation(translation, manifest);
  if (resource == null) {
    return ResourceMarker(
      icon: Icons.cloud_off_rounded,
      label: l10n.translationDownloadUnavailable,
      ready: false,
    );
  }
  return resourceStateMarker(
    l10n,
    ResourceInstallStore.instance.installStateFor(resource),
  );
}

/// The trailing status widget for a translation row, or null when the
/// translation is built in.
Widget? translationStatusWidget(
  AppLocalizations l10n,
  quran.Translation translation,
  ResourceManifest manifest,
) {
  final ResourceMarker? marker = translationStatusMarker(
    l10n,
    translation,
    manifest,
  );
  return marker == null ? null : ResourceStateMarker(marker: marker);
}

/// A status icon with a tooltip. Ready content uses the emerald accent; content
/// that still needs a download uses the muted text colour.
class ResourceStateMarker extends StatelessWidget {
  const ResourceStateMarker({super.key, required this.marker, this.size = 20});

  final ResourceMarker marker;
  final double size;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Tooltip(
      message: marker.label,
      child: Semantics(
        label: marker.label,
        child: Icon(
          marker.icon,
          size: size,
          color: marker.ready ? tokens.emText : tokens.muted,
        ),
      ),
    );
  }
}
