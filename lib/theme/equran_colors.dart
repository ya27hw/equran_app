import 'package:flutter/material.dart';

@immutable
class EquranColors extends ThemeExtension<EquranColors> {
  const EquranColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceSoft,
    required this.primary,
    required this.primaryStrong,
    required this.primarySoft,
    required this.primaryGradientStart,
    required this.primaryGradientEnd,
    required this.mint,
    required this.paleGreen,
    required this.accentGold,
    required this.goldSoft,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onPrimary,
    required this.onPrimaryMuted,
    required this.warning,
    required this.warningSurface,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceSoft;
  final Color primary;
  final Color primaryStrong;
  final Color primarySoft;
  final Color primaryGradientStart;
  final Color primaryGradientEnd;
  final Color mint;
  final Color paleGreen;
  final Color accentGold;
  final Color goldSoft;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color onPrimary;
  final Color onPrimaryMuted;
  final Color warning;
  final Color warningSurface;
  final Color shadow;

  /// Resolve the accent palette independently of the dark-background preference.
  /// The former `black` palette remains readable in older settings and backups.
  static EquranColors forScheme(
    String? scheme,
    bool isDark, {
    bool? pureBlackBackground,
  }) {
    final EquranColors colors = isDark
        ? switch (scheme) {
            'fancyBlue' => fancyBlueDark,
            'fancyPurple' => fancyPurpleDark,
            'sepia' => sepiaDark,
            'red' => redDark,
            _ => dark,
          }
        : switch (scheme) {
            'fancyBlue' => fancyBlueLight,
            'fancyPurple' => fancyPurpleLight,
            'sepia' => sepiaLight,
            'red' => redLight,
            _ => light,
          };
    final bool pureBlack = pureBlackBackground ?? scheme == 'black';
    return isDark && pureBlack
        ? colors.copyWith(background: Colors.black, surfaceSoft: Colors.black)
        : colors;
  }

