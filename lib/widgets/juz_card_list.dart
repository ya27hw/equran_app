import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/juz_search.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/widgets/grouped_card_sliver.dart';
import 'package:equran/widgets/quran_card_list.dart' show quranTabSideInset;
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'juz_card.dart';

class JuzCardList extends StatefulWidget {
  const JuzCardList({
    super.key,
    required this.searchQuery,
    required this.ascending,
  });

  final String searchQuery;
  final bool ascending;

  @override
  State<JuzCardList> createState() => _JuzCardListState();
}

class _JuzCardListState extends State<JuzCardList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _fallbackScrollController = ScrollController();

  @override
  void dispose() {
    _fallbackScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ScrollController scrollController =
        PrimaryScrollController.maybeOf(context) ?? _fallbackScrollController;
    final List<JuzGroup> rawJuzGroups = buildJuzGroups(widget.searchQuery);

    final localizations = AppLocalizations.of(context)!;
    if (rawJuzGroups.isEmpty) {
      return Center(child: Text(localizations.noJuzResultsFound));
    }

    final List<JuzGroup> juzGroups = widget.ascending
        ? rawJuzGroups
        : rawJuzGroups.reversed.map((group) {
            return JuzGroup(
              juzNumber: group.juzNumber,
              arabicName: group.arabicName,
              entries: group.entries.reversed.toList(),
            );
          }).toList();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Centres the juz content within the Quran tab's width cap.
        final double sideInset = quranTabSideInset(constraints.maxWidth);
        return Scrollbar(
          key: ValueKey<bool>(widget.ascending),
          controller: scrollController,
          thumbVisibility: true,
          interactive: true,
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            scrollCacheExtent: const ScrollCacheExtent.pixels(900),
            slivers: <Widget>[
              for (final JuzGroup group in juzGroups) ...<Widget>[
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: sideInset),
                  sliver: SliverToBoxAdapter(
                    child: _JuzSectionHeader(
                      key: ValueKey<String>('juz-header-${group.juzNumber}'),
                      juzNumber: group.juzNumber,
                      arabicName: group.arabicName,
                      surahCount: group.entries.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: sideInset),
                  sliver: GroupedCardSliver(
                    itemCount: group.entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      final JuzEntry entry = group.entries[index];
                      return QuranJuzTile(
                        key: ValueKey<String>(
                          'juz-${entry.surahId}-${entry.startVerse}-${entry.endVerse}',
                        ),
                        id: entry.surahId,
                        transliteration: entry.transliteration,
                        name: entry.name,
                        startVerse: entry.startVerse,
                        endVerse: entry.endVerse,
                        inkRadius: groupedInkRadius(
                          index,
                          group.entries.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// The juz' heading above its card: number pill, Arabic name, surah count.
class _JuzSectionHeader extends StatelessWidget {
  const _JuzSectionHeader({
    super.key,
    required this.juzNumber,
    required this.arabicName,
    required this.surahCount,
  });

  final int juzNumber;
  final String arabicName;
  final int surahCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 18, 14, 10),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.emWash,
              borderRadius: BorderRadius.circular(EquranRadii.pill),
            ),
            child: Text(
              localizedJuzLabel(localizations, juzNumber),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.emText,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                arabicName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: EquranTextStyles.activeFontFamily,
                  fontFamilyFallback: const <String>['UthmanicHafs'],
                  height: 1.18,
                  fontWeight: FontWeight.w700,
                  color: tokens.emText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            localizations.surahCount(surahCount),
            style: theme.textTheme.labelLarge?.copyWith(
              color: tokens.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
