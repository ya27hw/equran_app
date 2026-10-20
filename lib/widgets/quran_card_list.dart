import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:equran/backend/surah_db.dart';
import 'package:equran/backend/surah_model.dart';
import 'package:equran/widgets/grouped_card_sliver.dart';
import 'package:equran/widgets/quran_card.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

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
        final double width = constraints.maxWidth;
        final bool isWebLike = width >= 1200;
        final int columns = isWebLike ? 3 : (width >= 700 ? 2 : 1);
        final bool hasHeader = widget.header != null;

        Widget childList;
        if (columns == 1) {
          childList = Scrollbar(
            key: ValueKey<bool>(widget.ascending),
            controller: scrollController,
            thumbVisibility: true,
            interactive: true,
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                if (hasHeader)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: widget.header!,
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 30),
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
                ),
              ],
            ),
          );
        } else {
          childList = Scrollbar(
            key: ValueKey<bool>(widget.ascending),
            controller: scrollController,
            thumbVisibility: true,
            interactive: true,
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                if (widget.header != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: widget.header!,
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
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
        }

        // No cross-fade: while both lists are mounted they would share one
        // PrimaryScrollController, which Flutter rejects in debug builds.
        return childList;
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
