import 'dart:io' show Platform;
import 'dart:ui';
import 'package:equran/backend/library.dart' show SettingsDB;
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

const Map<String, Map<String, String>> widgetTranslations = {
  'en': {
    'header': 'Prayer Times',
    'fajr': 'Fajr',
    'sunrise': 'Sunrise',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
    'updated': 'Updated',
    'placeholder': 'Tap to load prayer times',
  },
  'ar': {
    'header':
        '\u0645\u0648\u0627\u0642\u064a\u062a \u0627\u0644\u0635\u0644\u0627\u0629',
    'fajr': '\u0627\u0644\u0641\u062c\u0631',
    'sunrise': '\u0627\u0644\u0634\u0631\u0648\u0642',
    'dhuhr': '\u0627\u0644\u0638\u0647\u0631',
    'asr': '\u0627\u0644\u0639\u0635\u0631',
    'maghrib': '\u0627\u0644\u0645\u063a\u0631\u0628',
    'isha': '\u0627\u0644\u0639\u0634\u0627\u0621',
    'updated': '\u0622\u062e\u0631 \u062a\u062d\u062f\u064a\u062b',
    'placeholder':
        '\u0627\u0641\u062a\u062d \u0627\u0644\u062a\u0637\u0628\u064a\u0642 \u0644\u062a\u062d\u0645\u064a\u0644 \u0645\u0648\u0627\u0642\u064a\u062a \u0627\u0644\u0635\u0644\u0627\u0629',
  },
  'fa': {
    'header': 'اوقات شرعی',
    'fajr': 'فجر',
    'sunrise': 'طلوع آفتاب',
    'dhuhr': 'ظهر',
    'asr': 'عصر',
    'maghrib': 'مغرب',
    'isha': 'عشاء',
    'updated': 'به‌روزرسانی شده',
    'placeholder': 'برای بارگذاری اوقات شرعی ضربه بزنید',
  },
  'de': {
    'header': 'Gebetszeiten',
    'fajr': 'Fajr',
    'sunrise': 'Sonnenaufgang',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
    'updated': 'Aktualisiert',
    'placeholder': 'Tippen, um Gebetszeiten zu laden',
  },
};

class PrayerWidgetService {
  static const String _appGroupId = 'com.app.equran';

  static bool get _isSupported => !kIsWeb && Platform.isAndroid;

