import 'package:equran/backend/library.dart'
    show
        DownloadableResource,
        QuranTranslationService,
        ResourceDownloadPhase,
        ResourceDownloadProgress,
        ResourceDownloadService,
        ResourceInstallException,
        ResourceInstallState,
        ResourceInstallStore,
        ResourceManifest,
        ResourceRepository,
        ResourceType,
        SettingsDB,
        prettyBytes,
        getResourceSize;
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/duas/widgets/dua_browser_widgets.dart'
    show DuaSearchField;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/library.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart'
    show RedesignEyebrow;
import 'package:equran/widgets/redesign/pill_tag.dart' show ChipButton;
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:equran/widgets/resource_state_marker.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:equran/word_by_word/word_by_word_download_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' show Translation;

/// Every downloadable resource in one place: browse, search, filter and sort,
/// then download, update, delete, or pick the tafsir and translation in use.
class DownloadableResourcesPage extends StatefulWidget {
  const DownloadableResourcesPage({super.key, this.manifest});

  /// Supplies the manifest directly. Tests use it to avoid the network; the app
  /// leaves it out and loads the manifest from the repository.
  final Future<ResourceManifest>? manifest;

  @override
  State<DownloadableResourcesPage> createState() =>
      _DownloadableResourcesPageState();
}

enum _StatusFilter { all, installed, notDownloaded, updates }

enum _SortOrder { name, sizeLargest, sizeSmallest, installedFirst }

/// The filter, sort and grouping choices shown on the page.
class _ResourceView {
  const _ResourceView({
    this.status = _StatusFilter.all,
    this.type,
    this.sort = _SortOrder.name,
    this.groupByType = true,
  });

  final _StatusFilter status;

  /// Null shows every type.
  final ResourceType? type;
  final _SortOrder sort;
  final bool groupByType;
}

/// Sections are listed in this order when grouped by type. Word-by-word packs
/// are drawn by their own card, so they are not in this list.
const List<ResourceType> _sectionOrder = <ResourceType>[
  ResourceType.translation,
  ResourceType.tafsir,
  ResourceType.quranFonts,
];

class _DownloadableResourcesPageState extends State<DownloadableResourcesPage> {
  late Future<ResourceManifest> _manifestFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _ResourceView _view = const _ResourceView();

