import 'package:equran/home/read.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/common/pressable_scale.dart';
import 'package:equran/widgets/number_badge.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranJuzTile extends StatelessWidget {
  final String transliteration;
  final String name;
  final int id;
  final int startVerse;
  final int endVerse;

  const QuranJuzTile({
    super.key,
    required this.transliteration,
    required this.startVerse,
    required this.endVerse,
    required this.id,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final BorderRadius radius = BorderRadius.circular(EquranRadii.large);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool arabicMode = isArabicLocalizations(localizations);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PressableScale(
        child: Material(
          color: colors.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: () async {
              await Future.delayed(const Duration(milliseconds: 180));
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReadPage(
                    chapter: id,
                    startVerse: startVerse,
                    juzMode: true,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: radius,
                border: Border.all(color: tokens.hair),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: <Widget>[
                  NumberBadge(label: id.toString()),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          arabicMode ? name : transliteration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: arabicMode ? TextDirection.rtl : null,
                          style: arabicMode
                              ? theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  letterSpacing: 0,
                                )
                              : theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  letterSpacing: 0,
                                ),
                        ),
                        if (!arabicMode) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily:
                                  GoogleFonts.notoNaskhArabic().fontFamily,
                              color: tokens.emText,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _JuzMetaChip(
                              icon: 'quran',
                              label: localizations.ayahRange(
                                startVerse,
                                endVerse,
                              ),
                              colors: colors,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JuzMetaChip extends StatelessWidget {
  const _JuzMetaChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  /// A [DesignIcon] name.
  final String icon;
  final String label;
  final EquranColors colors;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EquranRadii.pill),
        border: Border.all(color: tokens.hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DesignIcon(icon, size: 14, color: tokens.text2),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tokens.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
