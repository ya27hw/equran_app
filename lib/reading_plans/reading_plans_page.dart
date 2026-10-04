import 'package:equran/widgets/common/equran_asset_image.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/home/read.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/reading_plans/routine_progress.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:quran/quran.dart' as quran;

const String _routineDesignAsset = 'assets/media/images/app/design.webp';

class ReadingPlansPage extends StatelessWidget {
  const ReadingPlansPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

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
                      _RoutineHero(plan: activePlan),
                      const SizedBox(height: 18),
                      _ActivitySummary(plan: activePlan),
                      const SizedBox(height: 14),
                      if (activePlan == null)
                        _EmptyRoutineCard(onCreate: _createThirtyDayPlan)
                      else
                        _TodayTaskCard(plan: activePlan),
                      const SizedBox(height: 14),
                      _RoutineHistorySection(
                        plans: plans,
                        activePlan: activePlan,
                      ),
                      const SizedBox(height: 22),
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

class _RoutineHero extends StatelessWidget {
  const _RoutineHero({required this.plan});

  final ReadingPlanEntry? plan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final _PlanProgress? progress = plan == null ? null : _planProgress(plan!);

    return EquranGradientCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -12,
            bottom: -16,
            width: 150,
            height: 120,
            child: Opacity(
              opacity: 0.20,
              child: EquranAssetImage(_routineDesignAsset, fit: BoxFit.cover),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  EquranIconBadge(
                    icon: Icons.calendar_month_rounded,
                    backgroundColor: colors.onPrimary.withAlpha(26),
                    foregroundColor: colors.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      plan == null
                          ? localizations.buildQuranRoutine
                          : _localizedPlanTitle(plan!, localizations),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                plan == null
                    ? localizations.chooseGentlePlan
                    : localizations.routineCompletedAyahs(
                        progress!.completedAyahs,
                        progress.totalAyahs,
                      ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryMuted,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(EquranRadii.pill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress?.fraction ?? 0,
                  color: colors.onPrimary,
                  backgroundColor: colors.onPrimary.withAlpha(40),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                plan == null
                    ? localizations.plansReadyNotice
                    : localizations.finishTargetDate(
                        _shortDate(plan!.finishBy, localizations.localeName),
                      ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.plan});

  final ReadingPlanEntry? plan;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bool done = plan != null && routineProgressSummary(plan!).isTodayDone;
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
      children: items.map((item) => _SummaryPill(item: item)).toList(),
    );
  }
}

class _SummaryPillData {
  const _SummaryPillData(this.label, this.count);

  final String label;
  final int count;
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.item});

  final _SummaryPillData item;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.count > 0 ? colors.mint : colors.surface,
        borderRadius: BorderRadius.circular(EquranRadii.pill),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        '${item.label} ${item.count}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: item.count > 0 ? colors.primary : colors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyRoutineCard extends StatelessWidget {
  const _EmptyRoutineCard({required this.onCreate});

  final void Function(BuildContext context) onCreate;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return EquranSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localizations.noActiveRoutine,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.startBalancedPlanDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onCreate(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(localizations.start30DayPlan),
          ),
        ],
      ),
    );
  }
}

class _TodayTaskCard extends StatelessWidget {
  const _TodayTaskCard({required this.plan});

  final ReadingPlanEntry plan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final RoutineProgressSummary progress = routineProgressSummary(plan);
    final _AyahRef start = _ayahRefFromGlobalIndex(
      progress.todayStartGlobalAyah,
    );
    final _AyahRef end = _ayahRefFromGlobalIndex(progress.todayEndGlobalAyah);
    final bool done = progress.isTodayDone;
    final double dailyFraction = progress.todayFraction;
    final int percentComplete = (dailyFraction * 100).round();

