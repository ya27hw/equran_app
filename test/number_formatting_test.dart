import 'package:equran/utils/number_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const locales = ['ar', 'bn', 'de', 'en', 'fa', 'id', 'tr', 'ur'];
  final asciiOnly = RegExp(r'^[0-9.,KM]+$');

  test('counts always use Western digits, in every shipped locale', () {
    for (final locale in locales) {
      for (final value in [0, 7, 1840, 5400, 196400, 1250000]) {
        expect(
          formatGroupedCount(value, locale),
          matches(asciiOnly),
          reason: locale,
        );
        expect(
          formatCompactCount(value, locale),
          matches(asciiOnly),
          reason: locale,
        );
      }
    }
  });

  test('grouping and compact forms agree on the decimal mark', () {
    expect(formatGroupedCount(1840, 'en'), '1,840');
    expect(formatCompactCount(196400, 'en'), '196.4K');
    expect(formatGroupedCount(1840, 'de'), '1.840');
    expect(formatCompactCount(196400, 'de'), '196,4K');
    expect(formatCompactCount(1250000, 'tr'), '1,3M');
    expect(formatGroupedCount(5400, 'ar'), '5,400');
    expect(formatCompactCount(196400, 'ar'), '196.4K');
  });

  test('values below 10,000 are never abbreviated', () {
    expect(formatCompactCount(9999, 'en'), '9,999');
    expect(formatCompactCount(10000, 'en'), '10.0K');
  });
}
