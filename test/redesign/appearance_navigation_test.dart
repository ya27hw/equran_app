import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home/appearance_settings_page.dart';
import 'package:equran/home/navigation_settings_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// Appearance and Navigation settings on the redesign system. Both pages are
/// pumped for real. There is no design preview; they follow the Settings rows,
/// the More page cards and the reader sheet chrome.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await SettingsDB().clear();
  });
  tearDownAll(Hive.close);

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    required EquranColors colors,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 900,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(390 * 2, height * 2);
    addTearDown(tester.view.reset);
    final bool light = colors == EquranColors.light;
    await tester.pumpWidget(
      AdaptiveTheme(
        light: savedPreviewTheme(colors),
        dark: savedPreviewTheme(colors),
        initial: light ? AdaptiveThemeMode.light : AdaptiveThemeMode.dark,
        builder: (theme, darkTheme) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(body: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  final List<(String, EquranColors, double, Locale)> variants =
      <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
        ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
        ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ];

  for (final (String name, EquranColors colors, double scale, Locale locale)
      in variants) {
    testWidgets('Appearance golden $name', (tester) async {
      await pump(
        tester,
        const AppearanceSettingsPage(),
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1250 : 810,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/appearance/$name.png'),
      );
    });

    testWidgets('Navigation golden $name', (tester) async {
      NavigationBloc.instance.value = const NavigationState(
        activeNavbarItems: <NavItem>[
          NavItem.home,
          NavItem.quran,
          NavItem.prayer,
          NavItem.duas,
          NavItem.more,
        ],
        availableMoreItems: <NavItem>[
          NavItem.statistics,
          NavItem.qibla,
          NavItem.hifz,
          NavItem.tasbih,
        ],
        selectedIndex: 0,
      );
      await pump(
        tester,
        const NavigationSettingsPage(),
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1450 : 960,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/navigation/$name.png'),
      );
    });
  }

  testWidgets('tapping an available item pins it', (tester) async {
    NavigationBloc.instance.value = const NavigationState(
      activeNavbarItems: <NavItem>[NavItem.home, NavItem.quran, NavItem.more],
      availableMoreItems: <NavItem>[NavItem.statistics, NavItem.qibla],
      selectedIndex: 0,
    );
    await pump(
      tester,
      const NavigationSettingsPage(),
      colors: EquranColors.dark,
      height: 1250,
    );
    final AppLocalizations l = AppLocalizations.of(
      tester.element(find.byType(NavigationSettingsPage)),
    )!;
    await tester.tap(find.text(l.statistics));
    await tester.pumpAndSettle();
    expect(
      NavigationBloc.instance.value.activeNavbarItems,
      contains(NavItem.statistics),
    );
  });

  testWidgets('the Appearance mode cards still switch the theme mode', (
    tester,
  ) async {
    await pump(
      tester,
      const AppearanceSettingsPage(),
      colors: EquranColors.dark,
      height: 1000,
    );
    final AppLocalizations l = AppLocalizations.of(
      tester.element(find.byType(AppearanceSettingsPage)),
    )!;
    await tester.tap(find.text(l.themeModeLight));
    await tester.pumpAndSettle();
    expect(SettingsDB().get('themeMode'), 'light');
    await tester.tap(find.text(l.themeModeSystem));
    await tester.pumpAndSettle();
    expect(SettingsDB().get('themeMode'), 'auto');
  });
}
