import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/design_icon_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every design icon parses and draws', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF101614),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final name in designIconMarkup.keys)
                DesignIcon(
                  name,
                  size: 40,
                  strokeWidth: 1.6,
                  color: const Color(0xFFE8F1EC),
                ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(DesignIcon), findsNWidgets(designIconMarkup.length));
    await expectLater(
      find.byType(ColoredBox).first,
      matchesGoldenFile('goldens/design-icons.png'),
    );
  });
}
