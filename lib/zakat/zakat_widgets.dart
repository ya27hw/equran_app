import 'package:equran/l10n/app_localizations.dart';
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
import 'package:flutter/material.dart';
import 'package:equran/theme/inter_optical_size.dart';

/// Presentational pieces of the Zakat calculator. They only draw; the page
/// keeps every figure, the nisab choice, prices and history storage.

/// The page's opening card: what Zakat al-Mal is and the flat rate.
class ZakatIntroHero extends StatelessWidget {
  const ZakatIntroHero({
    super.key,
    required this.title,
    required this.arabicTitle,
    required this.rateLabel,
    required this.subtitle,
  });

  final String title;
  final String arabicTitle;
  final String rateLabel;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final Color gold = tokens.featGold;
    return HeroPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DesignIcon('heart', size: 16, color: gold),
              const SizedBox(width: 8),
              Expanded(child: RedesignEyebrow(title, color: tokens.featText2)),
              const SizedBox(width: 10),
              HeroPill(rateLabel),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            arabicTitle,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 30,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: tokens.featText2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A hairline card with an icon-well header, used for every input group.
class ZakatCard extends StatelessWidget {
  const ZakatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return HairlineCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              ReaderIconWell(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontVariations: const [FontVariation('opsz', 15.5)],
                    fontWeight: FontWeight.w600,
                    color: context.equranColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: trailing!,
                ),
              ],
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: tokens.muted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A value shown on a card header: the amount a category adds up to.
class ZakatAmountLabel extends StatelessWidget {
  const ZakatAmountLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.end,
    textDirection: TextDirection.ltr,
    style: TextStyle(
      fontSize: 14.5,
      fontVariations: const [FontVariation('opsz', 14.5)],
      fontWeight: FontWeight.w600,
      color: context.equranTokens.emText,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    ),
  );
}

/// One metal rate: a small label over a serif figure.
class ZakatRateTile extends StatelessWidget {
  const ZakatRateTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.equranColors.surfaceAlt,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 12.5, color: tokens.text2)),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DisplayNumeral(value, size: 22, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

/// The currency row: a chip-like field that opens the picker.
class ZakatCurrencyButton extends StatelessWidget {
  const ZakatCurrencyButton({
    super.key,
    required this.label,
    required this.currency,
    required this.onPressed,
  });

  final String label;
  final String currency;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Semantics(
      button: true,
      label: '$label: $currency',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(EquranRadii.large),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 12, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(EquranRadii.large),
              border: Border.all(color: tokens.hair2),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, color: tokens.text2),
                  ),
                ),
                Text(
                  currency,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 15,
                    fontVariations: const [FontVariation('opsz', 15)],
                    fontWeight: FontWeight.w600,
                    color: tokens.emText,
                  ),
                ),
                const SizedBox(width: 6),
                DesignIcon('chevd', size: 18, color: tokens.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The silver / gold nisab choice: the selected one sits on the emerald wash
/// and carries a check, so the state is never colour alone.
class ZakatNisabChoice extends StatelessWidget {
  const ZakatNisabChoice({
    super.key,
    required this.label,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(EquranRadii.xl);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? tokens.emWash : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? tokens.hair2 : tokens.hair),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? tokens.filled : Colors.transparent,
                        border: Border.all(
                          color: selected ? tokens.filled : tokens.hair2,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const DesignIcon(
                              'check',
                              size: 12,
                              strokeWidth: 2.4,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontVariations: const [FontVariation('opsz', 14.5)],
                          fontWeight: FontWeight.w600,
                          color: selected ? tokens.emText : colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: DisplayNumeral(amount, size: 22, height: 1.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A minus, count and plus row for the livestock heads.
class ZakatStepperRow extends StatelessWidget {
  const ZakatStepperRow({
    super.key,
    required this.label,
    required this.count,
    required this.onChanged,
    required this.decreaseTooltip,
    required this.increaseTooltip,
  });

  final String label;
  final int count;
  final ValueChanged<int> onChanged;
  final String decreaseTooltip;
  final String increaseTooltip;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: context.equranColors.surfaceAlt,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontVariations: const [FontVariation('opsz', 14.5)],
                fontWeight: FontWeight.w600,
                color: context.equranColors.textPrimary,
              ),
            ),
          ),
          IconButton44(
            icon: Icons.remove_rounded,
            tooltip: decreaseTooltip,
            ghost: true,
            onPressed: count > 0 ? () => onChanged(count - 1) : null,
          ),
          SizedBox(
            width: 34,
            child: DisplayNumeral('$count', size: 22, height: 1.2),
          ),
          IconButton44(
            designIcon: 'plus',
            tooltip: increaseTooltip,
            ghost: true,
            onPressed: () => onChanged(count + 1),
          ),
        ],
      ),
    );
  }
}

/// The result: net wealth, eligibility and the Zakat due, on a hero panel.
class ZakatResultHero extends StatelessWidget {
  const ZakatResultHero({
    super.key,
    required this.netLabel,
    required this.netAmount,
    required this.statusLabel,
    required this.eligible,
    required this.dueLabel,
    required this.dueAmount,
    this.showHeart = false,
    this.note,
  });

