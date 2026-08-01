import 'package:equran/features/quran_constellations.dart';
import 'package:flutter_test/flutter_test.dart';

QuranJourneyPack validPack({
  String reviewStatus = 'reviewed',
  List<JourneyReference>? references,
  List<String> sourceIds = const <String>['source-a'],
}) {
  return QuranJourneyPack(
    id: 'pack-a',
    title: 'Patience',
    version: '1.0.0',
    references:
        references ??
        const <JourneyReference>[
          JourneyReference(surah: 1, ayah: 1, order: 1),
          JourneyReference(surah: 2, ayah: 153, order: 2),
        ],
    sourceIds: sourceIds,
    license: 'CC BY-SA',
    reviewStatus: reviewStatus,
  );
}

void main() {
  const QuranJourneyPackValidator validator = QuranJourneyPackValidator();

  test('accepts reviewed, sourced, canonically ordered references', () {
    final QuranJourneyPack pack = validPack();
    expect(() => validator.validate(pack), returnsNormally);
    expect(QuranJourneyPack.fromMap(pack.toMap())?.id, pack.id);
  });

  test('keeps unreviewed or unprovenanced packs disabled', () {
    expect(
      () => validator.validate(validPack(reviewStatus: 'draft')),
      throwsA(isA<JourneyPackValidationException>()),
    );
    expect(
      () => validator.validate(validPack(sourceIds: const <String>[])),
      throwsA(isA<JourneyPackValidationException>()),
    );
  });

  test('rejects duplicate and out-of-range references', () {
    expect(
      () => validator.validate(
        validPack(
          references: const <JourneyReference>[
            JourneyReference(surah: 1, ayah: 1, order: 1),
            JourneyReference(surah: 1, ayah: 1, order: 2),
          ],
        ),
      ),
      throwsA(isA<JourneyPackValidationException>()),
    );
    expect(
      () => validator.validate(
        validPack(
          references: const <JourneyReference>[
            JourneyReference(surah: 114, ayah: 7, order: 1),
          ],
        ),
      ),
      throwsA(isA<JourneyPackValidationException>()),
    );
  });
}
