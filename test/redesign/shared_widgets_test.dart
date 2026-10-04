import 'package:equran/debug/redesign_gallery.dart';
import 'package:equran/services/device_capability_profile.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'gallery_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadGalleryFonts);

  testWidgets(
    'chip and 44 px icon invoke callbacks, expose state and disable',
    (tester) async {
      int taps = 0;
      await pumpGalleryFixture(
        tester,
        builder: (_) => Column(
          children: [
            ChipButton(
              'Selected filter',
              selected: true,
              onPressed: () => taps++,
            ),
            const ChipButton('Disabled filter', onPressed: null),
            IconButton44(
              icon: Icons.search,
              tooltip: 'Search ayahs',
              onPressed: () => taps++,
            ),
            const IconButton44(
              icon: Icons.edit,
              tooltip: 'Disabled edit',
              onPressed: null,
            ),
          ],
        ),
      );
      await tester.tap(find.text('Selected filter'));
      await tester.tap(find.byTooltip('Search ayahs'));
      await tester.tap(find.text('Disabled filter'));
      await tester.tap(find.byTooltip('Disabled edit'));
      expect(taps, 2);
      expect(
        tester.getSize(find.byType(IconButton44).first),
        const Size.square(44),
      );
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text('Selected filter')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: 'Selected filter',
          textDirection: TextDirection.ltr,
        ),
      );
      handle.dispose();
    },
  );

  testWidgets('dock callbacks preserve visual index and localized semantics', (
    tester,
  ) async {
    final selected = <int>[];
    await pumpGalleryFixture(
      tester,
      samplePadding: false,
      direction: TextDirection.rtl,
      builder: (_) => FloatingDock(
        items: galleryDockItems,
        selectedIndex: 1,
        onSelected: selected.add,
      ),
    );
    await tester.tap(find.text('Home'));
    await tester.tap(find.text('Duas'));
    expect(selected, [0, 3]);
    expect(tester.getSize(find.byType(FloatingDock)), const Size(390, 72));
    expect(
      tester.getTopLeft(find.text('Home')).dx,
      greaterThan(tester.getTopLeft(find.text('More')).dx),
    );
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('Quran')).getSemanticsData().label,
      'Quran',
    );
    semantics.dispose();
  });

  for (final count in [4, 5, 6]) {
    for (final direction in TextDirection.values) {
      testWidgets('dock fits $count items at 1.3 in ${direction.name}', (
        tester,
      ) async {
        final items = [
          ...galleryDockItems.take(count == 6 ? 4 : count - 1),
          if (count == 6)
            const FloatingDockItem(icon: 'calendar', label: 'Reading routine'),
          const FloatingDockItem(icon: 'grid', label: 'More'),
        ];
        final taps = <int>[];
        await pumpGalleryFixture(
          tester,
          textScale: 1.3,
          direction: direction,
          samplePadding: false,
          builder: (_) => FloatingDock(
            items: items,
            selectedIndex: count - 1,
            onSelected: taps.add,
          ),
        );
        expect(find.byType(DesignIcon), findsNWidgets(count));
        expect(find.byType(Icon), findsNothing);
        final targets = find.byType(InkWell);
        for (var index = 0; index < count; index++) {
          final target = tester.getRect(targets.at(index));
          final text = tester.renderObject<RenderBox>(
            find.descendant(of: targets.at(index), matching: find.byType(Text)),
          );
          final bounds = Rect.fromPoints(
            text.localToGlobal(Offset.zero),
            text.localToGlobal(text.size.bottomRight(Offset.zero)),
          );
          expect(bounds.left, greaterThanOrEqualTo(target.left));
          expect(bounds.right, lessThanOrEqualTo(target.right));
          expect(bounds.top, greaterThanOrEqualTo(target.top));
          expect(bounds.bottom, lessThanOrEqualTo(target.bottom));
          await tester.tap(targets.at(index));
        }
        // Includes reselecting the currently selected item.
        expect(taps, List.generate(count, (index) => index));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'dock has solid fallback for lite mode, reduce motion and explicit opt-out',
    (tester) async {
      final service = DeviceCapabilityService.instance;
      final previous = service.value;
      addTearDown(() => service.value = previous);
      service.value = const DeviceCapabilityProfile(
        lowRam: false,
        processorCount: 6,
      );
      await pumpGalleryFixture(
        tester,
        builder: (_) => FloatingDock(
          items: galleryDockItems,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      service.value = const DeviceCapabilityProfile(
        lowRam: true,
        processorCount: 2,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsNothing);
      service.value = previous;
      await pumpGalleryFixture(
        tester,
        reduceMotion: true,
        builder: (_) => FloatingDock(
          items: galleryDockItems,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      await pumpGalleryFixture(
        tester,
        builder: (_) => FloatingDock(
          items: galleryDockItems,
          selectedIndex: 0,
          enableBlur: false,
          onSelected: (_) {},
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    },
  );

  testWidgets(
    'both progress rings clamp, honour reduce motion and do not replay',
    (tester) async {
      Widget ring(
        BuildContext context, {
        double outer = 2,
        double inner = -1,
      }) => ProgressRing(
        value: outer,
        innerValue: inner,
        color: context.equranTokens.gold,
        innerColor: context.equranTokens.emText,
        trackColor: context.equranTokens.hair2,
        child: const Text('Progress'),
      );
      await pumpGalleryFixture(
        tester,
        reduceMotion: true,
        builder: (context) => ring(context),
      );
      expect(
        find.descendant(
          of: find.byType(ProgressRing),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(2),
      );
      final animation = tester.widget<TweenAnimationBuilder<Offset>>(
        find.byType(TweenAnimationBuilder<Offset>),
      );
      expect(animation.duration, Duration.zero);
      expect(animation.tween.end, const Offset(1, 0));
      final ancestorTick = ValueNotifier<int>(0);
      addTearDown(ancestorTick.dispose);
      await pumpGalleryFixture(
        tester,
        builder: (context) => ValueListenableBuilder<int>(
          valueListenable: ancestorTick,
          builder: (context, tick, child) =>
              ring(context, outer: 0.7, inner: 0.4),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      ancestorTick.value++;
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'numerals use explicit unit line height and real Newsreader axes',
    (tester) async {
      await pumpGalleryFixture(
        tester,
        viewportHeight: 1600,
        builder: (_) => const Column(
          children: [DisplayNumeral('15:24', size: 40), NewsreaderSpecimen()],
        ),
      );
      final numeral = tester.widget<Text>(find.text('15:24'));
      expect(numeral.style!.height, 1);
      expect(
        numeral.style!.fontFeatures!.map((feature) => feature.feature),
        containsAll(['lnum', 'tnum']),
      );
      final specimens = tester
          .widgetList<Text>(find.text('Mercy 012'))
          .toList();
      expect(specimens, hasLength(16));
      expect(specimens.map((text) => text.style!.fontSize).toSet(), {
        16,
        24,
        36,
        40,
      });
      for (final text in specimens) {
        final style = text.style!;
        expect(
          style.fontVariations!.firstWhere((axis) => axis.axis == 'opsz').value,
          style.fontSize,
        );
        expect(
          style.fontVariations!.firstWhere((axis) => axis.axis == 'wght').value,
          style.fontWeight!.value.toDouble(),
        );
      }
      expect(
        specimens.where((text) => text.style!.fontStyle == FontStyle.italic),
        hasLength(4),
      );
    },
  );

  testWidgets('prayer arches are drawn per prayer and expose names', (
    tester,
  ) async {
    await pumpGalleryFixture(
      tester,
      builder: (context) => gallerySample(context, 'prayer-arch'),
    );
    expect(find.byType(PrayerArch), findsNWidgets(6));
    expect(find.byType(Image), findsNothing);
    final sizes = {
      for (final arch in tester.widgetList<PrayerArch>(find.byType(PrayerArch)))
        arch.kind: tester.getSize(find.byWidget(arch)),
    };
    // Design sizes: 34 x 42, Sunrise 30 x 37.
    expect(sizes[PrayerTimeKind.fajr], const Size(34, 42));
    expect(sizes[PrayerTimeKind.sunrise], const Size(30, 37));
    expect(tester.takeException(), isNull);
  });

  testWidgets('debug gallery controls switch palette, scale and direction', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const RedesignGalleryApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('red-light'));
    await tester.pumpAndSettle();
    var context = tester.element(find.byType(RedesignWidgetGallery));
    expect(
      context.equranTokens.featA,
      EquranTokens.fromColors(GalleryPalette.redLight.colors).featA,
    );
    await tester.tap(find.text('Text 1.3'));
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(context).scale(10), 13);
    await tester.tap(find.text('RTL'));
    await tester.pumpAndSettle();
    context = tester.element(find.byType(RedesignWidgetGallery));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
