import 'package:equran/theme/inter_optical_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _sample = 'Saved for quick access';

double _width(TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: _sample, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

TextStyle _inter(double size, [FontWeight weight = FontWeight.w400]) =>
    TextStyle(fontFamily: 'Inter', fontSize: size, fontWeight: weight);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final FontLoader loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/media/fonts/inter/Inter.ttf'));
    await loader.load();
  });

  test('opsz equals the font size, clamped to the axis range 14 to 32', () {
    expect(interOpticalSize(12).value, 14);
    expect(interOpticalSize(14).value, 14);
    expect(interOpticalSize(20).value, 20);
    expect(interOpticalSize(44).value, 32);
    expect(interOpticalSize(20).axis, 'opsz');
  });

  test('narrows Inter at large sizes and leaves 14 px and below alone', () {
    for (final double size in <double>[10, 12, 14]) {
      expect(
        _width(_inter(size).withInterOpticalSize()),
        closeTo(_width(_inter(size)), 0.001),
        reason: 'size $size',
      );
    }
    final double before = _width(_inter(32));
    final double after = _width(_inter(32).withInterOpticalSize());
    expect(after / before, closeTo(0.911, 0.01));
    expect(
      _width(_inter(20).withInterOpticalSize()),
      lessThan(_width(_inter(20))),
    );
  });

  test('weights stay distinct and unchanged by the helper', () {
    // wght still comes from fontWeight; only opsz is added.
    final List<double> widths = <double>[];
    for (final FontWeight weight in <FontWeight>[
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w900,
    ]) {
      final TextStyle style = _inter(14, weight);
      expect(
        _width(style.withInterOpticalSize()),
        closeTo(_width(style), 0.001),
        reason: 'w${weight.value} at 14 px',
      );
      widths.add(_width(_inter(24, weight).withInterOpticalSize()));
    }
    for (int i = 1; i < widths.length; i++) {
      expect(widths[i], greaterThan(widths[i - 1]));
    }
  });

  test('keeps other variations, replaces a stale opsz, skips other fonts', () {
    final TextStyle themed = _inter(22).copyWith(
      fontVariations: const <FontVariation>[
        FontVariation('opsz', 14),
        FontVariation('wght', 500),
      ],
    );
    final List<FontVariation> result = themed
        .withInterOpticalSize()
        .fontVariations!;
    expect(result.map((FontVariation v) => '${v.axis}=${v.value}'), <String>[
      'wght=500.0',
      'opsz=22.0',
    ]);

    const TextStyle newsreader = TextStyle(
      fontFamily: 'Newsreader',
      fontSize: 36,
      fontVariations: <FontVariation>[FontVariation('opsz', 36)],
    );
    expect(newsreader.withInterOpticalSize(), same(newsreader));
    const TextStyle naskh = TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 24,
    );
    expect(naskh.withInterOpticalSize(), same(naskh));
    expect(
      const TextStyle(
        fontFamily: 'Inter',
      ).withInterOpticalSize().fontVariations,
      isNull,
    );
  });

  test('theme slots get their own opsz, display slots clamp at 32', () {
    final TextTheme theme = ThemeData(
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14),
        titleLarge: TextStyle(fontFamily: 'Inter', fontSize: 18),
        displayLarge: TextStyle(fontFamily: 'Inter', fontSize: 43),
      ),
    ).textTheme.withInterOpticalSizes();
    expect(theme.titleLarge!.fontVariations!.single.value, 18);
    expect(theme.displayLarge!.fontVariations!.single.value, 32);
  });
}
