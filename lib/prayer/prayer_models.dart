enum PrayerTimeKind {
  fajr('fajr', 'Fajr'),
  sunrise('sunrise', 'Sunrise'),
  dhuhr('dhuhr', 'Dhuhr'),
  asr('asr', 'Asr'),
  maghrib('maghrib', 'Maghrib'),
  isha('isha', 'Isha');

  const PrayerTimeKind(this.id, this.label);

  final String id;
  final String label;

  static const List<PrayerTimeKind> displayOrder = <PrayerTimeKind>[
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
  ];

  static const List<PrayerTimeKind> nextPrayerOrder = <PrayerTimeKind>[
    fajr,
    dhuhr,
    asr,
    maghrib,
    isha,
  ];

  static const List<PrayerTimeKind> reminderOrder = <PrayerTimeKind>[
    fajr,
    dhuhr,
    asr,
    maghrib,
    isha,
  ];

  static PrayerTimeKind fromId(String? id) {
    return PrayerTimeKind.values.firstWhere(
      (PrayerTimeKind kind) => kind.id == id,
      orElse: () => PrayerTimeKind.fajr,
    );
  }
}

const int minSunriseProhibitedDurationMinutes = 15;
const int maxSunriseProhibitedDurationMinutes = 20;
const int defaultSunriseProhibitedDurationMinutes = 20;

const int minDhuhrProhibitedDurationMinutes = 5;
const int maxDhuhrProhibitedDurationMinutes = 10;
const int defaultDhuhrProhibitedDurationMinutes = 10;

const int minSunsetProhibitedDurationMinutes = 15;
const int maxSunsetProhibitedDurationMinutes = 20;
const int defaultSunsetProhibitedDurationMinutes = 15;

enum PrayerCalculationMethod {
  auto('auto', 'Best for location'),
  muslimWorldLeague('muslimWorldLeague', 'Muslim World League'),
  egyptian('egyptian', 'Egyptian'),
  ummAlQura('ummAlQura', 'Umm al-Qura'),
  dubai('dubai', 'Dubai / Gulf'),
  kuwait('kuwait', 'Kuwait'),
  qatar('qatar', 'Qatar'),
  karachi('karachi', 'Karachi'),
  northAmerica('northAmerica', 'ISNA'),
  moonsightingCommittee('moonsightingCommittee', 'Moonsighting Committee'),
  morocco('morocco', 'Morocco'),
  singapore('singapore', 'Singapore'),
  tehran('tehran', 'Tehran'),
  turkiye('turkiye', 'Turkey / Diyanet'),
  uk18('uk18', 'UK 18°'),
  custom('custom', 'Custom');

  const PrayerCalculationMethod(this.id, this.label);

  final String id;
  final String label;

  static PrayerCalculationMethod fromId(String? id) {
    return PrayerCalculationMethod.values.firstWhere(
      (PrayerCalculationMethod method) => method.id == id,
      orElse: () => PrayerCalculationMethod.auto,
    );
  }

  String get shortLabel {
    return switch (this) {
      PrayerCalculationMethod.auto => 'Auto',
      PrayerCalculationMethod.muslimWorldLeague => 'MWL',
      PrayerCalculationMethod.egyptian => 'Egyptian',
      PrayerCalculationMethod.ummAlQura => 'Umm al-Qura',
      PrayerCalculationMethod.dubai => 'Dubai',
      PrayerCalculationMethod.kuwait => 'Kuwait',
      PrayerCalculationMethod.qatar => 'Qatar',
      PrayerCalculationMethod.karachi => 'Karachi',
      PrayerCalculationMethod.northAmerica => 'ISNA',
      PrayerCalculationMethod.moonsightingCommittee => 'Moonsighting',
      PrayerCalculationMethod.morocco => 'Morocco',
      PrayerCalculationMethod.singapore => 'Singapore',
      PrayerCalculationMethod.tehran => 'Tehran',
      PrayerCalculationMethod.turkiye => 'Turkey',
      PrayerCalculationMethod.uk18 => 'UK 18°',
      PrayerCalculationMethod.custom => 'Custom',
    };
  }
}