  @override
  void initState() {
    super.initState();
    _manifestFuture =
        widget.manifest ?? ResourceRepository.instance.loadManifest();
    _searchController.addListener(() {
      final String query = _searchController.text.trim();
      if (query != _query) setState(() => _query = query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return RedesignSubpage(
      title: l.downloadableResources,
      actions: <Widget>[
        IconButton44(
          icon: Icons.tune_rounded,
          tooltip: l.resourcesFilterTitle,
          onPressed: _openFilterSheet,
        ),
      ],
      child: FutureBuilder<ResourceManifest>(
        future: _manifestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final ResourceManifest? manifest = snapshot.data;
          if (manifest == null || manifest.resources.isEmpty) {
            return _buildUnavailable(l);
          }
          return ValueListenableBuilder<int>(
            valueListenable: ResourceInstallStore.instance.changes,
            builder: (context, _, _) {
              return ValueListenableBuilder<
                Map<String, ResourceDownloadProgress>
              >(
                valueListenable: ResourceDownloadService.instance.downloads,
                builder: (context, downloads, _) {
                  return _buildBody(l, manifest, downloads);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l,
    ResourceManifest manifest,
    Map<String, ResourceDownloadProgress> downloads,
  ) {
    final List<DownloadableResource> visible = _visibleResources(
      manifest,
      downloads,
    );
    final bool showWordByWord =
        !kIsWeb &&
        manifest.resourcesOfType(ResourceType.wordByWord).isNotEmpty &&
        (_view.type == null || _view.type == ResourceType.wordByWord) &&
        _view.status == _StatusFilter.all &&
        _query.isEmpty;

    final List<Widget> rows = <Widget>[];
    if (_view.groupByType) {
      for (final ResourceType type in _sectionOrder) {
        final List<DownloadableResource> group = visible
            .where((resource) => resource.type == type)
            .toList(growable: false);
        if (group.isEmpty) continue;
        rows.add(
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 10),
            child: RedesignEyebrow(_typeLabel(l, type)),
          ),
        );
        rows.addAll(
          _withHairlines(<Widget>[
            for (final DownloadableResource resource in group)
              _buildResourceRow(l, manifest, resource, downloads),
          ]),
        );
      }
    } else {
      rows.addAll(
        _withHairlines(<Widget>[
          for (final DownloadableResource resource in visible)
            _buildResourceRow(l, manifest, resource, downloads),
        ]),
      );
    }

    if (visible.isEmpty && !showWordByWord) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.resourcesNoMatches,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.equranTokens.muted),
          ),
        ),
      );
    }

    if (showWordByWord) {
      rows.add(_buildWordByWordCard(l, manifest, downloads));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: DuaSearchField(controller: _searchController, hint: l.search),
        ),
        ...rows,
        _hairline(context),
        ReaderOptionRow(
          leading: const Icon(Icons.refresh_rounded),
          title: l.refreshManifest,
          subtitle: l.checkGithubReleases,
          onTap: _refreshManifest,
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildUnavailable(AppLocalizations l) {
    return ListView(
      children: <Widget>[
        ReaderOptionRow(
          leading: const Icon(Icons.error_outline_rounded),
          title: l.resourcesUnavailable,
          subtitle: l.resourcesManifestUnavailable,
          onTap: null,
          showChevron: false,
        ),
        _hairline(context),
        ReaderOptionRow(
          leading: const Icon(Icons.refresh_rounded),
          title: l.retry,
          onTap: _refreshManifest,
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildResourceRow(
    AppLocalizations l,
    ResourceManifest manifest,
    DownloadableResource resource,
    Map<String, ResourceDownloadProgress> downloads,
  ) {
    final bool isTafsir = resource.type == ResourceType.tafsir;
    final bool isTranslation = resource.type == ResourceType.translation;
    final bool selected =
        (isTafsir &&
            ResourceInstallStore.instance
                .selectedTafsirResourceIds(manifest)
                .contains(resource.id)) ||
        (isTranslation && selectedTranslationResourceId() == resource.id);
    final ResourceInstallState state = _stateOf(resource, downloads);
    final bool downloading = state == ResourceInstallState.downloading;

    VoidCallback? onTap;
    if (!downloading && isTafsir) {
      onTap = () => _toggleTafsir(manifest, resource, !selected);
    } else if (!downloading && isTranslation) {
      onTap = () => _selectTranslation(manifest, resource);
    }

    return ReaderOptionRow(
      // A check in place of the type icon marks the tafsir or translation in use.
      leading: selected
          ? const DesignIcon('check', strokeWidth: 2)
          : _typeIcon(resource.type),
      title: resource.name,
      subtitle: _resourceSubtitle(l, resource),
      selected: selected,
      showChevron: false,
      onTap: onTap,
      trailing: _buildTrailing(
        l,
        resource,
        state,
        downloads[resource.id]?.fraction,
      ),
    );
  }

  /// Icons only: a status marker for installed content, then the action. The
  /// action icon (download or delete) already says which state a row is in.
  Widget _buildTrailing(
    AppLocalizations l,
    DownloadableResource resource,
    ResourceInstallState state,
    double? progress,
  ) {
    if (state == ResourceInstallState.downloading) {
      return SettingsProgressRing(progress: progress);
    }
    final bool installed = state == ResourceInstallState.installed;
    final bool hasUpdate = state == ResourceInstallState.updateAvailable;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (installed || hasUpdate) ...<Widget>[
          ResourceStateMarker(marker: resourceStateMarker(l, state)),
          const SizedBox(width: 4),
        ],
        if (installed)
          IconButton44(
            tooltip: l.delete,
            onPressed: () => _confirmDelete(resource),
            designIcon: 'trash',
          )
        else
          IconButton44(
            tooltip: hasUpdate ? l.update : l.download,
            onPressed: () => _download(resource),
            designIcon: 'download',
          ),
      ],
    );
  }

  Widget _buildWordByWordCard(
    AppLocalizations l,
    ResourceManifest manifest,
    Map<String, ResourceDownloadProgress> downloads,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: WordByWordDownloadCard(
        title: l.wordByWord,
        description: l.wordByWordDescription,
        downloadTooltip: l.download,
        updateTooltip: l.update,
        deleteTooltip: l.delete,
        rows: <WordByWordPackRow>[
          for (final DownloadableResource resource in manifest.resourcesOfType(
            ResourceType.wordByWord,
          ))
            WordByWordPackRow(
              name: resource.name,
              details: _resourceSubtitle(l, resource),
              state: _stateOf(resource, downloads),
              progress: downloads[resource.id]?.fraction,
              onDownload: () => _download(resource),
              onDelete: () => _confirmDelete(resource),
            ),
        ],
      ),
    );
  }

  List<DownloadableResource> _visibleResources(
    ResourceManifest manifest,
    Map<String, ResourceDownloadProgress> downloads,
  ) {
    final String query = _query.toLowerCase();
    final List<DownloadableResource> filtered =
        <DownloadableResource>[
          ...manifest.resourcesOfType(ResourceType.translation),
          ...manifest.resourcesOfType(ResourceType.tafsir),
          ...quranFontResources(manifest),
        ].where((DownloadableResource resource) {
          if (_view.type != null && resource.type != _view.type) return false;
          if (query.isNotEmpty &&
              !resource.name.toLowerCase().contains(query) &&
              !(resource.language ?? '').toLowerCase().contains(query)) {
            return false;
          }
          final ResourceInstallState state = _stateOf(resource, downloads);
          return switch (_view.status) {
            _StatusFilter.all => true,
            _StatusFilter.installed => state == ResourceInstallState.installed,
            _StatusFilter.notDownloaded =>
              state == ResourceInstallState.notDownloaded,
            _StatusFilter.updates =>
              state == ResourceInstallState.updateAvailable,
          };
        }).toList();
    filtered.sort(_comparatorFor(downloads));
    return filtered;
  }

  Comparator<DownloadableResource> _comparatorFor(
    Map<String, ResourceDownloadProgress> downloads,
  ) {
    int byName(DownloadableResource a, DownloadableResource b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    int bySize(DownloadableResource a, DownloadableResource b, bool largest) {
      final int sizeA = getResourceSize(a) ?? 0;
      final int sizeB = getResourceSize(b) ?? 0;
      final int order = largest
          ? sizeB.compareTo(sizeA)
          : sizeA.compareTo(sizeB);
      return order != 0 ? order : byName(a, b);
    }

    return switch (_view.sort) {
      _SortOrder.name => byName,
      _SortOrder.sizeLargest => (a, b) => bySize(a, b, true),
      _SortOrder.sizeSmallest => (a, b) => bySize(a, b, false),
      _SortOrder.installedFirst => (a, b) {
        final int order = _rank(
          _stateOf(b, downloads),
        ).compareTo(_rank(_stateOf(a, downloads)));
        return order != 0 ? order : byName(a, b);
      },
    };
  }

  Future<void> _openFilterSheet() async {
    final _ResourceView? result = await showReaderSheet<_ResourceView>(
      context: context,
      builder: (BuildContext sheetContext) =>
          _ResourceFilterSheet(initial: _view),
    );
    if (result == null || !mounted) return;
    setState(() => _view = result);
  }

  void _refreshManifest() {
    setState(() {
      _manifestFuture = ResourceRepository.instance.refreshManifest();
    });
  }

  Future<void> _download(DownloadableResource resource) async {
    final bool installed = await downloadResourceWithFeedback(
      context,
      resource,
    );
    if (installed && mounted) setState(() {});
  }

  Future<void> _confirmDelete(DownloadableResource resource) async {
    final bool deleted = await confirmAndDeleteResource(context, resource);
    if (deleted && mounted) setState(() {});
  }

  Future<void> _toggleTafsir(
    ResourceManifest manifest,
    DownloadableResource resource,
    bool selected,
  ) async {
    final ResourceInstallStore store = ResourceInstallStore.instance;
    final Set<String> selectedIds = store
        .selectedTafsirResourceIds(manifest)
        .toSet();
    if (selected) {
      selectedIds.add(resource.id);
    } else {
      selectedIds.remove(resource.id);
    }
    await store.saveSelectedTafsirResourceIds(selectedIds.toList());
    if (mounted) setState(() {});
  }

  Future<void> _selectTranslation(
    ResourceManifest manifest,
    DownloadableResource resource,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final Translation? translation = translationForResource(resource);
    if (translation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.translationUnsupported)));
      return;
    }
    final bool ready = await ensureTranslationReadyForSelection(
      context,
      translation: translation,
      manifest: manifest,
    );
    if (!ready || !mounted) return;
    await SettingsDB().put(
      'translation',
      Translation.values.indexOf(translation),
    );
    await QuranTranslationService.instance.loadInstalledTranslation(
      translation,
    );
    if (mounted) setState(() {});
  }

  String _typeLabel(AppLocalizations l, ResourceType type) {
    return switch (type) {
      ResourceType.translation => l.translations,
      ResourceType.tafsir => l.tafsir,
      ResourceType.quranFonts => l.quranFonts,
      ResourceType.wordByWord => l.wordByWord,
      _ => l.resourceTypeGeneric,
    };
  }

  Widget _typeIcon(ResourceType type) {
    return switch (type) {
      ResourceType.tafsir => const DesignIcon('book'),
      ResourceType.translation => const Icon(Icons.translate_rounded),
      ResourceType.quranFonts => const Icon(Icons.font_download_outlined),
      ResourceType.wordByWord => const Icon(Icons.touch_app_outlined),
      _ => const DesignIcon('headphones'),
    };
  }

  String _resourceSubtitle(AppLocalizations l, DownloadableResource resource) {
    final List<String> parts = <String>[
      if (resource.language != null) resource.language!.toUpperCase(),
      if (resource.reciterCode != null)
        AppReciter.fromCode(
          resource.reciterCode,
        ).displayName(arabic: isArabicLocalizations(l)),
      'v${resource.version}',
      prettyBytes(getResourceSize(resource)),
    ];
    return parts.join(' • ');
  }

  Widget _hairline(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.equranTokens.hair);

  List<Widget> _withHairlines(List<Widget> rows) {
    return <Widget>[
      for (int i = 0; i < rows.length; i++) ...<Widget>[
        if (i > 0) _hairline(context),
        rows[i],
      ],
    ];
  }
}

/// Filter, sort and grouping for [DownloadableResourcesPage]. The choices are
/// returned only when the user taps Apply.
class _ResourceFilterSheet extends StatefulWidget {
  const _ResourceFilterSheet({required this.initial});

  final _ResourceView initial;

  @override
  State<_ResourceFilterSheet> createState() => _ResourceFilterSheetState();
}

class _ResourceFilterSheetState extends State<_ResourceFilterSheet> {
  late _StatusFilter _status = widget.initial.status;
  late ResourceType? _type = widget.initial.type;
  late _SortOrder _sort = widget.initial.sort;
  late bool _groupByType = widget.initial.groupByType;

  void _reset() {
    setState(() {
      _status = _StatusFilter.all;
      _type = null;
      _sort = _SortOrder.name;
      _groupByType = true;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _ResourceView(
        status: _status,
        type: _type,
        sort: _sort,
        groupByType: _groupByType,
      ),
    );
  }

  Widget _choices<T>(
    List<(T, String)> options,
    T selected,
    ValueChanged<T> onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (T value, String label) in options)
          ChipButton(
            label,
            selected: value == selected,
            designIcon: value == selected ? 'check' : null,
            onPressed: () => onSelected(value),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: ReaderSheetFrame(
              title: l.resourcesFilterTitle,
              bottomInset: 0,
              children: <Widget>[
                ReaderFieldLabel(l.downloadsSortBy),
                _choices<_SortOrder>(
                  <(_SortOrder, String)>[
                    (_SortOrder.name, l.resourceSortName),
                    (_SortOrder.sizeLargest, l.downloadsSortSizeDesc),
                    (_SortOrder.sizeSmallest, l.downloadsSortSizeAsc),
                    (_SortOrder.installedFirst, l.resourceSortInstalledFirst),
                  ],
                  _sort,
                  (value) => setState(() => _sort = value),
                ),
                const SizedBox(height: 22),
                ReaderFieldLabel(l.resourceFilterStatus),
                _choices<_StatusFilter>(
                  <(_StatusFilter, String)>[
                    (_StatusFilter.all, l.all),
                    (_StatusFilter.installed, l.installed),
                    (_StatusFilter.notDownloaded, l.notDownloaded),
                    (_StatusFilter.updates, l.resourceStateUpdateAvailable),
                  ],
                  _status,
                  (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 22),
                ReaderFieldLabel(l.resourceFilterType),
                _choices<ResourceType?>(
                  <(ResourceType?, String)>[
                    (null, l.all),
                    (ResourceType.translation, l.translations),
                    (ResourceType.tafsir, l.tafsir),
                    (ResourceType.quranFonts, l.quranFonts),
                    if (!kIsWeb) (ResourceType.wordByWord, l.wordByWord),
                  ],
                  _type,
                  (value) => setState(() => _type = value),
                ),
                const SizedBox(height: 22),
                ReaderFieldLabel(l.downloadsGroupBy),
                _choices<bool>(
                  <(bool, String)>[
                    (true, l.resourceViewByType),
                    (false, l.resourceViewNone),
                  ],
                  _groupByType,
                  (value) => setState(() => _groupByType = value),
                ),
              ],
            ),
          ),
          // Pinned below the scrolling options, so Apply is always reachable.
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.equranTokens.hair)),
            ),
            child: SafeArea(
              top: false,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  TextButton(
                    style: readerTextButtonStyle(context),
                    onPressed: _reset,
                    child: Text(l.reset),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton(
                        style: readerTextButtonStyle(context),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: readerFilledButtonStyle(context),
                        onPressed: _apply,
                        child: Text(l.apply),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int _rank(ResourceInstallState state) => switch (state) {
  ResourceInstallState.installed => 3,
  ResourceInstallState.updateAvailable => 2,
  ResourceInstallState.downloading => 1,
  ResourceInstallState.notDownloaded => 0,
};

ResourceInstallState _stateOf(
  DownloadableResource resource,
  Map<String, ResourceDownloadProgress> downloads,
) {
  final ResourceDownloadProgress? progress = downloads[resource.id];
  if (progress != null &&
      progress.phase != ResourceDownloadPhase.complete &&
      progress.phase != ResourceDownloadPhase.failed) {
    return ResourceInstallState.downloading;
  }
  return ResourceInstallStore.instance.installStateFor(resource);
}

/// The Quran font pack, always listed even when the manifest leaves it out.
List<DownloadableResource> quranFontResources(ResourceManifest manifest) {
  final List<DownloadableResource> resources = manifest.resourcesOfType(
    ResourceType.quranFonts,
  );
  if (resources.any(
    (resource) => resource.id == QpcV4FontService.tajweedFontsResource.id,
  )) {
    return resources;
  }
  return <DownloadableResource>[
    QpcV4FontService.tajweedFontsResource,
    ...resources,
  ];
}

/// The translation id saved in settings, or null when it is built in or unset.
String? selectedTranslationResourceId() {
  final dynamic saved = SettingsDB().get('translation', defaultValue: 0);
  if (saved is! int ||
      saved < 0 ||
      saved >= Translation.values.length ||
      Translation.values[saved].isBundled) {
    return null;
  }
  return Translation.values[saved].resourceId;
}

Translation? translationForResource(DownloadableResource resource) {
  for (final Translation translation in Translation.values) {
    if (translation.resourceId == resource.id) return translation;
  }
  return null;
}

/// Downloads and installs one resource, showing the result as a snackbar.
/// Returns true when it is installed.
Future<bool> downloadResourceWithFeedback(
  BuildContext context,
  DownloadableResource resource,
) async {
  try {
    await ResourceDownloadService.instance.downloadAndInstall(resource);
    if (resource.id == QpcV4FontService.tajweedFontsResource.id) {
      QpcV4FontService.instance.clearCache();
    }
    await QuranTranslationService.instance.loadInstalledTranslationForResource(
      resource,
    );
    if (!context.mounted) return false;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.installedResource(resource.name))),
    );
    return true;
  } on ResourceInstallException catch (error) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
    return false;
  } catch (_) {
    if (!context.mounted) return false;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.unableInstallResource)),
    );
    return false;
  }
}

