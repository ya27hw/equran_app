import 'dart:typed_data';

import 'package:equran/backend/settings_db.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
  });
  setUp(() => SettingsDB().clear());
  tearDownAll(Hive.close);

  for (final scheme in [
    'default',
    'fancyBlue',
    'fancyPurple',
    'sepia',
    'red',
  ]) {
    test('$scheme keeps its accent and surfaces with pure black enabled', () {
      final original = EquranColors.forScheme(scheme, true);
      final black = EquranColors.forScheme(
        scheme,
        true,
        pureBlackBackground: true,
      );
      expect(black.background, Colors.black);
      expect(black.surfaceSoft, Colors.black);
      expect(black.primary, original.primary);
      expect(black.surface, original.surface);
      expect(black.textPrimary, original.textPrimary);
      expect(EquranTokens.fromColors(black).glow, Colors.transparent);
      expect(
        EquranColors.forScheme(scheme, false, pureBlackBackground: true),
        same(EquranColors.forScheme(scheme, false)),
      );
      expect(
        PrayerWidgetService.resolveColorsForScheme(
          scheme,
          true,
          pureBlackBackground: true,
        ).background,
        Colors.black,
      );
    });
  }

  test(
    'older AMOLED settings and backups retain pure black by default',
    () async {
      await SettingsDB().put('themeScheme', 'black');
      expect(SettingsDB().pureBlackBackground, isTrue);
      final migrated = EquranColors.forScheme('black', true);
      expect(migrated.background, Colors.black);
      expect(migrated.primary, EquranColors.dark.primary);
      expect(EquranColors.forScheme('black', false), same(EquranColors.light));

      await SettingsDB().put('pureBlackBackground', false);
      expect(SettingsDB().pureBlackBackground, isFalse);
      expect(
        EquranColors.forScheme('black', true, pureBlackBackground: false),
        same(EquranColors.dark),
      );
    },
  );

  test('pure black preference persists independently of the palette', () async {
    expect(SettingsDB().pureBlackBackground, isFalse);
    await SettingsDB().put('pureBlackBackground', true);
    await SettingsDB().put('themeScheme', 'fancyBlue');
    expect(SettingsDB().pureBlackBackground, isTrue);
    await SettingsDB().put('themeScheme', 'red');
    expect(SettingsDB().pureBlackBackground, isTrue);
  });
}