enum PrayerHighLatitudeRule {
  auto('auto', 'Auto'),
  none('none', 'None'),
  middleOfTheNight('middleOfTheNight', 'Middle of the night'),
  oneSeventh('oneSeventh', 'One seventh'),
  angleBased('angleBased', 'Angle based');

  const PrayerHighLatitudeRule(this.id, this.label);

  final String id;
  final String label;

  static PrayerHighLatitudeRule fromId(String? id) {
    return PrayerHighLatitudeRule.values.firstWhere(
      (PrayerHighLatitudeRule rule) => rule.id == id,
      orElse: () => PrayerHighLatitudeRule.auto,
    );
  }
}

enum PrayerCustomIshaMode {
  angle('angle', 'Angle'),
  interval('interval', 'Interval after Maghrib'),
  fixedTime('fixedTime', 'Fixed time'),
  latestCap('latestCap', 'Latest time cap');

  const PrayerCustomIshaMode(this.id, this.label);

  final String id;
  final String label;

  static PrayerCustomIshaMode fromId(String? id) {
    return PrayerCustomIshaMode.values.firstWhere(
      (PrayerCustomIshaMode mode) => mode.id == id,
      orElse: () => PrayerCustomIshaMode.angle,
    );
  }
}

enum PrayerAsrMethod {
  standard('standard', 'Standard'),
  hanafi('hanafi', 'Hanafi');

  const PrayerAsrMethod(this.id, this.label);

  final String id;
  final String label;

  static PrayerAsrMethod fromId(String? id) {
    return PrayerAsrMethod.values.firstWhere(
      (PrayerAsrMethod method) => method.id == id,
      orElse: () => PrayerAsrMethod.standard,
    );
  }
}

enum PrayerLocationMode {
  currentDevice('currentDevice', 'Current device location'),
  manual('manual', 'Manual location');

  const PrayerLocationMode(this.id, this.label);

  final String id;
  final String label;

  static PrayerLocationMode fromId(String? id) {
    return PrayerLocationMode.values.firstWhere(
      (PrayerLocationMode mode) => mode.id == id,
      orElse: () => PrayerLocationMode.manual,
    );
  }
}

class PrayerLocation {
  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.mode,
    this.countryCode,
    this.timezoneId,
  });

  static PrayerLocation? fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return null;
    final double? latitude = _readDouble(json['latitude']);
    final double? longitude = _readDouble(json['longitude']);
    if (latitude == null || longitude == null) {
      return null;
    }
    final dynamic labelValue = json['label'];
    final dynamic countryCodeValue = json['countryCode'];
    final dynamic timezoneValue = json['timezoneId'];
    final String? countryCode =
        countryCodeValue is String && countryCodeValue.trim().isNotEmpty
        ? countryCodeValue.trim().toUpperCase()
        : null;
    final String? timezoneId =
        timezoneValue is String && timezoneValue.trim().isNotEmpty
        ? timezoneValue.trim()
        : null;
    final String label = labelValue is String && labelValue.trim().isNotEmpty
        ? labelValue.trim()
        : 'Saved location';

    return PrayerLocation(
      latitude: latitude.clamp(-90, 90).toDouble(),
      longitude: longitude.clamp(-180, 180).toDouble(),
      label: label,
      countryCode: countryCode,
      timezoneId: timezoneId,
      mode: PrayerLocationMode.fromId(json['mode'] as String?),
    );
  }

  final double latitude;
  final double longitude;
  final String label;
  final String? countryCode;
  final String? timezoneId;
  final PrayerLocationMode mode;

  String get displayLabel {
    final String trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty ||
        trimmedLabel == 'Current location' ||
        trimmedLabel == 'Current device location' ||
        trimmedLabel == 'Manual location' ||
        trimmedLabel == 'Selected location' ||
        _looksLikeCoordinateLabel(trimmedLabel)) {
      return 'Saved location';
    }
    return trimmedLabel;
  }

  /// [displayLabel] cut to its first part, so "Muscat, Oman" reads "Muscat".
  String get cityLabel {
    final String label = displayLabel;
    final String first = label.split(RegExp('[,،]')).first.trim();
    return first.isEmpty ? label : first;
  }

  String get coordinateLabel {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'countryCode': countryCode,
      'timezoneId': timezoneId,
      'mode': mode.id,
    };
  }

  PrayerLocation copyWith({
    double? latitude,
    double? longitude,
    String? label,
    String? countryCode,
    String? timezoneId,
    PrayerLocationMode? mode,
  }) {
    return PrayerLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      countryCode: countryCode ?? this.countryCode,
      timezoneId: timezoneId ?? this.timezoneId,
      mode: mode ?? this.mode,
    );
  }
}

