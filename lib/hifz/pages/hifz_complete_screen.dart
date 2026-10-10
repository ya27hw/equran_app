import 'package:flutter/material.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/hifz/hifz_db.dart';
import 'package:equran/hifz/hifz_unit_labels.dart';
import 'package:equran/hifz/models/hifz_unit.dart';
import 'hifz_session_page.dart';
import 'package:equran/l10n/app_localizations.dart';

class HifzCompleteScreen extends StatefulWidget {
  final Map<String, int> ratingCounts;
  final Duration sessionDuration;
  final int totalReviewed;
  final int newGraduated;
  final HifzUnit unit;

  const HifzCompleteScreen({
    required this.ratingCounts,
    required this.sessionDuration,
    required this.totalReviewed,
    required this.newGraduated,
    required this.unit,
    super.key,
  });

  @override
  State<HifzCompleteScreen> createState() => _HifzCompleteScreenState();
}

class _HifzCompleteScreenState extends State<HifzCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _sessionSubtitle(AppLocalizations l10n) {
    final mins = widget.sessionDuration.inMinutes;
    if (mins < 1) return l10n.hifzCompleteSubtitleUnderMinute;
    return l10n.hifzCompleteSubtitleMinutes(mins);
  }

  String _retentionLabel() {
    final total = widget.ratingCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return '—';
    final positive =
        (widget.ratingCounts['good'] ?? 0) +
        (widget.ratingCounts['easy'] ?? 0) +
        (widget.ratingCounts['pass'] ?? 0) +
        (widget.ratingCounts['gotIt'] ?? 0);
    final pct = (positive / total * 100).toStringAsFixed(0);
    return '$pct%';
  }

  String _nextDueLabel(AppLocalizations l10n) {
    final due = HifzDB.getDueEntries();
    if (due.isEmpty) return l10n.hifzCompleteAllCaughtUp;
    final next = due.first.dueDate;
    final diff = next.difference(DateTime.now()).inDays;
    if (diff <= 0) return l10n.hifzCompleteNextDueToday;
    if (diff == 1) return l10n.hifzCompleteNextDueTomorrow;
    return l10n.hifzCompleteNextDueInDays(diff);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.equranColors;
    final tokens = context.equranTokens;
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final dueCount = HifzDB.getDueEntries().length;
    final heroInk = tokens.onFeat;

    Widget fade(double from, Widget child) => reduceMotion
        ? child
        : FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Interval(from, 1.0),
            ),
            child: child,
          );

    return Material(
      color: colors.background,
      child: RedesignPageTypography(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // COMPLETION HERO
                HeroPanel(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        builder: (_, value, child) => Transform.scale(
                          scale: value.clamp(0.0, 1.2),
                          child: child,
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.featGold.withValues(alpha: 0.14),
                            border: Border.all(
                              color: tokens.featGold.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Center(
                            child: DesignIcon(
                              'check',
                              size: 38,
                              strokeWidth: 1.8,
                              color: tokens.featGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      fade(
                        0.3,
                        Text(
                          l10n.hifzCompleteTitle,
                          style: redesignDisplayStyle(
                            context,
                            size: 32,
                            color: heroInk,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sessionSubtitle(l10n),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: tokens.featText2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                if (widget.unit.isComplete) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: tokens.goldWash,
                      borderRadius: BorderRadius.circular(EquranRadii.xl),
                      border: Border.all(
                        color: tokens.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        DesignIcon(
                          'trophy',
                          size: 30,
                          strokeWidth: 1.5,
                          color: tokens.gold,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.hifzUnitCompleteTitle(
                            hifzUnitLabel(widget.unit, l10n),
                          ),
                          style: redesignDisplayStyle(context, size: 22),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.hifzUnitCompleteSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: tokens.text2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // SUMMARY
                fade(
                  0.4,
                  HairlineCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RedesignEyebrow(l10n.hifzCompleteSummaryTitle),
                        const SizedBox(height: 14),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StatTile(
                                label: l10n.hifzRatingTryAgain,
                                count: widget.ratingCounts['again'] ?? 0,
                                bgColor: colors.surfaceAlt,
                                textColor: tokens.text2,
                              ),
                              const SizedBox(width: 8),
                              _StatTile(
                                label: l10n.hifzRatingGotIt,
                                count: widget.ratingCounts['gotIt'] ?? 0,
                                bgColor: tokens.emWash,
                                textColor: tokens.emText,
                              ),
                              const SizedBox(width: 8),
                              _StatTile(
                                label: l10n.hifzRatingFail,
                                count: widget.ratingCounts['fail'] ?? 0,
                                bgColor: tokens.goldWash,
                                textColor: tokens.goldText,
                              ),
                              const SizedBox(width: 8),
                              _StatTile(
                                label: l10n.hifzRatingPass,
                                count: widget.ratingCounts['pass'] ?? 0,
                                bgColor: tokens.emWash,
                                textColor: tokens.emText,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SummaryRow(
                          label: l10n.hifzCompleteTotalReviewed,
                          value: l10n.hifzCompleteTotalReviewedValue(
                            widget.totalReviewed,
                          ),
                        ),
                        if (widget.newGraduated > 0)
                          _SummaryRow(
                            label: l10n.hifzCompleteGraduated,
                            value: l10n.hifzCompleteGraduatedValue(
                              widget.newGraduated,
                            ),
                          ),
                        _SummaryRow(
                          label: l10n.hifzCompleteRetentionRate,
                          value: _retentionLabel(),
                        ),
                        _SummaryRow(
                          label: l10n.hifzCompleteNextDue,
                          value: _nextDueLabel(l10n),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // MOTIVATIONAL HADITH SNIPPET
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.goldWash,
                    borderRadius: BorderRadius.circular(EquranRadii.large),
                  ),
                  child: Text(
                    l10n.hifzCompleteHadith,
                    style: EquranTextStyles.displayTranslation(
                      context,
                      color: tokens.goldText,
                    ).copyWith(fontFamilyFallback: const ['NotoNaskhArabic']),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // BUTTONS
                FilledButton(
                  style: readerFilledButtonStyle(context).copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
                  ),
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.isFirst || route.settings.name == '/hifz',
                  ),
                  child: Text(l10n.hifzCompleteBackButton),
                ),

                if (dueCount > 0) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: readerOutlinedButtonStyle(context).copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => HifzSessionPage(unit: widget.unit),
                        ),
                      );
                    },
                    child: Text(l10n.hifzCompleteKeepReviewing(dueCount)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One rating count: a number over its label.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.count,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final int count;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: context.equranTokens.hair),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DisplayNumeral('$count', size: 26, color: textColor),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.2, color: textColor),
          ),
        ],
      ),
    ),
  );
}

/// A label and its value on one hairline-separated row.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.hair)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, height: 1.3, color: tokens.text2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: context.equranColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
