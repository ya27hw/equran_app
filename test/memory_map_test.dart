import 'package:equran/hifz/memory_map.dart';
import 'package:equran/hifz/models/hifz_entry.dart';
import 'package:flutter_test/flutter_test.dart';

HifzEntry entry({
  required int surah,
  required int ayah,
  String status = 'learning',
}) {
  return HifzEntry()
    ..surah = surah
    ..ayah = ayah
    ..status = status
    ..dueDate = DateTime.utc(2026, 1, 1)
    ..track = 'sabaq';
}

void main() {
  test('uses verified page boundaries for page one and page two', () {
    final MemoryMapRepository repository = MemoryMapRepository();

    final MemoryPageSummary pageOne = repository.pageSummary(1, const []);
    expect(pageOne.ayahs, hasLength(7));
    expect(pageOne.ayahs.first.surah, 1);
    expect(pageOne.ayahs.last.ayah, 7);
    expect(pageOne.state, MemoryPageState.unstarted);

    final MemoryPageSummary pageTwo = repository.pageSummary(2, <HifzEntry>[
      entry(surah: 2, ayah: 1, status: 'mastered'),
    ]);
    expect(pageTwo.ayahs, hasLength(5));
    expect(pageTwo.ayahs.first.surah, 2);
    expect(pageTwo.ayahs.first.ayah, 1);
    expect(pageTwo.ayahs.last.ayah, 5);
    expect(pageTwo.memorizedProportion, greaterThan(0));
  });

  test('rejects pages outside the canonical 604-page range', () {
    final MemoryMapRepository repository = MemoryMapRepository();

    expect(() => repository.pageSummary(0, const []), throwsRangeError);
    expect(() => repository.pageSummary(605, const []), throwsRangeError);
  });
}
