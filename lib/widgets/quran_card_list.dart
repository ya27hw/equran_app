import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:equran/backend/surah_db.dart';
import 'package:equran/backend/surah_model.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/widgets/grouped_card_sliver.dart';
import 'package:equran/widgets/quran_card.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

/// Widest the Quran tab's header and lists (surahs, juz, pages) may grow before
/// they are centred on a wide window.
const double quranTabMaxWidth = 820;

/// Side inset that centres Quran tab content within [quranTabMaxWidth] and
/// never drops below the phone page padding.
double quranTabSideInset(double viewportWidth) {
  final double centred = (viewportWidth - quranTabMaxWidth) / 2;
  return centred > EquranSpacing.pagePadding
      ? centred
      : EquranSpacing.pagePadding;
}

class QuranCardList extends StatefulWidget {
  final String searchQuery;
  final Widget? header;
  final bool ascending;

  const QuranCardList({
    super.key,
    required this.searchQuery,
    required this.ascending,
    this.header,
  });

  @override
  State<QuranCardList> createState() => _QuranCardListState();
}

class _QuranCardListState extends State<QuranCardList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _fallbackScrollController = ScrollController();
  List<Surah>? _surahs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void didUpdateWidget(covariant QuranCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _loadSurahs();
    }
  }

  @override
  void dispose() {
    _fallbackScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Surah> data = await _fetchSurahs();
      if (mounted) {
        setState(() {
          _surahs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ScrollController scrollController =
        PrimaryScrollController.maybeOf(context) ?? _fallbackScrollController;

    if (_isLoading || _surahs == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Surah> data = widget.ascending
        ? _surahs!
        : _surahs!.reversed.toList();
    if (data.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noSurahsFound));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // The insets centre the header and list within the content cap, while
        // the scrollbar still runs along the window edge.
        final double sideInset = quranTabSideInset(constraints.maxWidth);
        final double contentWidth = constraints.maxWidth - sideInset * 2;
        final int columns = contentWidth >= 700 ? 2 : 1;

        // No cross-fade: while both lists are mounted they would share one
        // PrimaryScrollController, which Flutter rejects in debug builds.
        return Scrollbar(
          key: ValueKey<bool>(widget.ascending),
          controller: scrollController,
          thumbVisibility: true,
          interactive: true,
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              if (widget.header != null)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: sideInset),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: widget.header!,
                    ),
                  ),
                ),
              if (columns == 1)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sideInset, 0, sideInset, 30),
                  sliver: GroupedCardSliver(
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return QuranCard(
                        surah: data[index],
                        compact: false,
                        grouped: true,
                        inkRadius: groupedInkRadius(index, data.length),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sideInset, 0, sideInset, 16),
                  sliver: SliverDynamicHeightGridView(
                    itemCount: data.length,
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    builder: (BuildContext context, int index) {
                      return QuranCard(
                        surah: data[index],
                        compact: true,
                        reduceTitleSize: columns == 2,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Surah>> _fetchSurahs() async {
    List<Surah> surahs = <Surah>[];

    if (SurahDB().contains("surahsList")) {
      final cachedData = SurahDB().get("surahsList");
      if (cachedData is List) {
        surahs = cachedData.cast<Surah>();
      } else {
        throw Exception("Cached data is not valid");
      }
    } else {
      for (int i = 1; i <= 114; i++) {
        surahs.add(
          Surah(
            id: i,
            transliteration: quran.getSurahName(i),
            verses: quran.getVerseCount(i),
            name: quran.getSurahNameArabic(i),
            englishName: quran.getSurahNameEnglish(i),
          ),
        );
      }
      await SurahDB().put("surahsList", surahs);
    }

    List<Surah> filteredSurahs;
    if (widget.searchQuery.isEmpty) {
      filteredSurahs = surahs;
    } else {
      filteredSurahs = surahs
          .where(
            (surah) =>
                surah.name.toLowerCase().contains(
                  widget.searchQuery.toLowerCase(),
                ) ||
                surah.transliteration.toLowerCase().contains(
                  widget.searchQuery.toLowerCase(),
                ) ||
                surah.id.toString() == widget.searchQuery,
          )
          .toList();
    }

    return filteredSurahs;
  }

  @override
  bool get wantKeepAlive => true;
}