  static const EquranColors light = EquranColors(
    background: Color(0xFFFAFAF7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6F7F3),
    surfaceSoft: Color(0xFFFBFBF8),
    primary: Color(0xFF176B55),
    primaryStrong: Color(0xFF145D4A),
    primarySoft: Color(0xFF247B62),
    primaryGradientStart: Color(0xFF1E735D),
    primaryGradientEnd: Color(0xFF8FC5A5),
    mint: Color(0xFFEAF6EF),
    paleGreen: Color(0xFFF5FBF7),
    accentGold: Color(0xFFD6A84F),
    goldSoft: Color(0xFFE8D6A8),
    border: Color(0xFFE5E7DF),
    divider: Color(0xFFE8E8E2),
    textPrimary: Color(0xFF1E2420),
    textSecondary: Color(0xFF69716B),
    textMuted: Color(0xFF8A918B),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFCBEADF),
    warning: Color(0xFF9B6A16),
    warningSurface: Color(0xFFFFF7E2),
    shadow: Color(0xFF14241E),
  );

  static const EquranColors dark = EquranColors(
    background: Color(0xFF07110E),
    surface: Color(0xFF111A17),
    surfaceAlt: Color(0xFF17211E),
    surfaceSoft: Color(0xFF0C1713),
    primary: Color(0xFF1E7A61),
    primaryStrong: Color(0xFF125B49),
    primarySoft: Color(0xFF7ED6B2),
    primaryGradientStart: Color(0xFF145F4D),
    primaryGradientEnd: Color(0xFF2A8A6D),
    mint: Color(0xFF183027),
    paleGreen: Color(0xFF10221B),
    accentGold: Color(0xFFD6A84F),
    goldSoft: Color(0xFF66542E),
    border: Color(0xFF26332E),
    divider: Color(0xFF23302A),
    textPrimary: Color(0xFFF3F7F4),
    textSecondary: Color(0xFFB8C2BC),
    textMuted: Color(0xFF83908A),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFDDEEE6),
    warning: Color(0xFFE0B866),
    warningSurface: Color(0xFF2D2414),
    shadow: Color(0xFF000000),
  );

  static const EquranColors fancyBlueLight = EquranColors(
    background: Color(0xFFF6F9FE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF4FC),
    surfaceSoft: Color(0xFFF9FBFF),
    primary: Color(0xFF1C63A7),
    primaryStrong: Color(0xFF124A82),
    primarySoft: Color(0xFF2D7FCC),
    primaryGradientStart: Color(0xFF123D73),
    primaryGradientEnd: Color(0xFF56B4D8),
    mint: Color(0xFFE4F3FB),
    paleGreen: Color(0xFFF1F7FD),
    accentGold: Color(0xFFD8AE55),
    goldSoft: Color(0xFFE7D6AA),
    border: Color(0xFFDDE7F3),
    divider: Color(0xFFE3EAF4),
    textPrimary: Color(0xFF162232),
    textSecondary: Color(0xFF657386),
    textMuted: Color(0xFF8794A6),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFDCEBFA),
    warning: Color(0xFF9B6A16),
    warningSurface: Color(0xFFFFF7E2),
    shadow: Color(0xFF102238),
  );

  static const EquranColors fancyBlueDark = EquranColors(
    background: Color(0xFF06101C),
    surface: Color(0xFF101B28),
    surfaceAlt: Color(0xFF172638),
    surfaceSoft: Color(0xFF0A1624),
    primary: Color(0xFF3B8DD6),
    primaryStrong: Color(0xFF1D5E9C),
    primarySoft: Color(0xFF8EC9F4),
    primaryGradientStart: Color(0xFF123D73),
    primaryGradientEnd: Color(0xFF2E91B9),
    mint: Color(0xFF142F46),
    paleGreen: Color(0xFF0D2437),
    accentGold: Color(0xFFD8AE55),
    goldSoft: Color(0xFF5F5133),
    border: Color(0xFF28384A),
    divider: Color(0xFF243346),
    textPrimary: Color(0xFFF4F8FC),
    textSecondary: Color(0xFFB9C6D5),
    textMuted: Color(0xFF8493A5),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFE2F3FF),
    warning: Color(0xFFE0B866),
    warningSurface: Color(0xFF2D2414),
    shadow: Color(0xFF000000),
  );

  static const EquranColors fancyPurpleLight = EquranColors(
    background: Color(0xFFFAF7FE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF3EFFB),
    surfaceSoft: Color(0xFFFCFAFF),
    primary: Color(0xFF6C3BAA),
    primaryStrong: Color(0xFF4C267E),
    primarySoft: Color(0xFF9368D0),
    primaryGradientStart: Color(0xFF3D236C),
    primaryGradientEnd: Color(0xFFA36DE0),
    mint: Color(0xFFF0E8FA),
    paleGreen: Color(0xFFF8F3FD),
    accentGold: Color(0xFFD7AF5A),
    goldSoft: Color(0xFFE7D6AA),
    border: Color(0xFFE7DFF0),
    divider: Color(0xFFEAE2F3),
    textPrimary: Color(0xFF261B34),
    textSecondary: Color(0xFF74677F),
    textMuted: Color(0xFF93879C),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFEADBFC),
    warning: Color(0xFF9B6A16),
    warningSurface: Color(0xFFFFF7E2),
    shadow: Color(0xFF1E142B),
  );

  static const EquranColors fancyPurpleDark = EquranColors(
    background: Color(0xFF100A19),
    surface: Color(0xFF1A1225),
    surfaceAlt: Color(0xFF251A34),
    surfaceSoft: Color(0xFF140D20),
    primary: Color(0xFF9368D0),
    primaryStrong: Color(0xFF6F43AE),
    primarySoft: Color(0xFFC7A7F4),
    primaryGradientStart: Color(0xFF40206F),
    primaryGradientEnd: Color(0xFF9B5ED0),
    mint: Color(0xFF2B2040),
    paleGreen: Color(0xFF21162F),
    accentGold: Color(0xFFD7AF5A),
    goldSoft: Color(0xFF5D4E32),
    border: Color(0xFF352843),
    divider: Color(0xFF30243C),
    textPrimary: Color(0xFFF8F4FC),
    textSecondary: Color(0xFFCABED6),
    textMuted: Color(0xFF9B8DA7),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFF2E8FF),
    warning: Color(0xFFE0B866),
    warningSurface: Color(0xFF2D2414),
    shadow: Color(0xFF000000),
  );

  static const EquranColors sepiaLight = EquranColors(
    background: Color(0xFFF8F1E6),
    surface: Color(0xFFFFFAF1),
    surfaceAlt: Color(0xFFF0E3CF),
    surfaceSoft: Color(0xFFFBF4E8),
    primary: Color(0xFF8B5E2E),
    primaryStrong: Color(0xFF5E3A1D),
    primarySoft: Color(0xFFB9894D),
    primaryGradientStart: Color(0xFF5E371B),
    primaryGradientEnd: Color(0xFFC39A57),
    mint: Color(0xFFF0E2CC),
    paleGreen: Color(0xFFFAF0DF),
    accentGold: Color(0xFFD1A24B),
    goldSoft: Color(0xFFEAD4A3),
    border: Color(0xFFE3D4BD),
    divider: Color(0xFFE8DCCB),
    textPrimary: Color(0xFF2D2117),
    textSecondary: Color(0xFF766957),
    textMuted: Color(0xFF9A8B73),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFF7EED8),
    warning: Color(0xFF946615),
    warningSurface: Color(0xFFFFF3D8),
    shadow: Color(0xFF2A1B10),
  );

  static const EquranColors sepiaDark = EquranColors(
    background: Color(0xFF130E09),
    surface: Color(0xFF1E1710),
    surfaceAlt: Color(0xFF2A2016),
    surfaceSoft: Color(0xFF18110C),
    primary: Color(0xFFC08A4C),
    primaryStrong: Color(0xFF8E5E2F),
    primarySoft: Color(0xFFE0B874),
    primaryGradientStart: Color(0xFF4F2F19),
    primaryGradientEnd: Color(0xFFB47B3F),
    mint: Color(0xFF332619),
    paleGreen: Color(0xFF261B12),
    accentGold: Color(0xFFD8AE55),
    goldSoft: Color(0xFF604B2A),
    border: Color(0xFF3B2D20),
    divider: Color(0xFF34281D),
    textPrimary: Color(0xFFFFF8EC),
    textSecondary: Color(0xFFD0C0A9),
    textMuted: Color(0xFFA3947E),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFFFEBC8),
    warning: Color(0xFFE0B866),
    warningSurface: Color(0xFF2D2414),
    shadow: Color(0xFF000000),
  );

  static const EquranColors blackDark = EquranColors(
    background: Color(0xFF000000),
    surface: Color(0xFF070807),
    surfaceAlt: Color(0xFF111312),
    surfaceSoft: Color(0xFF030403),
    primary: Color(0xFF18A28D),
    primaryStrong: Color(0xFF0E6C60),
    primarySoft: Color(0xFF83D8CC),
    primaryGradientStart: Color(0xFF060807),
    primaryGradientEnd: Color(0xFF117765),
    mint: Color(0xFF0C211D),
    paleGreen: Color(0xFF071815),
    accentGold: Color(0xFFD3A84E),
    goldSoft: Color(0xFF514224),
    border: Color(0xFF202423),
    divider: Color(0xFF191D1C),
    textPrimary: Color(0xFFF5F8F7),
    textSecondary: Color(0xFFBEC7C4),
    textMuted: Color(0xFF7E8885),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFE0F4F0),
    warning: Color(0xFFE0B866),
    warningSurface: Color(0xFF2D2414),
    shadow: Color(0xFF000000),
  );

  static const EquranColors redLight = EquranColors(
    background: Color(0xFFFCF7F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6EEEE),
    surfaceSoft: Color(0xFFFFFAFA),
    primary: Color(0xFF8E1F35),
    primaryStrong: Color(0xFF641426),
    primarySoft: Color(0xFFB94C63),
    primaryGradientStart: Color(0xFF4D111F),
    primaryGradientEnd: Color(0xFFC15768),
    mint: Color(0xFFF5E5E8),
    paleGreen: Color(0xFFFCF1F3),
    accentGold: Color(0xFFD8AE55),
    goldSoft: Color(0xFFE7D6AA),
    border: Color(0xFFEADCE0),
    divider: Color(0xFFEFE2E5),
    textPrimary: Color(0xFF31191F),
    textSecondary: Color(0xFF75636A),
    textMuted: Color(0xFF96868B),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFFADAE0),
    warning: Color(0xFF9B6A16),
    warningSurface: Color(0xFFFFF7E2),
    shadow: Color(0xFF2D0F17),
  );

  static const EquranColors redDark = EquranColors(
    background: Color(0xFF12070A),
    surface: Color(0xFF1F1014),
    surfaceAlt: Color(0xFF2B171D),
    surfaceSoft: Color(0xFF170B0F),
    primary: Color(0xFFC8475D),
    primaryStrong: Color(0xFF8A263C),
    primarySoft: Color(0xFFE38CA0),
    primaryGradientStart: Color(0xFF4E111F),
    primaryGradientEnd: Color(0xFFA82C45),
    mint: Color(0xFF371D25),
    paleGreen: Color(0xFF29131A),
    accentGold: Color(0xFFD8AE55),
    goldSoft: Color(0xFF5F4D2D),
    border: Color(0xFF3B2730),
    divider: Color(0xFF342129),
    textPrimary: Color(0xFFFFF6F8),
    textSecondary: Color(0xFFD2BDC4),
    textMuted: Color(0xFFA48B94),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFFFE6EC),
    warning: Color(0xFFE0B866),
    warningSurface: Color(0xFF2D2414),
    shadow: Color(0xFF000000),
  );

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryGradientStart, primary, primaryGradientEnd],
  );

  LinearGradient get softSurfaceGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color.alphaBlend(primary.withAlpha(18), surface),
      surface,
      Color.alphaBlend(accentGold.withAlpha(12), surface),
    ],
  );

  @override
  EquranColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceSoft,
    Color? primary,
    Color? primaryStrong,
    Color? primarySoft,
    Color? primaryGradientStart,
    Color? primaryGradientEnd,
    Color? mint,
    Color? paleGreen,
    Color? accentGold,
    Color? goldSoft,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? onPrimary,
    Color? onPrimaryMuted,
    Color? warning,
    Color? warningSurface,
    Color? shadow,
  }) {
    return EquranColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryGradientStart: primaryGradientStart ?? this.primaryGradientStart,
      primaryGradientEnd: primaryGradientEnd ?? this.primaryGradientEnd,
      mint: mint ?? this.mint,
      paleGreen: paleGreen ?? this.paleGreen,
      accentGold: accentGold ?? this.accentGold,
      goldSoft: goldSoft ?? this.goldSoft,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryMuted: onPrimaryMuted ?? this.onPrimaryMuted,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  EquranColors lerp(ThemeExtension<EquranColors>? other, double t) {
    if (other is! EquranColors) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;

    return EquranColors(
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      surfaceAlt: blend(surfaceAlt, other.surfaceAlt),
      surfaceSoft: blend(surfaceSoft, other.surfaceSoft),
      primary: blend(primary, other.primary),
      primaryStrong: blend(primaryStrong, other.primaryStrong),
      primarySoft: blend(primarySoft, other.primarySoft),
      primaryGradientStart: blend(
        primaryGradientStart,
        other.primaryGradientStart,
      ),
      primaryGradientEnd: blend(primaryGradientEnd, other.primaryGradientEnd),
      mint: blend(mint, other.mint),
      paleGreen: blend(paleGreen, other.paleGreen),
      accentGold: blend(accentGold, other.accentGold),
      goldSoft: blend(goldSoft, other.goldSoft),
      border: blend(border, other.border),
      divider: blend(divider, other.divider),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      textMuted: blend(textMuted, other.textMuted),
      onPrimary: blend(onPrimary, other.onPrimary),
      onPrimaryMuted: blend(onPrimaryMuted, other.onPrimaryMuted),
      warning: blend(warning, other.warning),
      warningSurface: blend(warningSurface, other.warningSurface),
      shadow: blend(shadow, other.shadow),
    );
  }
}

extension EquranColorsContext on BuildContext {
  EquranColors get equranColors {
    return Theme.of(this).extension<EquranColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? EquranColors.dark
            : EquranColors.light);
  }
}
