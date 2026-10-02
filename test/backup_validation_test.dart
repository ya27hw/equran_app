import 'package:equran/backend/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup validation preserves safe unknown optional settings', () {
    final Map<String, dynamic> validated =
        BackupService.validateSettingsForTesting(<String, dynamic>{
          'futureFeatureSetting': <String, dynamic>{'enabled': true},
        });

    expect(validated['futureFeatureSetting'], <String, dynamic>{
      'enabled': true,
    });
  });

  test('backup validation rejects unsafe known setting values', () {
    expect(
      () => BackupService.validateSettingsForTesting(<String, dynamic>{
        'fontSize': 100.0,
      }),
      throwsA(isA<AppBackupException>()),
    );
  });

  test('backup favourite keys are bounded to Quran surahs', () {
    expect(
      () => BackupService.validateFavouritesForTesting(<String, dynamic>{
        '115-001': 'invalid',
      }),
      throwsA(isA<AppBackupException>()),
    );
    expect(
      () => BackupService.validateFavouritesForTesting(<String, dynamic>{
        '2-001': 'note',
      }),
      returnsNormally,
    );
  });

  test('backup integrity hash is independent of map insertion order', () {
    final String first = BackupService.integrityHashForTesting(
      <String, dynamic>{'b': 2, 'a': 1},
    );
    final String second = BackupService.integrityHashForTesting(
      <String, dynamic>{'a': 1, 'b': 2},
    );
    expect(first, second);
  });

  test('backup sections are validated before any restore write', () {
    expect(
      () => BackupService.validateSectionsForTesting(<String, Object?>{
        'journeyCapsules': <Object?>[
          <String, Object?>{
            'key': 'capsule-1',
            'value': <String, Object?>{
              'id': 'capsule-1',
              'reflection': 'private note',
            },
          },
        ],
      }),
      returnsNormally,
    );
    expect(
      () => BackupService.validateSectionsForTesting(<String, Object?>{
        'broken': <Object?>[
          <String, Object?>{'key': 'missing-value'},
        ],
      }),
      throwsA(isA<AppBackupException>()),
    );
  });
}