String prayerMethodDisplayLabel({
  required PrayerTimeSettings settings,
  required PrayerCalculationMethod effectiveMethod,
}) {
  return switch (settings.method) {
    PrayerCalculationMethod.custom => 'Custom',
    _ => effectiveMethod.shortLabel,
  };
}

class PrayerOffsets {
  const PrayerOffsets({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  factory PrayerOffsets.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const PrayerOffsets();
    return PrayerOffsets(
      fajr: _readInt(json['fajr']),
      sunrise: _readInt(json['sunrise']),
      dhuhr: _readInt(json['dhuhr']),
      asr: _readInt(json['asr']),
      maghrib: _readInt(json['maghrib']),
      isha: _readInt(json['isha']),
    );
  }

  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  int forPrayer(PrayerTimeKind prayer) {
    return switch (prayer) {
      PrayerTimeKind.fajr => fajr,
      PrayerTimeKind.sunrise => sunrise,
      PrayerTimeKind.dhuhr => dhuhr,
      PrayerTimeKind.asr => asr,
      PrayerTimeKind.maghrib => maghrib,
      PrayerTimeKind.isha => isha,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }
}

class PrayerReminderSettings {
  const PrayerReminderSettings({
    this.remindersEnabled = false,
    this.fajrEnabled = true,
    this.dhuhrEnabled = true,
    this.asrEnabled = true,
    this.maghribEnabled = true,
    this.ishaEnabled = true,
    this.reminderOffsetMinutes = 0,
  });

  factory PrayerReminderSettings.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const PrayerReminderSettings();
    return PrayerReminderSettings(
      remindersEnabled: json['remindersEnabled'] == true,
      fajrEnabled: _readBool(json['fajrEnabled'], defaultValue: true),
      dhuhrEnabled: _readBool(json['dhuhrEnabled'], defaultValue: true),
      asrEnabled: _readBool(json['asrEnabled'], defaultValue: true),
      maghribEnabled: _readBool(json['maghribEnabled'], defaultValue: true),
      ishaEnabled: _readBool(json['ishaEnabled'], defaultValue: true),
      reminderOffsetMinutes: _readInt(
        json['reminderOffsetMinutes'],
      ).clamp(0, 120).toInt(),
    );
  }

  final bool remindersEnabled;
  final bool fajrEnabled;
  final bool dhuhrEnabled;
  final bool asrEnabled;
  final bool maghribEnabled;
  final bool ishaEnabled;
  final int reminderOffsetMinutes;

  bool prayerToggleFor(PrayerTimeKind prayer) {
    return switch (prayer) {
      PrayerTimeKind.fajr => fajrEnabled,
      PrayerTimeKind.dhuhr => dhuhrEnabled,
      PrayerTimeKind.asr => asrEnabled,
      PrayerTimeKind.maghrib => maghribEnabled,
      PrayerTimeKind.isha => ishaEnabled,
      PrayerTimeKind.sunrise => false,
    };
  }

  bool isReminderActiveFor(PrayerTimeKind prayer) {
    return remindersEnabled && prayerToggleFor(prayer);
  }

  List<PrayerTimeKind> get enabledPrayerKinds {
    if (!remindersEnabled) return const <PrayerTimeKind>[];
    return PrayerTimeKind.reminderOrder
        .where(prayerToggleFor)
        .toList(growable: false);
  }

  int get enabledPrayerCount => enabledPrayerKinds.length;

  PrayerReminderSettings copyWith({
    bool? remindersEnabled,
    bool? fajrEnabled,
    bool? dhuhrEnabled,
    bool? asrEnabled,
    bool? maghribEnabled,
    bool? ishaEnabled,
    int? reminderOffsetMinutes,
  }) {
    return PrayerReminderSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      fajrEnabled: fajrEnabled ?? this.fajrEnabled,
      dhuhrEnabled: dhuhrEnabled ?? this.dhuhrEnabled,
      asrEnabled: asrEnabled ?? this.asrEnabled,
      maghribEnabled: maghribEnabled ?? this.maghribEnabled,
      ishaEnabled: ishaEnabled ?? this.ishaEnabled,
      reminderOffsetMinutes:
          reminderOffsetMinutes?.clamp(0, 120).toInt() ??
          this.reminderOffsetMinutes,
    );
  }

