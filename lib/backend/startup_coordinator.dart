import 'dart:async';
import 'dart:io' show Platform;

import 'package:equran/backend/library.dart';
import 'package:equran/features/journey_capsules.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/hifz/memory_twin.dart';
import 'package:equran/hifz/memory_map.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_timezone_service.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:equran/widgets/prayer_widget_worker.dart';
import 'package:equran/zakat/zakat_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:quran/quran.dart' as quran;

class StartupIssue {
  const StartupIssue(this.step);

  final String step;
}

/// Owns application initialization in two explicit stages.
///
/// The blocking stage only prepares settings needed to render the first safe
/// frame. Everything else is idempotent, cancellable by lifecycle ownership at
/// the caller, and runs after the first frame without network prerequisites.
class StartupCoordinator extends ChangeNotifier {
  StartupCoordinator._();

  static final StartupCoordinator instance = StartupCoordinator._();

  Future<void>? _blockingFuture;
  Future<void>? _deferredFuture;
  final List<StartupIssue> _issues = <StartupIssue>[];
  bool _blockingReady = false;
  bool _deferredReady = false;

  bool get isBlockingReady => _blockingReady;
  bool get isReady => _deferredReady;
  List<StartupIssue> get issues => List<StartupIssue>.unmodifiable(_issues);

  Future<void> initializeBlocking() {
    return _blockingFuture ??= _initializeBlocking();
  }

  Future<void> startDeferred() {
    return _deferredFuture ??= _initializeDeferred();
  }

  Future<void> _initializeBlocking() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter('equran');

    // IDs are part of the persisted schema. Keep registration explicit and
    // idempotent; never delete a box when an adapter is unavailable.
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReadingEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SurahAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HifzEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HifzReviewLogAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HifzUnitAdapter());
    }
    registerCompanionStorageAdapters();

    // Settings is the only box required by MyApp for locale/theme selection.
    await SettingsDB().initBox();
    _blockingReady = true;
    notifyListeners();
  }

  Future<void> _initializeDeferred() async {
    await _runStep('storage', _initializeStorage);
    await _runStep('quran', _initializeQuran);
    await _runStep('audio', _initializeAudio);
    await _runStep('prayer', _initializePrayer);
    await _runStep('widgets', _initializeWidgets);
    _deferredReady = true;
    notifyListeners();
  }

  Future<void> _initializeStorage() async {
    await ZakatHistoryDB.instance.initialize();
    await BookmarkDB().initBox();
    await SurahDB().initBox();
    await FavouritesDB().initBox();
    await DuaFavouritesDB().initBox();
    await initCompanionStorageBoxes();
    await MemoryTwinDB.instance.initBox();
    await MemoryMapStateDB.instance.initBox();
    await JourneyCapsulesDB.instance.initBox();
    await HifzDB.init();

    final String lastCheck =
        SettingsDB().get('hifzFrontierLastCheck', defaultValue: '') as String;
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastCheck != today) {
      await HifzFrontierService.dailyFrontierCheck();
      await SettingsDB().put('hifzFrontierLastCheck', today);
    }
    await SchemaMigrationService.instance.runSafeMigrations();
  }

  Future<void> _initializeQuran() async {
    await quran.initializeQuran();
    await QuranTranslationService.instance.preloadSelectedTranslation();
  }

  Future<void> _initializeAudio() async {
    if (!kIsWeb && Platform.isLinux) {
      JustAudioMediaKit.ensureInitialized();
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.app.equran.audio',
        androidNotificationChannelName: 'Quran Audio Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/launcher_icon',
      );
    }
  }

  Future<void> _initializePrayer() async {
    await PrayerTimezoneService.configureDeviceTimezone();
    final PrayerSettingsStore prayerSettingsStore = PrayerSettingsStore();
    final PrayerTimeSettings prayerSettings = prayerSettingsStore.getSettings();
    final PrayerNotificationScheduleResult result =
        await PrayerNotificationService().reschedule(
          settings: prayerSettings,
          location: prayerSettingsStore.getLocation(),
        );
    if (result.status == PrayerNotificationScheduleStatus.permissionDenied &&
        prayerSettings.reminderSettings.remindersEnabled) {
      await prayerSettingsStore.saveSettings(
        prayerSettings.copyWith(
          reminderSettings: prayerSettings.reminderSettings.copyWith(
            remindersEnabled: false,
          ),
        ),
      );
    }
  }

  Future<void> _initializeWidgets() async {
    if (!kIsWeb && Platform.isAndroid) {
      await PrayerWidgetService.init();
      await PrayerWidgetWorker.init();
      await PrayerWidgetWorker.scheduleRefresh();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_refreshWidgetAfterFrame());
      });
    }
  }

  Future<void> _refreshWidgetAfterFrame() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await PrayerWidgetService.refreshWidget();
  }

  Future<void> _runStep(String name, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      // A noncritical subsystem must not prevent ordinary reading. Keep the
      // failure categorized and private-data-free while allowing later steps.
      _issues.add(StartupIssue(name));
      debugPrint('Startup step failed: $name');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'equran startup',
          context: ErrorDescription('while initializing $name'),
        ),
      );
    }
  }
}
