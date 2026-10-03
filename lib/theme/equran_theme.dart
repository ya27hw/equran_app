import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class EquranTheme {
  const EquranTheme._();

  static ThemeData light() => _build(EquranColors.light, Brightness.light);

  static ThemeData dark() => _build(EquranColors.dark, Brightness.dark);

  static ThemeData fancyBlueLight() =>
      _build(EquranColors.fancyBlueLight, Brightness.light);

  static ThemeData fancyBlueDark() =>
      _build(EquranColors.fancyBlueDark, Brightness.dark);

  static ThemeData fancyPurpleLight() =>
      _build(EquranColors.fancyPurpleLight, Brightness.light);

  static ThemeData fancyPurpleDark() =>
      _build(EquranColors.fancyPurpleDark, Brightness.dark);

  static ThemeData sepiaLight() =>
      _build(EquranColors.sepiaLight, Brightness.light);

  static ThemeData sepiaDark() =>
      _build(EquranColors.sepiaDark, Brightness.dark);

  static ThemeData blackLight() =>
      _build(EquranColors.blackDark, Brightness.dark);

  static ThemeData blackDark() =>
      _build(EquranColors.blackDark, Brightness.dark);

  static ThemeData redLight() =>
      _build(EquranColors.redLight, Brightness.light);

  static ThemeData redDark() => _build(EquranColors.redDark, Brightness.dark);

  static ThemeData _build(EquranColors tokens, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.mint,
      onPrimaryContainer: tokens.primaryStrong,
      secondary: tokens.accentGold,
      onSecondary: isDark ? const Color(0xFF2B1B00) : Colors.white,
      secondaryContainer: tokens.goldSoft,
      onSecondaryContainer: isDark
          ? const Color(0xFFFFEBC0)
          : const Color(0xFF3B2B0D),
      tertiary: tokens.primarySoft,
      onTertiary: isDark ? const Color(0xFF042018) : Colors.white,
      tertiaryContainer: tokens.paleGreen,
      onTertiaryContainer: tokens.primaryStrong,
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: isDark ? const Color(0xFF690005) : Colors.white,
      errorContainer: isDark
          ? const Color(0xFF93000A)
          : const Color(0xFFFFDAD6),
      onErrorContainer: isDark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF410002),
      surface: tokens.background,
      onSurface: tokens.textPrimary,
      surfaceContainerLowest: tokens.surfaceSoft,
      surfaceContainerLow: tokens.surface,
      surfaceContainer: tokens.surfaceAlt,
      surfaceContainerHigh: tokens.surfaceAlt,
      surfaceContainerHighest: tokens.surfaceAlt,
      onSurfaceVariant: tokens.textSecondary,
      outline: tokens.border,
      outlineVariant: tokens.divider,
      shadow: tokens.shadow,
      scrim: Colors.black,
      inverseSurface: isDark ? tokens.textPrimary : const Color(0xFF2F3530),
      onInverseSurface: isDark ? tokens.background : Colors.white,
      inversePrimary: tokens.primarySoft,
      surfaceTint: Colors.transparent,
    );

    final TextTheme textTheme = EquranTextStyles.buildTextTheme(
      brightness,
    ).apply(bodyColor: tokens.textPrimary, displayColor: tokens.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[
        tokens,
        EquranTokens.fromColors(tokens),
      ],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      dividerColor: tokens.divider,
      splashColor: tokens.primary.withAlpha(isDark ? 34 : 18),
      highlightColor: tokens.primary.withAlpha(isDark ? 24 : 12),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
          side: BorderSide(color: tokens.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          disabledBackgroundColor: tokens.border,
          disabledForegroundColor: tokens.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EquranRadii.pill),
          ),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, 46),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EquranRadii.pill),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EquranRadii.medium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
          borderSide: BorderSide(color: tokens.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.mint,
        selectedColor: tokens.primary,
        disabledColor: tokens.surfaceAlt,
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.pill),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: tokens.primaryStrong,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: tokens.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(EquranRadii.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.xl),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(tokens.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide(color: tokens.border)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EquranRadii.pill),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: tokens.onPrimary,
        unselectedLabelColor: tokens.textSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          for (final TargetPlatform platform in <TargetPlatform>[
            TargetPlatform.fuchsia,
            TargetPlatform.linux,
            TargetPlatform.macOS,
            TargetPlatform.windows,
          ])
            platform: FadeForwardsPageTransitionsBuilder(
              backgroundColor: tokens.background,
            ),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: tokens.accentGold,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.medium),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.textMuted;
          return states.contains(WidgetState.selected)
              ? tokens.onPrimary
              : tokens.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return states.contains(WidgetState.disabled)
                ? tokens.border
                : tokens.primary;
          }
          return tokens.surfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.transparent
              : tokens.border;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.primary,
        inactiveTrackColor: tokens.border,
        thumbColor: tokens.primary,
        overlayColor: tokens.primary.withAlpha(isDark ? 40 : 28),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearTrackColor: tokens.border,
        linearMinHeight: 6,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: tokens.shadow.withAlpha(isDark ? 120 : 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
          side: BorderSide(color: tokens.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(EquranRadii.medium),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.primary,
        indicatorColor: tokens.onPrimary.withAlpha(38),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? tokens.onPrimary : tokens.onPrimaryMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.onPrimary : tokens.onPrimaryMuted,
            size: 22,
          );
        }),
      ),
    );
  }
}
