import 'dart:math' as math;

import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/display_numeral.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/hero_panel.dart';
import 'package:equran/widgets/redesign/hero_parts.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:equran/widgets/redesign/segmented_control.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quran/quran.dart' as quran;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/backend/hifz_db.dart';
import '../hifz.dart';

class HifzHomePage extends StatefulWidget {
  const HifzHomePage({super.key});

  @override
  State<HifzHomePage> createState() => _HifzHomePageState();
}

class _HifzHomePageState extends State<HifzHomePage> {
  bool _gridExpanded = false;

  HifzUnitType _selectedType = HifzUnitType.surah;
  int? _selectedNumber; // surah 1-114 or juz 1-30
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _unitId(int n) =>
      _selectedType == HifzUnitType.surah ? 'surah_$n' : 'juz_$n';

  bool _hasContent(HifzUnit u) =>
      HifzDB.getNewAyahsForUnit(u.id, 1).isNotEmpty ||
      HifzDB.getSabqiAyahs(u.id).isNotEmpty ||
      HifzDB.getManzilAyahs(u.id).isNotEmpty;

  void _showSettingsSheet() {
    showReaderSheet<void>(
      context: context,
      builder: (context) => const _HifzSettingsSheet(),
    );
  }

  Future<void> _startUnit() async {
    if (_selectedNumber == null) return;

    // Create unit in DB (idempotent)
    final unit = await HifzDB.createUnit(
      type: _selectedType,
      unitNumber: _selectedNumber!,
    );

    // Advance frontier to unlock first batch of new ayahs
    await HifzDB.advanceFrontier(unit, HifzLimits.maxNewPerDay);

    // Navigate directly to session
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HifzSessionPage(unit: unit)),
      );
    }

    // Reset picker state
    setState(() {
      _selectedNumber = null;
      _searchController.clear();
    });
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
      child: RedesignEyebrow(label),
    );
  }

  Widget _buildSelectedPreview() {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final n = _selectedNumber!;
    final isAlreadyActive = HifzDB.getUnit(_unitId(n)) != null;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlreadyActive ? tokens.goldWash : tokens.emWash,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      child: Row(
        children: [
          DesignIcon(
            isAlreadyActive ? 'info' : 'check',
            color: isAlreadyActive ? tokens.goldText : tokens.emText,
            size: 18,
            strokeWidth: 1.9,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedType == HifzUnitType.surah
                      ? HifzSurahData.name(n)
                      : l10n.juzNumber(n),
                  style: TextStyle(
                    fontSize: 15,
                    fontVariations: const [FontVariation('opsz', 15)],
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  isAlreadyActive
                      ? l10n.hifzUnitAlreadyActive
                      : _selectedType == HifzUnitType.surah
                      ? l10n.hifzUnitAyahCount(HifzSurahData.ayahCount(n))
                      : l10n.hifzUnitAyahCount(
                          quran
                              .getSurahAndVersesFromJuz(n)
                              .values
                              .fold(
                                0,
                                (sum, range) => sum + (range[1] - range[0] + 1),
                              ),
                        ),
                  style: TextStyle(fontSize: 13, color: tokens.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The summary card: memorised ayahs, active units and progress.
  Widget _buildHero({
    required AppLocalizations l10n,
    required int masteredCount,
    required int activeUnitsCount,
    required int inProgressCount,
    required double progressFraction,
  }) {
    final EquranTokens tokens = context.equranTokens;
    final Color gold = heroGoldOf(context);
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: DisplayNumeral(value, size: 34, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
              color: tokens.featText2,
            ),
          ),
        ],
      ),
    );

    return HeroPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DesignIcon('sparkle', size: 16, color: gold),
              const SizedBox(width: 8),
              Expanded(
                child: RedesignEyebrow(l10n.hifzJourneyTitle, color: gold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: HeroPill(
              l10n.hifzNewTodayLabel(
                HifzLimits.todayNewCount,
                HifzLimits.maxNewPerDay,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat('$masteredCount', l10n.hifzMemorized),
              stat('$activeUnitsCount', l10n.hifzActiveUnits),
              stat('$inProgressCount', l10n.hifzInProgress),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.hifzAyahsMemorized(masteredCount),
                  style: TextStyle(fontSize: 13, color: tokens.featText2),
                ),
              ),
              Text(
                '${(progressFraction * 100).toStringAsFixed(1)}%',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HeroProgressBar(value: progressFraction, color: gold),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.equranColors;
    final tokens = context.equranTokens;
    final l10n = AppLocalizations.of(context)!;

    return RedesignSubpage(
      title: l10n.hifzTitle,
      actions: [
        IconButton44(
          designIcon: 'gear',
          tooltip: l10n.hifzSettingsSheetTitle,
          onPressed: _showSettingsSheet,
        ),
      ],
      child: SafeArea(
        child: ValueListenableBuilder<Box<HifzEntry>>(
          valueListenable: HifzDB.entriesListenable,
          builder: (context, box, _) {
            final allEntries = box.values.toList();

            // Computations for Hero summary
            final masteredCount = allEntries
                .where((e) => e.status == 'mastered')
                .length;
            final activeUnitsCount = HifzDB.getActiveUnits().length;
            final inProgressCount = allEntries
                .where((e) => e.status != 'unseen')
                .length;
            final progressFraction = masteredCount / HifzSurahData.totalAyahs;

            // Map entries by surah for progress grid performance
            final Map<int, List<HifzEntry>> entriesBySurah = {};
            for (final entry in allEntries) {
              entriesBySurah.putIfAbsent(entry.surah, () => []).add(entry);
            }

            int masteredSurahCount = 0;
            for (int surah = 1; surah <= 114; surah++) {
              final entries = entriesBySurah[surah] ?? [];
              final total = HifzSurahData.ayahCount(surah);
              if (entries.isNotEmpty &&
                  entries.where((e) => e.status == 'mastered').length ==
                      total) {
                masteredSurahCount++;
              }
            }

            final activeUnits = HifzDB.getActiveUnits();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    EquranSpacing.pagePadding,
                    4,
                    EquranSpacing.pagePadding,
                    0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // SECTION A - HERO SUMMARY CARD
                      _buildHero(
                        l10n: l10n,
                        masteredCount: masteredCount,
                        activeUnitsCount: activeUnitsCount,
                        inProgressCount: inProgressCount,
                        progressFraction: progressFraction,
                      ),
                      const SizedBox(height: 24),

                      // SECTION B - REMINDER CARD
                      if (activeUnits.any(_hasContent)) ...[
                        HairlineCard(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            14,
                            14,
                            14,
                          ),
                          child: Row(
                            children: [
                              const ReaderIconWell(
                                icon: DesignIcon('flame', strokeWidth: 1.8),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.hifzReminderTitle(
                                        HifzFrontierService.totalDueCount(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontVariations: const [
                                          FontVariation('opsz', 15),
                                        ],
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.hifzStartYourSession,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.3,
                                        color: tokens.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                style: readerFilledButtonStyle(context)
                                    .copyWith(
                                      minimumSize:
                                          const WidgetStatePropertyAll<Size>(
                                            Size(0, 44),
                                          ),
                                      padding:
                                          const WidgetStatePropertyAll<
                                            EdgeInsetsGeometry
                                          >(
                                            EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                          ),
                                    ),
                                onPressed: () {
                                  final unitWithDue = activeUnits.firstWhere(
                                    (u) => _hasContent(u),
                                    orElse: () => activeUnits.first,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HifzSessionPage(unit: unitWithDue),
                                    ),
                                  );
                                },
                                child: Text(l10n.hifzStart),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ] else ...[
                        HairlineCard(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DesignIcon(
                                'check',
                                color: tokens.emText,
                                size: 18,
                                strokeWidth: 1.9,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  l10n.hifzAllCaughtUp,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: tokens.text2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // SECTION C - ACTIVE UNITS
                      _buildSectionLabel(l10n.hifzActiveUnitsSection),
                      ValueListenableBuilder<Box<HifzUnit>>(
                        valueListenable: HifzDB.unitsListenable,
                        builder: (context, box, _) {
                          final activeUnitsList = HifzDB.getActiveUnits();

                          if (activeUnitsList.isEmpty) {
                            return HairlineCard(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DesignIcon(
                                    'book',
                                    color: tokens.emText,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      l10n.hifzNoActiveUnits,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: tokens.text2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeUnitsList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _UnitProgressCard(
                                unit: activeUnitsList[index],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // SECTION D - ADD A UNIT
                      _buildSectionLabel(l10n.hifzAddUnitSection),
                      HairlineCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // UNIT TYPE TOGGLE
                            RedesignSegmentedControl(
                              labels: [
                                l10n.hifzUnitTypeSurah,
                                l10n.hifzUnitTypeJuz,
                              ],
                              selectedIndex: _selectedType == HifzUnitType.surah
                                  ? 0
                                  : 1,
                              onChanged: (index) => setState(() {
                                _selectedType = index == 0
                                    ? HifzUnitType.surah
                                    : HifzUnitType.juz;
                                _selectedNumber = null;
                                _searchController.clear();
                              }),
                            ),
                            const SizedBox(height: 12),
                            // SEARCHABLE DROPDOWN
                            DropdownMenu<int>(
                              controller: _searchController,
                              enableSearch: true,
                              enableFilter: true,
                              requestFocusOnTap: true,
                              expandedInsets: EdgeInsets.zero,
                              hintText: _selectedType == HifzUnitType.surah
                                  ? l10n.hifzSearchSurahs
                                  : l10n.hifzSearchJuz,
                              textStyle: TextStyle(
                                fontSize: 15,
                                fontVariations: const [
                                  FontVariation('opsz', 15),
                                ],
                                color: colors.textPrimary,
                              ),
                              trailingIcon: DesignIcon(
                                'chevd',
                                size: 18,
                                color: tokens.muted,
                              ),
                              selectedTrailingIcon: DesignIcon(
                                'chevd',
                                size: 18,
                                color: tokens.emText,
                              ),
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  colors.surface,
                                ),
                                surfaceTintColor: const WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      EquranRadii.large,
                                    ),
                                    side: BorderSide(color: tokens.hair2),
                                  ),
                                ),
                                maximumSize: const WidgetStatePropertyAll(
                                  Size(double.infinity, 300),
                                ),
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: colors.surface,
                                hintStyle: TextStyle(
                                  color: tokens.muted,
                                  fontSize: 15,
                                  fontVariations: const [
                                    FontVariation('opsz', 15),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: tokens.hair2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: tokens.hair2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: tokens.emText),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onSelected: (val) =>
                                  setState(() => _selectedNumber = val),
                              dropdownMenuEntries:
                                  _selectedType == HifzUnitType.surah
                                  ? List.generate(114, (i) => i + 1).map((n) {
                                      final active =
                                          HifzDB.getUnit(_unitId(n)) != null;
                                      return DropdownMenuEntry<int>(
                                        value: n,
                                        label: '$n. ${HifzSurahData.name(n)}',
                                        trailingIcon: active
                                            ? DesignIcon(
                                                'check',
                                                color: tokens.emText,
                                                size: 16,
                                                strokeWidth: 2,
                                              )
                                            : null,
                                      );
                                    }).toList()
                                  : List.generate(30, (i) => i + 1).map((n) {
                                      final active =
                                          HifzDB.getUnit(_unitId(n)) != null;
                                      return DropdownMenuEntry<int>(
                                        value: n,
                                        label: l10n.juzNumber(n),
                                        trailingIcon: active
                                            ? DesignIcon(
                                                'check',
                                                color: tokens.emText,
                                                size: 16,
                                                strokeWidth: 2,
                                              )
                                            : null,
                                      );
                                    }).toList(),
                            ),
                            const SizedBox(height: 12),
                            // SELECTED UNIT PREVIEW
                            AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              child: _selectedNumber == null
                                  ? const SizedBox.shrink()
                                  : _buildSelectedPreview(),
                            ),
                            const SizedBox(height: 16),
                            // START BUTTON
                            FilledButton(
                              style: readerFilledButtonStyle(context).copyWith(
                                minimumSize: const WidgetStatePropertyAll<Size>(
                                  Size.fromHeight(52),
                                ),
                              ),
                              onPressed: _selectedNumber == null
                                  ? null
                                  : _startUnit,
                              child: Text(
                                _selectedNumber == null
                                    ? l10n.hifzSelectAbove
                                    : _selectedType == HifzUnitType.surah
                                    ? l10n.hifzStartMemorizingSurah(
                                        HifzSurahData.name(_selectedNumber!),
                                      )
                                    : l10n.hifzStartMemorizingJuz(
                                        _selectedNumber!,
                                      ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // SECTION E - SURAH PROGRESS GRID
                      _buildSectionLabel(l10n.hifzSurahProgress),
                      HairlineCard(
                        padding: const EdgeInsets.all(12),
                        child: ClipRect(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            child: SizedBox(
                              height: _gridExpanded ? null : 160.0,
                              child: Stack(
                                children: [
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 10,
                                    childAspectRatio: 1.0,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                    children: List.generate(114, (index) {
                                      final surah = index + 1;
                                      final unit = HifzDB.getUnit(
                                        'surah_$surah',
                                      );
                                      final total = HifzSurahData.ayahCount(
                                        surah,
                                      );
                                      final masteredCellCount =
                                          entriesBySurah[surah]
                                              ?.where(
                                                (e) => e.status == 'mastered',
                                              )
                                              .length ??
                                          0;

                                      // Not started: an empty hairline cell.
                                      // Started: an emerald wash, then solid
                                      // emerald once ayahs are introduced.
                                      // Fully memorised: solid gold. A gold dot
                                      // marks an active surah, so state is not
                                      // carried by colour alone.
                                      Color cellBg = Colors.transparent;
                                      Color cellBorder = tokens.hair;
                                      Color cellText = tokens.muted;
                                      bool hasActiveDot = false;

                                      if (unit != null) {
                                        cellBorder = Colors.transparent;
                                        if (masteredCellCount == total) {
                                          cellBg = tokens.gold;
                                          cellText =
                                              EquranColors.blackDark.background;
                                        } else if (unit.introducedAyahs == 0) {
                                          cellBg = tokens.emWash;
                                          cellText = tokens.emText;
                                          hasActiveDot = !unit.isComplete;
                                        } else {
                                          cellBg = tokens.filled;
                                          cellText = Colors.white;
                                          hasActiveDot = !unit.isComplete;
                                        }
                                      }

                                      final String languageCode =
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode;
                                      final isArabic =
                                          languageCode == 'ar' ||
                                          languageCode == 'fa' ||
                                          languageCode == 'ur';
                                      final surahName = isArabic
                                          ? quran.getSurahNameArabic(surah)
                                          : HifzSurahData.name(surah);

                                      Widget cellChild = Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '$surah',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: cellText,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );

                                      if (hasActiveDot) {
                                        cellChild = Stack(
                                          children: [
                                            cellChild,
                                            PositionedDirectional(
                                              top: 3,
                                              end: 3,
                                              child: Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: tokens.gold,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      return Tooltip(
                                        message:
                                            '$surahName: ${l10n.hifzSessionProgress(masteredCellCount, total)}',
                                        child: Material(
                                          color: cellBg,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: BorderSide(color: cellBorder),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () {
                                              final name = isArabic
                                                  ? quran.getSurahNameArabic(
                                                      surah,
                                                    )
                                                  : HifzSurahData.name(surah);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).clearSnackBars();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '$name: ${l10n.hifzSessionProgress(masteredCellCount, total)}',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            child: cellChild,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  if (!_gridExpanded)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      height: 60,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              colors.surface.withValues(
                                                alpha: 0.0,
                                              ),
                                              colors.surface,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ChipButton(
                          _gridExpanded
                              ? l10n.hifzShowLess
                              : l10n.hifzShowAllSurahs,
                          onPressed: () {
                            setState(() {
                              _gridExpanded = !_gridExpanded;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          l10n.hifzSurahsMastered(masteredSurahCount),
                          style: TextStyle(fontSize: 13, color: tokens.text2),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HifzSettingsSheet extends StatefulWidget {
  const _HifzSettingsSheet();

  @override
  State<_HifzSettingsSheet> createState() => _HifzSettingsSheetState();
}

class _HifzSettingsSheetState extends State<_HifzSettingsSheet> {
  late int _maxNewPerDay;
  late int _maxReviewPerDay;
  late bool _showTransliteration;
  late bool _showTranslation;
  late bool _autoPlayAudio;
  late String _blankingLevel;

  static const List<String> _blankingLevels = <String>[
    'auto',
    'easy',
    'medium',
    'hard',
  ];

  @override
  void initState() {
    super.initState();
    _maxNewPerDay = HifzPrefs.maxNewPerDay();
    _maxReviewPerDay = HifzPrefs.maxReviewPerDay();
    _showTransliteration = HifzPrefs.showTransliterationByDefault();
    _showTranslation = HifzPrefs.showTranslationByDefault();
    _autoPlayAudio = HifzPrefs.autoPlayAudioOnLearn();
    _blankingLevel = HifzPrefs.blankingLevel();
  }

  Future<void> _saveSettings() async {
    await HifzPrefs.setMaxNewPerDay(_maxNewPerDay);
    await HifzPrefs.setMaxReviewPerDay(_maxReviewPerDay);
    await HifzPrefs.setShowTransliterationByDefault(_showTransliteration);
    await HifzPrefs.setShowTranslationByDefault(_showTranslation);
    await HifzPrefs.setAutoPlayAudioOnLearn(_autoPlayAudio);
    await HifzPrefs.setBlankingLevel(_blankingLevel);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> blankingLabels = <String>[
      l10n.hifzSettingsBlankingAuto,
      l10n.hifzSettingsBlankingEasy,
      l10n.hifzSettingsBlankingMedium,
      l10n.hifzSettingsBlankingHard,
    ];
    return ReaderSheetFrame(
      title: l10n.hifzSettingsSheetTitle,
      trailing: IconButton44(
        designIcon: 'x',
        tooltip: l10n.close,
        ghost: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: [
        ReaderSheetGroup(
          children: [
            ReaderSliderBlock(
              title: l10n.hifzSettingsNewPerDay,
              valueLabel: '$_maxNewPerDay',
              slider: Slider(
                value: _maxNewPerDay.toDouble(),
                min: 1.0,
                max: 50.0,
                divisions: 49,
                onChanged: (val) {
                  setState(() {
                    _maxNewPerDay = val.round();
                  });
                },
              ),
            ),
            ReaderSliderBlock(
              title: l10n.hifzSettingsReviewsPerDay,
              valueLabel: '$_maxReviewPerDay',
              slider: Slider(
                value: _maxReviewPerDay.toDouble(),
                min: 5.0,
                max: 200.0,
                divisions: 195,
                onChanged: (val) {
                  setState(() {
                    _maxReviewPerDay = val.round();
                  });
                },
              ),
            ),
          ],
        ),
        ReaderSheetGroup(
          children: [
            ReaderSwitchRow(
              leading: const DesignIcon('sparkle'),
              title: l10n.hifzSettingsShowTranslit,
              value: _showTransliteration,
              onChanged: (val) => setState(() => _showTransliteration = val),
            ),
            ReaderSwitchRow(
              leading: const DesignIcon('chat'),
              title: l10n.hifzSettingsShowTranslation,
              value: _showTranslation,
              onChanged: (val) => setState(() => _showTranslation = val),
            ),
            ReaderSwitchRow(
              leading: const DesignIcon('headphones'),
              title: l10n.hifzSettingsAutoPlayAudio,
              value: _autoPlayAudio,
              onChanged: (val) => setState(() => _autoPlayAudio = val),
            ),
          ],
        ),
        ReaderFieldLabel(l10n.hifzSettingsBlankingLevel),
        RedesignSegmentedControl(
          labels: blankingLabels,
          selectedIndex: math.max(0, _blankingLevels.indexOf(_blankingLevel)),
          onChanged: (index) =>
              setState(() => _blankingLevel = _blankingLevels[index]),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await _saveSettings();
            navigator.pop();
          },
          style: readerFilledButtonStyle(context),
          child: Text(l10n.hifzSettingsDone),
        ),
      ],
    );
  }
}

class _UnitProgressCard extends StatelessWidget {
  final HifzUnit unit;
  const _UnitProgressCard({required this.unit});

  bool _hasSessionContent(HifzUnit unit) {
    return HifzDB.getNewAyahsForUnit(unit.id, 1).isNotEmpty ||
        HifzDB.getSabqiAyahs(unit.id).isNotEmpty ||
        HifzDB.getManzilAyahs(unit.id).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.equranColors;
    final tokens = context.equranTokens;
    final l10n = AppLocalizations.of(context)!;

    final newCount = math.min(
      HifzDB.getNewAyahsForUnit(unit.id, 999).length,
      HifzLimits.remainingNewToday,
    );
    final sabqiCount = HifzDB.getSabqiAyahs(unit.id).length;
    final manzilCount = HifzDB.getManzilAyahs(unit.id).length;
    final bool hasContent = _hasSessionContent(unit);

    return HairlineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: title + session button
          Row(
            children: [
              ReaderIconWell(
                icon: DesignIcon(
                  unit.type == HifzUnitType.surah ? 'book' : 'grid',
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.type == HifzUnitType.surah
                          ? l10n.hifzUnitTypeSurah
                          : l10n.hifzUnitTypeJuz,
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontVariations: const [FontVariation('opsz', 16)],
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: readerFilledButtonStyle(context).copyWith(
                  minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 44)),
                  padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                onPressed: hasContent
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HifzSessionPage(unit: unit),
                        ),
                      )
                    : null,
                child: Text(
                  hasContent ? l10n.hifzUnitReview : l10n.hifzUnitUpToDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Row 2: frontier info
          Text(
            l10n.hifzUnitNextAyah(
              HifzSurahData.name(unit.frontierSurah),
              unit.frontierAyah,
            ),
            style: TextStyle(fontSize: 13, color: tokens.text2),
          ),
          const SizedBox(height: 10),
          // Row 3: progress bar + fraction
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(EquranRadii.pill),
                  child: LinearProgressIndicator(
                    value: unit.progressFraction,
                    backgroundColor: tokens.hair2,
                    valueColor: AlwaysStoppedAnimation<Color>(tokens.filled),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.hifzUnitProgress(unit.introducedAyahs, unit.totalAyahs),
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12.5, color: tokens.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 4: due counts
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (newCount > 0)
                PillTag(
                  l10n.hifzDueNew(newCount),
                  selected: true,
                  compact: true,
                ),
              if (sabqiCount > 0)
                PillTag(
                  l10n.hifzDueRevision(sabqiCount),
                  gold: true,
                  compact: true,
                ),
              if (manzilCount > 0)
                PillTag(l10n.hifzDueMaintenance(manzilCount), compact: true),
              if (newCount == 0 && sabqiCount == 0 && manzilCount == 0)
                PillTag(l10n.hifzDueAllCaughtUp, selected: true, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}
