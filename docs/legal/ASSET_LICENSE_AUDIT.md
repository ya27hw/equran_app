# Asset & Content Licence Audit

Date: 2026-10-03 · Scope: everything bundled in the repo, downloaded at runtime, or contacted over the network by eQuran 3.4.1+102.

> **This is an engineering audit, not legal advice.** It records what the files themselves say, what could be confirmed, and what could not. Items marked **UNVERIFIED** need a human to confirm with the rights holder. Have a lawyer review the Terms/Privacy documents before relying on them.

## How this was checked

- **Primary evidence (strongest):** licence text and credits embedded inside the font files (read from the TTF `name` tables), the `LICENSE` files in `third_party/`, `pubspec.yaml`, the source code, and the provenance clues in `scripts/` and `tool/`.
- **Secondary evidence (weaker):** web search snippets about Tanzil, EveryAyah and KFGQPC terms. The sandbox's network proxy blocked direct access to tanzil.net, everyayah.com, qurancomplex.gov.sa and similar sites, so **their current terms pages could not be read first-hand**. Treat those rows as "to confirm".
- **Not inspectable:** the files hosted in `github.com/ya27hw/equran-assets` (downloadable translations, tafsir, timings, tajweed fonts). Only their names, as listed in `lib/backend/resource_repository.dart`, were reviewed.

## Verdict in one paragraph

*(Written for a free app. For a paid App Store subscription, read the "Commercial scenario" section first: the verdict becomes "do not ship until the blockers are resolved".)*

**Not everything is free to use as-is.** The app code and the original UI are fine. But several bundled or downloaded assets are copyrighted works distributed under conditions that the app does not currently meet or that could not be confirmed. Two are clear problems (the IndoPak font and the runtime modification of KFGQPC fonts), and the translation/tafsir/audio sets rely on non-commercial or unconfirmed permissions. None of this is unusual for Quran apps, and most of it is fixable by getting written permission, adding attribution (done in this change), or swapping the asset.

## Commercial scenario: paid subscription on the Apple App Store

The audit above was first written assuming a free, non-commercial app. **If the app is sold by subscription, the picture gets materially worse**, because most of the "non-commercial / unconfirmed" items stop being tolerable.

### Re-rated assets for a paid app

| Asset | Free app | Paid app | Why |
|---|---|---|---|
| QuranIndoPak font + IndoPak text (QuranWBW) | High | **Blocker** | "Sadaqa-e-Jaria" (charity) purposes only; "not for sale / distribution" without written notice. Charging for an app containing it contradicts the stated purpose. |
| Tanzil-sourced content: Saheeh International, transliteration, `quran_lite` metadata/text | High / Medium | **Blocker** | Tanzil publishes translations for non-commercial use and says to get permission from the translator/publisher otherwise. |
| All optional translations and tafsir in `equran-assets` | High | **Blocker** | In-copyright works; commercial use needs a licence from each publisher. |
| EveryAyah audio streaming/downloads | Medium | **Blocker** | Secondary sources describe it as CC-BY-NC; reciters/publishers hold the rights; EveryAyah is also an unpaid third-party host you would be depending on commercially. |
| KFGQPC fonts (Hafs, QPC V4) | Medium–High | **High** | The EULA is "free of cost" and bans *selling* the font. Bundling it in something you charge for is not clearly covered. Written confirmation from KFGQPC is the safe route. |
| AI-looking images, icon | Medium | **Medium–High** | App Store review (guideline 5.2) expects you to own or be licensed for everything. Some AI tools restrict commercial use; wholly AI-generated art may be unprotectable. |
| Hisn al-Muslim / hadith content | Medium | **Medium–High** | Author's / publisher's rights. Charging increases the chance they object. Translation source unknown. |
| CoinGecko free API | Low | **Medium** | The free public tier is not meant for production commercial apps (rate limits, attribution); use a paid plan or another source. |
| OSM tile server / Nominatim | Low | **Medium** | The public tile server prohibits heavy or commercial-scale use. Use a commercial tile provider (or self-host) and your own geocoding quota. |
| corsproxy.io | Low | Low | Web build only; not part of the App Store build. |
| MIT repo + F-Droid | n/a | **Review** | The public MIT repo already redistributes the restricted assets (fonts, translations); selling the same app does not change what the repo contains, but it makes a rights holder's complaint far more likely. Anyone may legally fork and sell the *code*. |

