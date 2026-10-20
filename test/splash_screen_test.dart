import 'dart:typed_data';

import 'package:equran/backend/settings_db.dart';
import 'package:equran/features/splash/splash_screen.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
  });
  setUp(() => SettingsDB().clear());
  tearDownAll(Hive.close);

  Widget app({
    bool? enabled,
    Future<void> Function()? ready,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: <ThemeExtension<dynamic>>[
          EquranColors.dark,
          EquranTokens.fromColors(EquranColors.dark),
        ],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: SplashScreen(
        enabled: enabled,
        ready: ready ?? () async {},
        nextBuilder: (_) => const Text('home'),
      ),
    );
  }

  test('the setting defaults to on and can be turned off', () async {
    expect(SettingsDB().showSplashScreen, isTrue);
    await SettingsDB().put('showSplash', false);
    expect(SettingsDB().showSplashScreen, isFalse);
    await SettingsDB().put('showSplash', true);
    expect(SettingsDB().showSplashScreen, isTrue);
  });

  testWidgets('disabled: no animation, leaves once startup is done', (
    tester,
  ) async {
    await tester.pumpWidget(app(enabled: false));
    await tester.pump();
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
    expect(find.text('eQuran'), findsNothing);
  });

  testWidgets('disabled: waits for startup work before leaving', (
    tester,
  ) async {
    final Future<void> gate = Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpWidget(app(enabled: false, ready: () => gate));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('home'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('enabled: plays the intro and is gone within 1.7 s', (
    tester,
  ) async {
    await tester.pumpWidget(app(enabled: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('home'), findsNothing);
    expect(find.text('eQuran'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(SplashScreen.exitDuration);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.text('eQuran'), findsNothing);
  });

  testWidgets('enabled: never leaves before startup work is done', (
    tester,
  ) async {
    final Future<void> gate = Future<void>.delayed(const Duration(seconds: 4));
    await tester.pumpWidget(app(enabled: true, ready: () => gate));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('home'), findsNothing);
    expect(find.text('eQuran'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('enabled: a failing startup step does not trap the user', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(enabled: true, ready: () async => throw StateError('boom')),
    );
    await tester.pump(SplashScreen.introDuration);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('enabled: tapping skips the rest of the intro', (tester) async {
    await tester.pumpWidget(app(enabled: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('eQuran'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(SplashScreen.exitDuration);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('reduced motion: shows the finished mark, leaves at once', (
    tester,
  ) async {
    await tester.pumpWidget(app(enabled: true, reduceMotion: true));
    await tester.pump();
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('reads the saved setting when not overridden', (tester) async {
    await SettingsDB().put('showSplash', false);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
  });
}
