import 'package:equran/home/read.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/number_badge.dart';
import 'package:flutter/material.dart';

/// One surah slice of a juz: a row of the juz' grouped card. It draws no
/// surface of its own; `GroupedCardSliver` does, and [inkRadius] rounds the
/// ripple of the first and last row.
class QuranJuzTile extends StatelessWidget {
  final String transliteration;
  final String name;
  final int id;
  final int startVerse;
  final int endVerse;
  final BorderRadius inkRadius;

  const QuranJuzTile({
    super.key,
    required this.transliteration,
    required this.startVerse,
    required this.endVerse,
    required this.id,
    required this.name,
    this.inkRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool arabicMode = isArabicLocalizations(localizations);
    final TextStyle? arabicStyle = theme.textTheme.titleMedium?.copyWith(
      fontFamily: EquranTextStyles.activeFontFamily == 'QuranIndoPak'
          ? 'UthmanicHafs'
          : EquranTextStyles.activeFontFamily,
      fontFamilyFallback: const <String>['UthmanicHafs'],
      fontSize: 21,
      height: 1.1,
    );
    final TextStyle? titleStyle = arabicMode
        ? arabicStyle
        : theme.textTheme.titleMedium;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: inkRadius,
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 180));
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ReadPage(chapter: id, startVerse: startVerse, juzMode: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              SurahNumberBadge(number: id, size: 40),
              const SizedBox(width: EquranSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      arabicMode ? name : transliteration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: arabicMode ? TextDirection.rtl : null,
                      style: titleStyle?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      localizations.ayahRange(startVerse, endVerse),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!arabicMode) ...<Widget>[
                const SizedBox(width: EquranSpacing.m),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: arabicStyle?.copyWith(color: tokens.emText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
