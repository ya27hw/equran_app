import 'package:equran/backend/library.dart';
import 'package:equran/home/read.dart';
import 'package:equran/search/quran_text_search_results.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/utils/debouncer.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/holographic_card.dart';
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
    final ThemeData theme = Theme.of(context);
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
          DecoratedBox(
            decoration: _topBarDecoration(),
            child: SafeArea(
              bottom: false,
              child: Material(
                color: colors.background.withAlpha(0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: _buildTopBar(theme),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              15,
            ),
            child: _buildSectionHeader(theme),
          ),

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
              shape: CircleBorder(side: BorderSide(color: colors.border)),
              elevation: 4,
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

  Widget _buildTopBar(ThemeData theme) {
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: <Widget>[
        const SizedBox(width: 48),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                alignment: Alignment.centerLeft,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _showSearch
                ? SearchBar(
                    key: const ValueKey<String>('header-search'),
                    controller: _searchController,
                    leading: const Icon(Icons.search_rounded),
                    trailing: <Widget>[
                      IconButton(
                        tooltip: localizations.closeSearch,
                        onPressed: _closeSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                    hintText: _searchHint(localizations),
                    hintStyle: WidgetStatePropertyAll(
                      theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: _changeSearchQuery,
                    elevation: const WidgetStatePropertyAll(0),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey<String>('header-title'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _scrollToTop,
                    child: Text(
                      localizations.quran,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Row(
            key: ValueKey<bool>(_showSearch),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _showSearch
                  ? const SizedBox(
                      key: ValueKey<String>('search-button-hidden'),
                      width: 0,
                    )
                  : IconButton(
                      key: const ValueKey<String>('search-button'),
                      tooltip: localizations.searchQuran,
                      onPressed: _openSearch,
                      color: colors.textPrimary,
                      icon: const Icon(Icons.search_rounded),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _topBarDecoration() {
    final EquranColors colors = context.equranColors;

    return BoxDecoration(
      color: colors.background.withAlpha(0),
      border: Border(bottom: BorderSide(color: colors.border.withAlpha(90))),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 390;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withAlpha(210),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: colors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.shadow.withAlpha(
                  theme.brightness == Brightness.light ? 8 : 14,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, segmentConstraints) {
                final double segmentWidth = segmentConstraints.maxWidth / 4;
                final double height = compact ? 38 : 42;
                final bool isRtl =
                    Directionality.of(context) == TextDirection.rtl;
                return SizedBox(
                  height: height,
                  child: Stack(
                    children: <Widget>[
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: isRtl ? null : segmentWidth * _selectedSegment,
                        right: isRtl ? segmentWidth * _selectedSegment : null,
                        top: 0,
                        bottom: 0,
                        width: segmentWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: colors.primarySoft.withAlpha(38),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          _buildSegmentButton(
                            theme,
                            index: 0,
                            icon: Icons.menu_book_rounded,
                            label: localizations.surahs,
                            tooltip: localizations.browseBySurah,
                            compact: compact,
                          ),
                          _buildSegmentButton(
                            theme,
                            index: 1,
                            icon: Icons.format_list_numbered_rtl_rounded,
                            label: localizations.juz,
                            tooltip: localizations.browseByJuz,
                            compact: compact,
                          ),
                          _buildSegmentButton(
                            theme,
                            index: 2,
                            icon: Icons.auto_stories_rounded,
                            label: localizations.pages,
                            tooltip: localizations.browseByPage,
                            compact: compact,
                          ),
                          _buildSegmentButton(
                            theme,
                            index: 3,
                            icon: Icons.bookmark_rounded,
                            label: localizations.saved,
                            tooltip: localizations.savedAyahs,
                            compact: compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentButton(
    ThemeData theme, {
    required int index,
    required IconData icon,
    required String label,
    required String tooltip,
    required bool compact,
  }) {
    final EquranColors colors = context.equranColors;
    final bool selected = _selectedSegment == index;
    final BorderRadius radius = BorderRadius.circular(AppRadii.pill);

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: colors.background.withAlpha(0),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              if (_tabController.index != index) {
                _tabController.animateTo(
                  index,
                  duration: const Duration(milliseconds: 220),
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
            },
            child: SizedBox(
              height: compact ? 38 : 42,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (!compact) ...<Widget>[
                        Icon(
                          icon,
                          size: 17,
                          color: selected
                              ? colors.onPrimary
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? colors.onPrimary
                              : colors.textSecondary,
                          fontSize: compact ? 12.5 : null,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: PrimaryScrollController(
            controller: _favouritesScrollController,
            child: FavouritesList(searchQuery: _searchQuery),
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
        final radius = BorderRadius.circular(AppRadii.large);

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    colors.primary.withAlpha(20),
                    colors.primary.withAlpha(5),
                  ],
                ),
                border: Border.all(color: colors.primary.withAlpha(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 118,
        mainAxisSpacing: 10,
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

    return Material(
      color: colors.background.withAlpha(0),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.large),
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
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.large),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.mint,
                      borderRadius: BorderRadius.circular(AppRadii.medium),
                    ),
                    child: Text(
                      page.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    summary.juzLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                summary.primarySurah,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary.rangeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
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
    return LastReadCard(entries: entries);
  }
}

class _QuranLastReadEmptySection extends StatelessWidget {
  const _QuranLastReadEmptySection({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return HolographicCardWrapper(
      child: EquranResumeImageCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const ReadPage(chapter: 1, startVerse: 1),
          ),
        ),
        primary: localizations.beginWithQuran,
        subtitle: localizations.startReadingSubtitle,
        actionText: localizations.startReading,
        trailingAssetPath: equranResumeQuranAsset,
      ),
    );
  }
}
