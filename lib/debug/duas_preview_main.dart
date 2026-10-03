import 'package:equran/backend/library.dart';
import 'package:equran/duas/duas_page.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Standalone, debug-only preview with synthetic history on its own web origin.
Future<void> main() async {
  if (!kDebugMode) return;
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init('redesign_duas_preview');
  registerCompanionStorageAdapters();
  for (final db in [
    SettingsDB(),
    DuaFavouritesDB(),
    DuaInteractionsDB(),
    DhikrSessionsDB(),
  ]) {
    await db.initBox();
  }
  await seedDuasPreview();
  final repository = HisnAlMuslimRepository();
  await repository.loadCategoryIndex();
  final params = Uri.base.queryParameters;
  runApp(
    DuasPreviewApp(
      repository: repository,
      colors: switch (params['palette']) {
        'emerald-light' => EquranColors.light,
        'black-dark' => EquranColors.blackDark,
        'red-dark' => EquranColors.redDark,
        _ => EquranColors.dark,
      },
      locale: Locale(params['locale'] ?? 'en'),
      textScale: double.tryParse(params['scale'] ?? '') ?? 1,
    ),
  );
}

DateTime duasPreviewNow() =>
    DateTime.utc(2026, 10, 3, 14); // 18:00 Muscat, after Asr.
Future<void> seedDuasPreview() async {
  await SettingsDB().clear();
  await DuaInteractionsDB().clear();
  await DuaFavouritesDB().clear();
  await DhikrSessionsDB().clear();
  await PrayerSettingsStore().saveLocation(
    const PrayerLocation(
      latitude: 23.588,
      longitude: 58.3829,
      label: 'Muscat',
      mode: PrayerLocationMode.manual,
      countryCode: 'OM',
      timezoneId: 'Asia/Muscat',
    ),
  );
  for (var i = 0; i < 12; i++) {
    await DuaFavouritesDB().put('029_${i.toString().padLeft(3, '0')}', true);
  }
  await DhikrSessionsDB().put(
    'preview-dhikr',
    DhikrSessionEntry(
      id: 'preview-dhikr',
      label: 'SubhanAllah',
      startedAt: duasPreviewNow(),
      count: 33,
      targetCount: 33,
    ),
  );
}

class DuasPreviewApp extends StatelessWidget {
  const DuasPreviewApp({
    super.key,
    required this.repository,
    this.colors = EquranColors.dark,
    this.locale = const Locale('en'),
    this.textScale = 1,
    this.navigatorObservers = const [],
    this.now = duasPreviewNow,
  });
  final HisnAlMuslimRepository repository;
  final EquranColors colors;
  final Locale locale;
  final double textScale;
  final List<NavigatorObserver> navigatorObservers;
  final DateTime Function() now;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: colors.background.computeLuminance() < .5
          ? Brightness.dark
          : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorSchemeSeed: colors.primary,
      fontFamily: 'Inter',
      extensions: [colors, EquranTokens.fromColors(colors)],
    ),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: navigatorObservers,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SafeArea(
        child: DuasPage(repository: repository, now: now),
      ),
    ),
  );
}