**Bottom line:** do not submit to the App Store for a subscription until the blocker rows are resolved by a written licence, a replacement with a commercial-friendly licence, or removal of the asset. Apple can reject the app (guideline 5.2.1) or pull it after a rights holder's complaint, and the account holder carries the risk.

### Practical way to ship a paid app

1. **Keep core Quran reading free** and put the subscription on premium features (Hifz tracking, plans, widgets, themes, offline downloads and so on) rather than charging for access to the Quran text itself. This lowers the content-licence exposure, avoids selling the KFGQPC and Tanzil text and fonts, and sidesteps the sensitivity of charging for Quran access.
2. **Source content with commercial rights.** Typical routes: written licences from KFGQPC, the Saheeh International publisher and each translator you keep; content from providers that publish under explicit commercial-friendly licences (check each, for example Quran Foundation / Quran.com API terms, QuranEnc terms); and public-domain translations.
3. **Audio:** license recitations (many reciters and Islamic organisations grant permission on request) or switch to a provider with a commercial licence. Do not rely on EveryAyah for a paid product without written agreement.
4. **Keep a `PERMISSIONS/` folder** with every written permission, and mirror the credits in `assets/legal/third_party_notices.md`.
5. **Remove or relabel the crypto-donation block in the README** if you start charging; asking for donations while also selling subscriptions confuses the non-commercial position and can breach licences.

### App Store requirements (iOS build)

Based on Apple's App Review Guidelines and App Store Connect requirements as I understand them; check the current wording before submitting.

- **Subscription disclosure (guideline 3.1.2).** The paywall must show the subscription name, duration, price (and price per unit if relevant), and functional links to the Terms of Use (EULA) and Privacy Policy, plus how to cancel. A "Restore purchases" control is required. Trial terms must be clear.
- **Privacy policy URL** is mandatory in App Store Connect and must also be reachable in-app. The repo's `assets/legal/privacy_policy.md` needs a public URL (for example the landing page or GitHub Pages).
- **Terms / EULA.** Either use Apple's standard EULA or upload a custom one. A custom EULA must include Apple's minimum terms. Section 15 of `terms_of_use.md` has them. It also needs your **contact details**; the Terms currently give only an email.
- **App Privacy "nutrition label".** Declare accurately: location (used on device, optionally sent to OSM/Nominatim), purchases, no tracking. Because the app contacts third parties, review each for what you must declare. iOS also needs a **privacy manifest** (`PrivacyInfo.xcprivacy`); `ios/Runner` currently has none, and some plugins need declarations for "required reason" APIs.
- **Location permission strings** in `ios/Runner/Info.plist` must clearly explain the use (already present in some form; review wording).
- **Trader / business information.** To sell in the EU you must provide trader status and contact details (name, address, phone, email), which Apple publishes on the app's page. A sole developer should consider a business entity.
- **Tax, banking and the Paid Applications Agreement** must be completed in App Store Connect.
- **Payments code does not exist yet.** The app has no purchase integration. For iOS use StoreKit via Flutter's `in_app_purchase` (StoreKit part only). **Do not ship the Android half in the F-Droid build**: Google Play Billing is a proprietary GMS dependency and would violate the F-Droid rule recorded in `AGENTS.md`. Use a separate iOS-only flavour/build or conditional dependency. Avoid third-party SDKs that add analytics or tracking unless you also update the privacy label and policy.
- **No external payment links or donation prompts** inside the iOS app (guideline 3.1.1 / 3.1.3).
- **Content rights (guideline 5.2).** Be ready to answer App Review's questions about the source of the Quran text, translations and audio, and keep the permissions at hand.

### Documents changed for the paid scenario

- `terms_of_use.md`: no longer says the app is free or non-commercial; adds a subscription section (price, billing, auto-renewal, cancellation, refunds, restore) and the Apple-specific terms.
- `privacy_policy.md`: adds how purchases are handled.
- `disclaimer.md`: notes that paying changes no disclaimer.
- `third_party_notices.md`: removed the "non-commercial" remark about audio.