  PrayerReminderSettings copyWithPrayer(PrayerTimeKind prayer, bool enabled) {
    return switch (prayer) {
      PrayerTimeKind.fajr => copyWith(fajrEnabled: enabled),
      PrayerTimeKind.dhuhr => copyWith(dhuhrEnabled: enabled),
      PrayerTimeKind.asr => copyWith(asrEnabled: enabled),
      PrayerTimeKind.maghrib => copyWith(maghribEnabled: enabled),
      PrayerTimeKind.isha => copyWith(ishaEnabled: enabled),
      PrayerTimeKind.sunrise => this,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'remindersEnabled': remindersEnabled,
      'fajrEnabled': fajrEnabled,
      'dhuhrEnabled': dhuhrEnabled,
      'asrEnabled': asrEnabled,
      'maghribEnabled': maghribEnabled,
      'ishaEnabled': ishaEnabled,
      'reminderOffsetMinutes': reminderOffsetMinutes,
    };
  }
}

class PrayerTimeSettings {
  const PrayerTimeSettings({
    this.method = PrayerCalculationMethod.auto,
    this.customFajrAngle = 18,
    this.customIshaAngle = 17,
    this.customIshaMode = PrayerCustomIshaMode.angle,
    this.customIshaInterval,
    this.customIshaFixedTimeHour = 22,
    this.customIshaFixedTimeMinute = 15,
    this.customIshaLatestCapHour = 22,
    this.customIshaLatestCapMinute = 15,
    this.customMaghribAngle,
    this.asrMethod = PrayerAsrMethod.standard,
    this.highLatitudeRule = PrayerHighLatitudeRule.auto,
    this.offsets = const PrayerOffsets(),
    this.use24HourFormat = false,
    this.useLocationTimezone = true,
    this.sunriseProhibitedDurationMinutes =
        defaultSunriseProhibitedDurationMinutes,
    this.dhuhrProhibitedDurationMinutes = defaultDhuhrProhibitedDurationMinutes,
    this.sunsetProhibitedDurationMinutes =
        defaultSunsetProhibitedDurationMinutes,
    this.reminderSettings = const PrayerReminderSettings(),
  }) : assert(
         sunriseProhibitedDurationMinutes >=
                 minSunriseProhibitedDurationMinutes &&
             sunriseProhibitedDurationMinutes <=
                 maxSunriseProhibitedDurationMinutes,
       ),
       assert(
         dhuhrProhibitedDurationMinutes >= minDhuhrProhibitedDurationMinutes &&
             dhuhrProhibitedDurationMinutes <=
                 maxDhuhrProhibitedDurationMinutes,
       ),
       assert(
         sunsetProhibitedDurationMinutes >=
                 minSunsetProhibitedDurationMinutes &&
             sunsetProhibitedDurationMinutes <=
                 maxSunsetProhibitedDurationMinutes,
       );

  factory PrayerTimeSettings.defaults() {
    return const PrayerTimeSettings();
  }

