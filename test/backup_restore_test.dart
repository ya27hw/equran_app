import 'dart:io';

import 'package:equran/backend/backup_service.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/features/halaqah_mode.dart';
import 'package:equran/features/journey_capsules.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/hifz/memory_map.dart';
import 'package:equran/hifz/memory_twin.dart';
import 'package:equran/zakat/zakat_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A real round trip through the backup service on in-process Hive boxes (no
/// file picker): export, old-style backups with a retired setting, restore.
void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('equran_backup_test');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReadingEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SurahAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HifzEntryAdapter());
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HifzReviewLogAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(HifzUnitAdapter());
    registerCompanionStorageAdapters();
    await SettingsDB().initBox();
    await ZakatHistoryDB.instance.initialize();
    await BookmarkDB().initBox();
    await FavouritesDB().initBox();
    await DuaFavouritesDB().initBox();
    await initCompanionStorageBoxes();
    await MemoryTwinDB.instance.initBox();
    await MemoryMapStateDB.instance.initBox();
    await JourneyCapsulesDB.instance.initBox();
    await HalaqahAssignmentsDB.instance.initBox();
    await HifzDB.init();
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> seed({bool withRetiredKey = false}) async {
    await SettingsDB().clear();
    await SettingsDB().put('pureBlackBackground', true);
    await SettingsDB().put('fontSize', 40.0);
    await SettingsDB().put('vibration', false);
    await SettingsDB().put('themeScheme', 'black');
    if (withRetiredKey) {
      await SettingsDB().put('holographicCardsEnabled', true);
    }
    await FavouritesDB().clear();
    await FavouritesDB().put('2-001', 'a note');
    await BookmarkDB().clear();
    await BookmarkDB().put(
      2,
      ReadingEntry(surah: 2, verse: 5, timestamp: DateTime.utc(2026, 10, 1)),
    );
    final Box<HifzUnit> units = Hive.box<HifzUnit>('hifzUnits');
    await units.clear();
    await units.put(
      'surah_18',
      HifzUnit()
        ..id = 'surah_18'
        ..unitType = 'surah'
        ..unitNumber = 18
        ..frontierSurah = 18
        ..frontierAyah = 12
        ..startedAt = DateTime.utc(2026, 9, 1)
        ..isComplete = false,
    );
  }

  /// Rebuilds the payload the way an old app version wrote it: the export of
  /// the current boxes plus the retired key, with a valid integrity hash.
  Map<String, dynamic> oldStyleBackup(Object? holographicValue) {
    final Map<String, dynamic> payload =
        BackupService.buildBackupPayloadForTesting();
    final Map<String, dynamic> settings = Map<String, dynamic>.from(
      payload['settings'] as Map,
    )..['holographicCardsEnabled'] = holographicValue;
    payload['settings'] = settings;
    payload['integrity'] = BackupService.integrityHashForTesting(payload);
    return payload;
  }

  test('new exports no longer write holographicCardsEnabled', () async {
    // A stale value left in the box by an older version must not leak back.
    await seed(withRetiredKey: true);
    final Map<String, dynamic> payload =
        BackupService.buildBackupPayloadForTesting();
    final Map<String, dynamic> settings = Map<String, dynamic>.from(
      payload['settings'] as Map,
    );
    expect(settings, isNot(contains('holographicCardsEnabled')));
    expect(settings['pureBlackBackground'], isTrue);
    expect(settings['fontSize'], 40.0);
  });

  for (final Object? value in <Object?>[true, false, 'not a bool', null]) {
    test(
      'an old backup with holographicCardsEnabled=$value restores',
      () async {
        await seed();
        final Map<String, dynamic> old = oldStyleBackup(value);
        expect((old['settings'] as Map), contains('holographicCardsEnabled'));

        // Replace the live data so the restore has something to overwrite.
        await SettingsDB().clear();
        await SettingsDB().put('fontSize', 20.0);
        await FavouritesDB().clear();
        await BookmarkDB().clear();

        final BackupRestoreResult result =
            await BackupService.restoreFromPayloadForTesting(old);

        // Every other key and store came back; the retired key is dropped.
        expect(SettingsDB().get('pureBlackBackground'), isTrue);
        expect(SettingsDB().get('fontSize'), 40.0);
        expect(SettingsDB().get('vibration'), isFalse);
        expect(SettingsDB().get('themeScheme'), 'black');
        expect(SettingsDB().contains('holographicCardsEnabled'), isFalse);
        expect(FavouritesDB().get('2-001'), 'a note');
        expect(BookmarkDB().get(2), isA<ReadingEntry>());
        // The typed Hifz boxes are restored too.
        final HifzUnit? unit = Hive.box<HifzUnit>('hifzUnits').get('surah_18');
        expect(unit?.frontierAyah, 12);
        expect(result.sectionCounts['hifzUnits'], 1);
        expect(result.settingsCount, 4);
        expect(result.favouritesCount, 1);
        expect(result.readingHistoryCount, 1);

        // A fresh export from the restored data has no retired key and the
        // same settings: a full round trip.
        final Map<String, dynamic> again = Map<String, dynamic>.from(
          BackupService.buildBackupPayloadForTesting()['settings'] as Map,
        );
        expect(again, <String, dynamic>{
          'pureBlackBackground': true,
          'fontSize': 40.0,
          'vibration': false,
          'themeScheme': 'black',
        });
      },
    );
  }

  test('other known settings are still validated', () async {
    await seed();
    final Map<String, dynamic> bad = oldStyleBackup(true);
    (bad['settings'] as Map<String, dynamic>)['pureBlackBackground'] = 'yes';
    bad['integrity'] = BackupService.integrityHashForTesting(bad);
    await expectLater(
      BackupService.restoreFromPayloadForTesting(bad),
      throwsA(isA<AppBackupException>()),
    );
    // Validation fails before any write: the live data is untouched.
    expect(SettingsDB().get('pureBlackBackground'), isTrue);
  });
}
