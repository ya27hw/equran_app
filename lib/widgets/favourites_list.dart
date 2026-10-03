import 'dart:math' as math;

import 'package:equran/backend/library.dart';
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/home/read.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:quran/quran.dart' as quran;

enum _SavedAyahFilter { all, favourites, notes }

class FavouritesList extends StatefulWidget {
  const FavouritesList({
    super.key,
    required this.searchQuery,
    this.onSearchChanged,
    this.onBrowseSurahs,
    this.searchFocusNode,
  });

  final String searchQuery;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onBrowseSurahs;

  @override
  State<FavouritesList> createState() => _FavouritesListState();
}

class _FavouritesListState extends State<FavouritesList> {
  final ScrollController _fallbackScrollController = ScrollController();
  _SavedAyahFilter _filter = _SavedAyahFilter.all;
  String? _folderFilter;
  String? _tagFilter;

  late final TextEditingController _searchController = TextEditingController(
    text: widget.searchQuery,
  );
  late String _query = widget.searchQuery;

  @override
  void didUpdateWidget(covariant FavouritesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _query = widget.searchQuery;
      if (_searchController.text != _query) _searchController.text = _query;
    }
  }

  @override
  void dispose() {
    _fallbackScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ScrollController scrollController =
        PrimaryScrollController.maybeOf(context) ?? _fallbackScrollController;

    return _SavedTypography(
      child: ColoredBox(
        color: colors.background,
        child: ValueListenableBuilder<Box<dynamic>>(
          valueListenable: QuranBookmarksDB().listener,
          builder: (BuildContext context, Box<dynamic> bookmarksBox, _) {
            return ValueListenableBuilder<Box<dynamic>>(
              valueListenable: FavouritesDB().listener,
              builder: (BuildContext context, Box<dynamic> favouritesBox, _) {
                return ValueListenableBuilder<Box<dynamic>>(
                  valueListenable: QuranBookmarkFoldersDB().listener,
                  builder: (BuildContext context, Box<dynamic> foldersBox, _) {
                    final List<QuranBookmarkEntry> allItems =
                        const QuranBookmarkService()
                            .bookmarkEntriesWithLegacyFallback();
                    final List<QuranBookmarkEntry> searched = allItems
                        .where(_matchesSearch)
                        .toList(growable: false);
                    final List<QuranBookmarkEntry> items = searched
                        .where(_matchesFilter)
                        .toList(growable: false);
                    final bool showEmpty = allItems.isEmpty || items.isEmpty;

                    return SafeArea(
                      top: false,
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: false,
                        interactive: true,
                        child: CustomScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: <Widget>[
                            SliverToBoxAdapter(
                              child: _BookmarkLibraryHeader(
                                searchController: _searchController,
                                searchFocusNode: widget.searchFocusNode,
                                onSearchChanged: (value) {
                                  setState(() => _query = value);
                                  widget.onSearchChanged?.call(value);
                                },
                                selected: _filter,
                                selectedFolder: _folderFilter,
                                selectedTag: _tagFilter,
                                allItems: searched,
                                totalSavedCount: allItems.length,
                                onSelected: (filter) => setState(() {
                                  _filter = filter;
                                  _folderFilter = null;
                                  _tagFilter = null;
                                }),
                                onFolderSelected: (folder) => setState(() {
                                  _filter = _SavedAyahFilter.all;
                                  _folderFilter = folder;
                                  _tagFilter = null;
                                }),
                                onTagSelected: (tag) => setState(() {
                                  _filter = _SavedAyahFilter.all;
                                  _folderFilter = null;
                                  _tagFilter = tag;
                                }),
                                onManageFolders: () =>
                                    _showFolderManager(context),
                                onCreateFolder: () async {
                                  final String? folder =
                                      await _showFolderNameDialog(context);
                                  if (folder == null) return;
                                  await const QuranBookmarkService()
                                      .createFolder(folder);
                                },
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  bottom: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _SavedEyebrow(
                                        '${AppLocalizations.of(context)!.allSaved} · ${items.length}',
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.newestFirst,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: context.equranTokens.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showEmpty)
                              SliverToBoxAdapter(
                                child: _BookmarkEmptyState(
                                  onBrowseSurahs: widget.onBrowseSurahs,
                                  isSearching: _query.trim().isNotEmpty,
                                  hasLibraryItems: allItems.isNotEmpty,
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  if (index.isOdd) {
                                    return const SizedBox(height: 14);
                                  }
                                  return _BookmarkRow(entry: items[index ~/ 2]);
                                }, childCount: items.length * 2 - 1),
                              ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 28),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _matchesFilter(QuranBookmarkEntry entry) {
    if (_folderFilter != null) return entry.folder == _folderFilter;
    if (_tagFilter != null) return entry.tags.contains(_tagFilter);
    return switch (_filter) {
      _SavedAyahFilter.all => true,
      _SavedAyahFilter.favourites => entry.isFavourite,
      _SavedAyahFilter.notes => entry.note.trim().isNotEmpty,
    };
  }

  bool _matchesSearch(QuranBookmarkEntry entry) {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final String haystack = <String>[
      quran.getSurahName(entry.surah),
      quran.getSurahNameArabic(entry.surah),
      entry.surah.toString(),
      entry.verse.toString(),
      entry.note,
      entry.folder,
      ...entry.tags,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }
}

/// The Saved page's chrome is scoped to this tab; other Quran tabs keep theirs.
class SavedQuranHeader extends StatelessWidget {
  const SavedQuranHeader({
    super.key,
    required this.onSelectSection,
    required this.onSearch,
    this.onTitleTap,
  });
  final ValueChanged<int> onSelectSection;
  final VoidCallback onSearch;
  final VoidCallback? onTitleTap;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.equranTokens;
    return _SavedTypography(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTitleTap,
                    child: Text(
                      l.quran,
                      style: EquranTextStyles.displayPageTitle(
                        context,
                      ).copyWith(fontFamilyFallback: const ['NotoNaskhArabic']),
                    ),
                  ),
                ),
                IconButton44(
                  icon: Icons.search_rounded,
                  tooltip: l.searchQuran,
                  onPressed: onSearch,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final (index, label) in [
                  l.surahs,
                  l.juz,
                  l.pages,
                  l.saved,
                ].indexed)
                  Expanded(
                    child: Semantics(
                      selected: index == 3,
                      child: InkWell(
                        onTap: () => onSelectSection(index),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: tokens.hair),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: index == 3
                                      ? context.equranColors.textPrimary
                                      : tokens.muted,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 32,
                                height: 2,
                                color: index == 3
                                    ? tokens.gold
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkLibraryHeader extends StatelessWidget {
  const _BookmarkLibraryHeader({
    required this.selected,
    required this.selectedFolder,
    required this.selectedTag,
    required this.allItems,
    required this.totalSavedCount,
    required this.onSelected,
    required this.onFolderSelected,
    required this.onTagSelected,
    required this.onManageFolders,
    required this.onCreateFolder,
    required this.searchController,
    required this.onSearchChanged,
    this.searchFocusNode,
  });
  final _SavedAyahFilter selected;
  final String? selectedFolder;
  final String? selectedTag;
  final List<QuranBookmarkEntry> allItems;
  final int totalSavedCount;
  final ValueChanged<_SavedAyahFilter> onSelected;
  final ValueChanged<String?> onFolderSelected;
  final ValueChanged<String?> onTagSelected;
  final VoidCallback onManageFolders;
  final VoidCallback onCreateFolder;
  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final folders = const QuranBookmarkService().folders();
    final tags = allItems.expand((entry) => entry.tags).toSet().toList()
      ..sort();
    final tokens = context.equranTokens;
    final noCollection = selectedFolder == null && selectedTag == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SavedEyebrow(l.personalLibrary),
                  const SizedBox(height: 10),
                  Text(
                    l.savedAyahsCount(totalSavedCount),
                    style: EquranTextStyles.displaySectionTitle(context)
                        .copyWith(
                          fontSize: 30,
                          fontFamilyFallback: const ['NotoNaskhArabic'],
                          letterSpacing: -.3,
                          fontVariations: const [
                            FontVariation('opsz', 30),
                            FontVariation('wght', 500),
                          ],
                        ),
                  ),
                ],
              ),
            ),
            IconButton44(
              icon: Icons.folder_open_outlined,
              tooltip: l.manageFolders,
              onPressed: onManageFolders,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CollectionTile(
                label: l.all,
                icon: Icons.bookmark_border_rounded,
                count: allItems.length,
                selected: noCollection && selected == _SavedAyahFilter.all,
                onPressed: () => onSelected(_SavedAyahFilter.all),
              ),
              _CollectionTile(
                label: l.favourites,
                icon: Icons.favorite_border_rounded,
                count: allItems.where((e) => e.isFavourite).length,
                selected:
                    noCollection && selected == _SavedAyahFilter.favourites,
                onPressed: () => onSelected(_SavedAyahFilter.favourites),
              ),
              _CollectionTile(
                label: l.notes,
                icon: Icons.edit_note_rounded,
                count: allItems.where((e) => e.note.trim().isNotEmpty).length,
                selected: noCollection && selected == _SavedAyahFilter.notes,
                onPressed: () => onSelected(_SavedAyahFilter.notes),
              ),
              for (final folder in folders)
                _CollectionTile(
                  label: _folderLabel(context, folder),
                  icon: Icons.folder_outlined,
                  count: allItems.where((e) => e.folder == folder).length,
                  selected: selectedFolder == folder,
                  onPressed: () => onFolderSelected(
                    selectedFolder == folder ? null : folder,
                  ),
                ),
              _CollectionTile(
                label: l.addNewFolder,
                icon: Icons.add_rounded,
                dashed: true,
                onPressed: onCreateFolder,
              ),
            ],
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tag in tags)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChipButton(
                      '#$tag',
                      selected: selectedTag == tag,
                      onPressed: () =>
                          onTagSelected(selectedTag == tag ? null : tag),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          key: const Key('saved-search'),
          controller: searchController,
          focusNode: searchFocusNode,
          onChanged: onSearchChanged,
          style: TextStyle(
            fontSize: 15,
            color: context.equranColors.textPrimary,
          ),
          decoration: _savedInputDecoration(context, l.searchHintSaved)
              .copyWith(
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: tokens.muted,
                ),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton44(
                        icon: Icons.close_rounded,
                        tooltip: l.clearSearch,
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      ),
              ),
        ),
      ],
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.count,
    this.selected = false,
    this.dashed = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final int? count;
  final bool selected;
  final bool dashed;
  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final colors = context.equranColors;
    // Preserve the 128 × 96 specimen, and grow labels at larger text scales.
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label${count == null ? '' : ', $count'}',
        child: ExcludeSemantics(
          child: CustomPaint(
            foregroundPainter: dashed
                ? _DashedBorderPainter(tokens.hair2)
                : null,
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onPressed,
                child: Ink(
                  width: 128,
                  height: 96 + math.max(0, scale - 1) * 56,
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 13, 14, 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: dashed
                        ? null
                        : Border.all(
                            color: selected
                                ? tokens.gold.withValues(alpha: .5)
                                : tokens.hair,
                          ),
                    gradient: selected
                        ? LinearGradient(
                            begin: const Alignment(-.34, -1),
                            end: const Alignment(.34, 1),
                            colors: [
                              EquranTokens.mix(
                                colors.surface,
                                colors.primary,
                                .3,
                              ),
                              colors.surface,
                            ],
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: selected ? tokens.goldText : tokens.emText,
                          ),
                          if (count != null)
                            DisplayNumeral(
                              '$count',
                              size: 24,
                              height: 1,
                              color: tokens.muted,
                            ),
                        ],
                      ),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
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
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 7) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 4, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}

InputDecoration _savedInputDecoration(BuildContext context, String hint) {
  final tokens = context.equranTokens;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: tokens.hair),
  );
  return InputDecoration(
    constraints: const BoxConstraints(minHeight: 52),
    hintText: hint,
    hintStyle: TextStyle(color: tokens.muted, fontSize: 15),
    filled: true,
    fillColor: context.equranColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(borderSide: BorderSide(color: tokens.hair2)),
  );
}

class _BookmarkRow extends StatefulWidget {
  const _BookmarkRow({required this.entry});

  final QuranBookmarkEntry entry;

  @override
  State<_BookmarkRow> createState() => _BookmarkRowState();
}

class _BookmarkRowState extends State<_BookmarkRow> {
  @override
  void initState() {
    super.initState();
    _loadFontIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _BookmarkRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.surah != widget.entry.surah ||
        oldWidget.entry.verse != widget.entry.verse) {
      _loadFontIfNeeded();
    }
  }

  Future<void> _loadFontIfNeeded() async {
    final String style = SettingsDB().quranScriptStyle;
    if (style == 'qpc-v4') {
      final int page = EquranTextStyles.getPageNumber(
        widget.entry.surah,
        widget.entry.verse,
      );
      final bool loaded = await QpcV4FontService.instance
          .ensureFontLoadedForPage(page);
      if (loaded && mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<dynamic>>(
      valueListenable: SettingsDB().listener,
      builder: (BuildContext context, Box<dynamic> box, _) {
        final QuranBookmarkEntry entry = widget.entry;
        final colors = context.equranColors;
        final tokens = context.equranTokens;
        final l = AppLocalizations.of(context)!;
        final fontFamily = SettingsDB().quranScriptStyle == 'qpc-v4'
            ? EquranTextStyles.fontFamilyForVerse(entry.surah, entry.verse)
            : EquranTextStyles.activeFontFamily;
        final translation = quran.cleanTranslationText(
          quran.getVerseTranslation(
            entry.surah,
            entry.verse,
            translation: QuranTranslationService.instance.selectedTranslation(),
          ),
        );
        return HairlineCard(
          padding: EdgeInsets.zero,
          child: Semantics(
            button: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        ReadPage(chapter: entry.surah, startVerse: entry.verse),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AyahHeading(entry: entry),
                          Semantics(
                            container: true,
                            toggled: entry.isFavourite,
                            child: IconButton(
                              key: ValueKey('saved-favourite-${entry.id}'),
                              style: IconButton.styleFrom(
                                fixedSize: const Size(44, 44),
                                minimumSize: const Size(44, 44),
                                maximumSize: const Size(44, 44),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              tooltip: l.favourites,
                              constraints: const BoxConstraints.tightFor(
                                width: 44,
                                height: 44,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                entry.isFavourite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 21,
                                color: entry.isFavourite
                                    ? tokens.gold
                                    : tokens.muted,
                              ),
                              onPressed: () async {
                                if (entry.isFavourite) {
                                  await const QuranBookmarkService()
                                      .removeFavourite(
                                        entry.surah,
                                        entry.verse,
                                      );
                                } else {
                                  await const QuranBookmarkService()
                                      .saveFavourite(entry.surah, entry.verse);
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: PopupMenuButton<_BookmarkAction>(
                              key: ValueKey('saved-menu-${entry.id}'),
                              tooltip: l.folderTagsAndNote,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                color: tokens.muted,
                              ),
                              onSelected: (action) async {
                                switch (action) {
                                  case _BookmarkAction.edit:
                                  case _BookmarkAction.folder:
                                  case _BookmarkAction.tags:
                                    await _showBookmarkEditor(context, entry);
                                  case _BookmarkAction.delete:
                                    final confirmed =
                                        await _confirmDeleteBookmark(context);
                                    if (!confirmed) return;
                                    await const QuranBookmarkService()
                                        .deleteBookmark(
                                          entry.surah,
                                          entry.verse,
                                        );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: _BookmarkAction.edit,
                                  child: Text(l.editNote),
                                ),
                                PopupMenuItem(
                                  value: _BookmarkAction.folder,
                                  child: Text(l.moveToFolder),
                                ),
                                PopupMenuItem(
                                  value: _BookmarkAction.tags,
                                  child: Text(l.editTags),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: _BookmarkAction.delete,
                                  child: Text(l.delete),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          quranVerseText(entry.surah, entry.verse),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontFamilyFallback: const ['UthmanicHafs'],
                            fontSize: 28,
                            height: 1.9,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (translation.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          translation,
                          style: EquranTextStyles.displayTranslation(context),
                        ),
                      ],
                      if (entry.hasNote) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.goldWash,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SavedEyebrow(l.privateNote),
                              const SizedBox(height: 7),
                              Text(
                                entry.note,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: tokens.text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: tokens.hair)),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PillTag(
                              _folderLabel(context, entry.folder),
                              gold: true,
                              icon: Icons.folder_outlined,
                            ),
                            for (final tag in entry.tags) PillTag('#$tag'),
                            Text(
                              DateFormat.MMMd(
                                l.localeName,
                              ).format(entry.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AyahHeading extends StatelessWidget {
  const _AyahHeading({required this.entry});
  final QuranBookmarkEntry entry;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Expanded(
      child: Row(
        children: [
          CustomPaint(
            painter: _MedallionPainter(context.equranTokens.gold),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: DisplayNumeral(
                  '${entry.surah}',
                  size: 13,
                  height: 1,
                  color: context.equranTokens.goldText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedSurahName(l, entry.surah),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.equranColors.textPrimary,
                  ),
                ),
                Text(
                  l.ayahNumber(entry.verse),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.equranTokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  const _MedallionPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 30, size.height / 30);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5.5, 5.5, 19, 19),
      const Radius.circular(2.2),
    );
    canvas.drawRRect(rect, paint);
    canvas.translate(15, 15);
    canvas.rotate(math.pi / 4);
    canvas.translate(-15, -15);
    canvas.drawRRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MedallionPainter oldDelegate) =>
      color != oldDelegate.color;
}

enum _BookmarkAction { edit, folder, tags, delete }

class _BookmarkEmptyState extends StatelessWidget {
  const _BookmarkEmptyState({
    required this.isSearching,
    required this.hasLibraryItems,
    this.onBrowseSurahs,
  });
  final bool isSearching;
  final bool hasLibraryItems;
  final VoidCallback? onBrowseSurahs;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isFiltered = isSearching || hasLibraryItems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 32),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(150, 168),
            painter: _EmptyLibraryPainter(
              context.equranColors.surface,
              context.equranTokens.gold,
              context.equranTokens.hair2,
              context.equranTokens.emText,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? l.noMatchingSavedAyahs : l.saveAyahsNotesHere,
            textAlign: TextAlign.center,
            style: EquranTextStyles.displaySectionTitle(
              context,
            ).copyWith(fontFamilyFallback: const ['NotoNaskhArabic']),
          ),
          const SizedBox(height: 12),
          Text(
            l.savedAyahLibraryHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: context.equranTokens.text2,
            ),
          ),
          const SizedBox(height: 24),
          if (onBrowseSurahs != null)
            FilledButton.icon(
              onPressed: onBrowseSurahs,
              style: FilledButton.styleFrom(
                backgroundColor: context.equranTokens.filled,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 19),
              label: Text(l.browseSurahs),
            ),
        ],
      ),
    );
  }
}

class _EmptyLibraryPainter extends CustomPainter {
  const _EmptyLibraryPainter(this.surface, this.gold, this.hair, this.em);
  final Color surface, gold, hair, em;
  @override
  void paint(Canvas canvas, Size size) {
    final arch = Path()
      ..moveTo(20, 160)
      ..lineTo(20, 70)
      ..cubicTo(20, 36, 44, 12, 75, 12)
      ..cubicTo(106, 12, 130, 36, 130, 70)
      ..lineTo(130, 160)
      ..close();
    canvas.drawPath(arch, Paint()..color = surface);
    canvas.drawPath(
      arch,
      Paint()
        ..color = gold.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final inner = Path()
      ..moveTo(36, 160)
      ..lineTo(36, 74)
      ..cubicTo(36, 46, 53, 28, 75, 28)
      ..cubicTo(97, 28, 114, 46, 114, 74)
      ..lineTo(114, 160);
    canvas.drawPath(
      inner,
      Paint()
        ..color = hair
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(58, 20)
        ..lineTo(92, 20)
        ..lineTo(92, 90)
        ..lineTo(75, 77)
        ..lineTo(58, 90)
        ..close(),
      Paint()..color = gold.withValues(alpha: .92),
    );
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? 12.0 : 5.0;
      final point = Offset(
        75 + math.cos(angle) * radius,
        124 + math.sin(angle) * radius,
      );
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      star..close(),
      Paint()
        ..color = em
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      const Offset(24, 36),
      2,
      Paint()..color = gold.withValues(alpha: .7),
    );
  }

  @override
  bool shouldRepaint(_EmptyLibraryPainter old) =>
      surface != old.surface ||
      gold != old.gold ||
      hair != old.hair ||
      em != old.em;
}

Future<void> _showBookmarkEditor(
  BuildContext context,
  QuranBookmarkEntry entry,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  backgroundColor: context.equranColors.surface,
  barrierColor: context.equranTokens.scrim,
  shape: RoundedRectangleBorder(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
    side: BorderSide(color: context.equranTokens.hair2),
  ),
  builder: (_) => _BookmarkEditor(entry: entry),
);

class _BookmarkEditor extends StatefulWidget {
  const _BookmarkEditor({required this.entry});
  final QuranBookmarkEntry entry;
  @override
  State<_BookmarkEditor> createState() => _BookmarkEditorState();
}

class _BookmarkEditorState extends State<_BookmarkEditor> {
  late final noteController = TextEditingController(text: widget.entry.note);
  late final folderController = TextEditingController(
    text: widget.entry.folder,
  );
  late final tagsController = TextEditingController(
    text: widget.entry.tags.join(', '),
  );
  late bool isFavourite = widget.entry.isFavourite;
  late String selectedFolder = widget.entry.folder;
  @override
  void initState() {
    super.initState();
    _loadFontIfNeeded();
  }

  Future<void> _loadFontIfNeeded() async {
    if (SettingsDB().quranScriptStyle != 'qpc-v4') return;
    final loaded = await QpcV4FontService.instance.ensureFontLoadedForPage(
      EquranTextStyles.getPageNumber(widget.entry.surah, widget.entry.verse),
    );
    if (loaded && mounted) setState(() {});
  }

  @override
  void dispose() {
    noteController.dispose();
    folderController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final colors = context.equranColors;
    final tokens = context.equranTokens;
    final localizations = AppLocalizations.of(context)!;
    final folders = const QuranBookmarkService().folders();
    if (!folders.contains(selectedFolder)) {
      selectedFolder = QuranBookmarkService.defaultFolder;
    }
    final style = SettingsDB().quranScriptStyle;
    return _SavedTypography(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          20,
          12,
          20,
          28 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.hair2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _AyahHeading(entry: entry),
                  IconButton44(
                    icon: Icons.close_rounded,
                    tooltip: localizations.close,
                    ghost: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Text(
                  quranVerseText(entry.surah, entry.verse),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: style == 'qpc-v4'
                        ? EquranTextStyles.fontFamilyForVerse(
                            entry.surah,
                            entry.verse,
                          )
                        : EquranTextStyles.activeFontFamily,
                    fontFamilyFallback: const ['UthmanicHafs'],
                    color: colors.textPrimary,
                    fontSize: 24,
                    height: 1.9,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.hair),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: SwitchListTile.adaptive(
                    secondary: Icon(
                      Icons.favorite_rounded,
                      color: tokens.gold,
                      size: 21,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      localizations.favourites,
                      style: TextStyle(fontSize: 15, color: colors.textPrimary),
                    ),
                    activeTrackColor: tokens.filled,
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    value: isFavourite,
                    onChanged: (value) => setState(() {
                      isFavourite = value;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SavedEyebrow(localizations.privateNote),
              const SizedBox(height: 9),
              TextField(
                key: const Key('saved-note-editor'),
                controller: noteController,
                maxLines: 4,
                minLines: 3,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: colors.textPrimary,
                ),
                decoration:
                    _savedInputDecoration(
                      context,
                      localizations.writeReflectionHint,
                    ).copyWith(
                      fillColor: colors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _SavedEyebrow(localizations.folders)),
                  TextButton(
                    onPressed: () => _showFolderManager(context),
                    style: TextButton.styleFrom(foregroundColor: tokens.emText),
                    child: Text(localizations.manageFolders),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final folder in folders)
                    ChipButton(
                      _folderLabel(context, folder),
                      selected: selectedFolder == folder,
                      icon: selectedFolder == folder
                          ? Icons.check_rounded
                          : null,
                      onPressed: () => setState(() {
                        selectedFolder = folder;
                        folderController.text = folder;
                      }),
                    ),
                  ChipButton(
                    localizations.addNewFolder,
                    icon: Icons.add_rounded,
                    onPressed: () async {
                      final folder = await _showFolderNameDialog(context);
                      if (folder == null) return;
                      final created = await const QuranBookmarkService()
                          .createFolder(folder);
                      if (!context.mounted) return;
                      setState(() {
                        selectedFolder = created;
                        folderController.text = created;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SavedEyebrow(localizations.tags),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  border: Border.all(color: tokens.hair2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_parseTags(tagsController.text).isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in _parseTags(tagsController.text))
                            Chip(
                              shape: const StadiumBorder(),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 12,
                              ),
                              deleteIconColor: tokens.emText,
                              deleteButtonTooltipMessage:
                                  '${localizations.remove} #$tag',
                              label: Text('#$tag'),
                              onDeleted: () => setState(() {
                                tagsController.text = _parseTags(
                                  tagsController.text,
                                ).where((value) => value != tag).join(', ');
                              }),
                              backgroundColor: tokens.emWash,
                              side: BorderSide(color: tokens.hair),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: tokens.emText,
                              ),
                            ),
                        ],
                      ),
                    TextField(
                      key: const Key('saved-tags-editor'),
                      controller: tagsController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: localizations.tagsHint,
                        hintStyle: TextStyle(color: tokens.muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: tokens.danger),
                    onPressed: () {
                      const QuranBookmarkService().deleteBookmark(
                        entry.surah,
                        entry.verse,
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(localizations.delete),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.filled,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(150, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      const QuranBookmarkService().saveBookmarkDetails(
                        entry.surah,
                        entry.verse,
                        isFavourite: isFavourite,
                        note: noteController.text,
                        folder: selectedFolder,
                        tags: _parseTags(tagsController.text),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(localizations.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _parseTags(String value) {
  final Set<String> tags = <String>{};
  for (final String tag in value.split(',')) {
    final String cleanTag = tag.trim();
    if (cleanTag.isNotEmpty) tags.add(cleanTag);
  }
  return tags.toList(growable: false)..sort();
}

String _folderLabel(BuildContext context, String folder) {
  return folder == QuranBookmarkService.defaultFolder
      ? AppLocalizations.of(context)!.unsorted
      : folder;
}

Future<bool> _confirmDeleteBookmark(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(localizations.removeSavedAyah),
        content: Text(localizations.removeSavedAyahDetailsBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.remove),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

Future<String?> _showFolderNameDialog(
  BuildContext context, {
  String initialValue = '',
  String? title,
}) => showDialog<String>(
  context: context,
  builder: (_) => _FolderNameDialog(initialValue: initialValue, title: title),
);

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.initialValue, this.title});
  final String initialValue;
  final String? title;
  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final controller = TextEditingController(
    text: widget.initialValue == QuranBookmarkService.defaultFolder
        ? ''
        : widget.initialValue,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = controller.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _SavedTypography(
      child: AlertDialog(
        title: Text(widget.title ?? l.newFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l.folderName,
            hintText: l.folderNameHint,
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(onPressed: _submit, child: Text(l.save)),
        ],
      ),
    );
  }
}

Future<void> _showFolderManager(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final AppLocalizations localizations = AppLocalizations.of(context)!;
          final List<String> folders = const QuranBookmarkService().folders();
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        localizations.libraryFolders,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final String? name = await _showFolderNameDialog(
                          context,
                        );
                        if (name == null) return;
                        await const QuranBookmarkService().createFolder(name);
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(localizations.newFolder),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final String folder in folders)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(_folderLabel(context, folder)),
                    subtitle: Text(
                      folder == QuranBookmarkService.defaultFolder
                          ? localizations.defaultSavedAyahDestination
                          : localizations.savedAyahCollection,
                    ),
                    trailing: folder == QuranBookmarkService.defaultFolder
                        ? null
                        : PopupMenuButton<_FolderAction>(
                            onSelected: (action) async {
                              switch (action) {
                                case _FolderAction.rename:
                                  final String? name =
                                      await _showFolderNameDialog(
                                        context,
                                        initialValue: folder,
                                        title: localizations.renameFolder,
                                      );
                                  if (name == null) return;
                                  await const QuranBookmarkService()
                                      .renameFolder(folder, name);
                                  setSheetState(() {});
                                case _FolderAction.delete:
                                  final bool confirmed =
                                      await _confirmDeleteFolder(
                                        context,
                                        folder,
                                      );
                                  if (!confirmed) return;
                                  await const QuranBookmarkService()
                                      .deleteFolder(folder);
                                  setSheetState(() {});
                              }
                            },
                            itemBuilder: (context) =>
                                <PopupMenuEntry<_FolderAction>>[
                                  PopupMenuItem<_FolderAction>(
                                    value: _FolderAction.rename,
                                    child: Text(localizations.rename),
                                  ),
                                  PopupMenuItem<_FolderAction>(
                                    value: _FolderAction.delete,
                                    child: Text(localizations.delete),
                                  ),
                                ],
                          ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

enum _FolderAction { rename, delete }

Future<bool> _confirmDeleteFolder(BuildContext context, String folder) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(
          localizations.deleteFolderQuestion(_folderLabel(context, folder)),
        ),
        content: Text(localizations.deleteFolderBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.delete),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

class _SavedTypography extends StatelessWidget {
  const _SavedTypography({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final family = ['ar', 'fa', 'ur'].contains(code)
        ? 'NotoNaskhArabic'
        : 'Inter';
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: family),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: family,
          fontFamilyFallback: const ['NotoNaskhArabic'],
        ),
        child: child,
      ),
    );
  }
}

class _SavedEyebrow extends StatelessWidget {
  const _SavedEyebrow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (!['ar', 'fa', 'ur'].contains(code)) return EyebrowLabel(label);
    return Text(
      label,
      style: EquranTextStyles.eyebrow(
        context,
      ).copyWith(fontFamily: 'NotoNaskhArabic', height: 1.6, letterSpacing: 0),
    );
  }
}