  factory PrayerTimeSettings.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return PrayerTimeSettings.defaults();
    return PrayerTimeSettings(
      method: PrayerCalculationMethod.fromId(json['method'] as String?),
      customFajrAngle: _readAngle(json['customFajrAngle'], defaultValue: 18),
      customIshaAngle: _readAngle(json['customIshaAngle'], defaultValue: 17),
      customIshaMode: PrayerCustomIshaMode.fromId(
        json['customIshaMode'] as String?,
      ),
      customIshaInterval: _readOptionalMinutes(json['customIshaInterval']),
      customIshaFixedTimeHour: _readClockHour(
        json['customIshaFixedTimeHour'],
        defaultValue: 22,
      ),
      customIshaFixedTimeMinute: _readClockMinute(
        json['customIshaFixedTimeMinute'],
        defaultValue: 15,
      ),
      customIshaLatestCapHour: _readClockHour(
        json['customIshaLatestCapHour'],
        defaultValue: 22,
      ),
      customIshaLatestCapMinute: _readClockMinute(
        json['customIshaLatestCapMinute'],
        defaultValue: 15,
      ),
      customMaghribAngle: _readOptionalAngle(json['customMaghribAngle']),
      asrMethod: PrayerAsrMethod.fromId(json['asrMethod'] as String?),
      highLatitudeRule: PrayerHighLatitudeRule.fromId(
        json['highLatitudeRule'] as String?,
      ),
      offsets: PrayerOffsets.fromJson(json['offsets'] as Map?),
      use24HourFormat: json['use24HourFormat'] == true,
      useLocationTimezone: json['useLocationTimezone'] != false,
      sunriseProhibitedDurationMinutes: _readBoundedMinutes(
        json['sunriseProhibitedDurationMinutes'],
        defaultValue: defaultSunriseProhibitedDurationMinutes,
        min: minSunriseProhibitedDurationMinutes,
        max: maxSunriseProhibitedDurationMinutes,
      ),
      dhuhrProhibitedDurationMinutes: _readBoundedMinutes(
        json['dhuhrProhibitedDurationMinutes'],
        defaultValue: defaultDhuhrProhibitedDurationMinutes,
        min: minDhuhrProhibitedDurationMinutes,
        max: maxDhuhrProhibitedDurationMinutes,
      ),
      sunsetProhibitedDurationMinutes: _readBoundedMinutes(
        json['sunsetProhibitedDurationMinutes'],
        defaultValue: defaultSunsetProhibitedDurationMinutes,
        min: minSunsetProhibitedDurationMinutes,
        max: maxSunsetProhibitedDurationMinutes,
      ),
      reminderSettings: PrayerReminderSettings.fromJson(
        json['reminderSettings'] as Map?,
      ),
    );
  }

  final PrayerCalculationMethod method;
  final double customFajrAngle;
  final double customIshaAngle;
  final PrayerCustomIshaMode customIshaMode;
  final int? customIshaInterval;
  final int customIshaFixedTimeHour;
  final int customIshaFixedTimeMinute;
  final int customIshaLatestCapHour;
  final int customIshaLatestCapMinute;
  final double? customMaghribAngle;
  final PrayerAsrMethod asrMethod;
  final PrayerHighLatitudeRule highLatitudeRule;
  final PrayerOffsets offsets;
  final bool use24HourFormat;
  final bool useLocationTimezone;
  final int sunriseProhibitedDurationMinutes;
  final int dhuhrProhibitedDurationMinutes;
  final int sunsetProhibitedDurationMinutes;
  final PrayerReminderSettings reminderSettings;

  PrayerTimeSettings copyWith({
    PrayerCalculationMethod? method,
    double? customFajrAngle,
    double? customIshaAngle,
    PrayerCustomIshaMode? customIshaMode,
    int? customIshaInterval,
    int? customIshaFixedTimeHour,
    int? customIshaFixedTimeMinute,
    int? customIshaLatestCapHour,
    int? customIshaLatestCapMinute,
    double? customMaghribAngle,
    PrayerAsrMethod? asrMethod,
    PrayerHighLatitudeRule? highLatitudeRule,
    PrayerOffsets? offsets,
    bool? use24HourFormat,
    bool? useLocationTimezone,
    int? sunriseProhibitedDurationMinutes,
    int? dhuhrProhibitedDurationMinutes,
    int? sunsetProhibitedDurationMinutes,
    PrayerReminderSettings? reminderSettings,
  }) {
    return PrayerTimeSettings(
      method: method ?? this.method,
      customFajrAngle:
          customFajrAngle?.clamp(0, 30).toDouble() ?? this.customFajrAngle,
      customIshaAngle:
          customIshaAngle?.clamp(0, 30).toDouble() ?? this.customIshaAngle,
      customIshaMode: customIshaMode ?? this.customIshaMode,
      customIshaInterval:
          customIshaInterval?.clamp(0, 240).toInt() ?? this.customIshaInterval,
      customIshaFixedTimeHour:
          customIshaFixedTimeHour?.clamp(0, 23).toInt() ??
          this.customIshaFixedTimeHour,
      customIshaFixedTimeMinute:
          customIshaFixedTimeMinute?.clamp(0, 59).toInt() ??
          this.customIshaFixedTimeMinute,
      customIshaLatestCapHour:
          customIshaLatestCapHour?.clamp(0, 23).toInt() ??
          this.customIshaLatestCapHour,
      customIshaLatestCapMinute:
          customIshaLatestCapMinute?.clamp(0, 59).toInt() ??
          this.customIshaLatestCapMinute,
      customMaghribAngle: customMaghribAngle ?? this.customMaghribAngle,
      asrMethod: asrMethod ?? this.asrMethod,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      offsets: offsets ?? this.offsets,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      useLocationTimezone: useLocationTimezone ?? this.useLocationTimezone,
      sunriseProhibitedDurationMinutes: _clampMinutes(
        sunriseProhibitedDurationMinutes ??
            this.sunriseProhibitedDurationMinutes,
        min: minSunriseProhibitedDurationMinutes,
        max: maxSunriseProhibitedDurationMinutes,
      ),
      dhuhrProhibitedDurationMinutes: _clampMinutes(
        dhuhrProhibitedDurationMinutes ?? this.dhuhrProhibitedDurationMinutes,
        min: minDhuhrProhibitedDurationMinutes,
        max: maxDhuhrProhibitedDurationMinutes,
      ),
      sunsetProhibitedDurationMinutes: _clampMinutes(
        sunsetProhibitedDurationMinutes ?? this.sunsetProhibitedDurationMinutes,
        min: minSunsetProhibitedDurationMinutes,
        max: maxSunsetProhibitedDurationMinutes,
      ),
      reminderSettings: reminderSettings ?? this.reminderSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method.id,
      'customFajrAngle': customFajrAngle,
      'customIshaAngle': customIshaAngle,
      'customIshaMode': customIshaMode.id,
      'customIshaInterval': customIshaInterval,
      'customIshaFixedTimeHour': customIshaFixedTimeHour,
      'customIshaFixedTimeMinute': customIshaFixedTimeMinute,
      'customIshaLatestCapHour': customIshaLatestCapHour,
      'customIshaLatestCapMinute': customIshaLatestCapMinute,
      'customMaghribAngle': customMaghribAngle,
      'asrMethod': asrMethod.id,
      'highLatitudeRule': highLatitudeRule.id,
      'offsets': offsets.toJson(),
      'use24HourFormat': use24HourFormat,
      'useLocationTimezone': useLocationTimezone,
      'sunriseProhibitedDurationMinutes': sunriseProhibitedDurationMinutes,
      'dhuhrProhibitedDurationMinutes': dhuhrProhibitedDurationMinutes,
      'sunsetProhibitedDurationMinutes': sunsetProhibitedDurationMinutes,
      'reminderSettings': reminderSettings.toJson(),
    };
  }
}

