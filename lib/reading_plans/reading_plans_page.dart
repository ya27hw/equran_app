import 'package:equran/backend/library.dart';
import 'package:equran/home/read.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/reading_plans/routine_progress.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/hero_panel.dart';
import 'package:equran/widgets/redesign/hero_parts.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:quran/quran.dart' as quran;

class ReadingPlansPage extends StatelessWidget {
  const ReadingPlansPage({super.key, this.showAppBar = true, this.now});

  final bool showAppBar;

  /// The clock for today's portion; tests pass a fixed one.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final DateTime Function() clock = now ?? DateTime.now;

    return RedesignSubpage(
      title: localizations.readingRoutine,
      child: ValueListenableBuilder<Box<dynamic>>(
        valueListenable: ReadingPlansDB().listener,
        builder: (BuildContext context, Box<dynamic> box, Widget? child) {
          final List<ReadingPlanEntry> plans =
              box.values.whereType<ReadingPlanEntry>().toList(growable: false)
                ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          final ReadingPlanEntry? activePlan = _activePlan(plans);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              EquranSpacing.pagePadding,
              16,
              EquranSpacing.pagePadding,
              32,
            ),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _RoutineHero(plan: activePlan, now: clock),
                      const SizedBox(height: 16),
                      _ActivitySummary(plan: activePlan, now: clock),
                      const SizedBox(height: 16),
                      if (activePlan == null)
                        _EmptyRoutineCard(onCreate: _createThirtyDayPlan)
                      else
                        _TodayTaskCard(plan: activePlan, now: clock),
                      _RoutineHistorySection(
                        plans: plans,
                        activePlan: activePlan,
                        now: clock,
                      ),
                      _PlanPresetGrid(
                        onCreatePlan: (BuildContext context, _PlanPreset plan) {
                          _createPresetPlan(context, plan);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createThirtyDayPlan(BuildContext context) {
    _createPresetPlan(context, _PlanPreset.thirtyDays);
  }

  static Future<void> _createPresetPlan(
    BuildContext context,
    _PlanPreset preset,
  ) async {
    final DateTime now = DateTime.now();
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<ReadingPlanEntry> existingPlans = ReadingPlansDB().box.values
        .whereType<ReadingPlanEntry>()
        .toList(growable: false);
    for (final ReadingPlanEntry plan in existingPlans) {
      if (!plan.active) continue;
      await ReadingPlansDB().put(
        plan.id,
        ReadingPlanEntry(
          id: plan.id,
          type: plan.type,
          title: plan.title,
          startedAt: plan.startedAt,
          finishBy: plan.finishBy,
          startGlobalAyah: plan.startGlobalAyah,
          targetGlobalAyah: plan.targetGlobalAyah,
          lastCompletedGlobalAyah: plan.lastCompletedGlobalAyah,
          active: false,
          schemaVersion: plan.schemaVersion,
        ),
      );
    }

    final ReadingPlanEntry newPlan = ReadingPlanEntry(
      id: 'plan:${preset.type}:${now.microsecondsSinceEpoch}',
      type: preset.type,
      title: preset.title(localizations),
      startedAt: DateTime(now.year, now.month, now.day),
      finishBy: DateTime(now.year, now.month, now.day + preset.days - 1),
      startGlobalAyah: 1,
      targetGlobalAyah: quran.totalVerseCount,
      lastCompletedGlobalAyah: 0,
    );
    await ReadingPlansDB().put(newPlan.id, newPlan);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.routineStartedMessage(preset.title(localizations)),
        ),
      ),
    );
  }
}

String _localizedPlanTitle(
  ReadingPlanEntry plan,
  AppLocalizations localizations,
) {
  return switch (plan.type) {
    'complete_7_days' => localizations.preset7DaysTitle,
    'complete_30_days' => localizations.preset30DaysTitle,
    'complete_60_days' => localizations.preset60DaysTitle,
    _ => plan.title,
  };
}

ReadingPlanEntry? _activePlan(List<ReadingPlanEntry> plans) {
  for (final ReadingPlanEntry plan in plans) {
    if (plan.active) return plan;
  }
  return null;
}

/// A section heading in the serif display face, in flow with the page.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 30, 4, 12),
    child: Text(text, style: redesignDisplayStyle(context, size: 24)),
  );
}

class _RoutineHero extends StatelessWidget {
  const _RoutineHero({required this.plan, required this.now});

