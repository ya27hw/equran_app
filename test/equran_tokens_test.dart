import 'dart:convert';
import 'dart:io';

import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const palettes = <String, EquranColors>{
  'emerald-light': EquranColors.light,
  'emerald-dark': EquranColors.dark,
  'blue-light': EquranColors.fancyBlueLight,
  'blue-dark': EquranColors.fancyBlueDark,
  'purple-light': EquranColors.fancyPurpleLight,
  'purple-dark': EquranColors.fancyPurpleDark,
  'sepia-light': EquranColors.sepiaLight,
  'sepia-dark': EquranColors.sepiaDark,
  'red-light': EquranColors.redLight,
  'red-dark': EquranColors.redDark,
  'black-dark': EquranColors.blackDark,
};

Map<String, Color> derivedColors(EquranColors colors, EquranTokens tokens) => {
  'bg': colors.background,
  'surface': colors.surface,
  'surface2': colors.surfaceAlt,
  'text': colors.textPrimary,
  'text2': tokens.text2,
  'muted': tokens.muted,
  'hair': tokens.hair,
  'hair2': tokens.hair2,
  'em': tokens.filled,
  'emText': tokens.emText,
  'emWash': tokens.emWash,
  'gold': tokens.gold,
  'goldText': tokens.goldText,
  'goldWash': tokens.goldWash,
  'danger': tokens.danger,
  'featA': tokens.featA,
  'featB': tokens.featB,
  'featText2': tokens.featText2,
  'glow': tokens.glow,
  'dock': tokens.dock,
  'scrim': tokens.scrim,
  'shadow': tokens.shadow,
};

// JSON contains CSS colours and a box-shadow string. For shadow, compare its
// rgba colour; offset/blur are deliberately outside this colour extension.
Color cssColor(String value) {
  if (value.startsWith('#')) {
    return Color(0xff000000 | int.parse(value.substring(1), radix: 16));
  }
  final match = RegExp(
    r'rgba\((\d+),(\d+),(\d+),([.\d]+)\)',
  ).firstMatch(value)!;
  return Color.from(
    red: int.parse(match[1]!) / 255,
    green: int.parse(match[2]!) / 255,
    blue: int.parse(match[3]!) / 255,
    alpha: double.parse(match[4]!),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture =
      jsonDecode(File('docs/redesign/tokens.json').readAsStringSync())
          as Map<String, dynamic>;

  test('fixture and Dart palette sets match all 11 palettes', () {
    expect(palettes.keys, unorderedEquals(fixture.keys));
    expect(palettes, hasLength(11));
  });

  for (final entry in palettes.entries) {
    final colors = entry.value;
    final tokens = EquranTokens.fromColors(colors);
    test('${entry.key}: every derived colour matches tokens.json', () {
      final expected =
          (fixture[entry.key] as Map<String, dynamic>)['derived']
              as Map<String, dynamic>;
      final actual = derivedColors(colors, tokens);
      expect(actual.keys, unorderedEquals(expected.keys));
      for (final field in expected.entries) {
        final color = actual[field.key]!;
        final reference = cssColor(field.value as String);
        final channels = [color.r, color.g, color.b, color.a];
        final referenceChannels = [
          reference.r,
          reference.g,
          reference.b,
          reference.a,
        ];
        for (int i = 0; i < channels.length; i++) {
          expect(
            channels[i],
            closeTo(referenceChannels[i], 1 / 255),
            reason: '${entry.key}.${field.key}, RGBA channel $i',
          );
        }
      }
    });

    test('${entry.key}: all 13 report() contrast pairs pass', () {
      final washSurface = EquranTokens.mix(
        colors.surface,
        colors.accentGold,
        tokens.goldWash.a,
      );
      // Keep the report's actual foreground/background pairs and thresholds.
      final pairs = <(String, Color, Color, double)>[
        ('text on surface', colors.textPrimary, colors.surface, 4.5),
        ('text2 on surface', tokens.text2, colors.surface, 4.5),
        ('muted on surface', tokens.muted, colors.surface, 4.5),
        ('muted on surfaceAlt', tokens.muted, colors.surfaceAlt, 4.5),
        ('white on filled primary', Colors.white, tokens.filled, 4.5),
        ('emText on surface', tokens.emText, colors.surface, 4.5),
        ('goldText on surface', tokens.goldText, colors.surface, 4.5),
        ('goldText on goldWash', tokens.goldText, washSurface, 4.5),
        ('danger on surface', tokens.danger, colors.surface, 4.5),
        ('hero text on featA', const Color(0xFFF3F7F4), tokens.featA, 4.5),
        ('hero caption on featA', tokens.featText2, tokens.featA, 4.5),
        ('hero gold on featB', const Color(0xFFE2BC6B), tokens.featB, 4.5),
        ('gold graphics on surface', tokens.gold, colors.surface, 3.0),
      ];
      expect(pairs, hasLength(13));
      for (final (name, foreground, background, target) in pairs) {
        expect(
          EquranTokens.contrast(foreground, background),
          greaterThanOrEqualTo(target),
          reason: '${entry.key}: $name',
        );
      }
    });
  }

  test('ensure chooses the first passing step across every background', () {
    const start = Color(0xFF999999);
    const backgrounds = [Colors.white, Color(0xFFEEEEEE)];
    final result = EquranTokens.ensure(
      start,
      against: backgrounds,
      target: 4.5,
      toward: Colors.black,
    );
    final candidates = List.generate(
      41,
      (i) => EquranTokens.mix(start, Colors.black, i / 40),
    );
    final index = candidates.indexOf(result);
    expect(index, greaterThan(0));
    for (final background in backgrounds) {
      expect(
        EquranTokens.contrast(result, background),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(
      backgrounds.any(
        (bg) => EquranTokens.contrast(candidates[index - 1], bg) < 4.5,
      ),
      isTrue,
    );
    expect(
      EquranTokens.ensure(
        start,
        against: backgrounds,
        target: 30,
        toward: Colors.black,
      ),
      Colors.black,
    );
  });

  test(
    'extension copies and interpolates every colour during theme changes',
    () {
      final light = EquranTokens.fromColors(EquranColors.light);
      final dark = EquranTokens.fromColors(EquranColors.dark);
      final lightFields = derivedColors(EquranColors.light, light);
      expect(derivedColors(EquranColors.light, light.copyWith()), lightFields);
      expect(light.copyWith(gold: dark.gold).gold, dark.gold);
      expect(light.lerp(null, 0.5), same(light));
      final halfway = derivedColors(EquranColors.light, light.lerp(dark, 0.5));
      final darkFields = derivedColors(EquranColors.light, dark);
      for (final field in lightFields.keys) {
        expect(
          halfway[field],
          Color.lerp(lightFields[field], darkFields[field], 0.5),
        );
      }
    },
  );

  test(
    'bundled Newsreader fonts load from assets without network access',
    () async {
      final loader = FontLoader('NewsreaderPhase0Test');
      for (final filename in ['Newsreader.ttf', 'Newsreader-Italic.ttf']) {
        final asset = rootBundle.load(
          'assets/media/fonts/newsreader/$filename',
        );
        final bytes = await asset;
        expect(
          bytes.getUint32(0),
          0x00010000,
          reason: 'TrueType signature for $filename',
        );
        loader.addFont(asset);
      }
      await loader.load();
    },
  );
}
