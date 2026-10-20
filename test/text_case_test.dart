import 'package:equran/utils/text_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Turkish upper-casing keeps the dotted and dotless i', () {
    expect(upperCaseFor('tr', 'kıble'), 'KIBLE');
    expect(upperCaseFor('tr', 'istikamet'), 'İSTİKAMET');
    expect(upperCaseFor('tr', 'şimdi'), 'ŞİMDİ');
  });

  test('other languages use the default mapping', () {
    expect(upperCaseFor('en', 'qibla'), 'QIBLA');
    expect(upperCaseFor('de', 'jetzt'), 'JETZT');
  });
}
