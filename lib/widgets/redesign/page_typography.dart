import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

/// Font scope for redesigned interface chrome. Reader typography stays separate.
class RedesignPageTypography extends StatelessWidget {
  const RedesignPageTypography({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final family =
        const [
          'ar',
          'fa',
          'ur',
        ].contains(Localizations.localeOf(context).languageCode)
        ? 'NotoNaskhArabic'
        : 'Inter';
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: family,
          fontFamilyFallback: const ['NotoNaskhArabic'],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: family,
          fontFamilyFallback: const ['NotoNaskhArabic'],
          color: context.equranColors.textPrimary,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.3,
              colors: [
                context.equranTokens.glow,
                context.equranTokens.glow.withValues(alpha: 0),
              ],
              stops: const [0, .62],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

TextStyle redesignDisplayStyle(
  BuildContext context, {
  double size = 36,
  double height = 1.08,
  Color? color,
}) => EquranTextStyles.displayPageTitle(context, color: color).copyWith(
  fontSize: size,
  height: height,
  letterSpacing: (size == 24 ? -.01 : -.015) * size,
  fontVariations: [
    FontVariation('opsz', size),
    const FontVariation('wght', 500),
  ],
  fontFamilyFallback: const ['NotoNaskhArabic'],
);

class RedesignEyebrow extends StatelessWidget {
  const RedesignEyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final arabic = const [
      'ar',
      'fa',
      'ur',
    ].contains(Localizations.localeOf(context).languageCode);
    return Text(
      arabic ? text : text.toUpperCase(),
      style: EquranTextStyles.eyebrow(context).copyWith(
        color: color,
        fontFamily: arabic ? 'NotoNaskhArabic' : 'Inter',
        height: arabic ? 1.6 : 1,
        letterSpacing: arabic ? 0 : 1.54,
      ),
    );
  }
}
