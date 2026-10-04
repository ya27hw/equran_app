import 'package:equran/widgets/common/equran_asset_image.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/home/read.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/holographic_card.dart';
import 'package:equran/widgets/common/geometric_pattern.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

const String equranResumeQuranAsset = 'assets/media/images/app/quran.webp';
const double _resumeImageCardMaxWidth = 620;
const double _resumeImageCardHeight = 160;

class LastReadCard extends StatefulWidget {
  const LastReadCard({
    super.key,
    required this.entries,
    this.enforceCompactWidth = true,
    this.cardBuilder,
    this.estimatedCardHeight = 158,
  });

  final List<ReadingEntry> entries;
  final bool enforceCompactWidth;
  final Widget Function(BuildContext, ReadingEntry, VoidCallback)? cardBuilder;
  final double estimatedCardHeight;

  static List<ReadingEntry> displayReadingHistory(Iterable<dynamic> values) {
    final rawEntries = values.whereType<ReadingEntry>().toList();

    // Keep one record per surah: latest ayah read only.
    final Map<int, ReadingEntry> latestPerSurah = <int, ReadingEntry>{};
    for (final entry in rawEntries) {
      final ReadingEntry? current = latestPerSurah[entry.surah];
      if (current == null || entry.timestamp.isAfter(current.timestamp)) {
        latestPerSurah[entry.surah] = entry;
      }
    }

    final entries = latestPerSurah.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(7).toList();
  }

  @override
  State<LastReadCard> createState() => _LastReadCardState();
}

class _LastReadCardState extends State<LastReadCard> {
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant LastReadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.isEmpty) {
      _currentPage = 0;
      return;
    }

    final int maxPage = widget.entries.length - 1;
    if (_currentPage > maxPage) {
      _currentPage = maxPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ReadingEntry> entries = widget.entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    final int activeIndex = _currentPage.clamp(0, entries.length - 1).toInt();
    final localizations = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExpandableCarousel.builder(
          itemCount: entries.length,
          itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
            final ReadingEntry entry = entries[itemIndex];
            void openReading() => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    ReadPage(chapter: entry.surah, startVerse: entry.verse),
              ),
            );
            final customCard = widget.cardBuilder?.call(
              context,
              entry,
              openReading,
            );
            if (customCard != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: customCard,
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: HolographicCardWrapper(
                child: EquranResumeImageCard(
                  key: ValueKey<String>(
                    '${entry.surah}-${entry.verse}-${entry.timestamp.microsecondsSinceEpoch}',
                  ),
                  primary: localizedSurahName(localizations, entry.surah),
                  subtitle: localizations.ayahLabel(entry.verse),
                  actionText: localizations.continueReading,
                  trailingAssetPath: equranResumeQuranAsset,
                  enforceCompactWidth: widget.enforceCompactWidth,
                  onTap: openReading,
                ),
              ),
            );
          },
          options: ExpandableCarouselOptions(
            showIndicator: false,
            estimatedPageSize: widget.estimatedCardHeight,
            enableInfiniteScroll: false,
            viewportFraction: 1,
            initialPage: 0,
            onPageChanged: (int index, _) {
              if (!mounted) return;
              setState(() {
                _currentPage = index.clamp(0, entries.length - 1).toInt();
              });
            },
          ),
        ),
        if (entries.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _CarouselPillsIndicator(
              itemCount: entries.length,
              activeIndex: activeIndex,
            ),
          ),
      ],
    );
  }
}

class _CarouselPillsIndicator extends StatelessWidget {
  const _CarouselPillsIndicator({
    required this.itemCount,
    required this.activeIndex,
  });

