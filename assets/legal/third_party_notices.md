# Content Sources & Third-Party Notices

Last updated: 3 October 2026

eQuran's source code is released under the MIT License. The content below is **not** covered by that licence. It belongs to the authors, publishers and rights holders named here, and is used or distributed subject to their terms. All trademarks and copyrights remain the property of their owners. Inclusion does not imply endorsement by, or affiliation with, any of them.

If you are a rights holder and believe a credit is missing or incorrect, please write to equran@elbaesy.com.

## Quran text

- **Uthmani / Hafs (KFGQPC)** — Arabic text data in the "Hafs" style, derived from the King Fahd Glorious Quran Printing Complex (KFGQPC), Madinah, Saudi Arabia, as distributed through the Quranic Universal Library / Quran.com data sets.
- **QPC V4 Tajweed (page-based) text** — derived from the KFGQPC / Quran.com "QPC V4" data set. The matching page fonts are an optional download.
- **IndoPak text** — Naskh Nastaleeq (IndoPak) script text in the form used by QuranWBW (quranwbw.com).
- **Surah, Juz, page and sajdah metadata** — the bundled `quran` package (a trimmed copy of the Dart package by Aqeel, MIT License), which derives from publicly distributed Quran metadata (including Tanzil Project data, tanzil.net).

The Arabic text of the Quran is preserved as published. If you redistribute it, keep it unaltered and keep the credit to its publishers.

## Fonts

- **KFGQPC HAFS Uthmanic Script** (UthmanicHafs_V22) — © 2010 King Fahd Glorious Quran Printing Complex (KFGQPC), Madinah, Saudi Arabia. All rights reserved. Distributed under the KFGQPC Electronic End-User License Agreement: free to use, copy and distribute; **it may not be sold, modified, altered, translated, reverse engineered, decompiled or disassembled.** The full licence text is embedded in the font file. http://fonts.qurancomplex.gov.sa/
- **AlQuran IndoPak by QuranWBW** (QuranIndoPak) — made by Ayman Siddiqui for QuranWBW.com, based on the Al Qalam Quran Majeed fonts (© Al Qalam, © Ghandhara), with ayah-number glyphs from KFGQPC. Credits embedded in the font: Abdul Majeed Khan, Arif Karim, Shakir-ul-Qadree, Jawad. The font's own notice states it was made for Sadaqa-e-Jaria (ongoing charity) and requires written notice to QuranWBW.com for modification, distribution or development. quranwbw.com
- **QPC V4 Tajweed page fonts** — KFGQPC / Quran.com colour-font set. Optional download.
- **Noto Naskh Arabic, Inter, Outfit, Amiri** — SIL Open Font License 1.1, loaded through the `google_fonts` package. Copyright remains with their respective authors (Google, The Inter Project Authors, The Outfit Project Authors, Khaled Hosny).

## Translations, transliteration and tafsir

- **English translation (bundled): "Saheeh International"** — The Qur'an translation by Saheeh International (Umm Muhammad, Amatullah Bantley and Mary Kennedy). Copyright held by its publishers, Dar Abul-Qasim and/or their successors; reproduced here as made available through the Tanzil Project (tanzil.net).
- **English transliteration (bundled)** — from the Tanzil Project (tanzil.net).
- **Optional downloadable translations** — offered as separate downloads, each credited under its own name in the Downloads screen, including: English Clear Quran (Dr. Mustafa Khattab), Turkish (Saheeh), Malayalam (Abdul Hameed), Persian (Hussein Dari), French (Hamidullah), Italian (Piccardo), Dutch (Siregar), Portuguese, Russian (Kuliev), Urdu, Bengali, Chinese, Indonesian, Spanish, Swedish, and German (Bubenheim, Nadeem, Abu Rida). Copyright in each translation remains with its translator and publisher.
- **Optional downloadable tafsir** — Tafsir al-Jalalayn and Al-Mukhtasar fi Tafsir al-Quran al-Karim (Tafsir Center for Quranic Studies). Copyright remains with the respective authors, translators and publishers.

Translations and tafsir are interpretations of the meanings of the Quran. They are not the Quran.

## Supplications, hadith and names of Allah

- **Hisn al-Muslim (Fortress of the Muslim)** — compiled by Sa'id bin Ali bin Wahf al-Qahtani. Arabic text and references follow the published work. Transliteration was generated for this app. Translations other than English were produced with automated assistance and may contain errors.
- **Daily hadith and dua selections** — brief excerpts from the Sahih collections (for example Sahih al-Bukhari and Sahih Muslim) with references.
- **Asma ul-Husna (99 Names of Allah)** — names and short meanings from openly available public data.

## Audio

- **Recitations** are streamed or downloaded from **EveryAyah.com** (everyayah.com). Each recitation belongs to its reciter and/or publisher. We do not host the audio.
- **Verse timing data** — optional downloads from the eQuran assets repository (github.com/ya27hw/equran-assets).

## Maps and location

- **Map tiles and place names** — © OpenStreetMap contributors, available under the Open Database Licence (ODbL). https://www.openstreetmap.org/copyright. Use is subject to the OpenStreetMap Foundation's tile and Nominatim usage policies.
- **Prayer-time calculation** — the `adhan_dart` package (MIT).

## Price data

- **Gold prices** for the Zakat calculator come from the CoinGecko public API (coingecko.com).

## Images and artwork

The app icon and interface illustrations were generated by the project owner using AI image-generation tools. Store screenshots show the app itself.

## Software libraries

eQuran is built with Flutter and open-source packages. Their licences are listed under **Licenses** in the About dialog (generated automatically from each package). Bundled third-party code includes:

- `quran` (trimmed local copy of the Dart package by Aqeel) — MIT License
- `foil` (by Adam Skelton / Zabadam) — BSD 3-Clause License
- `flutter`, `just_audio`, `audioplayers`, `hive`, `flutter_map`, `geolocator`, `adhan_dart` and others — see the Licenses screen

## Tanzil Project notice

Some text and metadata originate from the Tanzil Project (tanzil.net). Their terms require that the text is reproduced unaltered, that credit to Tanzil is retained, and that translations are used only as their respective licences permit.
