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
        ResourceManifest,
        ResourceRepository,
        RoutineDayProgressDB,
        SettingsDB;
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/backend/backup_service.dart';
import 'package:equran/prayer/prayer_times_settings_page.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/widgets/redesign/settings_group_card.dart';
import 'package:equran/utils/library.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/library.dart'
    show AppSelectionOption, FontSlider, PlayBackSlider, SettingsSwitch;
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/home/settings_dialogs.dart';
import 'package:equran/home/downloadable_resources_page.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/resource_state_marker.dart';
import 'package:equran/home_dashboard/daily_tools_edit_sheet.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/main.dart' show MyApp;
import 'package:quran/quran.dart' show Translation, isTranslationLoaded;

/// Side inset that holds the settings rows to a 760 px column on wide windows.
/// Zero at phone and tablet widths.
double _settingsSideInset(double windowWidth) {
  const double maxContentWidth = 760;
  return windowWidth > maxContentWidth
      ? (windowWidth - maxContentWidth) / 2
      : 0;
}

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
    // Keep the rows to a readable column on wide windows. The inset goes in
    // the list padding so the wheel still scrolls over the gutters.
    final double sideInset = _settingsSideInset(
      MediaQuery.sizeOf(context).width,
    );

    return RedesignSubpage(
      title: localizations.settings,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          EquranSpacing.pagePadding + sideInset,
          4,
          EquranSpacing.pagePadding + sideInset,
          32,
        ),
        children: <Widget>[
          _buildSettingsGroup(
            context: context,
            title: localizations.general,
            subtitle: localizations.generalSubtitle,
            icon: Icons.tune_rounded,
            initiallyExpanded: true,
            children: <Widget>[
              _buildLanguageTile(context),
              ReaderOptionRow(
                leading: const DesignIcon('clock'),
                title: localizations.prayerTimesSettings,
                subtitle: localizations.prayerTimesSettingsSubtitle,
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
              ReaderOptionRow(
                leading: const Icon(Icons.palette_rounded),
                title: localizations.appearance,
                subtitle: localizations.appearanceTileSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AppearanceSettingsPage(),
                  ),
                ),
              ),
              ReaderOptionRow(
                leading: const Icon(Icons.linear_scale_rounded),
                title: localizations.customizeNavigation,
                subtitle: localizations.navigationSettingsSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const NavigationSettingsPage(),
                  ),
                ),
              ),
              ReaderOptionRow(
                leading: const DesignIcon('grid'),
                title: DailyToolsEditSheet.translateCustomizeTitle(
                  localizations.localeName.toLowerCase(),
                ),
                subtitle: DailyToolsEditSheet.translateCustomizeDesc(
                  localizations.localeName.toLowerCase(),
                ),
                onTap: () => DailyToolsEditSheet.show(context),
              ),
              SettingsSwitch(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: localizations.showSplashScreen,
                subtitle: localizations.showSplashScreenSubtitle,
                settingsKey: "showSplash",
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
          _buildSettingsLinkCard(
            context: context,
            title: localizations.downloadableResources,
            subtitle: localizations.downloadableResourcesSubtitle,
            icon: Icons.cloud_download_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const DownloadableResourcesPage(),
              ),
            ),
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
  }) => SettingsGroupCard(
    title: title,
    subtitle: subtitle,
    icon: icon,
    initiallyExpanded: initiallyExpanded,
    children: children,
  );

  Widget _buildScriptStyleTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final String currentStyle = SettingsDB().quranScriptStyle;
    final String label = currentStyle == 'indopak'
        ? localizations.indoPak
        : currentStyle == 'qpc-v4'
        ? localizations.qpcV4Tajweed
        : localizations.uthmaniMadinah;

    return ReaderOptionRow(
      leading: const Icon(Icons.font_download_outlined),
      title: localizations.quranScriptStyle,
      subtitle: label,
      onTap: () async {
        final String? value = await _showSelectionDialog<String>(
          context: context,
          title: localizations.quranScriptStyle,
          icon: const Icon(Icons.font_download_outlined),
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
          if (!context.mounted) return;
          final bool ready = await ensureQpcV4FontsReady(
            context,
            _resourceManifestFuture,
          );
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
    return ReaderOptionRow(
      leading: const Icon(Icons.g_translate_rounded),
      title: localizations.translation,
      subtitle: _selectedTranslationName(localizations),
      onTap: () async {
        final ResourceManifest manifest = await _resourceManifestFuture;
        if (!context.mounted) return;
        final int selected = SettingsDB().get("translation", defaultValue: 0);
        final int? value = await _showSelectionDialog<int>(
          context: context,
          title: localizations.translationLanguage,
          icon: const Icon(Icons.translate_rounded),
          selectedValue: selected,
          options:
              Translation.values
                  .asMap()
                  .entries
                  .map(
                    (entry) => AppSelectionOption<int>(
                      value: entry.key,
                      title: translationDisplayName(entry.value),
                      trailing: translationStatusWidget(
                        localizations,
                        entry.value,
                        manifest,
                      ),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.title.compareTo(b.title)),
        );
        if (value == null) return;
        final Translation translation = Translation.values[value];
        if (!context.mounted) return;
        final bool ready = await ensureTranslationReadyForSelection(
          context,
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
    required Widget icon,
    required T selectedValue,
    required List<AppSelectionOption<T>> options,
  }) {
    return showReaderDialog<T>(
      context: context,
      builder: (context) => ReaderChoiceDialog<T>(
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
    return ReaderOptionRow(
      leading: const DesignIcon('headphones'),
      title: localizations.reciter,
      subtitle: _selectedReciterName(),
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
          icon: const DesignIcon('headphones'),
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

  /// A settings section that is a single link. The whole header opens
  /// [onTap] directly, with no expansion step.
  Widget _buildSettingsLinkCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HairlineCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.emWash,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20, color: tokens.emText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontVariations: const [FontVariation('opsz', 15.5)],
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 13, color: tokens.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: tokens.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuranGoalTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final int goal = _dailyQuranGoalAyahs();
    return ReaderOptionRow(
      leading: const Icon(Icons.flag_rounded),
      title: localizations.dailyQuranGoal,
      subtitle: localizations.dailyQuranGoalSubtitle(goal),
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
    return showReaderDialog<int>(
      context: context,
      builder: (context) => DailyGoalDialog(initialGoal: initialGoal),
    );
  }

  Widget _buildClearReadingHistoryTile(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ReaderOptionRow(
      leading: const DesignIcon('trash'),
      title: localizations.clearReadingHistory,
      subtitle: localizations.clearReadingHistorySubtitle,
      showChevron: false,
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
    return ReaderOptionRow(
      leading: const Icon(Icons.backup_rounded),
      title: localizations.backupData,
      subtitle: localizations.backupDataSubtitle,
      showChevron: false,
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
    return ReaderOptionRow(
      leading: const Icon(Icons.settings_backup_restore_rounded),
      title: localizations.restoreData,
      subtitle: localizations.restoreDataSubtitle,
      showChevron: false,
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
    return ReaderOptionRow(
      leading: const DesignIcon('trash'),
      title: localizations.clearFavourites,
      subtitle: localizations.clearFavouritesSubtitle,
      showChevron: false,
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
    showReaderDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          ClearDataDialog(title: title, message: message, onConfirm: onConfirm),
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
      dark: AppTheme.buildDarkTheme(
        color,
        schemeId: themeScheme,
        pureBlackBackground: SettingsDB().pureBlackBackground,
      ),
    );
    AdaptiveTheme.of(context).setThemeMode(themeMode);
  }

  String _selectedThemeScheme() {
    final dynamic savedScheme = SettingsDB().get("themeScheme");
    return switch (savedScheme) {
      AppTheme.fancyBlueScheme => AppTheme.fancyBlueScheme,
      AppTheme.fancyPurpleScheme => AppTheme.fancyPurpleScheme,
      AppTheme.sepiaScheme => AppTheme.sepiaScheme,
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
    final bool? shouldRestore = await showReaderDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return ReaderConfirmDialog(
          title: l.restoreBackup,
          body: l.restoreBackupWarning,
          icon: const Icon(Icons.restore_page_outlined),
          cancelLabel: l.cancel,
          confirmLabel: l.restore,
        );
      },
    );

    return shouldRestore == true;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

    return ReaderOptionRow(
      leading: const Icon(Icons.language_rounded),
      title: localizations.language,
      subtitle: _languageLabel(currentLang, localizations),
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
      icon: const Icon(Icons.language_rounded),
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
