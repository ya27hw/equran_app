import 'package:equran/utils/text_direction.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TextDirection of(String text, [TextDirection fallback = TextDirection.rtl]) =>
      scriptDirectionOf(text, fallback: fallback);

  test('English text is left-to-right even inside an RTL screen', () {
    expect(of('For indeed, with hardship [will be] ease.'), TextDirection.ltr);
    expect(of('#hope'), TextDirection.ltr);
    expect(of('"Quoted" English'), TextDirection.ltr);
  });

  test('Arabic, Persian and Urdu text is right-to-left', () {
    expect(
      of('فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا', TextDirection.ltr),
      TextDirection.rtl,
    );
    expect(of('#صبر', TextDirection.ltr), TextDirection.rtl);
    expect(of('یادداشت', TextDirection.ltr), TextDirection.rtl);
    expect(of('نوٹ', TextDirection.ltr), TextDirection.rtl);
  });

  test('other scripts are left-to-right', () {
    expect(of('Заметка'), TextDirection.ltr);
    expect(of('Σημείωση'), TextDirection.ltr);
    expect(of('नोट'), TextDirection.ltr);
    expect(of('আজকের নোট'), TextDirection.ltr);
  });

  test('the first letter decides mixed text', () {
    expect(of('Surah الفاتحة', TextDirection.rtl), TextDirection.ltr);
    expect(of('«الفاتحة» surah', TextDirection.ltr), TextDirection.rtl);
  });

  test('text without letters keeps the fallback', () {
    expect(of('123 - 45', TextDirection.rtl), TextDirection.rtl);
    expect(of('', TextDirection.ltr), TextDirection.ltr);
  });
}
