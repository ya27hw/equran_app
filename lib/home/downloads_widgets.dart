import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/display_numeral.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/hero_panel.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/material.dart';

/// Presentational pieces of the Downloads page. They only draw; the page keeps
/// the download summary, filters and every delete call.

/// The total size of the offline audio, on the redesign hero panel.
class DownloadsSummaryHero extends StatelessWidget {
  const DownloadsSummaryHero({
    super.key,
    required this.eyebrow,
    required this.size,
    required this.caption,
  });

  final String eyebrow;
  final String size;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return HeroPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DesignIcon('download', size: 16, color: tokens.goldText),
              const SizedBox(width: 8),
              Flexible(child: RedesignEyebrow(eyebrow, color: tokens.goldText)),
            ],
          ),
          const SizedBox(height: 14),
          DisplayNumeral(size, size: 40),
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: tokens.featText2,
            ),
          ),
        ],
      ),
    );
  }
}

/// What deleting everything would free, with the confirm entry point.
class DownloadsCleanupCard extends StatelessWidget {
  const DownloadsCleanupCard({
    super.key,
    required this.title,
    required this.rows,
    required this.note,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final List<(String, String)> rows;
  final String note;
  final String actionLabel;

  /// Null disables the button (nothing downloaded).
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return HairlineCard(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ReaderIconWell(icon: DesignIcon('trash')),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final (String label, String value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 14, color: tokens.text2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            note,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: tokens.muted),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: onAction,
              style: readerOutlinedButtonStyle(context),
              icon: const DesignIcon('trash', size: 18),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// A collapsible reciter or surah section on one hairline card.
class DownloadsSection extends StatelessWidget {
  const DownloadsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.collapsed,
    required this.onToggle,
    required this.children,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool collapsed;
  final VoidCallback onToggle;
  final List<Widget> children;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final bool still = MediaQuery.disableAnimationsOf(context);
    final Widget body = collapsed
        ? const SizedBox(width: double.infinity)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Divider(height: 1, thickness: 1, color: tokens.hair),
              ...children,
            ],
          );
    return HairlineCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              expanded: !collapsed,
              child: ReaderOptionRow(
                leading: leading ?? const DesignIcon('headphones'),
                title: title,
                subtitle: subtitle,
                onTap: onToggle,
                trailing: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Transform.rotate(
                    angle: collapsed ? 0 : 3.14159265,
                    child: DesignIcon(
                      'chevd',
                      size: 18,
                      strokeWidth: 1.8,
                      color: tokens.muted,
                    ),
                  ),
                ),
              ),
            ),
            if (still)
              body
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: body,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Surahs 4" or "Ayahs 12": the small heading between kinds of download.
class DownloadsGroupLabel extends StatelessWidget {
  const DownloadsGroupLabel({
    super.key,
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 4),
      child: Row(
        children: <Widget>[
          Flexible(child: RedesignEyebrow(title)),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// One downloaded surah, ayah or reciter batch with its delete button.
class DownloadRow extends StatelessWidget {
  const DownloadRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.deleteTooltip,
    required this.onDelete,
    this.active = false,
    this.nested = false,
    this.icon,
  });

  final String title;
  final String subtitle;
  final String deleteTooltip;
  final VoidCallback onDelete;

  /// The file being played offline right now.
  final bool active;

  /// A row inside a folder: smaller and indented.
  final bool nested;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: nested ? 52 : 60),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(nested ? 20 : 18, 6, 8, 6),
        child: Row(
          children: <Widget>[
            IconTheme(
              data: IconThemeData(
                color: active ? tokens.emText : tokens.muted,
                size: nested ? 17 : 20,
              ),
              child:
                  icon ??
                  DesignIcon(
                    active ? 'play' : 'download',
                    size: nested ? 17 : 20,
                    strokeWidth: 1.7,
                    color: active ? tokens.emText : tokens.muted,
                  ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: nested ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: active ? tokens.emText : colors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: tokens.muted),
                    ),
                  ],
                ],
              ),
            ),
            IconButton44(
              designIcon: 'trash',
              tooltip: deleteTooltip,
              ghost: true,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// A surah whose individual ayahs are downloaded: a folder that opens to the
/// ayah files.
class DownloadsFolder extends StatelessWidget {
  const DownloadsFolder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        collapsedShape: const Border(),
        shape: const Border(),
        iconColor: tokens.muted,
        collapsedIconColor: tokens.muted,
        leading: DesignIcon('folder', size: 20, color: tokens.emText),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12.5, color: tokens.muted),
        ),
        tilePadding: const EdgeInsetsDirectional.fromSTEB(18, 2, 14, 2),
        childrenPadding: const EdgeInsetsDirectional.only(bottom: 6),
        children: children,
      ),
    );
  }
}
