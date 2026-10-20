import 'dart:convert';
import 'dart:io';

import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/word_by_word/word_by_word_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart' as quran;

/// Exercises the real seam between the install store and the service: the
/// metadata key, the 'installed' status check and the change notification.
void main() {
  late Directory temp;
  late Directory pack;

  setUpAll(() async {
    temp = Directory.systemTemp.createTempSync('wbw_install_');
    Hive.init(temp.path);
    await SettingsDB().initBox();
    pack = Directory('${temp.path}/pack')..createSync();
    File('${pack.path}/meta.json').writeAsStringSync(
      jsonEncode(<String, Object?>{
        'schema': 1,
        'id': 'word_by_word_en',
        'language': 'en',
        'version': '1.0.0',
        'source': 'Test Source',
        'license': 'Test-License',
        'attribution': 'x',
        'reviewStatus': 'reviewed',
      }),
    );
    for (int surah = 1; surah <= 114; surah++) {
      File('${pack.path}/$surah.json').writeAsStringSync(
        jsonEncode(<String, Object?>{
          'surah': surah,
          'ayahs': <String, Object?>{
            for (int a = 1; a <= quran.getVerseCount(surah); a++)
              '$a': <Object?>[
                <String>['w', 't'],
              ],
          },
        }),
      );
    }
  });

  tearDownAll(() async {
    await Hive.close();
    temp.deleteSync(recursive: true);
  });

  const DownloadableResource resource = DownloadableResource(
    id: WordByWordService.resourceId,
    rawType: 'word_by_word',
    name: 'Word by word (English)',
    version: '1.0.0',
    url: 'https://example.invalid/word_by_word_en.zip',
  );

  test('install makes the singleton available; uninstall removes it', () async {
    final WordByWordService service = WordByWordService.instance;
    await service.ensureMeta();
    expect(service.isAvailable, isFalse, reason: 'nothing installed yet');

    await ResourceInstallStore.instance.markInstalled(
      resource: resource,
      directory: pack,
      sha256: null,
      sizeBytes: 1,
    );
    await service.ensureMeta();
    expect(service.isAvailable, isTrue);
    await service.prepare(112);
    expect(service.glossesFor(112, 1), isNotNull);

    await ResourceInstallStore.instance.uninstall(resource);
    await service.ensureMeta();
    expect(service.isAvailable, isFalse);
    expect(service.isPrepared(112), isFalse);
  });

  test(
    'a record whose directory is gone is treated as not installed',
    () async {
      final WordByWordService service = WordByWordService.instance;
      final Directory gone = Directory('${temp.path}/gone');
      await ResourceInstallStore.instance.markInstalled(
        resource: resource,
        directory: gone,
        sha256: null,
        sizeBytes: 1,
      );
      await service.ensureMeta();
      expect(service.isAvailable, isFalse);
    },
  );
}
