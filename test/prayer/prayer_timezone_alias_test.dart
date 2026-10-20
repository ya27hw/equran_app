import 'package:equran/prayer/prayer_timezone_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Asia/Muscat resolves through its Dubai alias', () {
    final location = PrayerTimezoneService.locationForId('Asia/Muscat');
    expect(location, isNotNull);
    expect(location!.name, 'Asia/Dubai');
  });

  test('unknown timezone ids still return null', () {
    expect(PrayerTimezoneService.locationForId('Not/AZone'), isNull);
  });
}