  final String netLabel;
  final String netAmount;
  final String statusLabel;
  final bool eligible;
  final String dueLabel;
  final String dueAmount;

  /// A heart badge beside the figure when Zakat is due.
  final bool showHeart;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final Color gold = tokens.featGold;
    final Color ink = tokens.onFeat;
    return HeroPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  netLabel,
                  style: TextStyle(fontSize: 14, color: tokens.featText2),
                ),
              ),
              const SizedBox(width: 10),
              HeroPill(
                statusLabel,
                strong: eligible,
                icon: eligible
                    ? const DesignIcon('check', size: 14, strokeWidth: 2)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: DisplayNumeral(
                netAmount,
                size: 40,
                height: 1.1,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: ink.withValues(alpha: 0.16)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RedesignEyebrow(dueLabel, color: tokens.featText2),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: DisplayNumeral(
                          dueAmount,
                          size: 30,
                          height: 1.1,
                          color: gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showHeart) ...<Widget>[
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.16),
                    border: Border.all(color: gold.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: DesignIcon('heart', size: 20, color: gold),
                ),
              ],
            ],
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              note!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: tokens.featText2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A line item in the result breakdown: the category and its value.
class ZakatBreakdownList extends StatelessWidget {
  const ZakatBreakdownList({super.key, required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return HairlineCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, thickness: 1, color: tokens.hair),
            ZakatValueRow(label: rows[i].$1, value: rows[i].$2),
          ],
        ],
      ),
    );
  }
}

/// A label and a figure on one line (breakdown and history rows).
class ZakatValueRow extends StatelessWidget {
  const ZakatValueRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasis ? 15 : 14,
                fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
                color: emphasis ? tokens.emText : tokens.text2,
              ).withInterOpticalSize(),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: emphasis ? 15 : 14,
              fontWeight: FontWeight.w600,
              color: emphasis ? tokens.emText : colors.textPrimary,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ).withInterOpticalSize(),
          ),
        ],
      ),
    );
  }
}

/// A unit switch (grams or tola) beside a weight field.
class ZakatUnitPicker extends StatelessWidget {
  const ZakatUnitPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Container(
      height: 36,
      padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EquranRadii.pill),
        border: Border.all(color: tokens.hair2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          onChanged: (String? v) {
            if (v != null) onChanged(v);
          },
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(value: 'grams', child: Text('g')),
            DropdownMenuItem<String>(
              value: 'bhori',
              child: Text(AppLocalizations.of(context)!.unitTola),
            ),
          ],
          icon: DesignIcon('chevd', size: 16, color: tokens.muted),
          borderRadius: BorderRadius.circular(EquranRadii.large),
          dropdownColor: context.equranColors.surface,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontFamilyFallback: const <String>['NotoNaskhArabic'],
            color: context.equranColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// A saved calculation in the history tab.
class ZakatHistoryCard extends StatelessWidget {
  const ZakatHistoryCard({
    super.key,
    required this.title,
    required this.rows,
    required this.dueLabel,
    required this.dueAmount,
    required this.paidLabel,
    required this.paidAmount,
    required this.deleteTooltip,
    required this.editTooltip,
    required this.onDelete,
    required this.onEditPaid,
  });

  final String title;
  final List<(String, String)> rows;
  final String dueLabel;
  final String dueAmount;
  final String paidLabel;
  final String paidAmount;
  final String deleteTooltip;
  final String editTooltip;
  final VoidCallback onDelete;
  final VoidCallback onEditPaid;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return HairlineCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ReaderIconWell(icon: DesignIcon('calendar'), size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontVariations: const [FontVariation('opsz', 14.5)],
                    fontWeight: FontWeight.w600,
                    color: context.equranColors.textPrimary,
                  ),
                ),
              ),
              IconButton44(
                designIcon: 'trash',
                tooltip: deleteTooltip,
                ghost: true,
                onPressed: onDelete,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Divider(height: 1, thickness: 1, color: tokens.hair),
                for (final (String label, String value) in rows)
                  ZakatValueRow(label: label, value: value),
                Divider(height: 1, thickness: 1, color: tokens.hair),
                ZakatValueRow(
                  label: dueLabel,
                  value: dueAmount,
                  emphasis: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    paidLabel,
                    style: TextStyle(fontSize: 14, color: tokens.text2),
                  ),
                ),
                Text(
                  paidAmount,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.equranColors.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                IconButton44(
                  designIcon: 'edit',
                  tooltip: editTooltip,
                  ghost: true,
                  onPressed: onEditPaid,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The empty history state: a quiet icon well, a title and a hint.
class ZakatEmptyState extends StatelessWidget {
  const ZakatEmptyState({super.key, required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ReaderIconWell(
              icon: DesignIcon('calendar', size: 28),
              size: 64,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: redesignDisplayStyle(context, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: tokens.text2),
            ),
          ],
        ),
      ),
    );
  }
}