  static Future<void> init() async {
    if (!_isSupported) return;
    await HomeWidget.setAppGroupId(_appGroupId);
    await HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  static String getLanguageCode() {
    try {
      final dynamic lang = SettingsDB().get("locale");
      if (lang == null || lang == "system") {
        return PlatformDispatcher.instance.locale.languageCode;
      }
      return lang.toString();
    } catch (_) {
      return PlatformDispatcher.instance.locale.languageCode;
    }
  }

  static Future<void> saveCoordinates({
    required double latitude,
    required double longitude,
    required String calculationMethod,
    required String madhab,
    required bool use24h,
  }) async {
    if (!_isSupported) return;
    await Future.wait([
      HomeWidget.saveWidgetData<String>('widget_lat', latitude.toString()),
      HomeWidget.saveWidgetData<String>('widget_lng', longitude.toString()),
      HomeWidget.saveWidgetData<String>(
        'widget_calc_method',
        calculationMethod,
      ),
      HomeWidget.saveWidgetData<String>('widget_madhab', madhab),
      HomeWidget.saveWidgetData<bool>('widget_use_24h', use24h),
    ]);
  }

  static Future<void> refreshWidget({
    BuildContext? context,
    EquranColors? colors,
  }) async {
    if (!_isSupported) return;
    final store = PrayerSettingsStore();
    final location = store.getLocation();
    final settings = store.getSettings();
    if (location == null) return;

    final service = const PrayerTimesService();
    final effectiveMethod = service.effectiveMethodFor(
      location: location,
      settings: settings,
    );
    final use24hr = settings.use24HourFormat;

    final String themeMode =
        SettingsDB().get("themeMode")?.toString() ?? 'auto';
    final String themeScheme =
        SettingsDB().get("themeScheme")?.toString() ?? 'default';
    final bool isDark =
        themeMode == 'dark' ||
        (themeMode == 'auto' &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    final resolvedColors = resolveColorsForScheme(themeScheme, isDark);

    await saveCoordinates(
      latitude: location.latitude,
      longitude: location.longitude,
      calculationMethod: effectiveMethod.name,
      madhab: settings.asrMethod.name,
      use24h: use24hr,
    );

    final langCode = getLanguageCode();
    final t = widgetTranslations[langCode] ?? widgetTranslations['en']!;

    final lightColors = resolveColorsForScheme(themeScheme, false);
    final darkColors = resolveColorsForScheme(themeScheme, true);

    await Future.wait([
      HomeWidget.saveWidgetData<String>('label_header', t['header']!),
      HomeWidget.saveWidgetData<String>('label_fajr', t['fajr']!),
      HomeWidget.saveWidgetData<String>('label_sunrise', t['sunrise']!),
      HomeWidget.saveWidgetData<String>('label_dhuhr', t['dhuhr']!),
      HomeWidget.saveWidgetData<String>('label_asr', t['asr']!),
      HomeWidget.saveWidgetData<String>('label_maghrib', t['maghrib']!),
      HomeWidget.saveWidgetData<String>('label_isha', t['isha']!),
      HomeWidget.saveWidgetData<String>('label_updated', t['updated']!),
      HomeWidget.saveWidgetData<String>('label_placeholder', t['placeholder']!),
      HomeWidget.saveWidgetData<String>('widget_locale', langCode),
      HomeWidget.saveWidgetData<bool>('widget_use_24h', use24hr),
      HomeWidget.saveWidgetData<String>('theme_mode', themeMode),
      HomeWidget.saveWidgetData<String>('theme_scheme', themeScheme),
      HomeWidget.saveWidgetData<bool>('is_dark_mode', isDark),

      // Light colors
      HomeWidget.saveWidgetData<String>(
        'w_bg_light',
        colorToHex(lightColors.background),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_surface_light',
        colorToHex(lightColors.surface),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_primary_light',
        colorToHex(lightColors.primary),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_primary_strong_light',
        colorToHex(lightColors.primaryStrong),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_text_light',
        colorToHex(lightColors.textPrimary),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_text_sec_light',
        colorToHex(lightColors.textSecondary),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_text_muted_light',
        colorToHex(lightColors.textMuted),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_gold_light',
        colorToHex(lightColors.accentGold),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_border_light',
        colorToHex(lightColors.border),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_on_primary_light',
        colorToHex(lightColors.onPrimary),
      ),

      // Dark colors
      HomeWidget.saveWidgetData<String>(
        'w_bg_dark',
        colorToHex(darkColors.background),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_surface_dark',
        colorToHex(darkColors.surface),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_primary_dark',
        colorToHex(darkColors.primary),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_primary_strong_dark',
        colorToHex(darkColors.primaryStrong),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_text_dark',
        colorToHex(darkColors.textPrimary),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_text_sec_dark',
        colorToHex(darkColors.textSecondary),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_text_muted_dark',
        colorToHex(darkColors.textMuted),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_gold_dark',
        colorToHex(darkColors.accentGold),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_border_dark',
        colorToHex(darkColors.border),
      ),
      HomeWidget.saveWidgetData<String>(
        'w_on_primary_dark',
        colorToHex(darkColors.onPrimary),
      ),
    ]);

    final now = DateTime.now();
    final todayDate = service.calendarDateForInstant(
      instant: now,
      location: location,
      settings: settings,
    );
    final today = service.calculateDay(
      date: todayDate,
      location: location,
      settings: settings,
    );
    final tomorrow = service.calculateDay(
      date: DateTime(todayDate.year, todayDate.month, todayDate.day + 1),
      location: location,
      settings: settings,
    );

    final nextPrayer = service.nextPrayer(
      day: today,
      tomorrow: tomorrow,
      now: now,
    );

    final fajr = today.entryFor(PrayerTimeKind.fajr);
    final sunrise = today.entryFor(PrayerTimeKind.sunrise);
    final dhuhr = today.entryFor(PrayerTimeKind.dhuhr);
    final asr = today.entryFor(PrayerTimeKind.asr);
    final maghrib = today.entryFor(PrayerTimeKind.maghrib);
    final isha = today.entryFor(PrayerTimeKind.isha);

    await updateWidget(
      fajr: formatTime(fajr.time, use24hr),
      sunrise: formatTime(sunrise.time, use24hr),
      dhuhr: formatTime(dhuhr.time, use24hr),
      asr: formatTime(asr.time, use24hr),
      maghrib: formatTime(maghrib.time, use24hr),
      isha: formatTime(isha.time, use24hr),
      sunriseLabel: t['sunrise']!,
      nextPrayer: nextPrayer.entry.kind.id,
      nextPrayerTime: formatTime(nextPrayer.entry.time, use24hr),
      locationName: location.displayLabel,
      lastUpdated: formatTime(now, use24hr),
      colorBackground: colorToHex(resolvedColors.background),
      colorSurface: colorToHex(resolvedColors.surface),
      colorPrimary: colorToHex(resolvedColors.primary),
      colorPrimaryStrong: colorToHex(resolvedColors.primaryStrong),
      colorPrimaryGradientStart: colorToHex(
        resolvedColors.primaryGradientStart,
      ),
      colorPrimaryGradientEnd: colorToHex(resolvedColors.primaryGradientEnd),
      colorTextPrimary: colorToHex(resolvedColors.textPrimary),
      colorTextSecondary: colorToHex(resolvedColors.textSecondary),
      colorTextMuted: colorToHex(resolvedColors.textMuted),
      colorAccentGold: colorToHex(resolvedColors.accentGold),
      colorBorder: colorToHex(resolvedColors.border),
      colorOnPrimary: colorToHex(resolvedColors.onPrimary),
    );
  }

  static EquranColors resolveColorsForScheme(String scheme, bool isDarkMode) {
    if (scheme == 'black') {
      return EquranColors.blackDark;
    }
    if (isDarkMode) {
      return switch (scheme) {
        'fancyBlue' => EquranColors.fancyBlueDark,
        'fancyPurple' => EquranColors.fancyPurpleDark,
        'sepia' => EquranColors.sepiaDark,
        'red' => EquranColors.redDark,
        _ => EquranColors.dark,
      };
    } else {
      return switch (scheme) {
        'fancyBlue' => EquranColors.fancyBlueLight,
        'fancyPurple' => EquranColors.fancyPurpleLight,
        'sepia' => EquranColors.sepiaLight,
        'red' => EquranColors.redLight,
        _ => EquranColors.light,
      };
    }
  }



  static String colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  static Future<void> updateWidget({
    required String fajr,
    required String sunrise,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
    required String nextPrayer,
    required String nextPrayerTime,
    required String locationName,
    required String lastUpdated,
    String sunriseLabel = '',
    String colorBackground = '',
    String colorSurface = '',
    String colorPrimary = '',
    String colorPrimaryStrong = '',
    String colorPrimaryGradientStart = '',
    String colorPrimaryGradientEnd = '',
    String colorTextPrimary = '',
    String colorTextSecondary = '',
    String colorTextMuted = '',
    String colorAccentGold = '',
    String colorBorder = '',
    String colorOnPrimary = '',
  }) async {
    if (!_isSupported) return;
    await Future.wait([
      HomeWidget.saveWidgetData<String>('fajr_time', fajr),
      HomeWidget.saveWidgetData<String>('sunrise_time', sunrise),
      HomeWidget.saveWidgetData<String>('dhuhr_time', dhuhr),
      HomeWidget.saveWidgetData<String>('asr_time', asr),
      HomeWidget.saveWidgetData<String>('maghrib_time', maghrib),
      HomeWidget.saveWidgetData<String>('isha_time', isha),
      if (sunriseLabel.isNotEmpty)
        HomeWidget.saveWidgetData<String>('label_sunrise', sunriseLabel),
      HomeWidget.saveWidgetData<String>('next_prayer', nextPrayer),
      HomeWidget.saveWidgetData<String>('next_prayer_time', nextPrayerTime),
      HomeWidget.saveWidgetData<String>('location_name', locationName),
      HomeWidget.saveWidgetData<String>('last_updated', lastUpdated),
      if (colorBackground.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_bg', colorBackground),
      if (colorSurface.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_surface', colorSurface),
      if (colorPrimary.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_primary', colorPrimary),
      if (colorPrimaryStrong.isNotEmpty)
        HomeWidget.saveWidgetData<String>(
          'w_primary_strong',
          colorPrimaryStrong,
        ),
      if (colorPrimaryGradientStart.isNotEmpty)
        HomeWidget.saveWidgetData<String>(
          'w_grad_start',
          colorPrimaryGradientStart,
        ),
      if (colorPrimaryGradientEnd.isNotEmpty)
        HomeWidget.saveWidgetData<String>(
          'w_grad_end',
          colorPrimaryGradientEnd,
        ),
      if (colorTextPrimary.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_text', colorTextPrimary),
      if (colorTextSecondary.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_text_sec', colorTextSecondary),
      if (colorTextMuted.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_text_muted', colorTextMuted),
      if (colorAccentGold.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_gold', colorAccentGold),
      if (colorBorder.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_border', colorBorder),
      if (colorOnPrimary.isNotEmpty)
        HomeWidget.saveWidgetData<String>('w_on_primary', colorOnPrimary),
    ]);

    await Future.wait([
      HomeWidget.updateWidget(androidName: 'PrayerTimesWidgetReceiver'),
      HomeWidget.updateWidget(androidName: 'NextPrayerWidgetReceiver'),
    ]);
  }

  static String determineNextPrayer({
    required DateTime fajr,
    required DateTime sunrise,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
  }) {
    final now = DateTime.now();
    if (now.isBefore(fajr)) return 'fajr';
    if (now.isBefore(sunrise)) return 'sunrise';
    if (now.isBefore(dhuhr)) return 'dhuhr';
    if (now.isBefore(asr)) return 'asr';
    if (now.isBefore(maghrib)) return 'maghrib';
    if (now.isBefore(isha)) return 'isha';
    return 'fajr';
  }

  static String formatTime(DateTime dt, bool use24hr) {
    final local = dt.toLocal();
    if (use24hr) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour < 12 ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundCallback(Uri? uri) async {}
