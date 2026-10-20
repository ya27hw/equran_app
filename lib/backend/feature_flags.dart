import 'package:equran/backend/settings_db.dart';
import 'package:flutter/foundation.dart';

enum RoadmapFeature {
  memoryMap('memoryMapEnabled'),
  memoryTwin('memoryTwinEnabled'),
  quranConstellations('quranConstellationsEnabled'),
  halaqahMode('halaqahModeEnabled'),
  reciterLens('reciterLensEnabled'),
  journeyCapsules('journeyCapsulesEnabled');

  const RoadmapFeature(this.storageKey);

  final String storageKey;
}

/// Local, fail-closed feature flags. No flag is remotely controlled.
@immutable
class FeatureFlags {
  const FeatureFlags({
    this.memoryMapEnabled = false,
    this.memoryTwinEnabled = false,
    this.quranConstellationsEnabled = false,
    this.halaqahModeEnabled = false,
    this.reciterLensEnabled = false,
    this.journeyCapsulesEnabled = false,
  });

  final bool memoryMapEnabled;
  final bool memoryTwinEnabled;
  final bool quranConstellationsEnabled;
  final bool halaqahModeEnabled;
  final bool reciterLensEnabled;
  final bool journeyCapsulesEnabled;

  bool isEnabled(RoadmapFeature feature) {
    return switch (feature) {
      RoadmapFeature.memoryMap => memoryMapEnabled,
      RoadmapFeature.memoryTwin => memoryTwinEnabled,
      RoadmapFeature.quranConstellations => quranConstellationsEnabled,
      RoadmapFeature.halaqahMode => halaqahModeEnabled,
      RoadmapFeature.reciterLens => reciterLensEnabled,
      RoadmapFeature.journeyCapsules => journeyCapsulesEnabled,
    };
  }

  Map<String, bool> toMap() => <String, bool>{
    for (final RoadmapFeature feature in RoadmapFeature.values)
      feature.storageKey: isEnabled(feature),
  };

  static FeatureFlags fromMap(Map<Object?, Object?> values) {
    bool value(RoadmapFeature feature) => values[feature.storageKey] == true;
    return FeatureFlags(
      memoryMapEnabled: value(RoadmapFeature.memoryMap),
      memoryTwinEnabled: value(RoadmapFeature.memoryTwin),
      quranConstellationsEnabled: value(RoadmapFeature.quranConstellations),
      halaqahModeEnabled: value(RoadmapFeature.halaqahMode),
      reciterLensEnabled: value(RoadmapFeature.reciterLens),
      journeyCapsulesEnabled: value(RoadmapFeature.journeyCapsules),
    );
  }

  FeatureFlags copyWith({
    bool? memoryMapEnabled,
    bool? memoryTwinEnabled,
    bool? quranConstellationsEnabled,
    bool? halaqahModeEnabled,
    bool? reciterLensEnabled,
    bool? journeyCapsulesEnabled,
  }) {
    return FeatureFlags(
      memoryMapEnabled: memoryMapEnabled ?? this.memoryMapEnabled,
      memoryTwinEnabled: memoryTwinEnabled ?? this.memoryTwinEnabled,
      quranConstellationsEnabled:
          quranConstellationsEnabled ?? this.quranConstellationsEnabled,
      halaqahModeEnabled: halaqahModeEnabled ?? this.halaqahModeEnabled,
      reciterLensEnabled: reciterLensEnabled ?? this.reciterLensEnabled,
      journeyCapsulesEnabled:
          journeyCapsulesEnabled ?? this.journeyCapsulesEnabled,
    );
  }
}

class FeatureFlagStore extends ValueNotifier<FeatureFlags> {
  FeatureFlagStore({SettingsDB? settings})
    : _settings = settings ?? SettingsDB(),
      super(const FeatureFlags());

  final SettingsDB _settings;

  Future<void> load() async {
    try {
      final Map<Object?, Object?> values = <Object?, Object?>{
        for (final RoadmapFeature feature in RoadmapFeature.values)
          feature.storageKey: _settings.get(
            feature.storageKey,
            defaultValue: false,
          ),
      };
      value = FeatureFlags.fromMap(values);
    } catch (_) {
      // A settings/storage failure must never open an incomplete feature.
      value = const FeatureFlags();
    }
  }

  Future<void> setEnabled(RoadmapFeature feature, bool enabled) async {
    await _settings.put(feature.storageKey, enabled);
    value = switch (feature) {
      RoadmapFeature.memoryMap => value.copyWith(memoryMapEnabled: enabled),
      RoadmapFeature.memoryTwin => value.copyWith(memoryTwinEnabled: enabled),
      RoadmapFeature.quranConstellations => value.copyWith(
        quranConstellationsEnabled: enabled,
      ),
      RoadmapFeature.halaqahMode => value.copyWith(halaqahModeEnabled: enabled),
      RoadmapFeature.reciterLens => value.copyWith(reciterLensEnabled: enabled),
      RoadmapFeature.journeyCapsules => value.copyWith(
        journeyCapsulesEnabled: enabled,
      ),
    };
  }
}
