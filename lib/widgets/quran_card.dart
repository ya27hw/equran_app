import 'package:equran/backend/surah_model.dart';
import 'package:equran/home/read.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/utils/responsive_nav.dart';
import 'package:equran/widgets/common/pressable_scale.dart';
import 'package:equran/widgets/number_badge.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

class QuranCard extends StatelessWidget {
  final Surah surah;
  final bool compact;
  final bool reduceTitleSize;

  /// A row inside the grouped hairline list: no surface or border of its own,
  /// the list draws them. [inkRadius] rounds the first and last row's ripple.
  final bool grouped;
  final BorderRadius inkRadius;

  const QuranCard({
    super.key,
    required this.surah,
    this.compact = false,
    this.reduceTitleSize = false,
    this.grouped = false,
    this.inkRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final bool tabletLayout = ResponsiveNav.isTablet(context);
    final bool compactText = compact && reduceTitleSize;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool rtlMode =
        localizations.localeName == 'ar' ||
        localizations.localeName == 'ur' ||
        localizations.localeName == 'fa';
    final BorderRadius radius = grouped
        ? inkRadius
        : BorderRadius.circular(EquranRadii.large);
    final double verticalPadding = grouped
        ? 14
        : compact
        ? (tabletLayout ? 14 : 12)
        : (tabletLayout ? 17 : 15);
    final TextStyle? titleStyle =
        (compactText
                ? theme.textTheme.titleSmall
                : compact
                ? theme.textTheme.titleLarge
                : theme.textTheme.titleMedium)
            ?.copyWith(fontWeight: FontWeight.w600);
    final TextStyle? arabicTitleStyle =
        (compactText
                ? theme.textTheme.titleSmall
                : compact
                ? theme.textTheme.titleLarge
                : theme.textTheme.titleMedium)
            ?.copyWith(
              color: colors.textPrimary,
              fontFamily: EquranTextStyles.activeFontFamily == 'QuranIndoPak'
                  ? 'UthmanicHafs'
                  : EquranTextStyles.activeFontFamily,
              fontFamilyFallback: const <String>['UthmanicHafs'],
              fontSize: compactText
                  ? 19
                  : compact
                  ? 22
                  : 21,
              height: 1.1,
            );
    final TextStyle? versesStyle =
        (compactText
                ? theme.textTheme.bodySmall
                : compact
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyMedium)
            ?.copyWith(color: tokens.muted, fontSize: grouped ? 12.5 : null);

    final Widget row = Row(
      children: <Widget>[
        SurahNumberBadge(number: surah.id, size: compact ? 38 : 40),
        const SizedBox(width: EquranSpacing.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                rtlMode
                    ? surah.name
                    : localizedSurahName(localizations, surah.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: rtlMode ? TextDirection.rtl : null,
                style: (rtlMode ? arabicTitleStyle : titleStyle)?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                rtlMode
                    ? localizations.versesCount(surah.verses)
                    : '${surah.englishName} • ${localizations.versesCount(surah.verses)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: rtlMode ? TextDirection.rtl : null,
                style: versesStyle,
              ),
            ],
          ),
        ),
        if (!rtlMode) ...<Widget>[
          const SizedBox(width: EquranSpacing.m),
          Text(
            surah.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
            style: arabicTitleStyle?.copyWith(color: tokens.emText),
          ),
        ],
      ],
    );

    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: grouped ? 16 : (compact ? 8 : 10),
      vertical: verticalPadding,
    );

    void open() => Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ReadPage(chapter: surah.id)),
    );

    if (grouped) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: open,
          child: Padding(padding: padding, child: row),
        ),
      );
    }

    return PressableScale(
      child: Material(
        color: colors.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: open,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: radius,
              border: Border.all(color: tokens.hair),
            ),
            padding: padding,
            child: row,
          ),
        ),
      ),
    );
  }
}
