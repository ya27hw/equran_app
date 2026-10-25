import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_timezone_service.dart';
import 'package:timezone/timezone.dart' as timezone;

class PrayerTimesService {
  const PrayerTimesService();

  PrayerDay calculateDay({
    required DateTime date,
    required PrayerLocation location,
    required PrayerTimeSettings settings,
  }) {
    final timezone.Location? prayerTimezone = _prayerTimezoneFor(
      location: location,
      settings: settings,
    );
    final PrayerCalculationMethod effectiveMethod = effectiveMethodFor(
      location: location,
      settings: settings,
    );
    final adhan.HighLatitudeRule highLatitudeRule = resolveHighLatitudeRule(
      location: location,
      settings: settings,
      effectiveMethod: effectiveMethod,
    );
    final adhan.CalculationParameters parameters = _parametersFor(
      method: effectiveMethod,
      settings: settings,
      highLatitudeRule: highLatitudeRule,
    );

    // Fajr, Sunrise, Dhuhr, Asr are calculated for day D (localDate)
    final DateTime localDate = prayerTimezone == null
        ? DateTime(date.year, date.month, date.day)
        : timezone.TZDateTime(prayerTimezone, date.year, date.month, date.day);
    // adhan_dart expects a UTC calendar date so that its internal
    // day-arithmetic (date.add/subtract(Duration(days: 1))) does not drift
    // or land on the same calendar day across daylight saving time transitions
    // (such as autumn 25-hour days). Astronomical coordinates and sunrise/sunset
    // are date-based; passing a UTC date prevents safeFajr from seeing a
    // negative night duration and corrupting Fajr time.
    final DateTime baseUtcDate = DateTime.utc(date.year, date.month, date.day);
    final adhan.PrayerTimes baseTimes = adhan.PrayerTimes(
      coordinates: adhan.Coordinates(location.latitude, location.longitude),
      date: baseUtcDate,
      calculationParameters: parameters,
      precision: true,
    );
    final DateTime baseSunrise = _displayTime(
      baseTimes.sunrise,
      prayerTimezone,
    );

    // Maghrib, Isha are calculated for day D - 1 (prevLocalDate)
    final DateTime prevLocalDate = prayerTimezone == null
        ? DateTime(date.year, date.month, date.day - 1)
        : timezone.TZDateTime(
            prayerTimezone,
            date.year,
            date.month,
            date.day - 1,
          );
    final adhan.PrayerTimes prevTimes = adhan.PrayerTimes(
      coordinates: adhan.Coordinates(location.latitude, location.longitude),
      date: DateTime.utc(date.year, date.month, date.day - 1),
      calculationParameters: parameters,
      precision: true,
    );
    final DateTime baseMaghrib = _displayTime(
      prevTimes.maghrib,
      prayerTimezone,
    );
    final DateTime baseIsha = _displayTime(prevTimes.isha, prayerTimezone);
    final DateTime customIsha = _customIshaTime(
      baseIsha: baseIsha,
      baseMaghrib: baseMaghrib,
      localDate: prevLocalDate,
      method: effectiveMethod,
      prayerTimezone: prayerTimezone,
      settings: settings,
    );

    final Map<PrayerTimeKind, DateTime> times = <PrayerTimeKind, DateTime>{
      PrayerTimeKind.fajr: _withOffset(
        _displayTime(baseTimes.fajr, prayerTimezone),
        settings.offsets.fajr,
      ),
      PrayerTimeKind.sunrise: _withOffset(
        baseSunrise,
        settings.offsets.sunrise,
      ),
      PrayerTimeKind.dhuhr: _withOffset(
        _displayTime(baseTimes.dhuhr, prayerTimezone),
        settings.offsets.dhuhr,
      ),
      PrayerTimeKind.asr: _withOffset(
        _displayTime(baseTimes.asr, prayerTimezone),
        settings.offsets.asr,
      ),
      PrayerTimeKind.maghrib: _withOffset(
        baseMaghrib,
        settings.offsets.maghrib,
      ),
      PrayerTimeKind.isha: _withOffset(customIsha, settings.offsets.isha),
    };

    return PrayerDay(
      date: localDate,
      location: location,
      settings: settings,
      effectiveMethod: effectiveMethod,
      timezoneId: prayerTimezone?.name,
      usesLocationTimezone: prayerTimezone != null,
      entries: PrayerTimeKind.displayOrder
          .map(
            (PrayerTimeKind kind) => PrayerTimeEntry(
              kind: kind,
              time: _floorToMinute(times[kind]!),
              offsetMinutes: settings.offsets.forPrayer(kind),
            ),
          )
          .toList(growable: false),
    );
  }