    return EquranSurfaceCard(
      backgroundColor: done ? null : colors.surface,
      borderColor: done ? colors.primary.withAlpha(90) : colors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              EquranIconBadge(
                icon: done ? Icons.check_rounded : Icons.menu_book_outlined,
                backgroundColor: done ? colors.primary : colors.mint,
                foregroundColor: done ? colors.onPrimary : colors.primary,
              ),
              const SizedBox(width: 12),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (!progress.isRoutineDone &&
                        progress.catchUpAyahs > 0) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        localizations.includesCatchUpAyahs(
                          progress.catchUpAyahs,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else if (!progress.isRoutineDone) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        localizations.ayahRangeConnector(
                          _refLabel(start),
                          _refLabel(end),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
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
              color: colors.primary,
              backgroundColor: colors.mint,
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: progress.isRoutineDone
                ? null
                : () => _openContinue(context),
            icon: const Icon(Icons.play_arrow_rounded),
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
    final RoutineProgressSummary progress = routineProgressSummary(plan);
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
  const _RoutineHistorySection({required this.plans, required this.activePlan});

  final List<ReadingPlanEntry> plans;
  final ReadingPlanEntry? activePlan;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<ReadingPlanEntry> pastPlans = plans
        .where((ReadingPlanEntry plan) => !plan.active)
        .toList(growable: false);

    return EquranSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localizations.routineHistory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (activePlan != null)
            _RoutineHistoryTile(
              plan: activePlan!,
              label: localizations.currentRoutine,
              onDelete: () => _deleteRoutine(context, activePlan!),
            )
          else
            Text(
              localizations.noCurrentRoutine,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          if (pastPlans.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                localizations.pastRoutines,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              children: <Widget>[
                for (final ReadingPlanEntry plan in pastPlans)
                  _RoutineHistoryTile(
                    plan: plan,
                    label: localizations.pastRoutine,
                    onDelete: () => _deleteRoutine(context, plan),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineHistoryTile extends StatelessWidget {
  const _RoutineHistoryTile({
    required this.plan,
    required this.label,
    required this.onDelete,
  });

  final ReadingPlanEntry plan;
  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final _PlanProgress progress = _planProgress(plan);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: EquranIconBadge(
        icon: plan.active ? Icons.route_outlined : Icons.history_rounded,
        size: 38,
      ),
      title: Text(_localizedPlanTitle(plan, localizations)),
      subtitle: Text(
        '$label • ${localizations.completedAyahsRatio(progress.completedAyahs, progress.totalAyahs)} • ${_shortDate(plan.startedAt, localizations.localeName)}',
      ),
      trailing: IconButton(
        tooltip: localizations.deleteRoutineTooltip,
        onPressed: onDelete,
        color: colors.textMuted,
        icon: const Icon(Icons.delete_outline_rounded),
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
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          localizations.choosePlan,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool twoColumn = constraints.maxWidth >= 620;
            return GridView.builder(
              itemCount: presets.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: twoColumn ? 2 : 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: twoColumn ? 3.2 : 3.8,
              ),
              itemBuilder: (BuildContext context, int index) {
                return _PlanPresetCard(
                  preset: presets[index],
                  onTap: () => onCreatePlan(context, presets[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PlanPresetCard extends StatelessWidget {
  const _PlanPresetCard({required this.preset, required this.onTap});

  final _PlanPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return EquranSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: <Widget>[
          EquranIconBadge(icon: preset.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  preset.title(localizations),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  preset.subtitle(localizations),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        ],
      ),
    );
  }
}

class _PlanPreset {
  const _PlanPreset({
    required this.type,
    required this.days,
    required this.icon,
  });

  final String type;
  final int days;
  final IconData icon;

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
    icon: Icons.bolt_outlined,
  );

  static const _PlanPreset thirtyDays = _PlanPreset(
    type: 'complete_30_days',
    days: 30,
    icon: Icons.calendar_month_outlined,
  );

  static const _PlanPreset sixtyDays = _PlanPreset(
    type: 'complete_60_days',
    days: 60,
    icon: Icons.auto_stories_outlined,
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

_PlanProgress _planProgress(ReadingPlanEntry plan) {
  final RoutineProgressSummary progress = routineProgressSummary(plan);
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
