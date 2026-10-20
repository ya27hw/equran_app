import 'dart:async';

import 'package:equran/backend/library.dart';
import 'package:equran/home/read.dart';
import 'package:equran/search/quran_text_search_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/utils/text_direction.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:equran/l10n/app_localizations.dart';

class QuranTextSearchResults extends StatefulWidget {
  const QuranTextSearchResults({
    super.key,
    required this.searchQuery,
    this.onSearchSelected,
  });

  final String searchQuery;
  final ValueChanged<String>? onSearchSelected;

  @override
  State<QuranTextSearchResults> createState() => _QuranTextSearchResultsState();
}

class _QuranTextSearchResultsState extends State<QuranTextSearchResults>
    with AutomaticKeepAliveClientMixin {
  final QuranTextSearchService _searchService = const QuranTextSearchService();
  final ScrollController _fallbackScrollController = ScrollController();
  Future<List<QuranTextSearchResult>>? _searchFuture;
  String _loadedQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshSearch();
  }

  @override
  void didUpdateWidget(covariant QuranTextSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery.trim() != widget.searchQuery.trim()) {
      _refreshSearch();
    }
  }

  @override
  void dispose() {
    _fallbackScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final String query = widget.searchQuery.trim();
    final ScrollController scrollController =
        PrimaryScrollController.maybeOf(context) ?? _fallbackScrollController;

    if (query.length < 2) {
      return _RecentQuranSearches(
        onSearchSelected: widget.onSearchSelected,
        scrollController: scrollController,
      );
    }

    return FutureBuilder<List<QuranTextSearchResult>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SearchLoadingState(scrollController: scrollController);
        }

        final List<QuranTextSearchResult> results =
            snapshot.data ?? const <QuranTextSearchResult>[];
        if (results.isEmpty) {
          return _EmptySearchState(query: query);
        }

        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          interactive: true,
          child: ListView.separated(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 30),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final QuranTextSearchResult result = results[index];
              return _QuranTextSearchTile(result: result, searchQuery: query);
            },
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _refreshSearch() {
    final String query = widget.searchQuery.trim();
    _loadedQuery = query;
    if (query.length < 2) {
      setState(() {
        _searchFuture = null;
      });
      return;
    }

    setState(() {
      _searchFuture = _searchService.search(query).then((results) {
        if (_loadedQuery == query) {
          unawaited(_searchService.storeRecentQuery(query, results.length));
        }
        return results;
      });
    });
  }
}

class _QuranTextSearchTile extends StatelessWidget {
  const _QuranTextSearchTile({required this.result, required this.searchQuery});

  final QuranTextSearchResult result;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String surahName = localizedSurahName(localizations, result.surah);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(EquranRadii.xl),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) =>
                  ReadPage(chapter: result.surah, startVerse: result.verse),
            ),
          );
        },
        child: HairlineCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: PillTag(
                        localizations.surahLabel(surahName, result.verse),
                        gold: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shows whether the match was in the translation or the
                  // Arabic text.
                  result.translationMatch
                      ? Icon(
                          Icons.translate_rounded,
                          size: 18,
                          color: tokens.muted,
                        )
                      : DesignIcon('book', size: 18, color: tokens.muted),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.arabicPreview,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: EquranTextStyles.activeFontFamily,
                  fontFamilyFallback: const <String>['UthmanicHafs'],
                  fontSize: 22,
                  height: 1.65,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                result.translationPreview,
                textDirection: scriptDirectionIn(
                  context,
                  result.translationPreview,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: tokens.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentQuranSearches extends StatelessWidget {
  const _RecentQuranSearches({
    required this.scrollController,
    this.onSearchSelected,
  });

  final ScrollController scrollController;
  final ValueChanged<String>? onSearchSelected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<dynamic>>(
      valueListenable: RecentSearchesDB().listener,
      builder: (context, box, child) {
        final List<RecentSearchEntry> entries = const QuranTextSearchService()
            .recentQuranTextSearches();

        if (entries.isEmpty) {
          return const _EmptyModeState();
        }

        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          interactive: true,
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 30),
            children: <Widget>[
              const SizedBox(height: 16),
              const _RecentSearchHeader(),
              const SizedBox(height: 12),
              ...entries.map(
                (RecentSearchEntry entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentSearchTile(
                    entry: entry,
                    onTap: onSearchSelected == null
                        ? null
                        : () => onSearchSelected!(entry.query),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentSearchHeader extends StatelessWidget {
  const _RecentSearchHeader();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: RedesignEyebrow(localizations.recentQuranTextSearches),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({required this.entry, this.onTap});

  final RecentSearchEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(EquranRadii.xl),
        onTap: onTap,
        child: HairlineCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.emWash,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: DesignIcon('clock', size: 19, color: tokens.emText),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.query,
                      textDirection: scriptDirectionIn(context, entry.query),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontVariations: const [FontVariation('opsz', 15)],
                        fontWeight: FontWeight.w500,
                        color: context.equranColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.searchResultCount(entry.resultCount),
                      style: TextStyle(fontSize: 12.5, color: tokens.muted),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 8),
                Icon(Icons.north_west_rounded, size: 18, color: tokens.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        const SizedBox(height: 120),
        Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: context.equranTokens.emText,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyModeState extends StatelessWidget {
  const _EmptyModeState();

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      title: AppLocalizations.of(context)!.searchQuranText,
      message: AppLocalizations.of(context)!.searchQuranTextEmptyMessage,
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      title: AppLocalizations.of(context)!.noQuranTextResults,
      message: AppLocalizations.of(context)!.noAyahSearchResults(query),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.emWash,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.hair2),
              ),
              child: Center(
                child: DesignIcon('search', size: 30, color: tokens.emText),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: redesignDisplayStyle(context, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontVariations: const [FontVariation('opsz', 14.5)],
                height: 1.45,
                color: tokens.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
