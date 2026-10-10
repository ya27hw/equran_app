import 'package:equran/backend/library.dart'
    show
        AudioDownloadEntry,
        AudioDownloadService,
        AudioDownloadType,
        AudioDownloadsSummary,
        DownloadMetadataService;
import 'package:equran/home/downloads_filter_sheet.dart';
import 'package:equran/home/downloads_widgets.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/utils/downloads_grouping.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/backend/playback_cache_service.dart';
import 'package:quran/quran.dart' as quran;

/// Row title for a download: the surah name, or "Surah • Ayah n" for a loose
/// ayah. [AudioDownloadEntry.title] is English only and stays for search.
String _entryTitle(AppLocalizations l10n, AudioDownloadEntry entry) {
  return switch (entry.type) {
    AudioDownloadType.ayah => localizedSurahAyahLabel(
      l10n,
      entry.surah,
      entry.ayah ?? 0,
    ),
    _ => localizedSurahName(l10n, entry.surah),
  };
}

String _entrySubtitle(AppLocalizations l10n, AudioDownloadEntry entry) {
  return switch (entry.type) {
    AudioDownloadType.surah => '',
    AudioDownloadType.ayahSurah => l10n.ayahsCount(
      quran.getVerseCount(entry.surah),
    ),
    AudioDownloadType.ayah => localizedAyahReference(l10n, entry.ayah ?? 0),
  };
}

class _SurahAyahDownloadsGroup {
  const _SurahAyahDownloadsGroup({required this.surah, required this.entries});

  final int surah;
  final List<AudioDownloadEntry> entries;

  int get ayahCount =>
      entries.fold<int>(0, (total, entry) => total + entry.ayahCount);