/// Asks before deleting. Returns true when the resource was removed.
Future<bool> confirmAndDeleteResource(
  BuildContext context,
  DownloadableResource resource,
) async {
  final bool? confirmed = await showReaderDialog<bool>(
    context: context,
    builder: (context) {
      final AppLocalizations l = AppLocalizations.of(context)!;
      return ReaderConfirmDialog(
        title: l.deleteResourceQuestion(resource.name),
        body: l.deleteResourceBody,
        icon: const DesignIcon('trash'),
        cancelLabel: l.cancel,
        confirmLabel: l.delete,
        destructive: true,
      );
    },
  );
  if (confirmed != true) return false;
  await ResourceDownloadService.instance.uninstall(resource);
  if (resource.id == QpcV4FontService.tajweedFontsResource.id) {
    QpcV4FontService.instance.clearCache();
    if (SettingsDB().quranScriptStyle == 'qpc-v4') {
      await SettingsDB().setQuranScriptStyle('qpc-hafs');
    }
  }
  if (!context.mounted) return true;
  final AppLocalizations localizations = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(localizations.deletedResource(resource.name))),
  );
  return true;
}

/// Makes sure the Quran font pack is installed before the script style that
/// needs it is chosen. Asks first, then downloads.
Future<bool> ensureQpcV4FontsReady(
  BuildContext context,
  Future<ResourceManifest> manifestFuture,
) async {
  if (await QpcV4FontService.instance.hasAllPageFonts()) return true;
  if (!context.mounted) return false;

  final DownloadableResource resource = await _qpcV4FontsResource(
    manifestFuture,
  );
  if (!context.mounted) return false;
  final int? size = getResourceSize(resource);
  final String sizeLabel = size == null ? '' : ' (${prettyBytes(size)})';
  final AppLocalizations localizations = AppLocalizations.of(context)!;
  final bool? download = await showReaderDialog<bool>(
    context: context,
    builder: (context) => ReaderConfirmDialog(
      title: localizations.downloadQpcFontsTitle,
      body: localizations.downloadQpcFontsBody(sizeLabel),
      icon: const DesignIcon('download'),
      cancelLabel: localizations.cancel,
      confirmLabel: localizations.download,
    ),
  );
  if (download != true) return false;

  if (!context.mounted) return false;
  final bool installed = await downloadResourceWithFeedback(context, resource);
  if (!installed) return false;
  QpcV4FontService.instance.clearCache();

  final bool ready = await QpcV4FontService.instance.hasAllPageFonts();
  if (!ready && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.qpcFontsDownloadError)),
    );
  }
  return ready;
}