  final ReadingPlanEntry? plan;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final Color gold = heroGoldOf(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final _PlanProgress? progress = plan == null
        ? null
        : _planProgress(plan!, now());
    final String title = plan == null
        ? localizations.buildQuranRoutine
        : _localizedPlanTitle(plan!, localizations);

    return HeroPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DesignIcon('route', size: 16, color: gold),
              const SizedBox(width: 8),
              Expanded(
                child: RedesignEyebrow(
                  localizations.readingRoutine,
                  color: gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: redesignDisplayStyle(
              context,
              size: 28,
              color: EquranColors.dark.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan == null
                ? localizations.chooseGentlePlan
                : localizations.routineCompletedAyahs(
                    progress!.completedAyahs,
                    progress.totalAyahs,
                  ),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: tokens.featText2,
            ),
          ),
          const SizedBox(height: 18),
          HeroProgressBar(value: progress?.fraction ?? 0, color: gold),
          const SizedBox(height: 10),
          Text(
            plan == null
                ? localizations.plansReadyNotice
                : localizations.finishTargetDate(
                    _shortDate(plan!.finishBy, localizations.localeName),
                  ),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: tokens.featText2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.plan, required this.now});

  final ReadingPlanEntry? plan;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bool done =
        plan != null && routineProgressSummary(plan!, now: now()).isTodayDone;
    final List<_SummaryPillData> items = <_SummaryPillData>[
      _SummaryPillData(localizations.allLabel, plan == null ? 0 : 1),
      _SummaryPillData(localizations.doneLabel, done ? 1 : 0),
      _SummaryPillData(
        localizations.ongoingLabel,
        plan != null && !done ? 1 : 0,
      ),
      _SummaryPillData(localizations.skippedLabel, 0),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final _SummaryPillData item in items)
          PillTag('${item.label} ${item.count}', selected: item.count > 0),
      ],
    );
  }
}

class _SummaryPillData {
  const _SummaryPillData(this.label, this.count);

  final String label;
  final int count;
}

class _EmptyRoutineCard extends StatelessWidget {
  const _EmptyRoutineCard({required this.onCreate});

  final void Function(BuildContext context) onCreate;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return HairlineCard(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ReaderIconWell(icon: DesignIcon('route')),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  localizations.noActiveRoutine,
                  style: TextStyle(
                    fontSize: 16,
                    fontVariations: const [FontVariation('opsz', 16)],
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.startBalancedPlanDescription,
            style: TextStyle(fontSize: 14, height: 1.45, color: tokens.text2),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onCreate(context),
            style: readerFilledButtonStyle(context),
            icon: const DesignIcon('plus', size: 18, strokeWidth: 2),
            label: Text(localizations.start30DayPlan),
          ),
        ],
      ),
    );
  }
}

class _TodayTaskCard extends StatelessWidget {
  const _TodayTaskCard({required this.plan, required this.now});

  final ReadingPlanEntry plan;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final RoutineProgressSummary progress = routineProgressSummary(
      plan,
      now: now(),
    );
    final _AyahRef start = _ayahRefFromGlobalIndex(
      progress.todayStartGlobalAyah,
    );
    final _AyahRef end = _ayahRefFromGlobalIndex(progress.todayEndGlobalAyah);
    final bool done = progress.isTodayDone;
    final double dailyFraction = progress.todayFraction;
    final int percentComplete = (dailyFraction * 100).round();
    final TextStyle detail = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: tokens.text2,
    );

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: done ? tokens.emWash : colors.surface,
        borderRadius: BorderRadius.circular(EquranRadii.xl),
        border: Border.all(color: done ? tokens.hair2 : tokens.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ReaderIconWell(
                icon: DesignIcon(done ? 'check' : 'book', strokeWidth: 1.8),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      progress.isRoutineDone
                          ? localizations.routineComplete
                          : done
                          ? localizations.todayCompleted
                          : localizations.todayReading,
                      style: TextStyle(
                        fontSize: 16,
                        fontVariations: const [FontVariation('opsz', 16)],
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      progress.isRoutineDone
                          ? localizations.routineCompletedAyahs(
                              progress.totalAyahs,
                              progress.totalAyahs,
                            )
                          : localizations.todaysPortionAyahs(
                              progress.todayPortionAyahs,
                            ),
                      style: detail,
                    ),
                    if (!progress.isRoutineDone &&
                        progress.catchUpAyahs > 0) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        localizations.includesCatchUpAyahs(
                          progress.catchUpAyahs,
                        ),
                        style: detail.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.goldText,
                        ),
                      ),
                    ] else if (!progress.isRoutineDone) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        localizations.ayahRangeConnector(
                          _refLabel(start),
                          _refLabel(end),
                        ),
                        style: detail,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(EquranRadii.pill),
            child: LinearProgressIndicator(
              value: dailyFraction,
              minHeight: 8,
              color: tokens.filled,
              backgroundColor: tokens.hair2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done
                ? localizations.todaysPortionComplete
                : localizations.dailyPercentCompleteRemaining(
                    percentComplete,
                    progress.todayRemainingAyahs,
                  ),
            style: detail.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: progress.isRoutineDone
                ? null
                : () => _openContinue(context),
            style: readerFilledButtonStyle(context),
            icon: const DesignIcon(
              'play',
              size: 16,
              strokeWidth: 1.8,
              filled: true,
            ),
            label: Text(
              progress.isRoutineDone
                  ? localizations.routineComplete
                  : localizations.resume,
            ),
          ),
        ],
      ),
    );
  }

  void _openContinue(BuildContext context) {
    final RoutineProgressSummary progress = routineProgressSummary(
      plan,
      now: now(),
    );
    final int resumeGlobalAyah = progress.nextUnreadGlobalAyah;
    final _AyahRef resume = _ayahRefFromGlobalIndex(resumeGlobalAyah);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ReadPage(
            chapter: resume.surah,
            startVerse: resume.verse,
            mode: ReadPageMode.routine,
            routineId: plan.id,
          );
        },
      ),
    );
  }
}