class PrayerTimeEntry {
  const PrayerTimeEntry({
    required this.kind,
    required this.time,
    required this.offsetMinutes,
  });

  final PrayerTimeKind kind;
  final DateTime time;
  final int offsetMinutes;
}

class PrayerDay {
  const PrayerDay({
    required this.date,
    required this.location,
    required this.settings,
    required this.effectiveMethod,
    required this.entries,
    required this.timezoneId,
    required this.usesLocationTimezone,
  });

  final DateTime date;
  final PrayerLocation location;
  final PrayerTimeSettings settings;
  final PrayerCalculationMethod effectiveMethod;
  final List<PrayerTimeEntry> entries;
  final String? timezoneId;
  final bool usesLocationTimezone;

  PrayerTimeEntry entryFor(PrayerTimeKind kind) {
    return entries.firstWhere((PrayerTimeEntry entry) => entry.kind == kind);
  }

  /// The six times as the Prayer list should show them.
  ///
  /// The service dates Maghrib and Isha to the evening before (the Islamic day
  /// starts at Maghrib). During that night, before Fajr, those are the right
  /// ones: Isha is current or just passed. From Fajr on, the list should look
  /// ahead to this evening, so Maghrib and Isha come from [following], the day
  /// after. [now] is null when browsing another date, which always looks
  /// ahead. Without this, from Fajr until Maghrib the list marks the evening
  /// prayers "Passed" even though they have not begun.
  List<PrayerTimeEntry> displayEntries(PrayerDay following, {DateTime? now}) {
    final bool lookAhead =
        now == null || !now.isBefore(entryFor(PrayerTimeKind.fajr).time);
    return <PrayerTimeEntry>[
      for (final PrayerTimeEntry entry in entries)
        switch (entry.kind) {
          PrayerTimeKind.maghrib ||
          PrayerTimeKind.isha when lookAhead => following.entryFor(entry.kind),
          _ => entry,
        },
    ];
  }
}