  PrayerCalculationMethod effectiveMethodFor({
    required PrayerLocation location,
    required PrayerTimeSettings settings,
  }) {
    if (settings.method != PrayerCalculationMethod.auto) {
      return settings.method;
    }
    return bestMethodForLocation(location);
  }

  DateTime calendarDateForInstant({
    required DateTime instant,
    required PrayerLocation location,
    required PrayerTimeSettings settings,
  }) {
    final timezone.Location? prayerTimezone = _prayerTimezoneFor(
      location: location,
      settings: settings,
    );
    final DateTime zonedInstant = prayerTimezone == null
        ? instant.toLocal()
        : timezone.TZDateTime.from(instant.toUtc(), prayerTimezone);
    final DateTime baseDate = DateTime(
      zonedInstant.year,
      zonedInstant.month,
      zonedInstant.day,
    );

    final PrayerCalculationMethod effectiveMethod = effectiveMethodFor(
      location: location,
      settings: settings,
    );
    final adhan.HighLatitudeRule highLatitudeRule = resolveHighLatitudeRule(
      location: location,
      settings: settings,
      effectiveMethod: effectiveMethod,
    );
    final adhan.CalculationParameters parameters = _parametersFor(
      method: effectiveMethod,
      settings: settings,
      highLatitudeRule: highLatitudeRule,
    );

    final adhan.PrayerTimes baseTimes = adhan.PrayerTimes(
      coordinates: adhan.Coordinates(location.latitude, location.longitude),
      date: DateTime.utc(baseDate.year, baseDate.month, baseDate.day),
      calculationParameters: parameters,
      precision: true,
    );

    final DateTime baseMaghrib = _displayTime(
      baseTimes.maghrib,
      prayerTimezone,
    );

    final DateTime maghribTime = _floorToMinute(
      _withOffset(baseMaghrib, settings.offsets.maghrib),
    );

    if (!zonedInstant.isBefore(maghribTime)) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day + 1);
    }
    return baseDate;
  }

  PrayerCalculationMethod bestMethodForLocation(PrayerLocation location) {
    final String countryCode = location.countryCode?.toUpperCase() ?? '';
    return switch (countryCode) {
      'AE' || 'OM' || 'BH' => PrayerCalculationMethod.dubai,
      'KW' => PrayerCalculationMethod.kuwait,
      'QA' => PrayerCalculationMethod.qatar,
      'SA' => PrayerCalculationMethod.ummAlQura,
      'EG' => PrayerCalculationMethod.egyptian,
      'PK' || 'IN' || 'BD' || 'AF' => PrayerCalculationMethod.karachi,
      'GB' || 'UK' || 'IE' => PrayerCalculationMethod.uk18,
      'MA' => PrayerCalculationMethod.morocco,
      'IR' => PrayerCalculationMethod.tehran,
      'US' || 'CA' => PrayerCalculationMethod.northAmerica,
      'SG' || 'MY' || 'ID' || 'BN' => PrayerCalculationMethod.singapore,
      'TR' => PrayerCalculationMethod.turkiye,
      _ => PrayerCalculationMethod.muslimWorldLeague,
    };
  }

  PrayerHighLatitudeRule effectiveHighLatitudeRuleFor({
    required PrayerLocation location,
    required PrayerTimeSettings settings,
    PrayerCalculationMethod? effectiveMethod,
  }) {
    if (settings.highLatitudeRule != PrayerHighLatitudeRule.auto) {
      return settings.highLatitudeRule;
    }
    if (!_needsHighLatitudeAdjustment(location)) {
      return PrayerHighLatitudeRule.none;
    }

    final PrayerCalculationMethod method =
        effectiveMethod ??
        effectiveMethodFor(location: location, settings: settings);
    if (method == PrayerCalculationMethod.moonsightingCommittee) {
      return PrayerHighLatitudeRule.oneSeventh;
    }
    return PrayerHighLatitudeRule.angleBased;
  }

  adhan.HighLatitudeRule resolveHighLatitudeRule({
    required PrayerLocation location,
    required PrayerTimeSettings settings,
    PrayerCalculationMethod? effectiveMethod,
  }) {
    final PrayerHighLatitudeRule appRule = effectiveHighLatitudeRuleFor(
      location: location,
      settings: settings,
      effectiveMethod: effectiveMethod,
    );
    return _adhanHighLatitudeRuleFor(appRule);
  }

  NextPrayer nextPrayer({
    required PrayerDay day,
    required DateTime now,
    PrayerDay? tomorrow,
  }) {
    final DateTime localNow = now.toLocal();
    final DateTime displayNow = _floorToMinute(localNow);

    final List<PrayerTimeEntry> candidates = <PrayerTimeEntry>[];
    for (final PrayerTimeKind kind in PrayerTimeKind.nextPrayerOrder) {
      candidates.add(day.entryFor(kind));
      if (tomorrow != null) {
        candidates.add(tomorrow.entryFor(kind));
      }
    }

    candidates.sort((a, b) => a.time.compareTo(b.time));

    for (final PrayerTimeEntry entry in candidates) {
      final DateTime displayTime = _floorToMinute(entry.time);
      if (displayTime.isAfter(displayNow)) {
        return NextPrayer(
          entry: entry,
          countdown: displayTime.difference(localNow),
        );
      }
    }

    final PrayerTimeEntry fajr;
    if (tomorrow != null) {
      fajr = tomorrow.entryFor(PrayerTimeKind.fajr);
    } else {
      final PrayerDay tomorrowDay = calculateDay(
        date: DateTime(day.date.year, day.date.month, day.date.day + 1),
        location: day.location,
        settings: day.settings,
      );
      fajr = tomorrowDay.entryFor(PrayerTimeKind.fajr);
    }
    final DateTime nextFajr = fajr.time;
    final DateTime displayNextFajr = _floorToMinute(nextFajr);
    return NextPrayer(
      entry: PrayerTimeEntry(
        kind: PrayerTimeKind.fajr,
        time: nextFajr,
        offsetMinutes: fajr.offsetMinutes,
      ),
      countdown: displayNextFajr.difference(localNow),
    );
  }

  List<PrayerCurrentPeriod> _periodsForDay(
    PrayerDay d,
    DateTime nextFajr,
    DateTime nextMaghrib,
  ) {
    final PrayerTimeEntry fajr = d.entryFor(PrayerTimeKind.fajr);
    final PrayerTimeEntry sunrise = d.entryFor(PrayerTimeKind.sunrise);
    final PrayerTimeEntry dhuhr = d.entryFor(PrayerTimeKind.dhuhr);
    final PrayerTimeEntry asr = d.entryFor(PrayerTimeKind.asr);
    final PrayerTimeEntry maghrib = d.entryFor(PrayerTimeKind.maghrib);
    final PrayerTimeEntry isha = d.entryFor(PrayerTimeKind.isha);

    final DateTime sunriseProhibitedEnd = sunrise.time.add(
      Duration(minutes: d.settings.sunriseProhibitedDurationMinutes),
    );
    final DateTime dhuhrProhibitedStart = dhuhr.time.subtract(
      Duration(minutes: d.settings.dhuhrProhibitedDurationMinutes),
    );
    final DateTime sunsetProhibitedStart = nextMaghrib.subtract(
      Duration(minutes: d.settings.sunsetProhibitedDurationMinutes),
    );

    return <PrayerCurrentPeriod>[
      _normalPrayerPeriod(entry: maghrib, endsAt: isha.time),
      _normalPrayerPeriod(entry: isha, endsAt: fajr.time),
      _normalPrayerPeriod(entry: fajr, endsAt: sunrise.time),
      PrayerCurrentPeriod(
        type: PrayerCurrentPeriodType.sunriseProhibited,
        featuredEntry: sunrise,
        endsAt: _earlierOf(sunriseProhibitedEnd, dhuhr.time),
        highlightedKind: PrayerTimeKind.sunrise,
      ),
      if (sunriseProhibitedEnd.isBefore(dhuhrProhibitedStart))
        PrayerCurrentPeriod(
          type: PrayerCurrentPeriodType.beforeDhuhr,
          featuredEntry: dhuhr,
          endsAt: dhuhrProhibitedStart,
        ),
      PrayerCurrentPeriod(
        type: PrayerCurrentPeriodType.dhuhrProhibited,
        featuredEntry: dhuhr,
        endsAt: dhuhr.time,
      ),
      _normalPrayerPeriod(entry: dhuhr, endsAt: asr.time),
      _normalPrayerPeriod(entry: asr, endsAt: sunsetProhibitedStart),
      PrayerCurrentPeriod(
        type: PrayerCurrentPeriodType.sunsetProhibited,
        featuredEntry: PrayerTimeEntry(
          kind: PrayerTimeKind.maghrib,
          time: nextMaghrib,
          offsetMinutes: maghrib.offsetMinutes,
        ),
        endsAt: nextMaghrib,
      ),
    ];
  }

  PrayerCurrentPeriod currentPrayerPeriod({
    required PrayerDay today,
    required PrayerDay yesterday,
    required DateTime now,
    PrayerDay? tomorrow,
  }) {
    final PrayerDay following =
        tomorrow ??
        calculateDay(
          date: DateTime(today.date.year, today.date.month, today.date.day + 1),
          location: today.location,
          settings: today.settings,
        );
    final List<PrayerCurrentPeriod> periods = <PrayerCurrentPeriod>[
      ..._periodsForDay(
        yesterday,
        today.entryFor(PrayerTimeKind.fajr).time,
        today.entryFor(PrayerTimeKind.maghrib).time,
      ),
      ..._periodsForDay(
        today,
        following.entryFor(PrayerTimeKind.fajr).time,
        following.entryFor(PrayerTimeKind.maghrib).time,
      ),
    ];

    for (final PrayerCurrentPeriod period in periods) {
      if (now.isBefore(period.endsAt)) {
        return period;
      }
    }

    return _normalPrayerPeriod(
      entry: today.entryFor(PrayerTimeKind.isha),
      endsAt: following.entryFor(PrayerTimeKind.fajr).time,
    );
  }

  adhan.CalculationParameters _parametersFor({
    required PrayerCalculationMethod method,
    required PrayerTimeSettings settings,
    required adhan.HighLatitudeRule highLatitudeRule,
  }) {
    final adhan.CalculationParameters parameters = switch (method) {
      PrayerCalculationMethod.auto ||
      PrayerCalculationMethod.muslimWorldLeague =>
        adhan.CalculationMethodParameters.muslimWorldLeague(),
      PrayerCalculationMethod.egyptian =>
        adhan.CalculationMethodParameters.egyptian(),
      PrayerCalculationMethod.ummAlQura =>
        adhan.CalculationMethodParameters.ummAlQura(),
      PrayerCalculationMethod.dubai =>
        adhan.CalculationMethodParameters.dubai(),
      PrayerCalculationMethod.kuwait =>
        adhan.CalculationMethodParameters.kuwait(),
      PrayerCalculationMethod.qatar =>
        adhan.CalculationMethodParameters.qatar(),
      PrayerCalculationMethod.karachi =>
        adhan.CalculationMethodParameters.karachi(),
      PrayerCalculationMethod.northAmerica =>
        adhan.CalculationMethodParameters.northAmerica(),
      PrayerCalculationMethod.moonsightingCommittee =>
        adhan.CalculationMethodParameters.moonsightingCommittee(),
      PrayerCalculationMethod.morocco =>
        adhan.CalculationMethodParameters.morocco(),
      PrayerCalculationMethod.singapore =>
        adhan.CalculationMethodParameters.singapore(),
      PrayerCalculationMethod.tehran =>
        adhan.CalculationMethodParameters.tehran(),
      PrayerCalculationMethod.turkiye =>
        adhan.CalculationMethodParameters.turkiye(),
      PrayerCalculationMethod.uk18 || PrayerCalculationMethod.custom =>
        adhan.CalculationMethodParameters.other(),
    };

    parameters.madhab = switch (settings.asrMethod) {
      PrayerAsrMethod.standard => adhan.Madhab.shafi,
      PrayerAsrMethod.hanafi => adhan.Madhab.hanafi,
    };

    if (method == PrayerCalculationMethod.uk18) {
      parameters.fajrAngle = 18;
      parameters.ishaAngle = 18;
      parameters.ishaInterval = null;
      parameters.maghribAngle = null;
    } else if (method == PrayerCalculationMethod.custom) {
      parameters.fajrAngle = settings.customFajrAngle;
      parameters.ishaAngle = settings.customIshaAngle;
      parameters.ishaInterval = _customIshaIntervalForCalculation(settings);
      parameters.maghribAngle = settings.customMaghribAngle;
    }

    parameters.highLatitudeRule = highLatitudeRule;

    return parameters;
  }

  adhan.HighLatitudeRule _adhanHighLatitudeRuleFor(
    PrayerHighLatitudeRule rule,
  ) {
    return switch (rule) {
      PrayerHighLatitudeRule.auto ||
      PrayerHighLatitudeRule.none => adhan.HighLatitudeRule.middleOfTheNight,
      PrayerHighLatitudeRule.middleOfTheNight =>
        adhan.HighLatitudeRule.middleOfTheNight,
      PrayerHighLatitudeRule.oneSeventh =>
        adhan.HighLatitudeRule.seventhOfTheNight,
      PrayerHighLatitudeRule.angleBased => adhan.HighLatitudeRule.twilightAngle,
    };
  }

  bool _needsHighLatitudeAdjustment(PrayerLocation location) {
    return location.latitude.abs() >= 48;
  }

  int? _customIshaIntervalForCalculation(PrayerTimeSettings settings) {
    return switch (settings.customIshaMode) {
      PrayerCustomIshaMode.interval ||
      PrayerCustomIshaMode.latestCap => settings.customIshaInterval,
      PrayerCustomIshaMode.angle || PrayerCustomIshaMode.fixedTime => null,
    };
  }

  DateTime _customIshaTime({
    required DateTime baseIsha,
    required DateTime baseMaghrib,
    required DateTime localDate,
    required PrayerCalculationMethod method,
    required timezone.Location? prayerTimezone,
    required PrayerTimeSettings settings,
  }) {
    if (method != PrayerCalculationMethod.custom) return baseIsha;

    final DateTime isha = switch (settings.customIshaMode) {
      PrayerCustomIshaMode.angle => baseIsha,
      PrayerCustomIshaMode.interval =>
        settings.customIshaInterval == null
            ? baseIsha
            : baseMaghrib.add(Duration(minutes: settings.customIshaInterval!)),
      PrayerCustomIshaMode.fixedTime => _clockTimeOnDate(
        date: localDate,
        hour: settings.customIshaFixedTimeHour,
        minute: settings.customIshaFixedTimeMinute,
        prayerTimezone: prayerTimezone,
      ),
      PrayerCustomIshaMode.latestCap => _cappedIshaTime(
        baseIsha: baseIsha,
        cap: _clockTimeOnDate(
          date: localDate,
          hour: settings.customIshaLatestCapHour,
          minute: settings.customIshaLatestCapMinute,
          prayerTimezone: prayerTimezone,
        ),
      ),
    };

    // Custom Isha mode is resolved first; the manual Isha offset is applied
    // afterwards with the other prayer offsets.
    return isha;
  }

  DateTime _cappedIshaTime({
    required DateTime baseIsha,
    required DateTime cap,
  }) {
    return baseIsha.isAfter(cap) ? cap : baseIsha;
  }

  DateTime _clockTimeOnDate({
    required DateTime date,
    required int hour,
    required int minute,
    required timezone.Location? prayerTimezone,
  }) {
    if (prayerTimezone == null) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    return timezone.TZDateTime(
      prayerTimezone,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  timezone.Location? _prayerTimezoneFor({
    required PrayerLocation location,
    required PrayerTimeSettings settings,
  }) {
    if (!settings.useLocationTimezone) return null;
    return PrayerTimezoneService.locationForId(location.timezoneId);
  }

  DateTime _displayTime(DateTime time, timezone.Location? prayerTimezone) {
    final DateTime utcTime = time.isUtc ? time : time.toUtc();
    if (prayerTimezone == null) return utcTime.toLocal();
    return timezone.TZDateTime.from(utcTime, prayerTimezone);
  }

  DateTime _withOffset(DateTime time, int minutes) {
    if (minutes == 0) return time;
    return time.add(Duration(minutes: minutes));
  }

  PrayerCurrentPeriod _normalPrayerPeriod({
    required PrayerTimeEntry entry,
    required DateTime endsAt,
  }) {
    return PrayerCurrentPeriod(
      type: PrayerCurrentPeriodType.normalPrayer,
      featuredEntry: entry,
      endsAt: endsAt,
      highlightedKind: entry.kind,
    );
  }

  DateTime _earlierOf(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  DateTime _floorToMinute(DateTime time) {
    if (time is timezone.TZDateTime) {
      return timezone.TZDateTime(
        time.location,
        time.year,
        time.month,
        time.day,
        time.hour,
        time.minute,
      );
    }
    return DateTime(time.year, time.month, time.day, time.hour, time.minute);
  }
}
