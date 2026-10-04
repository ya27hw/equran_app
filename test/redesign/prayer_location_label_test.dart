import 'package:equran/prayer/prayer_models.dart';
import 'package:flutter_test/flutter_test.dart';

PrayerLocation _at(String label) => PrayerLocation(
  latitude: 24.7,
  longitude: 46.7,
  label: label,
  mode: PrayerLocationMode.manual,
);

void main() {
  test('cityLabel keeps only the city of a "city, country" label', () {
    expect(_at('Muscat, Oman').cityLabel, 'Muscat');
    expect(_at('Riyadh, Riyadh Province, Saudi Arabia').cityLabel, 'Riyadh');
    expect(_at('الرياض، السعودية').cityLabel, 'الرياض');
    expect(_at('Makkah').cityLabel, 'Makkah');
    expect(_at('  Jeddah ,  Saudi Arabia ').cityLabel, 'Jeddah');
  });
  test('placeholder and coordinate labels still fall back unchanged', () {
    expect(_at('').cityLabel, 'Saved location');
    expect(_at('Current location').cityLabel, 'Saved location');
    expect(_at(', Oman').cityLabel, ', Oman');
  });
}
