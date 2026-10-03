#!/usr/bin/env python3
"""Build the downloadable word-by-word pack consumed by the eQuran app.

Input is a JSON file in the "page list" shape used by word-by-word datasets
derived from the Quran.com API: a list of pages, each with ``ayahs``, each with
``words`` carrying ``char_type_name``, ``position``, ``parentAyahVerseKey``,
``translation.text`` and ``transliteration.text``.

The script does not fetch anything and bundles no data. Provenance is supplied
on the command line and written to ``meta.json`` because the app refuses packs
without it (docs/roadmap/RELIGIOUS_CONTENT_POLICY.md).

Example:
    python3 scripts/build_word_by_word_pack.py \
        --input data.json --out-dir build/word_by_word \
        --source "<dataset name and URL>" --license "<SPDX or license text>" \
        --attribution "<credit line>" --version 1.0.0

Pass ``--review-status reviewed`` only after a person has verified the data and
its license; the default ``unreviewed`` produces a pack the app will reject.
See docs/word_by_word.md for the full publishing checklist.
"""

import argparse
import collections
import hashlib
import json
import os
import sys
import zipfile

SURAH_COUNT = 114
SCHEMA = 1


def load_words(path):
    with open(path, encoding="utf-8") as handle:
        pages = json.load(handle)
    words = collections.defaultdict(dict)
    for page in pages:
        for ayah in page.get("ayahs") or []:
            for word in ayah.get("words") or []:
                if not word or word.get("char_type_name") != "word":
                    continue
                key = word["parentAyahVerseKey"]
                position = int(word["position"])
                meaning = (word.get("translation") or {}).get("text") or ""
                translit = (word.get("transliteration") or {}).get("text") or ""
                if not meaning.strip():
                    raise SystemExit(f"{key} word {position} has no translation")
                if position in words[key]:
                    raise SystemExit(f"{key} word {position} appears twice")
                words[key][position] = [meaning.strip(), translit.strip()]
    return words


def build_surahs(words):
    surahs = {}
    total = 0
    for key in sorted(words, key=lambda k: tuple(map(int, k.split(":")))):
        surah, ayah = map(int, key.split(":"))
        positions = sorted(words[key])
        if positions != list(range(1, len(positions) + 1)):
            raise SystemExit(f"{key} has non-contiguous word positions")
        surahs.setdefault(surah, {})[str(ayah)] = [words[key][p] for p in positions]
        total += len(positions)
    if sorted(surahs) != list(range(1, SURAH_COUNT + 1)):
        raise SystemExit("input does not cover all 114 surahs")
    return surahs, total


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--input", required=True, help="dataset JSON file")
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--source", required=True)
    parser.add_argument("--license", required=True)
    parser.add_argument("--attribution", required=True)
    parser.add_argument("--version", default="1.0.0")
    parser.add_argument("--language", default="en")
    parser.add_argument(
        "--review-status",
        default="unreviewed",
        choices=["unreviewed", "reviewed"],
    )
    args = parser.parse_args()

    resource_id = f"word_by_word_{args.language}"
    surahs, total_words = build_surahs(load_words(args.input))

    pack_dir = os.path.join(args.out_dir, resource_id)
    os.makedirs(pack_dir, exist_ok=True)
    meta = {
        "schema": SCHEMA,
        "id": resource_id,
        "language": args.language,
        "version": args.version,
        "source": args.source,
        "license": args.license,
        "attribution": args.attribution,
        "reviewStatus": args.review_status,
        "wordCount": total_words,
    }
    files = {"meta.json": meta}
    for surah, ayahs in surahs.items():
        files[f"{surah}.json"] = {"surah": surah, "ayahs": ayahs}
    for name, content in files.items():
        with open(os.path.join(pack_dir, name), "w", encoding="utf-8") as handle:
            json.dump(content, handle, ensure_ascii=False, separators=(",", ":"))

    zip_path = os.path.join(args.out_dir, f"{resource_id}.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in files:  # files at the archive root
            archive.write(os.path.join(pack_dir, name), name)

    with open(zip_path, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    size = os.path.getsize(zip_path)
    print(f"Built {zip_path}: {size} bytes, {total_words} words, sha256 {digest}")
    print("Manifest entry (set \"url\" to where you upload the zip):")
    print(
        json.dumps(
            {
                "id": resource_id,
                "type": "word_by_word",
                "name": "Word by word (English)",
                "language": args.language,
                "version": args.version,
                "url": f"<UPLOAD URL>/{resource_id}.zip",
                "sha256": digest,
                "sizeBytes": size,
            },
            indent=2,
        )
    )
    if args.review_status != "reviewed":
        print(
            "NOTE: reviewStatus is 'unreviewed'; the app will refuse to install "
            "this pack until it is rebuilt with --review-status reviewed.",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
