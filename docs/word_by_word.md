# Word-by-word meanings

Tapping a word in the ayah card shows its English meaning and transliteration.
The data is an **optional download**, not part of the APK, so it does not grow
the install size. Nothing is shown (and nothing breaks) until a pack is
installed.

## How it fits together

| Piece | File |
|---|---|
| Aligns rendered words to glosses | `lib/word_by_word/word_alignment.dart` |
| Pack format, provenance, validator | `lib/word_by_word/word_by_word_pack.dart` |
| Loads the installed pack per surah | `lib/word_by_word/word_by_word_service.dart` |
| Tappable text + meaning sheet | `lib/word_by_word/word_by_word_text.dart` |
| Download entry (`ResourceType.wordByWord`) | `lib/backend/resource_models.dart`, `lib/home/settings.dart` |
| Pack builder | `scripts/build_word_by_word_pack.py` |

The Downloads section ("Word by word") only appears when the remote resource
manifest lists a `word_by_word` entry, so shipping the app first is safe: older
app versions ignore the unknown type, and new versions show nothing.

## Pack format (schema 1)

A ZIP with files at its root:

* `meta.json` — `schema`, `id` (`word_by_word_en`), `language`, `version`,
  `source`, `license`, `attribution`, `reviewStatus`, optional `wordCount`.
* `1.json` … `114.json` — `{"surah": N, "ayahs": {"1": [["meaning", "translit"], ...]}}`.

The installer rejects a pack that lacks any provenance field, is not marked
`"reviewStatus": "reviewed"`, misses a surah or ayah, or whose `wordCount`
disagrees. This follows `docs/roadmap/RELIGIOUS_CONTENT_POLICY.md`: unreviewed
or unlicensed packs stay disabled, and the meaning sheet shows the source and
license and calls the glosses a reading aid, not a translation or tafsir.

## Alignment

Glosses follow the Quran.com word segmentation; each bundled script spells and
spaces text differently. `alignWordRanges` normalises the rendered string
(drops stop signs/hizb markers, the QPC v4 ayah-number glyph, joins the IndoPak
vocative particle) and **returns null unless the word count matches exactly**, so
an ayah the rules do not explain is shown as plain text instead of risking a
wrong gloss.

Measured on the rendered text of all 6,236 ayahs (`test/word_alignment_test.dart`,
against `test/fixtures/wbw_word_counts.json`, which holds counts only):

| Script | Unaligned ayahs (plain text) |
|---|---|
| QPC Hafs | 7 |
| QPC v4 | 3 |
| IndoPak | 18 |

Equal counts alone could hide a shifted word, so the test also compares every
word of IndoPak against Hafs by letter skeleton wherever both align.

Not covered yet: the continuous page/mushaf view and the ayah-details sheet
still show plain text.

## Publishing a pack (maintainer checklist)

1. Choose a dataset whose license permits redistribution in a free-software app
   and record its exact source and license. Do not ship data of unknown origin.
2. Build: `python3 scripts/build_word_by_word_pack.py --input <data.json>
   --out-dir build/wbw --source ... --license ... --attribution ...
   --review-status reviewed` (use `reviewed` only after a person has checked the
   data and the license).
3. Upload `word_by_word_en.zip` to the assets release the manifest points at
   (`ya27hw/equran-assets`).
4. Add the printed entry (with the real `url`, `sha256`, `sizeBytes`) to the
   remote `resource_manifest.json`.
5. In the app: Settings → Downloads → Refresh, install "Word by word", open any
   ayah and tap a word.