Still needed for a paid launch: the exact subscription price, period and trial wording on the paywall, a public URL for the Terms and Privacy Policy, your legal entity and contact address, and the governing-law choice.

## Summary table

| # | Asset | Where | Licence / status | Risk |
|---|---|---|---|---|
| 1 | AlQuran IndoPak by QuranWBW font | `assets/media/fonts/QuranIndoPak.ttf` | Embedded notice: *"NOT FOR SALE, NOT FOR MODIFICATION, NOT FOR DISTRIBUTION OR NOT FOR DEVELOPMENT WITHOUT WRITTEN NOTICE BY QURANWBW.COM"*. Derived from Al Qalam Quran Majeed (© Al Qalam, © Ghandhara) and KFGQPC glyphs. | **High** |
| 2 | KFGQPC HAFS Uthmanic Script font | `assets/media/fonts/UthmanicHafs_V22.ttf` (+ unused duplicate in `assets/data/quran/`) | KFGQPC EULA: free to use/copy/distribute; **no** sale, modification, alteration, translation, reverse engineering. | Medium (see #3) |
| 3 | QPC V4 Tajweed fonts, patched at runtime | `lib/backend/qcf_cpal_patcher.dart`, `qpc_v4_font_service.dart`, downloaded `tajweed.zip` | KFGQPC/Quran.com colour fonts. `QcfCpalPatcher` rewrites the CPAL colour table in memory for dark mode, which is arguably "modifying/altering" the font under the EULA wording. | **High** (literal reading) |
| 4 | Saheeh International English translation | `assets/data/quran/translations/en_saheeh/` | In-copyright translation (Saheeh International / Dar Abul-Qasim). Obtained via Tanzil, whose translations are for **non-commercial use** and require unaltered text + credit. | **High** |
| 5 | English transliteration | `assets/data/transliteration/quran_en_transliteration.json` | Tanzil Project data (identical style to `en.transliteration`). Tanzil terms: non-commercial, unaltered, credit. | Medium |
| 6 | Optional translations (Clear Quran, Hamidullah, Kuliev, Piccardo, Siregar, Bubenheim, Nadeem, Abu Rida, Hussein Dari, Abdul Hameed, etc.) | Hosted in `ya27hw/equran-assets` releases; listed in `resource_repository.dart` | All are in-copyright translations (translators mostly living or deceased < 70 years). You redistribute them from your own GitHub releases. Permissions **UNVERIFIED**. | **High** |
| 7 | Tafsir Al-Jalalayn (English), Al-Mukhtasar | Same repo | Copyrighted (Jalalayn English: Feras Hamza / Royal Aal al-Bayt Institute; Mukhtasar: Tafsir Center for Quranic Studies). Permissions **UNVERIFIED**. | Medium–High |
| 8 | EveryAyah audio | Streamed/downloaded from everyayah.com (`lib/utils/reciter.dart`, `audio_downloads.dart`) | Secondary sources describe EveryAyah data as CC-BY-NC. Recitations belong to the reciters/publishers. The app also downloads whole-surah ZIPs and caches audio offline. First-hand terms **UNVERIFIED**. | Medium |
| 9 | Arabic Quran text (IndoPak, QPC Hafs, QPC V4) | `assets/data/quran/text/*` | Hafs/V4 derive from KFGQPC / Quran.com (QUL) data; IndoPak from QuranWBW. Redistribution terms **UNVERIFIED**; Tanzil-origin text requires unaltered text + credit. | Medium |
| 10 | Hisn al-Muslim content | `assets/data/dua/hisn/` | Arabic text by Sa'id al-Qahtani; widely and freely distributed, but the copyright holder is the author/heirs/publisher. English translation source is **undocumented**. Non-EN/AR translations are machine-generated (`scratch/translate_*.py`). | Medium |
| 11 | Daily hadith duas, Asma ul-Husna | `assets/data/dua/*.json` | Short hadith excerpts with references; names are public-domain facts. `asma_al_husna.json` has an API-response shape (`code/status/data`), so it was copied from a third-party API; source **UNVERIFIED**. | Low |
| 12 | App images / icon / banners | `assets/media/images/**`, `metadata/`, `fastlane/`, `landing/assets/img` | **Resolved (owner statement):** generated by the project owner with an AI tool. Keep a note of the tool and its terms (see detail below). | Low |
| 13 | `quran_lite` package | `third_party/quran_lite/` | MIT, © 2023 Aqeel. LICENSE present. | Low |
| 14 | `foil` package | `third_party/foil/` | BSD-3-Clause, © 2021 Adam Skelton. LICENSE present. | Low |
| 15 | Google Fonts at runtime | `google_fonts` use in `equran_text_styles.dart`, `splash_screen.dart`, `read.dart` | Fonts (Noto Naskh Arabic, Inter, Outfit, Amiri) are SIL OFL 1.1: fine to use. But they are **fetched from Google at runtime** (no bundled copies), which leaks IP to Google and is awkward for an F-Droid-style "no Google services" posture. | Low (licence) / Medium (privacy) |
| 16 | Landing-page fonts | `landing/fonts/*.woff2` | Amiri, Marcellus, Outfit: SIL OFL 1.1. OFL requires shipping the licence text with the fonts; not currently included. | Low |
| 17 | OpenStreetMap tiles + Nominatim | `prayer_map_location_page.dart`, `prayer_location_service.dart` | Data © OSM contributors (ODbL). In-app attribution exists. `tile.openstreetmap.org` and Nominatim have usage policies (light use only, identifying User-Agent, ≤1 req/s). | Low |
| 18 | CoinGecko API | `lib/zakat/zakat_page.dart` | Free public API: attribution is expected and rate limits apply. | Low |
| 19 | corsproxy.io (web build only) | `lib/widgets/play_button.dart` | Third-party proxy used without an agreement; the free tier is intended for development. Leaks the audio URL. | Low–Medium |
| 20 | Other Flutter/pub dependencies | `pubspec.yaml` | Standard permissive packages; `showLicensePage` already lists them. Not individually audited here. | Low |

## Detail on the main findings

### 1. QuranIndoPak.ttf (highest priority)

The font's own notice (name ID 13) reads: *"Made only for Sadaqa-e-Jaria purposes. No Copyright infringement intended. NOT FOR SALE, NOT FOR MODIFICATION, NOT FOR DISTRIBUTION OR NOT FOR DEVELOPMENT WITHOUT WRITTEN NOTICE BY QURANWBW.COM"*, contact quranwbw@gmail.com. It is also derived from Al Qalam fonts whose rights sit with Al Qalam / Ghandhara. The app bundles it and the public repository redistributes it, which this notice does not permit without written notice/permission.

**Do one of:** (a) email QuranWBW and keep their written reply in the repo; (b) stop shipping the font and the IndoPak script option; (c) replace it with a font whose licence permits redistribution.

### 2 & 3. KFGQPC fonts

The embedded EULA allows free use, copying and distribution but forbids selling, modifying, altering, translating, reverse engineering or disassembling the font. Shipping the unmodified `UthmanicHafs_V22.ttf` is consistent with that. `QcfCpalPatcher.patchForDarkMode` swaps palette 0 and palette 1 of the downloaded QPC V4 fonts in memory before loading them. It does not redistribute a modified file, but a strict reading of "modified/altered" could still catch it. Options: ask KFGQPC (https://qurancomplex.gov.sa) for written confirmation; or drop the patch and handle dark mode another way.

`assets/data/quran/UthmanicHafs_V22.ttf` is a byte-identical duplicate that `pubspec.yaml` does not bundle. It only adds repository weight and one more redistribution; consider deleting it.

### 4–7. Translations and tafsir

Almost every translation named in the app is in copyright. Tanzil publishes translations for non-commercial use and asks that they stay unaltered and credited. Tanzil's page is not a grant from the translators. Redistribution from `ya27hw/equran-assets` makes *you* the distributor.

What helps: (a) obtain written permission from each translator/publisher (many Quran-publishing organisations grant it freely for non-profit apps on request); (b) switch to translations that have an explicit open licence or are in the public domain (for example older translations whose authors died long ago such as Pickthall, d. 1936, checking each jurisdiction); (c) keep the attribution added in `third_party_notices.md`; (d) if the app stays free, keep it ad-free and non-commercial. A paid subscription changes this: see the commercial scenario above. Publishing cryptocurrency donation addresses in the README may be read as commercial activity by a strict licensor.

### 8. Audio

Streaming from EveryAyah is a normal pattern, but EveryAyah is itself an aggregator, and the app additionally downloads whole-surah ZIPs and caches audio. Ask the site's owner whether this use is fine, and keep the credit in the app (added). Do not ship or re-host the audio in your own repository.

### 12. Images

The project owner states the images were generated personally with an AI tool, so there is no third-party copyright claim to clear. Two small housekeeping points: (a) record which tool you used and keep a copy of its terms, since some AI services restrict certain commercial uses, which would matter only if you later sell the app; (b) wholly AI-generated art may not be copyright-protected in some jurisdictions, so you may be unable to stop others copying it. Neither blocks free distribution.

## Replacement plan: assets that need an alternative

Goal: swap each problem asset for one that can be distributed freely, commercially or not. "Verified" means I read the licence text shipped inside the package or font file. Network limits (see "How this was checked") prevented verifying everything.

### Verified replacements

| Problem asset | Replacement | Licence evidence | Notes |
|---|---|---|---|
| KFGQPC Hafs font (`UthmanicHafs_V22.ttf`) and the QuranWBW IndoPak font | **Scheherazade New** (SIL) | SIL OFL 1.1: `LICENSE_FONT` in `@expo-google-fonts/scheherazade-new` states "licensed under the SIL Open Font License, Version 1.1". OFL permits use, bundling and redistribution, including commercial, provided the licence text ships with the font and the font is not sold on its own. | Covers **every** character in the app's `qpc-hafs` and `indopak` text (0 missing glyphs). Rendered both datasets cleanly in a browser test, with all small marks present; Hafs output is very close to the current font. IndoPak output is Naskh, not the Nastaleeq look of the QuranWBW font. |
| (alternative) | Amiri Quran (OFL 1.1, verified) | `LICENSE_FONT` in `@expo-google-fonts/amiri-quran` | **Not recommended for this text**: lacks U+065E (1,807 uses in the Hafs data) so it shows empty boxes in places (seen in the render test). |
| (UI/fallback) | Noto Naskh Arabic, Lateef (OFL) | Same OFL check | Cover all characters. Noto Nastaliq Urdu does **not** cover the Quranic marks, so it can't be used for Quran text. |
| Quran Arabic text from KFGQPC / Quran.com (QPC data) and QuranWBW | **Tanzil Quran text** | Licence block in the `ar.tanzil.quran-simple.txt` package: "License: Creative Commons Attribution 3.0". Terms: verbatim copies only (CHANGING IT IS NOT ALLOWED); free to use in any website or application provided Tanzil.net is credited and linked; the copyright block must be kept. **No non-commercial restriction.** | Usable commercially if you keep it verbatim, credit and link tanzil.net, and keep the notice block. Only the "Simple" edition was found in a form I could read; the **Uthmani** edition (closest to the current text) must be downloaded from tanzil.net and its licence block checked. Re-sharding into per-surah JSON is fine; editing the words is not. |
| `quran_lite` metadata (surah, juz, page, sajdah) | Facts about the Quran's structure | Not copyrightable as bare facts; the package itself is MIT. | Low risk; keep the credit. |

### Not solved: needs a source I could not verify here

- **English translation (replace Saheeh International).** The safest open choice is **Marmaduke Pickthall, *The Meaning of the Glorious Koran* (1930)**: public domain because the author died in 1936, and in the US because works published in 1930 entered the public domain on 1 January 2026. Yusuf Ali (d. 1953) is public domain in life+70 countries but riskier in the US. I could not obtain a clean, verse-aligned digital copy with a verifiable licence: Project Gutenberg, Wikisource and archive.org are blocked from this environment, and the npm packages I found don't state a licence for their translation data. **You or I can get it from Project Gutenberg / Wikisource (public domain) and align it to ayah numbers.** Do not use Tanzil's translation files: they carry the non-commercial terms.
- **Other languages.** The same method applies: use only translations whose translators died more than 70 years ago or that are published under an explicit open licence. Examples to check one by one: Turkish (Elmalili Hamdi Yazir, d. 1942), Urdu (Fateh Muhammad Jalandhari, d. 1920), Russian (Krachkovsky, d. 1951), and the Indonesian Ministry of Religious Affairs translation (a government publication; confirm Indonesian copyright law and its terms). Keep a licence note for each. Delete the rest from the `equran-assets` releases and the manifest. I cannot see that repository from this session.
- **Tafsir.** Al-Jalalayn (1460s/1505) and the Arabic original are public domain; the *English* translation by Feras Hamza is not. Options: offer the Arabic tafsir only, or get permission for the English. Al-Mukhtasar: remove unless you get permission.
- **English transliteration.** Tanzil's transliteration is non-commercial. Replace by generating your own transliteration from the Arabic text (as `scripts/improve_transliteration.py` already does for the duas), or remove it.
- **Tajweed page fonts (QPC V4) and the dark-mode patch.** No open equivalent of the page-by-page KFGQPC colour fonts exists. The clean fix is to remove the QPC V4 style, which also removes the font-modification problem. Open tajweed *colouring* of plain text is possible in principle but is a new feature.
- **IndoPak text.** There is no openly licensed IndoPak text dataset I could verify. Options: remove the IndoPak script option and show the Tanzil text in Scheherazade New (or the Naskh style) instead, or get permission from QuranWBW.
- **Hisn al-Muslim English translation.** Replace with your own translations of the Arabic du'a texts (a translation you write is yours), reviewed by someone qualified; the Arabic hadith wording itself is not copyrightable, but check the selection and arrangement against the published work.
- **Audio.** Left as is, per your decision.

### Suggested order

1. Switch the Hafs and IndoPak font families to Scheherazade New and bundle its OFL text (small code change, low risk).
2. Move the Arabic text to the Tanzil Uthmani edition with its credit and link.
3. Replace English translation with Pickthall and trim the downloadable translations to those you can document.
4. Remove QPC V4, the IndoPak option, the Tanzil transliteration, and the tafsir you can't license, or get written permission for them.
5. Delete the KFGQPC and QuranWBW font files, and the duplicate under `assets/data/quran/`, from the repo.

## Fixes made in this change

- Added user-facing **Terms of Use**, **Privacy Policy**, **Disclaimer** and **Content Sources & Third-Party Notices** (`assets/legal/*.md`), shown in the new in-app **Legal** screen (reachable from the About dialog) and linked from the README.
- Registered the bundled font and data licences with Flutter's `LicenseRegistry` so they appear in the standard **Licenses** screen.
- Clarified in the README that the MIT licence covers source code only.
- Added a short disclaimer to the store descriptions and a content note to the landing page footer.

## Recommended follow-ups (need your decision or an outside party)

1. Get written permission or replace: **QuranIndoPak font and IndoPak text** (QuranWBW).
2. Decide on the **dark-mode font patch** (get KFGQPC confirmation or remove it).
3. Request permissions for each **translation/tafsir** hosted in `equran-assets`, or remove those you cannot get; keep a `PERMISSIONS/` folder with the replies.
4. Confirm **EveryAyah** is happy with the use.
5. Record the AI tool used for the images (resolved otherwise) and the origin of the English Hisn al-Muslim translation.
6. Bundle the OFL fonts and set `GoogleFonts.config.allowRuntimeFetching = false` (removes the Google request, and the privacy-policy line about it); add the OFL text for the landing-page fonts.
7. Show "Powered by CoinGecko" on the Zakat page, or switch to a source with no attribution requirement.
8. Search for existing apps/trademarks named "eQuran" before investing further in the brand; the name is generic and heavily used.
9. Replace the web-build use of corsproxy.io with your own proxy.
10. Decide on the governing-law clause in the Terms (currently generic) and have a lawyer review both documents.
