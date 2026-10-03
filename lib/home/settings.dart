import 'package:adaptive_theme/adaptive_theme.dart';
import 'appearance_settings_page.dart';
import 'navigation_settings_page.dart';
import 'package:equran/backend/library.dart'
    show
        BookmarkDB,
        DuaInteractionsDB,
        FavouritesDB,
        QuranActivityDB,
        QuranBookmarkFoldersDB,
        QuranBookmarksDB,
        QuranStatsDB,
        QuranTranslationService,
        ResumeStateDB,
        DownloadableResource,
        ResourceDownloadPhase,
        ResourceDownloadProgress,
        ResourceDownloadService,
        ResourceInstallException,
        ResourceInstallState,
        ResourceInstallStore,
        ResourceManifest,
        ResourceRepository,
        ResourceType,
        RoutineDayProgressDB,
        SettingsDB,
        prettyBytes,
        getResourceSize;
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/backend/backup_service.dart';
import 'package:equran/prayer/prayer_times_settings_page.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/library.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/library.dart'
    show
        AppSelectionDialog,
        AppSelectionOption,
        FontSlider,
        PlayBackSlider,
        SettingsSwitch;
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/home_dashboard/daily_tools_edit_sheet.dart';
import 'package:equran/main.dart' show MyApp;
import 'package:quran/quran.dart' show Translation, isTranslationLoaded;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<ResourceManifest> _resourceManifestFuture;

  @override
  void initState() {
    super.initState();
    _resourceManifestFuture = ResourceRepository.instance.loadManifest();
  }

  @override
  Widget build(BuildContext context) {
    final bool cardViewEnabled = SettingsDB().get(
      "viewMode",
      defaultValue: true,
    );
    final bool translationEnabled = SettingsDB().get(
      "enableTranslation",
      defaultValue: true,
    );
    final bool showTranslationControls = cardViewEnabled && translationEnabled;
    final localizations = AppLocalizations.of(context)!;

    return Material(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: <Widget>[
          _buildSettingsGroup(
            context: context,
            title: localizations.general,
            subtitle: localizations.generalSubtitle,
            icon: Icons.tune_rounded,
            initiallyExpanded: true,
            children: <Widget>[
              _buildLanguageTile(context),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: Text(localizations.prayerTimesSettings),
                subtitle: Text(localizations.prayerTimesSettingsSubtitle),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const PrayerTimesSettingsPage(),
                  ),
                ),
              ),
              SettingsSwitch(
                leading: const Icon(Icons.vibration_rounded),
                title: localizations.vibration,
                subtitle: localizations.vibrationSubtitle,
                settingsKey: "vibration",
              ),
            ],
          ),
          _buildSettingsGroup(
            context: context,
            title: localizations.appearance,
            subtitle: localizations.appearanceSubtitle,
            icon: Icons.palette_rounded,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: Text(localizations.appearance),
                subtitle: Text(localizations.appearanceTileSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AppearanceSettingsPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.linear_scale_rounded),
                title: Text(localizations.customizeNavigation),
                subtitle: Text(localizations.navigationSettingsSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const NavigationSettingsPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: Text(
                  DailyToolsEditSheet.translateCustomizeTitle(
                    localizations.localeName.toLowerCase(),
                  ),
                ),
                subtitle: Text(
                  DailyToolsEditSheet.translateCustomizeDesc(
                    localizations.localeName.toLowerCase(),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => DailyToolsEditSheet.show(context),
              ),
              SettingsSwitch(
                leading: const Icon(Icons.history_rounded),
                title: localizations.showReadingHistory,
                settingsKey: "showLastRead",
                subtitle: localizations.showReadingHistorySubtitle,
              ),
            ],
          ),
          _buildSettingsGroup(
            context: context,
            title: localizations.reading,
            subtitle: localizations.readingSubtitle,
            icon: Icons.menu_book_rounded,
            initiallyExpanded: true,
            children: <Widget>[
              SettingsSwitch(
                leading: const Icon(Icons.view_day_rounded),
                title: localizations.cardView,
                subtitle: localizations.cardViewSubtitle,
                settingsKey: "viewMode",
                onChanged: (_) => setState(() {}),
              ),
              if (cardViewEnabled)
                SettingsSwitch(
                  leading: const Icon(Icons.subtitles_rounded),
                  title: localizations.displayTranslation,
                  subtitle: localizations.displayTranslationSubtitle,
                  settingsKey: "enableTranslation",
                  onChanged: (_) => setState(() {}),
                  defaultValue: true,
                ),
              if (cardViewEnabled) _buildTransliterationToggle(context),
              _buildDailyQuranGoalTile(context),
              _buildTranslationTile(context),
              _buildScriptStyleTile(context),
              FontSlider(showTranslationControls: showTranslationControls),
            ],
          ),
          _buildSettingsGroup(
            context: context,
            title: localizations.audio,
            subtitle: localizations.audioSubtitle,
            icon: Icons.graphic_eq_rounded,
            children: <Widget>[
              _buildReciterTile(context),
              const PlayBackSlider(),
            ],
          ),
          _buildSettingsGroup(
            context: context,
            title: localizations.downloadableResources,
            subtitle: localizations.downloadableResourcesSubtitle,
            icon: Icons.cloud_download_outlined,
            children: <Widget>[_buildDownloadableResourcesSection(context)],
          ),
          _buildSettingsGroup(
            context: context,
            title: localizations.data,
            subtitle: localizations.dataSubtitle,
            icon: Icons.storage_rounded,
            children: <Widget>[
              _buildBackupDataTile(context),
              _buildRestoreDataTile(context),
              _buildClearReadingHistoryTile(context),
              _buildClearFavouritesTile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(AppRadii.medium);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: radius,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildScriptStyleTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final String currentStyle = SettingsDB().quranScriptStyle;
    final String label = currentStyle == 'indopak'
        ? localizations.indoPak
        : currentStyle == 'qpc-v4'
        ? localizations.qpcV4Tajweed
        : localizations.uthmaniMadinah;

    return ListTile(
      leading: const Icon(Icons.font_download_outlined),
      title: Text(localizations.quranScriptStyle),
      subtitle: Text(label),
      onTap: () async {
        final String? value = await _showSelectionDialog<String>(
          context: context,
          title: localizations.quranScriptStyle,
          icon: Icons.font_download_outlined,
          selectedValue: currentStyle,
          options: <AppSelectionOption<String>>[
            AppSelectionOption<String>(
              value: 'qpc-hafs',
              title: localizations.uthmaniMadinah,
            ),
            AppSelectionOption<String>(
              value: 'indopak',
              title: localizations.indoPak,
            ),
            AppSelectionOption<String>(
              value: 'qpc-v4',
              title: localizations.qpcV4Tajweed,
            ),
          ],
        );
        if (value == null) return;
        if (value == 'qpc-v4') {
          final bool ready = await _ensureQpcV4FontsReady();
          if (!ready) return;
          await QpcV4FontService.instance.ensureFontLoadedForPage(1);
        }
        await SettingsDB().setQuranScriptStyle(value);
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildTranslationTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.g_translate_rounded),
      title: Text(localizations.translation),
      subtitle: Text(_selectedTranslationName(localizations)),
      onTap: () async {
        final ResourceManifest manifest = await _resourceManifestFuture;
        if (!context.mounted) return;
        final int selected = SettingsDB().get("translation", defaultValue: 0);
        final int? value = await _showSelectionDialog<int>(
          context: context,
          title: localizations.translationLanguage,
          icon: Icons.translate_rounded,
          selectedValue: selected,
          options:
              Translation.values
                  .asMap()
                  .entries
                  .map(
                    (entry) => AppSelectionOption<int>(
                      value: entry.key,
                      title:
                          '${translationDisplayName(entry.value)} • '
                          '${QuranTranslationService.instance.availabilityLabel(entry.value, manifest)}',
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.title.compareTo(b.title)),
        );
        if (value == null) return;
        final Translation translation = Translation.values[value];
        final bool ready = await _ensureTranslationReadyForSelection(
          translation: translation,
          manifest: manifest,
        );
        if (!ready) return;
        await SettingsDB().put("translation", value);
        await QuranTranslationService.instance.loadInstalledTranslation(
          translation,
        );
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<T?> _showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required IconData icon,
    required T selectedValue,
    required List<AppSelectionOption<T>> options,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AppSelectionDialog<T>(
        title: title,
        icon: icon,
        selectedValue: selectedValue,
        options: options,
      ),
    );
  }

  Widget _buildTransliterationToggle(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SettingsSwitch(
      leading: const Icon(Icons.abc_rounded),
      title: localizations.displayTransliteration,
      subtitle: localizations.displayTransliterationSubtitle,
      settingsKey: "showTransliteration",
      defaultValue: false,
    );
  }

  Widget _buildReciterTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.record_voice_over_rounded),
      title: Text(localizations.reciter),
      subtitle: Text(_selectedReciterName()),
      onTap: () async {
        final List<AppReciter> items = AppReciter.values.toList()
          ..sort(
            (a, b) => a.englishName.toLowerCase().compareTo(
              b.englishName.toLowerCase(),
            ),
          );
        final selected = SettingsDB().get("reciter", defaultValue: "1");
        final selectedReciter = AppReciter.fromCode(selected);
        final AppReciter? value = await _showSelectionDialog<AppReciter>(
          context: context,
          title: localizations.reciter,
          icon: Icons.record_voice_over_rounded,
          selectedValue: selectedReciter,
          options: items
              .map(
                (reciter) => AppSelectionOption<AppReciter>(
                  value: reciter,
                  title: reciter.displayName(
                    arabic: isArabicLocalizations(localizations),
                  ),
                ),
              )
              .toList(),
        );
        if (value == null) return;
        SettingsDB().put("reciter", value.code);
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildDownloadableResourcesSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return FutureBuilder<ResourceManifest>(
      future: _resourceManifestFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final ResourceManifest? manifest = snapshot.data;
        if (manifest == null || manifest.resources.isEmpty) {
          return Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.error_outline_rounded),
                title: Text(localizations.resourcesUnavailable),
                subtitle: Text(localizations.resourcesManifestUnavailable),
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(localizations.retry),
                onTap: _refreshResourceManifest,
              ),
            ],
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: ResourceInstallStore.instance.changes,
          builder: (context, _, _) {
            return ValueListenableBuilder<
              Map<String, ResourceDownloadProgress>
            >(
              valueListenable: ResourceDownloadService.instance.downloads,
              builder: (context, downloads, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildResourceSubsection(
                      context: context,
                      manifest: manifest,
                      title: localizations.tafsir,
                      resources: manifest.resourcesOfType(ResourceType.tafsir),
                      downloads: downloads,
                    ),
                    _buildResourceSubsection(
                      context: context,
                      manifest: manifest,
                      title: localizations.quranFonts,
                      resources: _quranFontResources(manifest),
                      downloads: downloads,
                    ),
                    _buildResourceSubsection(
                      context: context,
                      manifest: manifest,
                      title: localizations.translations,
                      resources: manifest.resourcesOfType(
                        ResourceType.translation,
                      ),
                      downloads: downloads,
                    ),
                    if (manifest
                        .resourcesOfType(ResourceType.wordByWord)
                        .isNotEmpty)
                      _buildResourceSubsection(
                        context: context,
                        manifest: manifest,
                        title: localizations.wordByWord,
                        description: localizations.wordByWordDescription,
                        resources: manifest.resourcesOfType(
                          ResourceType.wordByWord,
                        ),
                        downloads: downloads,
                      ),
                    ListTile(
                      leading: const Icon(Icons.refresh_rounded),
                      title: Text(localizations.refreshManifest),
                      subtitle: Text(localizations.checkGithubReleases),
                      onTap: _refreshResourceManifest,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildResourceSubsection({
    required BuildContext context,
    required ResourceManifest manifest,
    required String title,
    required List<DownloadableResource> resources,
    required Map<String, ResourceDownloadProgress> downloads,
    String? description,
  }) {
    if (resources.isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return ListTile(
        leading: const Icon(Icons.cloud_off_rounded),
        title: Text(title),
        subtitle: Text(localizations.noResourcesListed),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final DownloadableResource resource in resources)
          _buildResourceTile(
            context: context,
            manifest: manifest,
            resource: resource,
            progress: downloads[resource.id],
          ),
      ],
    );
  }

  Widget _buildResourceTile({
    required BuildContext context,
    required ResourceManifest manifest,
    required DownloadableResource resource,
    required ResourceDownloadProgress? progress,
  }) {
    final ResourceInstallStore store = ResourceInstallStore.instance;
    final bool isTafsir = resource.type == ResourceType.tafsir;
    final bool isTranslation = resource.type == ResourceType.translation;
    final bool isQuranFonts = resource.type == ResourceType.quranFonts;
    final bool isWordByWord = resource.type == ResourceType.wordByWord;
    final bool selected =
        (isTafsir &&
            store.selectedTafsirResourceIds(manifest).contains(resource.id)) ||
        (isTranslation && _selectedTranslationResourceId() == resource.id);
    final ResourceInstallState installState =
        progress != null &&
            progress.phase != ResourceDownloadPhase.complete &&
            progress.phase != ResourceDownloadPhase.failed
        ? ResourceInstallState.downloading
        : store.installStateFor(resource);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String status = selected
        ? '${installState.label} • ${localizations.selected}'
        : installState.label;

    return ListTile(
      leading: isTafsir
          ? Checkbox(
              value: selected,
              onChanged: (value) => _toggleTafsirSelection(
                manifest: manifest,
                resource: resource,
                selected: value == true,
              ),
            )
          : Icon(
              isTranslation
                  ? selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.translate_rounded
                  : isQuranFonts
                  ? Icons.font_download_outlined
                  : isWordByWord
                  ? Icons.touch_app_outlined
                  : Icons.graphic_eq_rounded,
            ),
      title: Text(resource.name),
      subtitle: Text('${_resourceSubtitle(resource)} • $status'),
      trailing: _buildResourceAction(resource, installState, progress),
      onTap: isTafsir
          ? () => _toggleTafsirSelection(
              manifest: manifest,
              resource: resource,
              selected: !selected,
            )
          : isTranslation
          ? () => _selectTranslationResource(
              manifest: manifest,
              resource: resource,
            )
          : null,
    );
  }

  Widget _buildResourceAction(
    DownloadableResource resource,
    ResourceInstallState state,
    ResourceDownloadProgress? progress,
  ) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (state == ResourceInstallState.downloading) {
      final double? fraction = progress?.fraction;
      return SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(strokeWidth: 2.4, value: fraction),
      );
    }

    if (state == ResourceInstallState.installed) {
      return IconButton(
        tooltip: localizations.delete,
        onPressed: () => _confirmDeleteResource(resource),
        icon: const Icon(Icons.delete_outline_rounded),
      );
    }

    return IconButton(
      tooltip: state == ResourceInstallState.updateAvailable
          ? localizations.update
          : localizations.download,
      onPressed: () => _downloadResource(resource),
      icon: Icon(
        state == ResourceInstallState.updateAvailable
            ? Icons.system_update_alt_rounded
            : Icons.download_rounded,
      ),
    );
  }

  String _resourceSubtitle(DownloadableResource resource) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<String> parts = <String>[
      if (resource.language != null) resource.language!.toUpperCase(),
      if (resource.reciterCode != null)
        AppReciter.fromCode(
          resource.reciterCode,
        ).displayName(arabic: isArabicLocalizations(localizations)),
      'v${resource.version}',
      prettyBytes(getResourceSize(resource)),
    ];
    return parts.join(' • ');
  }

  List<DownloadableResource> _quranFontResources(ResourceManifest manifest) {
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

  Future<bool> _ensureQpcV4FontsReady() async {
    if (await QpcV4FontService.instance.hasAllPageFonts()) return true;

    if (!mounted) return false;
    final DownloadableResource resource = await _qpcV4FontsResource();
    if (!mounted) return false;
    final int? size = getResourceSize(resource);
    final String sizeLabel = size == null ? '' : ' (${prettyBytes(size)})';
    final localizations = AppLocalizations.of(context)!;
    final bool? download = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.downloadQpcFontsTitle),
        content: Text(localizations.downloadQpcFontsBody(sizeLabel)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.download_rounded),
            label: Text(localizations.download),
          ),
        ],
      ),
    );
    if (download != true) return false;

    final bool installed = await _downloadResource(resource);
    if (!installed) return false;
    QpcV4FontService.instance.clearCache();

    final bool ready = await QpcV4FontService.instance.hasAllPageFonts();
    if (!ready && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.qpcFontsDownloadError)),
      );
    }
    return ready;
  }

  Future<DownloadableResource> _qpcV4FontsResource() async {
    try {
      final ResourceManifest manifest = await _resourceManifestFuture;
      return manifest.resourceById(QpcV4FontService.tajweedFontsResource.id) ??
          QpcV4FontService.tajweedFontsResource;
    } catch (_) {
      return QpcV4FontService.tajweedFontsResource;
    }
  }

  Future<void> _toggleTafsirSelection({
    required ResourceManifest manifest,
    required DownloadableResource resource,
    required bool selected,
  }) async {
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

  String? _selectedTranslationResourceId() {
    final dynamic saved = SettingsDB().get('translation', defaultValue: 0);
    if (saved is! int ||
        saved < 0 ||
        saved >= Translation.values.length ||
        Translation.values[saved].isBundled) {
      return null;
    }
    return Translation.values[saved].resourceId;
  }

  Future<void> _selectTranslationResource({
    required ResourceManifest manifest,
    required DownloadableResource resource,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final Translation? translation = _translationForResource(resource);
    if (translation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translationUnsupported)),
      );
      return;
    }

    final bool ready = await _ensureTranslationReadyForSelection(
      translation: translation,
      manifest: manifest,
    );
    if (!ready) return;

    await SettingsDB().put(
      'translation',
      Translation.values.indexOf(translation),
    );
    await QuranTranslationService.instance.loadInstalledTranslation(
      translation,
    );
    if (mounted) setState(() {});
  }

  Future<bool> _ensureTranslationReadyForSelection({
    required Translation translation,
    required ResourceManifest manifest,
  }) async {
    if (translation.isBundled) return true;

    final DownloadableResource? resource = QuranTranslationService.instance
        .resourceForTranslation(translation, manifest);
    if (resource == null) {
      if (!mounted) return false;
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translationNotInManifest)),
      );
      return false;
    }

    if (ResourceInstallStore.instance.isInstalled(resource)) return true;

    final bool? download = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(
            context,
          )!.downloadTranslationQuestion(translationDisplayName(translation)),
        ),
        content: Text(
          AppLocalizations.of(
            context,
          )!.translationNotInstalled(prettyBytes(getResourceSize(resource))),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.download_rounded),
            label: Text(AppLocalizations.of(context)!.download),
          ),
        ],
      ),
    );
    if (download != true) return false;
    return _downloadResource(resource);
  }

  Translation? _translationForResource(DownloadableResource resource) {
    for (final Translation translation in Translation.values) {
      if (translation.resourceId == resource.id) return translation;
    }
    return null;
  }

  Future<bool> _downloadResource(DownloadableResource resource) async {
    try {
      await ResourceDownloadService.instance.downloadAndInstall(resource);
      if (resource.id == QpcV4FontService.tajweedFontsResource.id) {
        QpcV4FontService.instance.clearCache();
      }
      await QuranTranslationService.instance
          .loadInstalledTranslationForResource(resource);
      if (!mounted) return false;
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.installedResource(resource.name))),
      );
      setState(() {});
      return true;
    } on ResourceInstallException catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return false;
    } catch (_) {
      if (!mounted) return false;
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.unableInstallResource)),
      );
      return false;
    }
  }

  Future<void> _confirmDeleteResource(DownloadableResource resource) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteResourceQuestion(resource.name),
        ),
        content: Text(AppLocalizations.of(context)!.deleteResourceBody),
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
    if (confirmed != true) return;
    await ResourceDownloadService.instance.uninstall(resource);
    if (resource.id == QpcV4FontService.tajweedFontsResource.id) {
      QpcV4FontService.instance.clearCache();
      if (SettingsDB().quranScriptStyle == 'qpc-v4') {
        await SettingsDB().setQuranScriptStyle('qpc-hafs');
      }
    }
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.deletedResource(resource.name))),
    );
    setState(() {});
  }

  void _refreshResourceManifest() {
    setState(() {
      _resourceManifestFuture = ResourceRepository.instance.refreshManifest();
    });
  }

  Widget _buildDailyQuranGoalTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final int goal = _dailyQuranGoalAyahs();
    return ListTile(
      leading: const Icon(Icons.flag_rounded),
      title: Text(localizations.dailyQuranGoal),
      subtitle: Text(localizations.dailyQuranGoalSubtitle(goal)),
      onTap: () async {
        final int? value = await _showDailyGoalDialog(context, goal);
        if (value == null) return;
        await SettingsDB().put("dailyQuranGoalAyahs", value);
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<int?> _showDailyGoalDialog(BuildContext context, int initialGoal) {
    final TextEditingController controller = TextEditingController(
      text: initialGoal.toString(),
    );
    String? errorText;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final localizations = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(localizations.dailyQuranGoal),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: localizations.ayahsPerDay,
                  hintText: '20',
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(localizations.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final int? value = int.tryParse(controller.text.trim());
                    if (value == null || value < 1 || value > 1000) {
                      setDialogState(() {
                        errorText = localizations.enterGoalRange;
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Text(localizations.save),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Widget _buildClearReadingHistoryTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.delete_sweep_rounded),
      title: Text(localizations.clearReadingHistory),
      subtitle: Text(localizations.clearReadingHistorySubtitle),
      onTap: () => _showClearDataDialog(
        context: context,
        title: localizations.clearReadingHistory,
        message: localizations.clearReadingHistoryWarning,
        onConfirm: _clearReadingHistory,
      ),
    );
  }

  Widget _buildBackupDataTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.backup_rounded),
      title: Text(localizations.backupData),
      subtitle: Text(localizations.backupDataSubtitle),
      onTap: () async {
        try {
          final String? outputPath = await BackupService.exportBackupFile();
          if (!context.mounted) return;
          _showMessage(
            context,
            outputPath == null
                ? localizations.backupReadyToShare
                : localizations.backupSavedTo(outputPath),
          );
        } on AppBackupException catch (error) {
          if (error.message != 'Backup cancelled.') {
            _showMessage(context, error.message);
          }
        } catch (_) {
          _showMessage(context, localizations.unableCreateBackup);
        }
      },
    );
  }

  Widget _buildRestoreDataTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.settings_backup_restore_rounded),
      title: Text(localizations.restoreData),
      subtitle: Text(localizations.restoreDataSubtitle),
      onTap: () async {
        final bool shouldRestore = await _showRestoreConfirmation(context);
        if (!shouldRestore || !context.mounted) return;

        try {
          final BackupRestoreResult result =
              await BackupService.restoreFromPickedFile();
          if (!context.mounted) return;
          await _applyRestoredTheme(context);
          if (!context.mounted) return;
          setState(() {});
          _showMessage(
            context,
            localizations.restoredBackupSummary(
              result.favouritesCount,
              result.readingHistoryCount,
              result.settingsCount,
            ),
          );
        } on AppBackupException catch (error) {
          if (error.message != 'Restore cancelled.' && context.mounted) {
            _showMessage(context, error.message);
          }
        } catch (_) {
          if (context.mounted) {
            _showMessage(context, localizations.unableRestoreBackup);
          }
        }
      },
    );
  }

  Widget _buildClearFavouritesTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.delete_forever_rounded),
      title: Text(localizations.clearFavourites),
      subtitle: Text(localizations.clearFavouritesSubtitle),
      onTap: () => _showClearDataDialog(
        context: context,
        title: localizations.clearFavourites,
        message: localizations.clearFavouritesWarning,
        onConfirm: _clearSavedAyahLibrary,
      ),
    );
  }

  Future<void> _clearReadingHistory() async {
    await BookmarkDB().clear();
    await ResumeStateDB().clear();
    await QuranActivityDB().clear();
    await QuranStatsDB().clear();
    await DuaInteractionsDB().clear();
    await RoutineDayProgressDB().clear();
  }

  Future<void> _clearSavedAyahLibrary() async {
    await FavouritesDB().clear();
    await QuranBookmarksDB().clear();
    await QuranBookmarkFoldersDB().clear();
  }

  void _showClearDataDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    final localizations = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        icon: const Icon(Icons.warning_amber_rounded),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localizations.no,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await onConfirm();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              localizations.yes,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyRestoredTheme(BuildContext context) async {
    final MaterialColor color = _savedMaterialColor();
    final String themeScheme = _selectedThemeScheme();
    final dynamic themeModeValue = SettingsDB().get("themeMode");
    final AdaptiveThemeMode themeMode = switch (themeModeValue) {
      "light" => AdaptiveThemeMode.light,
      "dark" => AdaptiveThemeMode.dark,
      "auto" => AdaptiveThemeMode.system,
      _ => AdaptiveThemeMode.system,
    };

    AdaptiveTheme.of(context).setTheme(
      light: AppTheme.buildLightTheme(color, schemeId: themeScheme),
      dark: AppTheme.buildDarkTheme(color, schemeId: themeScheme),
    );
    AdaptiveTheme.of(context).setThemeMode(themeMode);
  }

  String _selectedThemeScheme() {
    final dynamic savedScheme = SettingsDB().get("themeScheme");
    return switch (savedScheme) {
      AppTheme.fancyBlueScheme => AppTheme.fancyBlueScheme,
      AppTheme.fancyPurpleScheme => AppTheme.fancyPurpleScheme,
      AppTheme.sepiaScheme => AppTheme.sepiaScheme,
      AppTheme.blackScheme => AppTheme.blackScheme,
      AppTheme.redScheme => AppTheme.redScheme,
      _ => AppTheme.defaultScheme,
    };
  }

  MaterialColor _savedMaterialColor() {
    final dynamic savedColorIndex = SettingsDB().get("color");
    final int colorIndex =
        savedColorIndex is int &&
            savedColorIndex >= 0 &&
            savedColorIndex < Colors.primaries.length
        ? savedColorIndex
        : 7;
    return Colors.primaries[colorIndex];
  }

  Future<bool> _showRestoreConfirmation(BuildContext context) async {
    final bool? shouldRestore = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreBackup),
        icon: const Icon(Icons.restore_page_outlined),
        content: Text(AppLocalizations.of(context)!.restoreBackupWarning),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.restore),
          ),
        ],
      ),
    );

    return shouldRestore == true;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int _dailyQuranGoalAyahs() {
    final dynamic saved = SettingsDB().get("dailyQuranGoalAyahs");
    if (saved is int) return saved.clamp(1, 1000).toInt();
    if (saved is String) {
      return (int.tryParse(saved) ?? 20).clamp(1, 1000).toInt();
    }
    return 20;
  }

  String _selectedTranslationName(AppLocalizations localizations) {
    final dynamic savedTranslation = SettingsDB().get(
      "translation",
      defaultValue: 0,
    );
    if (savedTranslation is int &&
        savedTranslation >= 0 &&
        savedTranslation < Translation.values.length) {
      final Translation translation = Translation.values[savedTranslation];
      final String name = translationDisplayName(translation);
      if (!translation.isBundled && !isTranslationLoaded(translation)) {
        return '$name • ${localizations.notDownloaded}';
      }
      return name;
    }
    return translationDisplayName(Translation.values.first);
  }

  Widget _buildLanguageTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final String currentLang = SettingsDB().get(
      "locale",
      defaultValue: "system",
    );

    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text(localizations.language),
      subtitle: Text(_languageLabel(currentLang, localizations)),
      onTap: () => _showLanguageDialog(context),
    );
  }

  String _languageLabel(String lang, AppLocalizations localizations) {
    return switch (lang) {
      "en" => localizations.english,
      "ar" => localizations.arabic,
      "id" => localizations.indonesian,
      "ur" => localizations.urdu,
      "tr" => localizations.turkish,
      "bn" => localizations.bengali,
      "de" => localizations.german,
      "fa" => localizations.farsi,
      _ => localizations.systemDefault,
    };
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final String currentLang = SettingsDB().get(
      "locale",
      defaultValue: "system",
    );

    final String? selectedLang = await _showSelectionDialog<String>(
      context: context,
      title: localizations.language,
      icon: Icons.language_rounded,
      selectedValue: currentLang,
      options: <AppSelectionOption<String>>[
        AppSelectionOption<String>(
          value: "system",
          title: localizations.systemDefault,
          subtitle: localizations.sysDefaultSubtitle,
          leading: const Icon(Icons.brightness_auto_rounded),
        ),
        AppSelectionOption<String>(
          value: "en",
          title: localizations.english,
          subtitle: localizations.enSubtitle,
          leading: const Icon(Icons.translate_rounded),
        ),
        AppSelectionOption<String>(
          value: "ar",
          title: localizations.arabic,
          subtitle: localizations.arSubtitle,
          leading: const Icon(Icons.translate_rounded),
        ),
        AppSelectionOption<String>(
          value: "id",
          title: localizations.indonesian,
          subtitle: localizations.idSubtitle,
          leading: const Icon(Icons.translate_rounded),
        ),
        AppSelectionOption<String>(
          value: "ur",
          title: localizations.urdu,
          subtitle: localizations.urSubtitle,
          leading: const Icon(Icons.translate_rounded),
        ),
        AppSelectionOption<String>(
          value: "tr",
          title: localizations.turkish,
          subtitle: localizations.trSubtitle,
          leading: const Icon(Icons.translate_rounded),
        ),
        AppSelectionOption<String>(
          value: "bn",
          title: localizations.bengali,
          subtitle: localizations.bnSubtitle,
          leading: const Icon(Icons.translate_rounded),
        ),
        AppSelectionOption<String>(
          value: "de",
          title: localizations.german,
          subtitle: "Deutsch / German",
          leading: const Icon(Icons.translate_rounded),
        ),
        AppSelectionOption<String>(
          value: "fa",
          title: localizations.farsi,
          subtitle: localizations.faSubtitle,
          leading: const Icon(Icons.translate_rounded),
        ),
      ],
    );

    if (selectedLang == null) return;
    await SettingsDB().put("locale", selectedLang);
    if (context.mounted) {
      final Locale? targetLocale = selectedLang == "system"
          ? null
          : Locale(selectedLang);
      MyApp.of(context)?.setLocale(targetLocale);
      setState(() {});
    }
  }

  String _selectedReciterName() {
    final dynamic savedReciter = SettingsDB().get("reciter", defaultValue: "1");
    final AppLocalizations? localizations = AppLocalizations.of(context);
    return AppReciter.fromCode(savedReciter?.toString()).displayName(
      arabic: localizations != null && isArabicLocalizations(localizations),
    );
  }
}