Future<DownloadableResource> _qpcV4FontsResource(
  Future<ResourceManifest> manifestFuture,
) async {
  try {
    final ResourceManifest manifest = await manifestFuture;
    return manifest.resourceById(QpcV4FontService.tajweedFontsResource.id) ??
        QpcV4FontService.tajweedFontsResource;
  } catch (_) {
    return QpcV4FontService.tajweedFontsResource;
  }
}

/// Asks to download a translation that is not installed yet. Returns true when
/// it is ready to use.
Future<bool> ensureTranslationReadyForSelection(
  BuildContext context, {
  required Translation translation,
  required ResourceManifest manifest,
}) async {
  if (translation.isBundled) return true;

  final DownloadableResource? resource = QuranTranslationService.instance
      .resourceForTranslation(translation, manifest);
  if (resource == null) {
    if (!context.mounted) return false;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.translationNotInManifest)),
    );
    return false;
  }

  if (ResourceInstallStore.instance.isInstalled(resource)) return true;

  final bool? download = await showReaderDialog<bool>(
    context: context,
    builder: (context) {
      final AppLocalizations l = AppLocalizations.of(context)!;
      return ReaderConfirmDialog(
        title: l.downloadTranslationQuestion(
          translationDisplayName(translation),
        ),
        body: l.translationNotInstalled(prettyBytes(getResourceSize(resource))),
        icon: const DesignIcon('download'),
        cancelLabel: l.cancel,
        confirmLabel: l.download,
      );
    },
  );
  if (download != true) return false;
  if (!context.mounted) return false;
  return downloadResourceWithFeedback(context, resource);
}
