import 'dart:async';
import 'dart:io' show Platform;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/backend/startup_coordinator.dart';
import 'package:equran/features/splash/splash_screen.dart' show SplashScreen;
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/utils/responsive_nav.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

Future<void> main() async {
  final StartupCoordinator startup = StartupCoordinator.instance;
  await startup.initializeBlocking();
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(startup.startDeferred());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale = _getSavedLocale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!kIsWeb && Platform.isAndroid) {
        unawaited(PrayerWidgetService.refreshWidget());
      }
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    QpcV4FontService.instance.clearCache();
    if (!kIsWeb && Platform.isAndroid) {
      unawaited(PrayerWidgetService.refreshWidget());
    }
  }

  Locale? _getSavedLocale() {
    final dynamic lang = SettingsDB().get("locale");
    if (lang == null || lang == "system") return null;
    return Locale(lang.toString());
  }

  void setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final AdaptiveThemeMode? savedThemeMode = _getSavedThemeMode();
    final MaterialColor seedColor = _getPrimaryColor();
    final String themeScheme = _getThemeScheme();

    return AdaptiveTheme(
      light: AppTheme.buildLightTheme(seedColor, schemeId: themeScheme),
      dark: AppTheme.buildDarkTheme(seedColor, schemeId: themeScheme),
      initial: savedThemeMode ?? AdaptiveThemeMode.dark,
      overrideMode: savedThemeMode,
      builder: (theme, darkTheme) => MaterialApp(
        scrollBehavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false),
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          final ThemeData localizedTheme = EquranTextStyles.localizeTheme(
            Theme.of(context),
            Localizations.localeOf(context),
          );
          final double tabletTextScale = ResponsiveNav.appTextScale(context);
          final double chromeTextScale = ResponsiveNav.appChromeTextScale(
            context,
          );
          final double effectiveTextScale =
              mediaQuery.textScaler.scale(1.0) * tabletTextScale;
          final ThemeData effectiveTheme = chromeTextScale == 1.0
              ? localizedTheme
              : localizedTheme.copyWith(
                  textTheme: localizedTheme.textTheme.apply(
                    fontSizeFactor: chromeTextScale,
                  ),
                  primaryTextTheme: localizedTheme.primaryTextTheme.apply(
                    fontSizeFactor: chromeTextScale,
                  ),
                );
          final Widget themedChild = AnimatedTheme(
            data: effectiveTheme,
            duration: Duration.zero,
            child: child ?? const SizedBox.shrink(),
          );
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(effectiveTextScale),
            ),
            child: themedChild,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }

  static MaterialColor _getPrimaryColor() {
    final colorIndex = SettingsDB().get("color");
    return colorIndex != null ? Colors.primaries[colorIndex] : Colors.cyan;
  }

  static AdaptiveThemeMode? _getSavedThemeMode() {
    final themeMode = SettingsDB().get("themeMode");
    return switch (themeMode) {
      "light" => AdaptiveThemeMode.light,
      "dark" => AdaptiveThemeMode.dark,
      "auto" => AdaptiveThemeMode.system,
      _ => null,
    };
  }

  static String _getThemeScheme() {
    final dynamic scheme = SettingsDB().get("themeScheme");
    return switch (scheme) {
      AppTheme.fancyBlueScheme => AppTheme.fancyBlueScheme,
      AppTheme.fancyPurpleScheme => AppTheme.fancyPurpleScheme,
      AppTheme.sepiaScheme => AppTheme.sepiaScheme,
      AppTheme.blackScheme => AppTheme.blackScheme,
      AppTheme.redScheme => AppTheme.redScheme,
      _ => AppTheme.defaultScheme,
    };
  }
}
