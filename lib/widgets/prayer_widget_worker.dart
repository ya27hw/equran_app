import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:workmanager/workmanager.dart';
import 'package:equran/widgets/prayer_widget_service.dart';

const String _prayerWidgetTask = 'prayerWidgetRefresh';

class PrayerWidgetWorker {
  static Future<void> init() async {
    await Workmanager().initialize(_callbackDispatcher);
  }

  static Future<void> scheduleRefresh() async {
    // Hourly refresh for next prayer accuracy
    await Workmanager().registerPeriodicTask(
      '${_prayerWidgetTask}_hourly',
      _prayerWidgetTask,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Daily midnight recalculation
    final now = DateTime.now();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
      0,
      5,
    ); // 00:05 next day
    final delay = midnight.difference(now);

    await Workmanager().registerOneOffTask(
      '${_prayerWidgetTask}_midnight',
      _prayerWidgetTask,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // MUST be first — before any Flutter API
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (taskName == _prayerWidgetTask ||
        taskName.startsWith('${_prayerWidgetTask}_')) {
      await HomeWidget.setAppGroupId('com.app.equran');

      try {
        // Read stored coordinates from prefs
        final latStr = await HomeWidget.getWidgetData<String>('widget_lat');
        final lngStr = await HomeWidget.getWidgetData<String>('widget_lng');
        final methodStr = await HomeWidget.getWidgetData<String>(
          'widget_calc_method',
        );
        final madhabStr = await HomeWidget.getWidgetData<String>(
          'widget_madhab',
        );
        final localeStr =
            await HomeWidget.getWidgetData<String>('widget_locale') ?? 'en';
        final dynamic use24hRaw = await HomeWidget.getWidgetData<dynamic>(
          'widget_use_24h',
        );
        final bool use24h = use24hRaw is bool
            ? use24hRaw
            : use24hRaw?.toString().toLowerCase() == 'true';
        final locationName =
            await HomeWidget.getWidgetData<String>('location_name') ?? '';

        // Sync localized labels in background
        final t = widgetTranslations[localeStr] ?? widgetTranslations['en']!;
        await Future.wait([
          HomeWidget.saveWidgetData<String>('label_header', t['header']!),
          HomeWidget.saveWidgetData<String>('label_fajr', t['fajr']!),
          HomeWidget.saveWidgetData<String>('label_sunrise', t['sunrise']!),
          HomeWidget.saveWidgetData<String>('label_dhuhr', t['dhuhr']!),
          HomeWidget.saveWidgetData<String>('label_asr', t['asr']!),
          HomeWidget.saveWidgetData<String>('label_maghrib', t['maghrib']!),
          HomeWidget.saveWidgetData<String>('label_isha', t['isha']!),
          HomeWidget.saveWidgetData<String>('label_updated', t['updated']!),
          HomeWidget.saveWidgetData<String>(
            'label_placeholder',
            t['placeholder']!,
          ),
        ]);

        // No coordinates saved yet — skip update
        if (latStr == null || lngStr == null) {
          return Future.value(true);
        }

        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lngStr);
        if (lat == null || lng == null) {
          return Future.value(true);
        }

        // Reconstruct adhan_dart objects
        final coordinates = Coordinates(lat, lng);

        // Map stored method string to calculation parameters
        final params = _parametersFromString(
          methodStr ?? 'muslimWorldLeague',
          madhabStr ?? 'shafi',
        );

        // Calculate for today
        final now = DateTime.now();
        final prayerTimes = PrayerTimes(
          coordinates: coordinates,
          date: now,
          calculationParameters: params,
          precision: true,
        );

        // Determine next prayer
        final nextPrayer = PrayerWidgetService.determineNextPrayer(
          fajr: prayerTimes.fajr,
          sunrise: prayerTimes.sunrise,
          dhuhr: prayerTimes.dhuhr,
          asr: prayerTimes.asr,
          maghrib: prayerTimes.maghrib,
          isha: prayerTimes.isha,
        );

        String fmt(DateTime dt, bool use24h) {
          // Convert UTC to device local time
          final local = dt.toLocal();
          if (use24h) {
            final h = local.hour.toString().padLeft(2, '0');
            final m = local.minute.toString().padLeft(2, '0');
            return '$h:$m';
          }
          final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
          final minute = local.minute.toString().padLeft(2, '0');
          final period = local.hour < 12 ? 'AM' : 'PM';
          return '$hour:$minute $period';
        }

        final Map<String, DateTime> prayerLookup = <String, DateTime>{
          'fajr': prayerTimes.fajr,
          'sunrise': prayerTimes.sunrise,
          'dhuhr': prayerTimes.dhuhr,
          'asr': prayerTimes.asr,
          'maghrib': prayerTimes.maghrib,
          'isha': prayerTimes.isha,
        };

        final themeMode =
            await HomeWidget.getWidgetData<String>('theme_mode') ?? 'auto';
        final themeScheme =
            await HomeWidget.getWidgetData<String>('theme_scheme') ?? 'default';
        final dynamic storedIsDark = await HomeWidget.getWidgetData<dynamic>(
          'is_dark_mode',
        );
        final bool isDarkMode;
        if (storedIsDark != null) {
          // Trust the value written by the foreground app
          isDarkMode = storedIsDark is bool
              ? storedIsDark
              : storedIsDark.toString().toLowerCase() == 'true';
        } else {
          // Fallback: infer from themeMode + system brightness
          isDarkMode =
              themeMode == 'dark' ||
              (themeMode == 'auto' &&
                  PlatformDispatcher.instance.platformBrightness ==
                      Brightness.dark);
        }

        final colors = PrayerWidgetService.resolveColorsForScheme(
          themeScheme,
          isDarkMode,
        );

        await HomeWidget.saveWidgetData<bool>('is_dark_mode', isDarkMode);

        await PrayerWidgetService.updateWidget(
          fajr: fmt(prayerTimes.fajr, use24h),
          sunrise: fmt(prayerTimes.sunrise, use24h),
          dhuhr: fmt(prayerTimes.dhuhr, use24h),
          asr: fmt(prayerTimes.asr, use24h),
          maghrib: fmt(prayerTimes.maghrib, use24h),
          isha: fmt(prayerTimes.isha, use24h),
          sunriseLabel: t['sunrise']!,
          nextPrayer: nextPrayer,
          nextPrayerTime: fmt(
            prayerLookup[nextPrayer] ?? prayerTimes.fajr,
            use24h,
          ),
          locationName: locationName,
          lastUpdated: fmt(DateTime.now(), use24h),
          colorBackground: PrayerWidgetService.colorToHex(colors.background),
          colorSurface: PrayerWidgetService.colorToHex(colors.surface),
          colorPrimary: PrayerWidgetService.colorToHex(colors.primary),
          colorPrimaryStrong: PrayerWidgetService.colorToHex(
            colors.primaryStrong,
          ),
          colorPrimaryGradientStart: PrayerWidgetService.colorToHex(
            colors.primaryGradientStart,
          ),
          colorPrimaryGradientEnd: PrayerWidgetService.colorToHex(
            colors.primaryGradientEnd,
          ),
          colorTextPrimary: PrayerWidgetService.colorToHex(colors.textPrimary),
          colorTextSecondary: PrayerWidgetService.colorToHex(
            colors.textSecondary,
          ),
          colorTextMuted: PrayerWidgetService.colorToHex(colors.textMuted),
          colorAccentGold: PrayerWidgetService.colorToHex(colors.accentGold),
          colorBorder: PrayerWidgetService.colorToHex(colors.border),
          colorOnPrimary: PrayerWidgetService.colorToHex(colors.onPrimary),
        );

        // Chain the midnight task if this was the midnight run
        if (taskName.endsWith('_midnight')) {
          await PrayerWidgetWorker.scheduleRefresh();
        }
      } catch (e) {
        // Silent fail — widget keeps last data
      }
    }
    return Future.value(true);
  });
}

CalculationParameters _parametersFromString(String method, String madhab) {
  final params = switch (method.toLowerCase()) {
    'moonsightingcommittee' =>
      CalculationMethodParameters.moonsightingCommittee(),
    'northamerica' => CalculationMethodParameters.northAmerica(),
    'karachi' => CalculationMethodParameters.karachi(),
    'ummalqura' => CalculationMethodParameters.ummAlQura(),
    'dubai' => CalculationMethodParameters.dubai(),
    'qatar' => CalculationMethodParameters.qatar(),
    'kuwait' => CalculationMethodParameters.kuwait(),
    'egypt' || 'egyptian' => CalculationMethodParameters.egyptian(),
    'turkey' || 'turkiye' => CalculationMethodParameters.turkiye(),
    'tehran' => CalculationMethodParameters.tehran(),
    _ => CalculationMethodParameters.muslimWorldLeague(),
  };
  params.madhab = madhab.toLowerCase() == 'hanafi'
      ? Madhab.hanafi
      : Madhab.shafi;
  return params;
}