enum PrayerCurrentPeriodType {
  normalPrayer,
  sunriseProhibited,
  dhuhrProhibited,
  sunsetProhibited,
  beforeDhuhr,
}

class PrayerCurrentPeriod {
  const PrayerCurrentPeriod({
    required this.type,
    required this.featuredEntry,
    required this.endsAt,
    this.highlightedKind,
  });

  final PrayerCurrentPeriodType type;
  final PrayerTimeEntry featuredEntry;
  final DateTime endsAt;
  final PrayerTimeKind? highlightedKind;

  PrayerTimeEntry? get currentPrayer {
    return switch (type) {
      PrayerCurrentPeriodType.normalPrayer ||
      PrayerCurrentPeriodType.sunriseProhibited => featuredEntry,
      PrayerCurrentPeriodType.dhuhrProhibited ||
      PrayerCurrentPeriodType.sunsetProhibited ||
      PrayerCurrentPeriodType.beforeDhuhr => null,
    };
  }
}

class NextPrayer {
  const NextPrayer({required this.entry, required this.countdown});

  final PrayerTimeEntry entry;
  final Duration countdown;
}

int _readInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double _readAngle(dynamic value, {required double defaultValue}) {
  return (_readDouble(value) ?? defaultValue).clamp(0, 30).toDouble();
}

double? _readOptionalAngle(dynamic value) {
  return _readDouble(value)?.clamp(0, 30).toDouble();
}

int? _readOptionalMinutes(dynamic value) {
  return _readNullableInt(value)?.clamp(0, 240).toInt();
}

int _readBoundedMinutes(
  dynamic value, {
  required int defaultValue,
  required int min,
  required int max,
}) {
  return _clampMinutes(
    _readInt(value, defaultValue: defaultValue),
    min: min,
    max: max,
  );
}

int _clampMinutes(int value, {required int min, required int max}) {
  return value.clamp(min, max).toInt();
}

int _readClockHour(dynamic value, {required int defaultValue}) {
  return _readInt(value, defaultValue: defaultValue).clamp(0, 23).toInt();
}

int _readClockMinute(dynamic value, {required int defaultValue}) {
  return _readInt(value, defaultValue: defaultValue).clamp(0, 59).toInt();
}

bool _readBool(dynamic value, {required bool defaultValue}) {
  if (value is bool) return value;
  if (value is String) {
    final String normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return defaultValue;
}

double? _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _looksLikeCoordinateLabel(String value) {
  return RegExp(
    r'^\s*-?\d{1,2}(?:\.\d+)?\s*,\s*-?\d{1,3}(?:\.\d+)?\s*$',
  ).hasMatch(value);
}