  final int itemCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(itemCount, (index) {
        final bool isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive
                ? colors.accentGold
                : colors.onPrimaryMuted.withAlpha(150),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class EquranResumeImageCard extends StatelessWidget {
  const EquranResumeImageCard({
    super.key,
    required this.primary,
    required this.subtitle,
    required this.actionText,
    required this.trailingAssetPath,
    required this.onTap,
    this.secondary = false,
    this.artworkScale = 1,
    this.artworkOffsetX = -2,
    this.maxWidth = _resumeImageCardMaxWidth,
    this.enforceCompactWidth = true,
  });

  final String primary;
  final String subtitle;
  final String actionText;
  final String trailingAssetPath;
  final VoidCallback onTap;
  final bool secondary;
  final double artworkScale;
  final double artworkOffsetX;
  final double maxWidth;
  final bool enforceCompactWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    final Widget cardContent = LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 300;
        final double artworkEdgePadding = _artworkEdgePadding(
          constraints.maxWidth,
        );
        final double scale = artworkScale.clamp(0.82, 1.28).toDouble();
        final double artWidth = (compact ? 108 : 132) * scale;
        final double textRightPadding =
            ((compact ? 94 : 124) * scale.clamp(0.94, 1.16)) +
            artworkEdgePadding;
        final double horizontalPadding = compact ? 16 : 18;
        final double topPadding = compact ? 13 : 14;
        final double bottomPadding = compact ? 13 : 13;
        final double titleSubtitleGap = compact ? 4 : 5;
        final double subtitleDividerGap = compact ? 19 : 28;
        final double dividerActionGap = compact ? 8 : 10;
        final double dividerWidth = 170;
        final bool isRtl = Directionality.of(context) == TextDirection.rtl;
        final TextStyle? titleStyle = compact
            ? theme.textTheme.titleLarge?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w900,
                height: 1.05,
              )
            : theme.textTheme.headlineSmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w900,
                height: 1.05,
              );
        final TextStyle? subtitleStyle =
            (compact ? theme.textTheme.bodyMedium : theme.textTheme.titleSmall)
                ?.copyWith(
                  color: colors.onPrimaryMuted,
                  fontWeight: FontWeight.w800,
                );
        final TextStyle? actionStyle = theme.textTheme.labelLarge?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w900,
        );
        final BorderRadius radius = BorderRadius.circular(AppRadii.large);
        final bool isLight = Theme.of(context).brightness == Brightness.light;
        final Gradient cardGradient = secondary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    colors.primary.withAlpha(isLight ? 120 : 80),
                    colors.surface,
                  ),
                  Color.alphaBlend(
                    colors.primaryStrong.withAlpha(isLight ? 130 : 92),
                    colors.surface,
                  ),
                  Color.alphaBlend(
                    colors.accentGold.withAlpha(isLight ? 45 : 22),
                    colors.primaryStrong,
                  ),
                ],
              )
            : colors.heroGradient;
        return SizedBox(
          width: double.infinity,
          height: _resumeImageCardHeight,
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: cardGradient,
                  borderRadius: radius,
                  border: Border.all(color: colors.onPrimary.withAlpha(36)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.primaryStrong.withAlpha(
                        Theme.of(context).brightness == Brightness.light
                            ? 34
                            : 54,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GeometricPattern(
                        color: colors.onPrimary,
                        anchor: AlignmentDirectional.bottomStart,
                        maxOpacity: 0.18,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: artworkEdgePadding,
                        ),
                        child: Transform.translate(
                          offset: Offset(
                            (compact
                                        ? artworkOffsetX.clamp(0, 15)
                                        : artworkOffsetX.clamp(0, 22))
                                    .toDouble() *
                                (isRtl ? -1 : 1),
                            0,
                          ),
                          child: SizedBox(
                            width: artWidth,
                            child: EquranAssetImage(
                              trailingAssetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          horizontalPadding,
                          topPadding,
                          textRightPadding,
                          bottomPadding,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                primary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                              SizedBox(height: titleSubtitleGap),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: subtitleStyle,
                              ),
                              SizedBox(height: subtitleDividerGap),
                              SizedBox(
                                width: dividerWidth,
                                child: Divider(
                                  height: 1,
                                  color: colors.onPrimary.withAlpha(52),
                                ),
                              ),
                              SizedBox(height: dividerActionGap),
                              Text(
                                actionText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: actionStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (enforceCompactWidth) {
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  double _artworkEdgePadding(double width) {
    if (width < 340) return 2;
    if (width < 430) return 6;
    if (width < 560) return 12;
    return 18;
  }
}
