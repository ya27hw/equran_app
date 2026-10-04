import 'package:equran/backend/library.dart';
import 'package:equran/home/read.dart';
import 'package:equran/search/quran_text_search_results.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/utils/debouncer.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/quran_reading_hero.dart';
import 'package:equran/widgets/library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart' as quran;

enum QuranSearchMode { surahs, quranText }

class QuranSearchRequest {
  const QuranSearchRequest({required this.mode, required this.nonce});

  final QuranSearchMode mode;
  final int nonce;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.searchRequestListenable});

  final ValueListenable<QuranSearchRequest?>? searchRequestListenable;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  final FocusNode _favouritesSearchFocus = FocusNode();
  final Debouncer _debouncer = Debouncer(milliseconds: 400);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _surahScrollController = ScrollController();
  final ScrollController _juzScrollController = ScrollController();
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _favouritesScrollController = ScrollController();
  late final TabController _tabController;

  String _searchQuery = '';
  QuranSearchMode _activeSearchMode = QuranSearchMode.surahs;
  int _selectedSegment = 0;
  int _lastHandledSearchRequestNonce = -1;
  bool _showSearch = false;
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    widget.searchRequestListenable?.addListener(_handleExternalSearchRequest);
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchRequestListenable != widget.searchRequestListenable) {
      oldWidget.searchRequestListenable?.removeListener(
        _handleExternalSearchRequest,
      );
      widget.searchRequestListenable?.addListener(_handleExternalSearchRequest);
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _favouritesSearchFocus.dispose();
    widget.searchRequestListenable?.removeListener(
      _handleExternalSearchRequest,
    );
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _surahScrollController.dispose();
    _juzScrollController.dispose();
    _pageScrollController.dispose();
    _favouritesScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final double width = MediaQuery.of(context).size.width;
    final double horizontalPadding = width >= 1400
        ? 36
        : width >= 1100
        ? 28
        : EquranSpacing.pagePadding;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: SavedQuranHeader(
              selectedIndex: _selectedSegment,
              searchField: _showSearch && _selectedSegment != 3
                  ? _buildSearchField()
                  : null,
              onTitleTap: _scrollToTop,
              onSearch: () {
                if (_selectedSegment == 3) {
                  _favouritesSearchFocus.requestFocus();
                } else {
                  _openSearch();
                }
              },
              onSelectSection: _selectSection,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildSegmentPager(horizontalPadding)),
        ],
      ),
      floatingActionButton: _selectedSegment == 3
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _ascending = !_ascending;
                });
              },
              backgroundColor: colors.surface,
              foregroundColor: colors.primary,
              shape: CircleBorder(
                side: BorderSide(color: context.equranTokens.hair2),
              ),
              elevation: 0,
              highlightElevation: 0,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: _ascending ? 0.0 : 0.5,
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
            ),
    );
  }

  void _selectSection(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(
        index,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    if (_selectedSegment != index ||
        _activeSearchMode != QuranSearchMode.surahs) {
      setState(() {
        _selectedSegment = index;
        _activeSearchMode = QuranSearchMode.surahs;
      });
    }
  }

  Widget _buildSearchField() {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey<String>('header-search'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      padding: const EdgeInsetsDirectional.only(start: 14, end: 2),
      child: Row(
        children: <Widget>[
          DesignIcon('search', size: 19, color: tokens.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _changeSearchQuery,
              style: TextStyle(fontSize: 15, color: colors.textPrimary),
              decoration: InputDecoration.collapsed(
                hintText: _searchHint(localizations),
                hintStyle: TextStyle(fontSize: 15, color: tokens.muted),
              ),
            ),
          ),
          IconButton(
            tooltip: localizations.closeSearch,
            onPressed: _closeSearch,
            icon: DesignIcon('x', size: 18, color: tokens.text2),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPager(double horizontalPadding) {
    final bool showQuranTextSearch =
        _showSearch &&
        _activeSearchMode == QuranSearchMode.quranText &&
        _selectedSegment == 0;

    return TabBarView(
      controller: _tabController,
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: PrimaryScrollController(
            controller: _surahScrollController,
            child: showQuranTextSearch
                ? QuranTextSearchResults(
                    key: const ValueKey<String>('quran-text-search'),
                    searchQuery: _searchQuery,
                    onSearchSelected: _selectRecentQuranTextSearch,
                  )
                : QuranCardList(
                    key: const ValueKey<String>('surah-list'),
                    searchQuery: _searchQuery,
                    ascending: _ascending,
                    header: _buildHeader(),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: PrimaryScrollController(
            controller: _juzScrollController,
            child: JuzCardList(
              key: const ValueKey<String>('juz-list'),
              searchQuery: _searchQuery,
              ascending: _ascending,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: PrimaryScrollController(
            controller: _pageScrollController,
            child: _QuranPageList(
              searchQuery: _searchQuery,
              ascending: _ascending,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PrimaryScrollController(
            controller: _favouritesScrollController,
            child: FavouritesList(
              searchQuery: _searchQuery,
              searchFocusNode: _favouritesSearchFocus,
              onSearchChanged: (value) {
                _searchController.text = value;
                _changeSearchQuery(value);
              },
              onBrowseSurahs: () {
                _closeSearch();
                _tabController.animateTo(
                  0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _changeSearchQuery(String value) {
    _debouncer.call(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
      });
    });
  }

  void _openSearch() {
    setState(() {
      _activeSearchMode = QuranSearchMode.surahs;
      _showSearch = true;
    });
  }

  void _closeSearch() {
    _debouncer.cancel();
    setState(() {
      _showSearch = false;
      _activeSearchMode = QuranSearchMode.surahs;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _handleTabChanged() {
    if (_selectedSegment == _tabController.index) return;
    setState(() {
      _selectedSegment = _tabController.index;
      if (_selectedSegment != 0) {
        _activeSearchMode = QuranSearchMode.surahs;
      }
    });
  }

  void _handleExternalSearchRequest() {
    final QuranSearchRequest? request = widget.searchRequestListenable?.value;
    if (request == null || request.nonce == _lastHandledSearchRequestNonce) {
      return;
    }
    _lastHandledSearchRequestNonce = request.nonce;
    final int targetIndex = switch (request.mode) {
      QuranSearchMode.surahs => 0,
      QuranSearchMode.quranText => 0,
    };

    if (_tabController.index != targetIndex) {
      _tabController.animateTo(targetIndex);
    }
    setState(() {
      _selectedSegment = targetIndex;
      _activeSearchMode = request.mode;
      _showSearch = true;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _selectRecentQuranTextSearch(String query) {
    _debouncer.cancel();
    _searchController.text = query;
    setState(() {
      _activeSearchMode = QuranSearchMode.quranText;
      _showSearch = true;
      _searchQuery = query;
    });
  }

  String _searchHint(AppLocalizations localizations) =>
      switch (_selectedSegment) {
        1 => localizations.searchHintJuz,
        2 => localizations.searchHintPage,
        3 => localizations.searchHintSaved,
        _ =>
          _activeSearchMode == QuranSearchMode.quranText
              ? localizations.searchHintText
              : localizations.searchHintSurah,
      };

  Widget? _buildLastReadCard() {
    if (SettingsDB().get("showLastRead", defaultValue: true) != true) {
      return null;
    }

    return ValueListenableBuilder(
      valueListenable: BookmarkDB().listener,
      builder: (BuildContext context, Box<dynamic> box, child) {
        final entries = LastReadCard.displayReadingHistory(box.values);
        final Widget currentChild = entries.isEmpty
            ? const _QuranLastReadEmptySection(
                key: ValueKey<String>('last-read-empty'),
              )
            : _QuranLastReadSection(
                key: const ValueKey<String>('last-read-card'),
                entries: entries,
              );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: currentChild,
        );
      },
    );
  }

  Widget _buildHeader() {
    final lastRead = _buildLastReadCard();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [?lastRead, const _HifzReminderCard()],
    );
  }

  void _scrollToTop() {
    final ScrollController scrollController = switch (_selectedSegment) {
      0 => _surahScrollController,
      1 => _juzScrollController,
      2 => _pageScrollController,
      _ => _favouritesScrollController,
    };
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

class _HifzReminderCard extends StatelessWidget {
  const _HifzReminderCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.equranColors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder(
      valueListenable: HifzDB.entriesListenable,
      builder: (context, box, child) {
        final showCard =
            HifzDB.getActiveUnits().isNotEmpty &&
            HifzFrontierService.totalDueCount() > 0;
        if (!showCard) {
          return const SizedBox.shrink();
        }
        final count = HifzFrontierService.totalDueCount();
        final activeUnits = HifzDB.getActiveUnits();
        bool hasContent(HifzUnit u) =>
            HifzDB.getNewAyahsForUnit(u.id, 1).isNotEmpty ||
            HifzDB.getSabqiAyahs(u.id).isNotEmpty ||
            HifzDB.getManzilAyahs(u.id).isNotEmpty;
        final unitWithDue = activeUnits.firstWhere(
          (u) => hasContent(u),
          orElse: () => activeUnits.first,
        );
        final radius = BorderRadius.circular(EquranRadii.large);
        final tokens = context.equranTokens;

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: tokens.goldWash,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    DesignIcon('book', size: 22, color: tokens.goldText),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.hifzReminderDueCount(count),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HifzSessionPage(unit: unitWithDue),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.filled,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        l10n.hifzReminderReview,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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
  }
}

class _QuranPageList extends StatelessWidget {
  const _QuranPageList({required this.searchQuery, required this.ascending});

  final String searchQuery;
  final bool ascending;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String query = searchQuery.trim().toLowerCase();

    final List<int> rawPages =
        List<int>.generate(quran.totalPagesCount, (index) {
          return index + 1;
        }).where((page) {
          if (query.isEmpty) return true;
          final _PageSummary summary = _pageSummary(page, localizations);
          return page.toString().contains(query) ||
              summary.primarySurah.toLowerCase().contains(query) ||
              summary.juzLabel.toLowerCase().contains(query);
        }).toList();

    final List<int> pages = ascending ? rawPages : rawPages.reversed.toList();

    Widget child = GridView.builder(
      key: ValueKey<bool>(ascending),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 520,
        mainAxisExtent:
            76 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final int page = pages[index];
        return _QuranPageTile(
          page: page,
          summary: _pageSummary(page, localizations),
        );
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}

class _QuranPageTile extends StatelessWidget {
  const _QuranPageTile({required this.page, required this.summary});

  final int page;
  final _PageSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final BorderRadius radius = BorderRadius.circular(EquranRadii.large);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => ReadPage(
              chapter: summary.startSurah,
              startVerse: summary.startVerse,
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: tokens.hair),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              NumberBadge(label: page.toString(), size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary.primarySurah,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                summary.juzLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSummary {
  const _PageSummary({
    required this.startSurah,
    required this.startVerse,
    required this.primarySurah,
    required this.rangeLabel,
    required this.juzLabel,
  });

  final int startSurah;
  final int startVerse;
  final String primarySurah;
  final String rangeLabel;
  final String juzLabel;
}

_PageSummary _pageSummary(int page, AppLocalizations localizations) {
  final List<dynamic> data = quran.getPageData(page);
  final Map<dynamic, dynamic> first = data.first as Map<dynamic, dynamic>;
  final Map<dynamic, dynamic> last = data.last as Map<dynamic, dynamic>;
  final int startSurah = first['surah'] as int;
  final int startVerse = first['start'] as int;
  final int endSurah = last['surah'] as int;
  final int endVerse = last['end'] as int;
  final int juz = quran.getJuzNumber(startSurah, startVerse);
  final String primarySurah = localizedSurahName(localizations, startSurah);
  final String rangeLabel = startSurah == endSurah
      ? localizations.ayahRange(startVerse, endVerse)
      : localizations.surahRange(
          localizedSurahName(localizations, endSurah),
          endVerse,
          primarySurah,
          startVerse,
        );
  return _PageSummary(
    startSurah: startSurah,
    startVerse: startVerse,
    primarySurah: primarySurah,
    rangeLabel: rangeLabel,
    juzLabel: localizations.juzNumber(juz),
  );
}

class _QuranLastReadSection extends StatelessWidget {
  const _QuranLastReadSection({super.key, required this.entries});

  final List<ReadingEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LastReadCard(
      entries: entries,
      estimatedCardHeight: 200,
      cardBuilder: (context, entry, onTap) =>
          QuranReadingHero(entry: entry, onTap: onTap),
    );
  }
}

class _QuranLastReadEmptySection extends StatelessWidget {
  const _QuranLastReadEmptySection({super.key});

  @override
  Widget build(BuildContext context) {
    return QuranReadingHero(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const ReadPage(chapter: 1, startVerse: 1),
        ),
      ),
    );
  }
}
