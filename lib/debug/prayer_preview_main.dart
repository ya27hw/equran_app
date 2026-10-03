import 'package:equran/backend/settings_db.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_page.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

DateTime prayerPreviewNow() => DateTime.utc(2026, 10, 4, 9, 12);
Future<void> seedPrayerPreview() async {
  await SettingsDB().clear();
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
  await PrayerSettingsStore().saveSettings(
    PrayerTimeSettings.fromJson(null).copyWith(use24HourFormat: false),
  );
}

Future<void> main() async {
  if (!kDebugMode) return;
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init('redesign_prayer_preview');
  await SettingsDB().initBox();
  await seedPrayerPreview();
  final params = Uri.base.queryParameters;
  runApp(
    PrayerPreviewApp(
      colors: switch (params['palette']) {
        'emerald-light' => EquranColors.light,
        'black-dark' => EquranColors.blackDark,
        'red-dark' => EquranColors.redDark,
        _ => EquranColors.dark,
      },
      locale: Locale(params['locale'] ?? 'en'),
      scale: double.tryParse(params['scale'] ?? '') ?? 1,
    ),
  );
}

class PrayerPreviewApp extends StatelessWidget {
  const PrayerPreviewApp({
    super.key,
    this.colors = EquranColors.dark,
    this.locale = const Locale('en'),
    this.scale = 1,
    this.now,
    this.navigatorObservers = const [],
  });
  final EquranColors colors;
  final Locale locale;
  final double scale;
  final DateTime? now;
  final List<NavigatorObserver> navigatorObservers;
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
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: SafeArea(
        child: PrayerTimesPage(
          enableLiveCountdown: false,
          initialNow: now ?? prayerPreviewNow(),
        ),
      ),
    ),
  );
}