class _RoutineHistorySection extends StatelessWidget {
  const _RoutineHistorySection({
    required this.plans,
    required this.activePlan,
    required this.now,
  });

  final List<ReadingPlanEntry> plans;
  final ReadingPlanEntry? activePlan;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<ReadingPlanEntry> pastPlans = plans
        .where((ReadingPlanEntry plan) => !plan.active)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeading(localizations.routineHistory),
        HairlineCard(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (activePlan != null)
                  _RoutineHistoryTile(
                    plan: activePlan!,
                    label: localizations.currentRoutine,
                    now: now,
                    onDelete: () => _deleteRoutine(context, activePlan!),
                  )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      18,
                      18,
                      18,
                    ),
                    child: Text(
                      localizations.noCurrentRoutine,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: tokens.text2,
                      ),
                    ),
                  ),
                if (pastPlans.isNotEmpty) ...<Widget>[
                  Divider(height: 1, thickness: 1, color: tokens.hair),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsetsDirectional.fromSTEB(
                        18,
                        4,
                        14,
                        4,
                      ),
                      childrenPadding: EdgeInsets.zero,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      iconColor: tokens.muted,
                      collapsedIconColor: tokens.muted,
                      title: Text(
                        localizations.pastRoutines,
                        style: TextStyle(
                          fontSize: 15,
                          fontVariations: const [FontVariation('opsz', 15)],
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      children: <Widget>[
                        for (final ReadingPlanEntry plan
                            in pastPlans) ...<Widget>[
                          Divider(height: 1, thickness: 1, color: tokens.hair),
                          _RoutineHistoryTile(
                            plan: plan,
                            label: localizations.pastRoutine,
                            now: now,
                            onDelete: () => _deleteRoutine(context, plan),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineHistoryTile extends StatelessWidget {
  const _RoutineHistoryTile({
    required this.plan,
    required this.label,
    required this.onDelete,
    required this.now,
  });

  final ReadingPlanEntry plan;
  final String label;
  final VoidCallback onDelete;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final _PlanProgress progress = _planProgress(plan, now());
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 6, 10),
        child: Row(
          children: <Widget>[
            ReaderIconWell(icon: DesignIcon(plan.active ? 'route' : 'clock')),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _localizedPlanTitle(plan, localizations),
                    style: TextStyle(
                      fontSize: 15,
                      fontVariations: const [FontVariation('opsz', 15)],
                      fontWeight: FontWeight.w600,
                      color: context.equranColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$label • ${localizations.completedAyahsRatio(progress.completedAyahs, progress.totalAyahs)} • ${_shortDate(plan.startedAt, localizations.localeName)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton44(
              designIcon: 'trash',
              tooltip: localizations.deleteRoutineTooltip,
              ghost: true,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _deleteRoutine(BuildContext context, ReadingPlanEntry plan) async {
  final AppLocalizations localizations = AppLocalizations.of(context)!;
  final bool confirmed = await _confirmRoutineAction(
    context: context,
    title: plan.active
        ? localizations.deleteCurrentRoutineQuestion
        : localizations.deleteRoutineQuestion,
    message: localizations.deleteRoutineWarning(
      _localizedPlanTitle(plan, localizations),
    ),
    confirmLabel: localizations.delete,
    destructive: true,
  );
  if (!confirmed) return;
  await ReadingPlansDB().delete(plan.id);
  await RoutineDayProgressDB().deleteProgressForRoutine(plan.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(localizations.routineDeleted)));
}

Future<bool> _confirmRoutineAction({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final AppLocalizations localizations = AppLocalizations.of(context)!;
  final bool? confirmed = await showReaderDialog<bool>(
    context: context,
    builder: (BuildContext context) => ReaderConfirmDialog(
      title: title,
      body: message,
      cancelLabel: localizations.cancel,
      confirmLabel: confirmLabel,
      destructive: destructive,
      icon: const DesignIcon('trash'),
    ),
  );
  return confirmed == true;
}

class _PlanPresetGrid extends StatelessWidget {
  const _PlanPresetGrid({required this.onCreatePlan});

  final void Function(BuildContext context, _PlanPreset plan) onCreatePlan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<_PlanPreset> presets = <_PlanPreset>[
      _PlanPreset.sevenDays,
      _PlanPreset.thirtyDays,
      _PlanPreset.sixtyDays,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeading(localizations.choosePlan),
        HairlineCard(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < presets.length; i++) ...<Widget>[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.equranTokens.hair,
                    ),
                  ReaderOptionRow(
                    leading: DesignIcon(presets[i].designIcon),
                    title: presets[i].title(localizations),
                    subtitle: presets[i].subtitle(localizations),
                    subtitleMaxLines: 2,
                    onTap: () => onCreatePlan(context, presets[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanPreset {
  const _PlanPreset({
    required this.type,
    required this.days,
    required this.designIcon,
  });

  final String type;
  final int days;
  final String designIcon;

  String title(AppLocalizations localizations) {
    return switch (type) {
      'complete_7_days' => localizations.preset7DaysTitle,
      'complete_30_days' => localizations.preset30DaysTitle,
      'complete_60_days' => localizations.preset60DaysTitle,
      _ => '',
    };
  }

  String subtitle(AppLocalizations localizations) {
    return switch (type) {
      'complete_7_days' => localizations.preset7DaysSubtitle,
      'complete_30_days' => localizations.preset30DaysSubtitle,
      'complete_60_days' => localizations.preset60DaysSubtitle,
      _ => '',
    };
  }

  static const _PlanPreset sevenDays = _PlanPreset(
    type: 'complete_7_days',
    days: 7,
    designIcon: 'sparkle',
  );

  static const _PlanPreset thirtyDays = _PlanPreset(
    type: 'complete_30_days',
    days: 30,
    designIcon: 'calendar',
  );

  static const _PlanPreset sixtyDays = _PlanPreset(
    type: 'complete_60_days',
    days: 60,
    designIcon: 'book',
  );
}

class _PlanProgress {
  const _PlanProgress({required this.completedAyahs, required this.totalAyahs});

  final int completedAyahs;
  final int totalAyahs;

  double get fraction {
    if (totalAyahs <= 0) return 0;
    return (completedAyahs / totalAyahs).clamp(0.0, 1.0).toDouble();
  }
}

class _AyahRef {
  const _AyahRef({required this.surah, required this.verse});

  final int surah;
  final int verse;
}

_PlanProgress _planProgress(ReadingPlanEntry plan, DateTime now) {
  final RoutineProgressSummary progress = routineProgressSummary(
    plan,
    now: now,
  );
  return _PlanProgress(
    completedAyahs: progress.completedAyahs,
    totalAyahs: progress.totalAyahs,
  );
}

_AyahRef _ayahRefFromGlobalIndex(int globalAyah) {
  int remaining = globalAyah.clamp(1, quran.totalVerseCount).toInt();
  for (int surah = 1; surah <= 114; surah++) {
    final int verseCount = quran.getVerseCount(surah);
    if (remaining <= verseCount) {
      return _AyahRef(surah: surah, verse: remaining);
    }
    remaining -= verseCount;
  }
  return const _AyahRef(surah: 114, verse: 6);
}

String _refLabel(_AyahRef ref) {
  return '${quran.getSurahName(ref.surah)} ${ref.verse}';
}

String _shortDate(DateTime date, String locale) {
  return DateFormat.MMMd(locale).format(date);
}
