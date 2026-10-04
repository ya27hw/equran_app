import 'package:equran/backend/library.dart'
    show
        AudioDownloadEntry,
        AudioDownloadService,
        AudioDownloadsSummary,
        DownloadMetadataService;
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/downloads_grouping.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/backend/playback_cache_service.dart';
import 'package:quran/quran.dart' as quran;

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
  const DownloadsPage({super.key});

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
    final AudioDownloadsSummary summary = await AudioDownloadService()
        .summary();
    await const DownloadMetadataService().syncFromSummary(summary);
    return summary;
  }

  Future<void> _deleteEntry(AudioDownloadEntry entry) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(AppLocalizations.of(context)!.deleteDownloadQuestion),
        content: Text(
          AppLocalizations.of(context)!.removeDownloadFromOffline(entry.title),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await AudioDownloadService().deleteEntry(entry);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.deletedDownload(entry.title),
          ),
        ),
      );
    }
  }

  Future<void> _clearAll(AudioDownloadsSummary summary) async {
    if (summary.allDownloads.isEmpty) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(AppLocalizations.of(context)!.deleteAllDownloadsQuestion),
        content: Text(
          AppLocalizations.of(context)!.deleteAllDownloadsBody(
            summary.allDownloads.length,
            AudioDownloadService.formatBytes(summary.totalSizeBytes),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.deleteAll),
          ),
        ],
      ),
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
    final ThemeData theme = Theme.of(context);
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
                _buildSummaryCard(theme, summary),
                const SizedBox(height: 16),
                _buildCleanupPreviewCard(theme, summary),
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
    final EquranColors colors = context.equranColors;

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
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasActive)
            TextButton(
              onPressed: _resetAllFilters,
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              IconButton(
                onPressed: () => _showFilterSortSheet(summary, originalGroups),
                icon: const Icon(Icons.filter_list_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                  ),
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(40, 40),
                ),
                tooltip: 'Filter & sort',
              ),
              if (activeCount > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: colors.accentGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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

  Widget _buildSummaryCard(ThemeData theme, AudioDownloadsSummary summary) {
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;
    final double headlineSize = theme.textTheme.headlineMedium?.fontSize ?? 28;

    return EquranGradientCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 120,
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.offline_pin_rounded,
                        color: colors.onPrimary.withAlpha(200),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localizations.offlineAudio.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onPrimary.withAlpha(200),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AudioDownloadService.formatBytes(summary.totalSizeBytes),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: headlineSize + 2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.surahAyahSummary(
                      summary.surahCount,
                      summary.ayahCount,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanupPreviewCard(
    ThemeData theme,
    AudioDownloadsSummary summary,
  ) {
    final EquranColors colors = context.equranColors;
    final bool hasDownloads = summary.allDownloads.isNotEmpty;
    final localizations = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.cleaning_services_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations.cleanupPreview,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CleanupPreviewRow(
              label: localizations.downloadedSurahs,
              value: '${summary.surahCount}',
            ),
            _CleanupPreviewRow(
              label: localizations.downloadedAyahs,
              value: '${summary.ayahCount}',
            ),
            _CleanupPreviewRow(
              label: localizations.potentialSpaceToFree,
              value: AudioDownloadService.formatBytes(summary.totalSizeBytes),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.cleanupDoesNotRemoveData,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                onPressed: hasDownloads ? () => _clearAll(summary) : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(localizations.reviewDeletion),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDownloadsCard() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    return Material(
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.download_done_outlined),
            title: Text(localizations.noDownloadedAudioYet),
            subtitle: Text(
              localizations.downloadedAudioEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    final bool isCollapsed = _collapsedSurahs.contains(group.surah);
    final byReciter = group.entriesByReciter;

    return Material(
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(
            onTap: () => _toggleSurahSection(group.surah),
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(
              localizedSurahName(localizations, group.surah),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${byReciter.length} reciter${byReciter.length == 1 ? '' : 's'}  •  ${AudioDownloadService.formatBytes(group.sizeBytes)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            child: isCollapsed
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Divider(height: 1),
                      ...byReciter.entries.map((reciterEntry) {
                        final reciterCode = reciterEntry.key;
                        final reciterEntries = reciterEntry.value;
                        final reciterSize = reciterEntries.fold<int>(
                          0,
                          (sum, e) => sum + e.sizeBytes,
                        );

                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.record_voice_over_rounded,
                            size: 18,
                          ),
                          title: Text(reciterDisplayName(reciterCode)),
                          subtitle: Text(
                            '${reciterEntries.length} item${reciterEntries.length == 1 ? '' : 's'}  •  ${AudioDownloadService.formatBytes(reciterSize)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            onPressed: () async {
                              // Single confirmation for the whole reciter+surah batch
                              final bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  icon: const Icon(Icons.warning_amber_rounded),
                                  title: const Text('Delete downloads?'),
                                  content: Text(
                                    'Remove all downloads for ${reciterDisplayName(reciterCode)} on ${localizedSurahName(localizations, group.surah)}?',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              for (final e in reciterEntries) {
                                await _deleteEntry(e);
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReciterSection(ReciterDownloadsGroup group) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
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

    return Material(
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(
            onTap: () => _toggleReciterSection(group.reciterCode),
            title: Text(
              reciterDisplayName(group.reciterCode),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${surahs.length} surahs  •  ${group.ayahCount} ayahs  •  ${AudioDownloadService.formatBytes(group.sizeBytes)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 1,
              ),
            ),
            trailing: Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: isCollapsed
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Divider(height: 1),
                      if (surahs.isNotEmpty)
                        _buildGroupHeader(localizations.surahs, surahs.length),
                      ...surahs.map(_buildDownloadTile),
                      if (surahs.isNotEmpty && ayahSurahs.isNotEmpty)
                        const Divider(height: 1),
                      if (ayahSurahs.isNotEmpty)
                        _buildGroupHeader(
                          localizations.ayahs,
                          ayahSectionCount,
                        ),
                      ...ayahSurahs.map(_buildAyahSurahTile),
                    ],
                  ),
          ),
        ],
      ),
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ExpansionTile(
      leading: Icon(
        Icons.folder_outlined,
        color: colorScheme.primary.withAlpha(200),
      ),
      collapsedShape: const Border(),
      shape: const Border(),
      title: Text(
        localizedSurahName(localizations, group.surah),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${group.ayahCount} ayahs  •  ${AudioDownloadService.formatBytes(group.sizeBytes)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 8),
      children: group.entries
          .map((entry) => _buildNestedDownloadTile(entry))
          .toList(growable: false),
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 2),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTile(AudioDownloadEntry entry) {
    return ValueListenableBuilder<ActivePlaybackTrack?>(
      valueListenable: PlaybackCacheService.instance.activeTrackNotifier,
      builder: (context, activeTrack, child) {
        final bool isActiveOffline =
            activeTrack != null &&
            activeTrack.isPlaying &&
            activeTrack.isOffline &&
            activeTrack.surah == entry.surah &&
            activeTrack.reciterCode == entry.reciterCode;

        final ThemeData theme = Theme.of(context);
        final ColorScheme colorScheme = theme.colorScheme;

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: Icon(
            Icons.offline_pin_rounded,
            color: isActiveOffline
                ? Colors.greenAccent
                : colorScheme.primary.withAlpha(180),
            size: 22,
          ),
          title: Text(
            entry.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            entry.subtitle.isNotEmpty
                ? '${entry.subtitle}  •  ${AudioDownloadService.formatBytes(entry.sizeBytes)}'
                : AudioDownloadService.formatBytes(entry.sizeBytes),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: IconButton(
            tooltip: AppLocalizations.of(context)!.deleteDownload,
            onPressed: () => _deleteEntry(entry),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
          ),
        );
      },
    );
  }

  Widget _buildNestedDownloadTile(AudioDownloadEntry entry) {
    return ValueListenableBuilder<ActivePlaybackTrack?>(
      valueListenable: PlaybackCacheService.instance.activeTrackNotifier,
      builder: (context, activeTrack, child) {
        final bool isActiveOffline =
            activeTrack != null &&
            activeTrack.isPlaying &&
            activeTrack.isOffline &&
            activeTrack.surah == entry.surah &&
            activeTrack.reciterCode == entry.reciterCode;

        final ThemeData theme = Theme.of(context);
        final ColorScheme colorScheme = theme.colorScheme;

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 4),
          leading: Icon(
            Icons.music_note_rounded,
            size: 16,
            color: isActiveOffline
                ? Colors.greenAccent
                : colorScheme.onSurfaceVariant.withAlpha(160),
          ),
          title: Text(
            entry.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            AudioDownloadService.formatBytes(entry.sizeBytes),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: IconButton(
            tooltip: AppLocalizations.of(context)!.deleteDownload,
            onPressed: () => _deleteEntry(entry),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
          ),
        );
      },
    );
  }

  Future<void> _showFilterSortSheet(
    AudioDownloadsSummary summary,
    List<ReciterDownloadsGroup> groups,
  ) async {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    String pendingReciter = _selectedReciterFilter;
    String pendingCategory = _selectedCategoryFilter;
    int? pendingSurah = _selectedSurahFilter;
    String pendingType = _selectedTypeFilter;
    String pendingSort = _sortBy;
    String pendingSearch = _searchQuery;
    String pendingGroupBy = _groupBy;

    final Map<String, String> reciterNames = <String, String>{
      'all': localizations.allReciters,
    };
    for (final ReciterDownloadsGroup group in groups) {
      reciterNames[group.reciterCode] = reciterDisplayName(group.reciterCode);
    }
    if (!reciterNames.containsKey(pendingReciter)) pendingReciter = 'all';

    final List<int> downloadedSurahs =
        summary.allDownloads.map((e) => e.surah).toSet().toList()..sort();

    final List<DropdownMenuItem<int?>> surahItems = [
      DropdownMenuItem<int?>(
        value: null,
        child: const Text(
          'All Surahs',
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

    final List<DropdownMenuItem<String>> categoryItems = [
      DropdownMenuItem<String>(
        value: 'all',
        child: const Text('All', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      DropdownMenuItem<String>(
        value: 'makki',
        child: const Text(
          'Makki',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DropdownMenuItem<String>(
        value: 'madani',
        child: const Text(
          'Madani',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    // sortOptions are dynamically built inside the stateful builder based on pendingGroupBy.

    final List<Map<String, String>> typeOptions = <Map<String, String>>[
      {'value': 'all', 'label': 'All'},
      {'value': 'surahs', 'label': 'Surahs'},
      {'value': 'ayahs', 'label': 'Ayahs'},
    ];

    final TextEditingController filterSearchController = TextEditingController(
      text: pendingSearch,
    );

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext sheetContext) {
          return StatefulBuilder(
            builder: (BuildContext _, StateSetter setModalState) {
              final List<Map<String, dynamic>> sortOptions =
                  pendingGroupBy == 'reciter'
                  ? <Map<String, dynamic>>[
                      {
                        'value': 'reciterAsc',
                        'label': 'Reciter (A → Z)',
                        'icon': Icons.sort_by_alpha_rounded,
                      },
                      {
                        'value': 'reciterDesc',
                        'label': 'Reciter (Z → A)',
                        'icon': Icons.sort_by_alpha_rounded,
                      },
                      {
                        'value': 'sizeDesc',
                        'label': 'Size (largest first)',
                        'icon': Icons.storage_rounded,
                      },
                      {
                        'value': 'sizeAsc',
                        'label': 'Size (smallest first)',
                        'icon': Icons.storage_rounded,
                      },
                    ]
                  : <Map<String, dynamic>>[
                      {
                        'value': 'surahAsc',
                        'label': 'Surah (1 → 114)',
                        'icon': Icons.format_list_numbered_rounded,
                      },
                      {
                        'value': 'surahDesc',
                        'label': 'Surah (114 → 1)',
                        'icon': Icons.format_list_numbered_rounded,
                      },
                      {
                        'value': 'sizeDesc',
                        'label': 'Size (largest first)',
                        'icon': Icons.storage_rounded,
                      },
                      {
                        'value': 'sizeAsc',
                        'label': 'Size (smallest first)',
                        'icon': Icons.storage_rounded,
                      },
                    ];
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // === STICKY HEADER ===
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Filter & Sort Downloads',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'More control over which recitations appear in your library',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // === SCROLLABLE MIDDLE ===
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Search
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.medium,
                                  ),
                                  border: Border.all(color: colors.border),
                                ),
                                child: TextField(
                                  controller: filterSearchController,
                                  onChanged: (value) {
                                    setModalState(() {
                                      pendingSearch = value.trim();
                                    });
                                  },
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search recitations or surahs...',
                                    hintStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(color: colors.textMuted),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                    suffixIcon: pendingSearch.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear_rounded,
                                              color: colors.textMuted,
                                              size: 18,
                                            ),
                                            onPressed: () => setModalState(() {
                                              pendingSearch = '';
                                              filterSearchController.clear();
                                            }),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // GROUP BY (Option C+)
                              Text(
                                'Group by',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() {
                                        pendingGroupBy = 'reciter';
                                        if (pendingSort == 'surahAsc' ||
                                            pendingSort == 'surahDesc') {
                                          pendingSort = 'reciterAsc';
                                        }
                                      }),
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.medium,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pendingGroupBy == 'reciter'
                                              ? colors.primary.withAlpha(15)
                                              : colors.surfaceAlt,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.medium,
                                          ),
                                          border: Border.all(
                                            color: pendingGroupBy == 'reciter'
                                                ? colors.primary
                                                : colors.border,
                                            width: pendingGroupBy == 'reciter'
                                                ? 1.5
                                                : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Reciter',
                                            style: TextStyle(
                                              fontWeight:
                                                  pendingGroupBy == 'reciter'
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: pendingGroupBy == 'reciter'
                                                  ? colors.primary
                                                  : colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() {
                                        pendingGroupBy = 'surah';
                                        if (pendingSort == 'reciterAsc' ||
                                            pendingSort == 'reciterDesc') {
                                          pendingSort = 'surahAsc';
                                        }
                                      }),
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.medium,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pendingGroupBy == 'surah'
                                              ? colors.primary.withAlpha(15)
                                              : colors.surfaceAlt,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.medium,
                                          ),
                                          border: Border.all(
                                            color: pendingGroupBy == 'surah'
                                                ? colors.primary
                                                : colors.border,
                                            width: pendingGroupBy == 'surah'
                                                ? 1.5
                                                : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Surah',
                                            style: TextStyle(
                                              fontWeight:
                                                  pendingGroupBy == 'surah'
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: pendingGroupBy == 'surah'
                                                  ? colors.primary
                                                  : colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // SORT
                              Text(
                                'Sort by',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...sortOptions.map<Widget>((opt) {
                                final String val = opt['value'] as String;
                                final bool sel = pendingSort == val;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () =>
                                        setModalState(() => pendingSort = val),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.medium,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? colors.primary.withAlpha(15)
                                            : colors.surfaceAlt,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.medium,
                                        ),
                                        border: Border.all(
                                          color: sel
                                              ? colors.primary
                                              : colors.border,
                                          width: sel ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            opt['icon'] as IconData,
                                            size: 18,
                                            color: sel
                                                ? colors.primary
                                                : colors.textSecondary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              opt['label'] as String,
                                              style: TextStyle(
                                                fontWeight: sel
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: sel
                                                    ? colors.primary
                                                    : colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (sel)
                                            Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                              color: colors.primary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),

                              // RECITER (as Dropdown)
                              Text(
                                'Reciter',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.medium,
                                  ),
                                  border: Border.all(color: colors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: pendingReciter,
                                    isExpanded: true,
                                    dropdownColor: colors.surface,
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: colors.primary,
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setModalState(() {
                                          pendingReciter = value;
                                        });
                                      }
                                    },
                                    items: reciterNames.entries.map((e) {
                                      return DropdownMenuItem<String>(
                                        value: e.key,
                                        child: Text(
                                          e.value,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // SURAH (as Dropdown)
                              Text(
                                'Surah',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.medium,
                                  ),
                                  border: Border.all(color: colors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: pendingSurah,
                                    isExpanded: true,
                                    dropdownColor: colors.surface,
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: colors.primary,
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    onChanged: (value) {
                                      setModalState(() {
                                        pendingSurah = value;
                                      });
                                    },
                                    items: surahItems,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // CATEGORY (as Dropdown)
                              Text(
                                'Category',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.medium,
                                  ),
                                  border: Border.all(color: colors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: pendingCategory,
                                    isExpanded: true,
                                    dropdownColor: colors.surface,
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: colors.primary,
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setModalState(() {
                                          pendingCategory = value;
                                        });
                                      }
                                    },
                                    items: categoryItems,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // CONTENT TYPE
                              Text(
                                'Content type',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: typeOptions.map((o) {
                                  final bool sel = pendingType == o['value'];
                                  final bool isLast = o == typeOptions.last;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: isLast ? 0 : 8,
                                      ),
                                      child: InkWell(
                                        onTap: () => setModalState(
                                          () => pendingType = o['value']!,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.medium,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            color: sel
                                                ? colors.primary.withAlpha(15)
                                                : colors.surfaceAlt,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.medium,
                                            ),
                                            border: Border.all(
                                              color: sel
                                                  ? colors.primary
                                                  : colors.border,
                                              width: sel ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              o['label']!,
                                              style: TextStyle(
                                                fontWeight: sel
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: sel
                                                    ? colors.primary
                                                    : colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // === PINNED FOOTER ===
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Row(
                          children: <Widget>[
                            TextButton(
                              onPressed: () => setModalState(() {
                                pendingReciter = pendingCategory = pendingType =
                                    'all';
                                pendingSurah = null;
                                pendingSort = 'reciterAsc';
                                pendingSearch = '';
                                filterSearchController.clear();
                                pendingGroupBy = 'reciter';
                              }),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedReciterFilter = pendingReciter;
                                  _selectedCategoryFilter = pendingCategory;
                                  _selectedSurahFilter = pendingSurah;
                                  _selectedTypeFilter = pendingType;
                                  _sortBy = pendingSort;
                                  _searchQuery = pendingSearch;
                                  _searchController.text = pendingSearch;
                                  _groupBy = pendingGroupBy;
                                });
                                Navigator.of(sheetContext).pop();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      filterSearchController.dispose();
    }
  }
}

class _CleanupPreviewRow extends StatelessWidget {
  const _CleanupPreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
