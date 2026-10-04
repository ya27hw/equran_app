import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/juz_search.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:flutter/rendering.dart';

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

    final List<JuzListItem> items = buildJuzListItems(juzGroups);
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.2).toDouble();
    final double headerExtent = 76 * textScale;
    final double tileExtent = 122 * textScale;

    Widget child = Scrollbar(
      key: ValueKey<bool>(widget.ascending),
      controller: scrollController,
      thumbVisibility: true,
      interactive: true,
      child: ListView.builder(
        scrollCacheExtent: ScrollCacheExtent.pixels(tileExtent * 8),
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(end: 2, bottom: 24),
        itemCount: items.length,
        itemExtentBuilder: (int index, _) {
          return items[index].group != null ? headerExtent : tileExtent;
        },
        itemBuilder: (BuildContext context, int index) {
          final JuzListItem item = items[index];
          final JuzGroup? group = item.group;
          if (group != null) {
            return SizedBox(
              key: ValueKey<String>('juz-header-${group.juzNumber}'),
              height: headerExtent,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 12),
                child: _JuzSectionHeader(
                  juzNumber: group.juzNumber,
                  arabicName: group.arabicName,
                  surahCount: group.entries.length,
                ),
              ),
            );
          }

          final JuzEntry entry = item.entry!;
          return SizedBox(
            key: ValueKey<String>(
              'juz-${entry.surahId}-${entry.startVerse}-${entry.endVerse}',
            ),
            height: tileExtent,
            child: QuranJuzTile(
              id: entry.surahId,
              transliteration: entry.transliteration,
              name: entry.name,
              startVerse: entry.startVerse,
              endVerse: entry.endVerse,
            ),
          );
        },
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _JuzSectionHeader extends StatelessWidget {
  const _JuzSectionHeader({
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
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: tokens.emWash,
              borderRadius: BorderRadius.circular(EquranRadii.pill),
            ),
            child: Text(
              localizedJuzLabel(localizations, juzNumber),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
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
            _surahCountLabel(surahCount, localizations),
            style: theme.textTheme.labelLarge?.copyWith(
              color: tokens.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _surahCountLabel(int count, AppLocalizations localizations) {
    return localizations.surahCount(count);
  }
}
