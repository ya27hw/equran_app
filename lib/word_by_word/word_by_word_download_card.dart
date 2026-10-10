import 'package:equran/utils/resource_labels.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:flutter/material.dart';

/// One downloadable word-by-word pack as shown in the card.
class WordByWordPackRow {
  const WordByWordPackRow({
    required this.name,
    required this.details,
    required this.state,
    required this.onDownload,
    required this.onDelete,
    this.progress,
  });

  final String name;

  /// Language, version and size, already formatted.
  final String details;
  final ResourceInstallState state;

  /// 0 to 1 while downloading, or null when the size is not known yet.
  final double? progress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
}

/// The Settings card for the optional word-by-word pack. It only draws; the
/// Settings page owns the manifest, the install store and the download service.
class WordByWordDownloadCard extends StatelessWidget {
  const WordByWordDownloadCard({
    super.key,
    required this.title,
    required this.description,
    required this.rows,
    required this.downloadTooltip,
    required this.updateTooltip,
    required this.deleteTooltip,
  });

  final String title;
  final String description;
  final List<WordByWordPackRow> rows;
  final String downloadTooltip;
  final String updateTooltip;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ReaderIconWell(icon: DesignIcon('quran')),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontVariations: const [FontVariation('opsz', 15)],
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final WordByWordPackRow row in rows) ...<Widget>[
            Divider(height: 1, thickness: 1, color: tokens.hair),
            _PackRow(
              row: row,
              downloadTooltip: downloadTooltip,
              updateTooltip: updateTooltip,
              deleteTooltip: deleteTooltip,
            ),
          ],
        ],
      ),
    );
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({
    required this.row,
    required this.downloadTooltip,
    required this.updateTooltip,
    required this.deleteTooltip,
  });

  final WordByWordPackRow row;
  final String downloadTooltip;
  final String updateTooltip;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final ResourceInstallState state = row.state;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  row.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontVariations: const [FontVariation('opsz', 14.5)],
                    fontWeight: FontWeight.w500,
                    color: context.equranColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.details,
                  style: TextStyle(fontSize: 12.5, color: tokens.muted),
                ),
                const SizedBox(height: 8),
                // Shape and wording carry the state, not colour alone.
                PillTag(
                  resourceInstallStateLabel(
                    AppLocalizations.of(context)!,
                    state,
                  ),
                  selected: state == ResourceInstallState.installed,
                  gold: state == ResourceInstallState.updateAvailable,
                  compact: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          switch (state) {
            ResourceInstallState.downloading => SizedBox.square(
              dimension: 44,
              child: Center(
                child: SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    value: row.progress,
                    color: tokens.emText,
                    backgroundColor: tokens.hair2,
                  ),
                ),
              ),
            ),
            ResourceInstallState.installed => IconButton44(
              designIcon: 'trash',
              tooltip: deleteTooltip,
              onPressed: row.onDelete,
            ),
            ResourceInstallState.updateAvailable => IconButton44(
              designIcon: 'download',
              tooltip: updateTooltip,
              onPressed: row.onDownload,
            ),
            ResourceInstallState.notDownloaded => IconButton44(
              designIcon: 'download',
              tooltip: downloadTooltip,
              onPressed: row.onDownload,
            ),
          },
        ],
      ),
    );
  }
}