  int get sizeBytes =>
      entries.fold<int>(0, (total, entry) => total + entry.sizeBytes);
}

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key, @visibleForTesting this.loadSummary});

  /// Replaces the file-system scan; tests use it to show fixed downloads.
  final Future<AudioDownloadsSummary> Function()? loadSummary;

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  late Future<AudioDownloadsSummary> _summaryFuture;
  String _selectedReciterFilter = 'all';
  String _selectedCategoryFilter = 'all';
  int? _selectedSurahFilter;

  // State for the modern Filter & Sort icon button + sheet
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'reciterAsc';
  String _selectedTypeFilter = 'all';

  // Track which reciter sections are collapsed
  final Set<String> _collapsedReciters = {};

  // Grouping mode for the downloads list (Option C+ implementation)
  String _groupBy = 'reciter'; // 'reciter' | 'surah'

  // Track which surah sections are collapsed (when in surah-group mode)
  final Set<int> _collapsedSurahs = {};

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedReciterFilter = 'all';
      _selectedCategoryFilter = 'all';
      _selectedSurahFilter = null;
      _selectedTypeFilter = 'all';
      _sortBy = 'reciterAsc';
      _searchQuery = '';
      _groupBy = 'reciter';
    });
  }

  void _toggleReciterSection(String reciterCode) {
    setState(() {
      if (_collapsedReciters.contains(reciterCode)) {
        _collapsedReciters.remove(reciterCode);
      } else {
        _collapsedReciters.add(reciterCode);
      }
    });
  }

  void _toggleSurahSection(int surah) {
    setState(() {
      if (_collapsedSurahs.contains(surah)) {
        _collapsedSurahs.remove(surah);
      } else {
        _collapsedSurahs.add(surah);
      }
    });
  }

  void _refresh() {
    setState(() {
      _summaryFuture = _loadSummary();
    });
  }

  Future<AudioDownloadsSummary> _loadSummary() async {
    final Future<AudioDownloadsSummary> Function()? override =
        widget.loadSummary;
    if (override != null) return override();
    final AudioDownloadsSummary summary = await AudioDownloadService()
        .summary();
    await const DownloadMetadataService().syncFromSummary(summary);
    return summary;
  }

  Future<void> _deleteEntry(AudioDownloadEntry entry) async {
    final bool? confirm = await showReaderDialog<bool>(
      context: context,
      builder: (context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return ReaderConfirmDialog(
          title: l.deleteDownloadQuestion,
          body: l.removeDownloadFromOffline(_entryTitle(l, entry)),
          icon: const DesignIcon('trash'),
          cancelLabel: l.cancel,
          confirmLabel: l.delete,
          destructive: true,
        );
      },
    );

    if (confirm != true) return;
    await AudioDownloadService().deleteEntry(entry);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.deletedDownload(
              _entryTitle(AppLocalizations.of(context)!, entry),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _clearAll(AudioDownloadsSummary summary) async {
    if (summary.allDownloads.isEmpty) return;
    final bool? confirm = await showReaderDialog<bool>(
      context: context,
      builder: (context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return ReaderConfirmDialog(
          title: l.deleteAllDownloadsQuestion,
          body: l.deleteAllDownloadsBody(
            summary.allDownloads.length,
            AudioDownloadService.formatBytes(summary.totalSizeBytes),
          ),
          icon: const DesignIcon('trash'),
          cancelLabel: l.cancel,
          confirmLabel: l.deleteAll,
          destructive: true,
        );
      },
    );

    if (confirm != true) return;
    await AudioDownloadService().clearAll();
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.deletedAllDownloadedAudio,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RedesignSubpage(
      title: AppLocalizations.of(context)!.downloads,
      child: FutureBuilder<AudioDownloadsSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final AudioDownloadsSummary summary = snapshot.data!;
          final List<ReciterDownloadsGroup> reciterGroups =
              groupDownloadsByReciter(summary);

          final List<ReciterDownloadsGroup> filteredGroups = reciterGroups
              .map((group) {
                if (_selectedReciterFilter != 'all' &&
                    group.reciterCode != _selectedReciterFilter) {
                  return null;
                }

                // Filter by category (place of revelation)
                var filteredSurahs = group.surahs.where((surah) {
                  if (_selectedCategoryFilter == 'all') return true;
                  final place = quran
                      .getPlaceOfRevelation(surah.surah)
                      .toLowerCase();
                  final target = _selectedCategoryFilter.toLowerCase();
                  return place == target ||
                      (place == 'makkah' && target == 'makki') ||
                      (place == 'madinah' && target == 'madani');
                }).toList();

                var filteredAyahs = group.ayahs.where((ayah) {
                  if (_selectedCategoryFilter == 'all') return true;
                  final place = quran
                      .getPlaceOfRevelation(ayah.surah)
                      .toLowerCase();
                  final target = _selectedCategoryFilter.toLowerCase();
                  return place == target ||
                      (place == 'makkah' && target == 'makki') ||
                      (place == 'madinah' && target == 'madani');
                }).toList();

                // Filter by surah
                if (_selectedSurahFilter != null) {
                  filteredSurahs = filteredSurahs
                      .where((s) => s.surah == _selectedSurahFilter)
                      .toList();
                  filteredAyahs = filteredAyahs
                      .where((a) => a.surah == _selectedSurahFilter)
                      .toList();
                }

                // Filter by type (surahs only / ayahs only)
                if (_selectedTypeFilter == 'surahs') {
                  filteredAyahs = [];
                } else if (_selectedTypeFilter == 'ayahs') {
                  filteredSurahs = [];
                }

                // Apply search
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filteredSurahs = filteredSurahs
                      .where((s) => s.title.toLowerCase().contains(query))
                      .toList();
                  filteredAyahs = filteredAyahs
                      .where((a) => a.title.toLowerCase().contains(query))
                      .toList();
                }

                if (filteredSurahs.isEmpty && filteredAyahs.isEmpty) {
                  return null;
                }

                return ReciterDownloadsGroup(
                  reciterCode: group.reciterCode,
                  entries: <AudioDownloadEntry>[
                    ...filteredSurahs,
                    ...filteredAyahs,
                  ],
                );
              })
              .whereType<ReciterDownloadsGroup>()
              .toList();

          // Apply group-level sorting
          if (_sortBy == 'reciterAsc') {
            filteredGroups.sort(
              (a, b) => reciterDisplayName(
                a.reciterCode,
              ).compareTo(reciterDisplayName(b.reciterCode)),
            );
          } else if (_sortBy == 'reciterDesc') {
            filteredGroups.sort(
              (a, b) => reciterDisplayName(
                b.reciterCode,
              ).compareTo(reciterDisplayName(a.reciterCode)),
            );
          } else if (_sortBy == 'sizeDesc') {
            filteredGroups.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
          } else if (_sortBy == 'sizeAsc') {
            filteredGroups.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
          }

          // Validate active filters to prevent assertions when content is deleted
          final List<String> availableReciters = reciterGroups
              .map((g) => g.reciterCode)
              .toList();
          if (_selectedReciterFilter != 'all' &&
              !availableReciters.contains(_selectedReciterFilter)) {
            _selectedReciterFilter = 'all';
          }

          final List<int> downloadedSurahs =
              summary.allDownloads.map((e) => e.surah).toSet().toList()..sort();
          if (_selectedSurahFilter != null &&
              !downloadedSurahs.contains(_selectedSurahFilter)) {
            _selectedSurahFilter = null;
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: <Widget>[
                _buildSummaryCard(summary),
                const SizedBox(height: 16),
                _buildCleanupPreviewCard(summary),
                const SizedBox(height: 16),
                if (reciterGroups.isNotEmpty) ...<Widget>[
                  _buildFilterButton(summary, reciterGroups),
                  const SizedBox(height: 16),
                ],
                if (filteredGroups.isEmpty)
                  _buildEmptyDownloadsCard()
                else if (_groupBy == 'reciter')
                  ...filteredGroups.expand(
                    (group) => <Widget>[
                      _buildReciterSection(group),
                      const SizedBox(height: 16),
                    ],
                  )
                else
                  ..._buildSurahGroupedList(filteredGroups),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton(
    AudioDownloadsSummary summary,
    List<ReciterDownloadsGroup> originalGroups,
  ) {
    final EquranTokens tokens = context.equranTokens;

    final bool hasActive =
        _selectedReciterFilter != 'all' ||
        _selectedCategoryFilter != 'all' ||
        _selectedSurahFilter != null ||
        _selectedTypeFilter != 'all' ||
        _searchQuery.isNotEmpty ||
        _sortBy != (_groupBy == 'reciter' ? 'reciterAsc' : 'surahAsc') ||
        _groupBy != 'reciter';

    int activeCount = 0;
    if (_selectedReciterFilter != 'all') activeCount++;
    if (_selectedCategoryFilter != 'all') activeCount++;
    if (_selectedSurahFilter != null) activeCount++;
    if (_selectedTypeFilter != 'all') activeCount++;
    if (_sortBy != (_groupBy == 'reciter' ? 'reciterAsc' : 'surahAsc')) {
      activeCount++;
    }
    if (_searchQuery.isNotEmpty) activeCount++;
    if (_groupBy != 'reciter') activeCount++;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasActive)
            TextButton(
              onPressed: _resetAllFilters,
              style: readerTextButtonStyle(context, color: tokens.emText),
              child: Text(AppLocalizations.of(context)!.clear),
            ),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              IconButton44(
                onPressed: () => _showFilterSortSheet(summary, originalGroups),
                designIcon: 'sliders',
                tooltip: AppLocalizations.of(context)!.filterAndSort,
              ),
              if (activeCount > 0)
                PositionedDirectional(
                  end: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.goldWash,
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.goldText, width: 1),
                    ),
                    child: Text(
                      '$activeCount',
                      style: TextStyle(
                        color: tokens.goldText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AudioDownloadsSummary summary) {
    final localizations = AppLocalizations.of(context)!;
    return DownloadsSummaryHero(
      eyebrow: localizations.offlineAudio,
      size: AudioDownloadService.formatBytes(summary.totalSizeBytes),
      caption: localizations.surahAyahSummary(
        summary.surahCount,
        summary.ayahCount,
      ),
    );
  }

  Widget _buildCleanupPreviewCard(AudioDownloadsSummary summary) {
    final bool hasDownloads = summary.allDownloads.isNotEmpty;
    final localizations = AppLocalizations.of(context)!;
    return DownloadsCleanupCard(
      title: localizations.cleanupPreview,
      rows: <(String, String)>[
        (localizations.downloadedSurahs, '${summary.surahCount}'),
        (localizations.downloadedAyahs, '${summary.ayahCount}'),
        (
          localizations.potentialSpaceToFree,
          AudioDownloadService.formatBytes(summary.totalSizeBytes),
        ),
      ],
      note: localizations.cleanupDoesNotRemoveData,
      actionLabel: localizations.reviewDeletion,
      onAction: hasDownloads ? () => _clearAll(summary) : null,
    );
  }

  Widget _buildEmptyDownloadsCard() {
    final localizations = AppLocalizations.of(context)!;
    return HairlineCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
        child: ReaderOptionRow(
          leading: const DesignIcon('download'),
          title: localizations.noDownloadedAudioYet,
          subtitle: localizations.downloadedAudioEmpty,
          subtitleMaxLines: 4,
          showChevron: false,
          onTap: null,
        ),
      ),
    );
  }

  List<Widget> _buildSurahGroupedList(
    List<ReciterDownloadsGroup> filteredReciterGroups,
  ) {
    // Flatten all entries from the already-filtered reciter groups
    final List<AudioDownloadEntry> allEntries = filteredReciterGroups
        .expand((g) => g.entries)
        .toList();

    final List<SurahDownloadsGroup> surahGroups = groupDownloadsBySurah(
      allEntries,
    );

    if (_sortBy == 'surahAsc') {
      surahGroups.sort((a, b) => a.surah.compareTo(b.surah));
    } else if (_sortBy == 'surahDesc') {
      surahGroups.sort((a, b) => b.surah.compareTo(a.surah));
    } else if (_sortBy == 'sizeDesc') {
      surahGroups.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    } else if (_sortBy == 'sizeAsc') {
      surahGroups.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    }

    return surahGroups
        .expand(
          (group) => <Widget>[
            _buildSurahSection(group),
            const SizedBox(height: 16),
          ],
        )
        .toList();
  }

  Widget _buildSurahSection(SurahDownloadsGroup group) {
    final localizations = AppLocalizations.of(context)!;

    final bool isCollapsed = _collapsedSurahs.contains(group.surah);
    final byReciter = group.entriesByReciter;

    return DownloadsSection(
      leading: const DesignIcon('quran'),
      title: localizedSurahName(localizations, group.surah),
      subtitle:
          '${localizations.downloadsReciterCount(byReciter.length)}  •  ${AudioDownloadService.formatBytes(group.sizeBytes)}',
      collapsed: isCollapsed,
      onToggle: () => _toggleSurahSection(group.surah),
      children: <Widget>[
        ...byReciter.entries.map((reciterEntry) {
          final reciterCode = reciterEntry.key;
          final reciterEntries = reciterEntry.value;
          final reciterSize = reciterEntries.fold<int>(
            0,
            (sum, e) => sum + e.sizeBytes,
          );

          return DownloadRow(
            icon: const DesignIcon('headphones'),
            title: reciterDisplayName(reciterCode),
            subtitle:
                '${localizations.downloadsItemCount(reciterEntries.length)}  •  ${AudioDownloadService.formatBytes(reciterSize)}',
            deleteTooltip: localizations.deleteDownload,
            onDelete: () async {
              // Single confirmation for the whole reciter+surah batch
              final bool? confirm = await showReaderDialog<bool>(
                context: context,
                builder: (context) => ReaderConfirmDialog(
                  icon: const DesignIcon('trash'),
                  title: localizations.deleteDownloadsQuestion,
                  body: localizations.downloadsDeleteReciterBody(
                    reciterDisplayName(reciterCode),
                    localizedSurahName(localizations, group.surah),
                  ),
                  cancelLabel: localizations.cancel,
                  confirmLabel: localizations.delete,
                  destructive: true,
                ),
              );

              if (confirm != true) return;

              for (final e in reciterEntries) {
                await _deleteEntry(e);
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildReciterSection(ReciterDownloadsGroup group) {
    final localizations = AppLocalizations.of(context)!;

    final bool isCollapsed = _collapsedReciters.contains(group.reciterCode);

    final List<AudioDownloadEntry> surahs = group.surahs;
    final List<_SurahAyahDownloadsGroup> ayahSurahs = _groupAyahsBySurah(
      group.ayahs,
    );

    // Only count the ayahs that are actually displayed in the "Ayahs" section
    // (i.e. loose individual ayahs, not the ones already bundled into surahs)
    final int ayahSectionCount = ayahSurahs.fold<int>(
      0,
      (total, g) => total + g.ayahCount,
    );

    return DownloadsSection(
      title: reciterDisplayName(group.reciterCode),
      subtitle:
          '${localizations.surahCount(surahs.length)}  •  ${localizations.ayahsCount(group.ayahCount)}  •  ${AudioDownloadService.formatBytes(group.sizeBytes)}',
      collapsed: isCollapsed,
      onToggle: () => _toggleReciterSection(group.reciterCode),
      children: <Widget>[
        if (surahs.isNotEmpty)
          DownloadsGroupLabel(
            title: localizations.surahs,
            count: surahs.length,
          ),
        ...surahs.map(_buildDownloadTile),
        if (surahs.isNotEmpty && ayahSurahs.isNotEmpty)
          Divider(height: 1, thickness: 1, color: context.equranTokens.hair),
        if (ayahSurahs.isNotEmpty)
          DownloadsGroupLabel(
            title: localizations.ayahs,
            count: ayahSectionCount,
          ),
        ...ayahSurahs.map(_buildAyahSurahTile),
      ],
    );
  }

  List<_SurahAyahDownloadsGroup> _groupAyahsBySurah(
    List<AudioDownloadEntry> ayahs,
  ) {
    final Map<int, List<AudioDownloadEntry>> grouped =
        <int, List<AudioDownloadEntry>>{};
    for (final AudioDownloadEntry entry in ayahs) {
      grouped.putIfAbsent(entry.surah, () => <AudioDownloadEntry>[]).add(entry);
    }

    final List<_SurahAyahDownloadsGroup> groups = grouped.entries
        .map(
          (entry) =>
              _SurahAyahDownloadsGroup(surah: entry.key, entries: entry.value),
        )
        .toList();
    groups.sort((a, b) => a.surah.compareTo(b.surah));
    return groups;
  }

  Widget _buildAyahSurahTile(_SurahAyahDownloadsGroup group) {
    final localizations = AppLocalizations.of(context)!;
    return DownloadsFolder(
      title: localizedSurahName(localizations, group.surah),
      subtitle:
          '${localizations.ayahsCount(group.ayahCount)}  •  ${AudioDownloadService.formatBytes(group.sizeBytes)}',
      children: group.entries
          .map((entry) => _buildNestedDownloadTile(entry))
          .toList(growable: false),
    );
  }

  bool _isActiveOffline(
    ActivePlaybackTrack? activeTrack,
    AudioDownloadEntry e,
  ) =>
      activeTrack != null &&
      activeTrack.isPlaying &&
      activeTrack.isOffline &&
      activeTrack.surah == e.surah &&
      activeTrack.reciterCode == e.reciterCode;

  Widget _buildDownloadTile(AudioDownloadEntry entry) {
    return ValueListenableBuilder<ActivePlaybackTrack?>(
      valueListenable: PlaybackCacheService.instance.activeTrackNotifier,
      builder: (context, activeTrack, child) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        final String detail = _entrySubtitle(l10n, entry);
        final String size = AudioDownloadService.formatBytes(entry.sizeBytes);
        return DownloadRow(
          active: _isActiveOffline(activeTrack, entry),
          title: _entryTitle(l10n, entry),
          subtitle: detail.isNotEmpty ? '$detail  •  $size' : size,
          deleteTooltip: l10n.deleteDownload,
          onDelete: () => _deleteEntry(entry),
        );
      },
    );
  }

  Widget _buildNestedDownloadTile(AudioDownloadEntry entry) {
    return ValueListenableBuilder<ActivePlaybackTrack?>(
      valueListenable: PlaybackCacheService.instance.activeTrackNotifier,
      builder: (context, activeTrack, child) {
        return DownloadRow(
          nested: true,
          active: _isActiveOffline(activeTrack, entry),
          title: _entryTitle(AppLocalizations.of(context)!, entry),
          subtitle: AudioDownloadService.formatBytes(entry.sizeBytes),
          deleteTooltip: AppLocalizations.of(context)!.deleteDownload,
          onDelete: () => _deleteEntry(entry),
        );
      },
    );
  }

  Future<void> _showFilterSortSheet(
    AudioDownloadsSummary summary,
    List<ReciterDownloadsGroup> groups,
  ) async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final Map<String, String> reciterNames = <String, String>{
      'all': localizations.allReciters,
    };
    for (final ReciterDownloadsGroup group in groups) {
      reciterNames[group.reciterCode] = reciterDisplayName(group.reciterCode);
    }

    final List<int> downloadedSurahs =
        summary.allDownloads.map((e) => e.surah).toSet().toList()..sort();

    final List<DropdownMenuItem<int?>> surahItems = [
      DropdownMenuItem<int?>(
        value: null,
        child: Text(
          localizations.downloadsAllSurahs,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ...downloadedSurahs.map((surahNum) {
        return DropdownMenuItem<int?>(
          value: surahNum,
          child: Text(
            '$surahNum. ${localizedSurahName(localizations, surahNum)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    ];

    final DownloadsFilterResult? result =
        await showReaderSheet<DownloadsFilterResult>(
          context: context,
          builder: (BuildContext sheetContext) => DownloadsFilterSheet(
            initial: DownloadsFilterResult(
              reciter: _selectedReciterFilter,
              category: _selectedCategoryFilter,
              surah: _selectedSurahFilter,
              type: _selectedTypeFilter,
              sort: _sortBy,
              search: _searchQuery,
              groupBy: _groupBy,
            ),
            reciterNames: reciterNames,
            surahItems: surahItems,
          ),
        );
    if (result == null || !mounted) return;
    setState(() {
      _selectedReciterFilter = result.reciter;
      _selectedCategoryFilter = result.category;
      _selectedSurahFilter = result.surah;
      _selectedTypeFilter = result.type;
      _sortBy = result.sort;
      _searchQuery = result.search;
      _searchController.text = result.search;
      _groupBy = result.groupBy;
    });
  }
}
