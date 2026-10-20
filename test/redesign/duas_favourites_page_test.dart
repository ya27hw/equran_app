import 'package:equran/backend/base_db.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/duas/duas_favourites_page.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Favourite duas page and the shared dua card on the redesign system.
/// There was no design preview; the page follows the finished Duas and Saved
/// pages. Favourites are seeded as stored snapshots, so the page never needs
/// the repository. The same card is used for the dua list inside a category.
void main() {
  setUpAll(() async {
    registerCompanionStorageAdapters();
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final BaseDB db in <BaseDB>[SettingsDB(), DuaFavouritesDB()]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await loadGalleryFonts();
    for (final (String family, String asset) in <(String, String)>[
      (
        'NotoNaskhArabic',
        'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
      ),
      ('UthmanicHafs', 'assets/media/fonts/UthmanicHafs_V22.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });
  tearDownAll(Hive.close);

  DuaEntry dua(
    String id,
    String categoryId,
    String categoryTitle,
    int index, {
    String? reference,
    int? count,
    String? translation,
    String? transliteration,
  }) => DuaEntry(
    id: id,
    categoryId: categoryId,
    categoryTitle: categoryTitle,
    categoryIndex: int.parse(categoryId) - 1,
    index: index,
    text:
        'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    reference: reference,
    count: count,
    translation: translation,
    transliteration: transliteration,
  );

  Future<void> seed({bool empty = false}) async {
    await DuaFavouritesDB().box.clear();
    if (empty) return;
    for (final DuaEntry d in <DuaEntry>[
      dua(
        'hisn-003-1',
        '003',
        'الاستيقاظ من النوم',
        0,
        reference: 'Al-Bukhari',
        translation:
            'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
        transliteration:
            'Alhamdu lillahil-ladhi ahyana ba\'da ma amatana wa ilayhin-nushur.',
      ),
      dua(
        'hisn-003-2',
        '003',
        'الاستيقاظ من النوم',
        1,
        count: 3,
        translation: 'A short second dua with a repeat count.',
      ),
      dua(
        'hisn-029-1',
        '029',
        'أذكار الصباح والمساء',
        0,
        reference: 'Abu Dawud',
        count: 7,
        translation: 'Allah is sufficient for me; there is no god but Him.',
      ),
    ]) {
      await DuaFavouritesDB().put(d.id, d.toFavouriteSnapshot());
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 1500,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(390, height);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
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
        home: Scaffold(
          body: DuasFavouritesPage(
            categoryIndex: const <DuaCategoryIndex>[],
            repository: HisnAlMuslimRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DuasFavouritesPage)))!;

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
    testWidgets('Favourite duas golden $name', (tester) async {
      await seed();
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1900 : 1300,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/duas_favourites/list-$name.png'),
      );
    });
  }

  for (final (String name, EquranColors colors, Locale locale)
      in <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('emerald-light', EquranColors.light, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, const Locale('ar')),
      ]) {
    testWidgets('Favourite duas empty golden $name', (tester) async {
      await seed(empty: true);
      await pump(tester, colors: colors, locale: locale, height: 700);
      expect(find.text(l10n(tester).noFavouriteDuasYet), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/duas_favourites/empty-$name.png'),
      );
    });
  }

  testWidgets('cards are grouped by category with a count', (tester) async {
    await seed();
    await pump(tester);
    // One group heading plus the title on each of the group's two cards.
    expect(find.text('Remembrance of waking up from sleep'), findsNWidgets(3));
    expect(find.text('Morning and evening remembrances'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('${l10n(tester).dua} 1'), findsNWidgets(2));
  });

  testWidgets('removing a favourite takes its card away', (tester) async {
    await seed();
    await pump(tester);
    expect(DuaFavouritesDB().getKeys().length, 3);
    await tester.tap(find.byTooltip(l10n(tester).removeFavourite).first);
    await tester.pumpAndSettle();
    expect(DuaFavouritesDB().getKeys().length, 2);
  });
}
