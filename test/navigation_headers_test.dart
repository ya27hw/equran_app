import 'dart:typed_data';

import 'package:equran/backend/navigation_bloc.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home/home.dart';
import 'package:equran/home/more_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'redesign/gallery_test_support.dart' show loadGalleryFonts;

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
    await initializeDateFormatting();
    await loadGalleryFonts();
  });
  tearDownAll(Hive.close);

  testWidgets(
    'secondary pages with their own header have one working back button',
    (tester) async {
      NavigationBloc.instance.value = const NavigationState(
        activeNavbarItems: [NavItem.home, NavItem.more],
        availableMoreItems: [NavItem.settings, NavItem.calendar],
        selectedIndex: 1,
      );
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: savedPreviewTheme(EquranColors.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      for (final open in <VoidCallback Function(MorePage)>[
        (page) => page.onOpenSettings,
        (page) => page.onOpenCalendar,
      ]) {
        open(tester.widget<MorePage>(find.byType(MorePage)))();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(AppBar), findsNothing);
        expect(find.byTooltip('Back'), findsOneWidget);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(MorePage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
