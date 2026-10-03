# Phase 3: Duas

Base: beta after merged Phase 2 PR #97 (`3d1776f`). Branch: `redesign/p3-duas`.
Scope: Duas home and a new theme/category browser. The existing dua reader,
favourites page, Tasbih page, repositories, mappings, storage and prayer calculations
retain their behavior. No Prayer or Statistics redesign is included.

## Behavior and approved suggestion rule

- Home: 36px Newsreader title, offline total, search, suggestion hero, Favourites
  and Tasbih tiles, then 13 themes in two columns. General spans both columns.
- Counts come from the bundled index and existing group mapper: 134 categories,
  298 duas; Daily Athkar has 7 categories and 54 duas. No preview count is used in
  production. Each theme opens its filtered list; each row opens the existing reader.
- Before local noon: category 029, “For this morning”. From the configured Asr
  time: category 029, “For this evening”. Between noon and Asr: the latest valid
  category view from `DuaInteractionsDB`, with “Continue”. No history falls back
  to category 029 with “For this morning” until Asr. No configured location uses
  category 029 with “Suggested for you”. This is the owner's approved rule.
- Uses the prayer location timezone when enabled, existing calculation settings
  and Asr offsets. Uses device civil time when location timezone is disabled or
  unresolved, matching the existing prayer service. Does not request a location,
  create storage or write view history. Existing category reader tracking remains.
- History and settings react immediately; the minute clock updates visible pages
  and avoids clock rebuilds while the route/app is inactive. Timers are disposed.
- Home and theme searches retain existing matching and also accept English and
  Arabic titles in any locale. Theme row numbers retain their original positions
  during search. The selected suggestion gets a gold wash and reason badge.
- Favourites reflects the existing box live. Tasbih shows saved sessions dated
  today, labelled “Logged today”; an unfinished counter has no stored date and
  is not assigned to today. Both tiles preserve their original destinations.

## Changed files

- `lib/duas/duas_page.dart`: home structure; existing loading/error/retry flow.
- `lib/duas/duas_category_page.dart`: adds `DuasThemePage`; existing reader unchanged.
- `lib/duas/widgets/dua_browser_widgets.dart`: feature-local typography, search,
  group discs, bilingual rows, hero and read-only suggestion projection.
- `lib/home/home.dart`: removes only the redundant legacy Duas toolbar, because
  the redesigned page owns its title. Other destinations and navigation unchanged.
- All eight `lib/l10n/app_*.arb` files and generated localizations: new labels,
  navigation/search text and real count placeholders. Existing keys reused first.
- `lib/debug/duas_preview_main.dart`: standalone debug preview on a dedicated origin
  with synthetic favourites/session data and a fixed Muscat clock. Not in app navigation.
- `test/redesign/duas_page_test.dart` and 21 `duas-*.png` goldens.
- Three screenshot matrices below. No dependency, lockfile, model or service changes.

## Verification

All captures use 390×844 logical pixels. The golden renderer produces 1170×2532
PNGs; the matrices resample them to 390×844 per cell. Variants: emerald-dark,
emerald-light, AMOLED black, red-dark, scale 1.3, Arabic RTL, plus Arabic at scale 1.3.
Home, scrolled theme grid and Daily Athkar are captured in each variant (21 goldens).
All themes and long Daily Athkar rows are exercised, not only the first viewport.

- [Home matrix](screenshots/p3-duas-home-verification.png)
- [Category matrix](screenshots/p3-duas-category-verification.png)
- [Theme grid matrix](screenshots/p3-duas-grid-verification.png)
- Full-size captures: `test/redesign/goldens/duas-{home,grid,category}-*.png`.
- Live web preview: `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8135 --no-pub -t lib/debug/duas_preview_main.dart`.
  Query parameters: `palette=emerald-light|black-dark|red-dark`, `scale=1.3`, `locale=ar`.
- Tests verify real totals and group coverage, every theme route and General width,
  English/Arabic searches, stable row positions, original destination parameters,
  reactive existing history/settings/favourites, no history writes by the suggestion,
  no-location/no-history/invalid-history fallbacks, exact noon/Asr boundaries and
  timezone behavior, loading/error/empty states, and Arabic badge font fallback.
- Required checks: dependency policy, localization consistency across 8 locales,
  stable localization generation, `dart format .`, static analysis (zero issues),
  full test suite (186 passing), clean diff whitespace and unchanged tracked lockfile.
- Formatting reports the same pre-existing missing `very_good_analysis` include
  in excluded `third_party/foil`; no vendor files changed. Analysis is clean.

## Visual decisions and limits

CSS sizes and section order were read from both supplied Duas previews. The browser
previously denied local HTML reference navigation; that restriction was respected.
Thus direct rendered reference comparison and a pixel-difference guarantee are
unavailable. Flutter captures and the live preview were inspected against CSS.

- The existing dock stays; the standalone capture excludes global navigation.
- Existing category translations and group mapping win over mock copy/counts.
  Arabic locale puts Arabic first and English secondary; other locales use their
  localized title first and Arabic secondary.
- Bundled Noto Naskh Arabic renders interface Arabic, rather than fetching Amiri.
  Its fallback is confined to Duas; Quran and dua reader fonts remain unchanged.
- Material icons substitute for the preview's custom stroke icons. HairlineCard's
  shared 24px radius is used for the 22px quick/theme tiles (2px difference).
- The highlight badge uses the actual reason (“For this evening”, “Continue”, etc.)
  on its own line instead of mock “Now” inline. This explains the selection and
  preserves full titles at 1.3 scale. Shared pill minimum height is 28px vs mock 22px.
- Existing longer favourites helper copy stays. Tasbih uses the accurate “Logged
  today” label described above. Layout grows for translated or enlarged text.
- Hero eyebrow gold is contrast-adjusted against both hero gradient stops in
  light palettes; all colors originate from existing colors/derived tokens.

## Rollback

Revert this phase commit/PR on beta. No data migration or new box exists; saved
favourites, session logs and category-view history remain usable by the earlier UI.
The standalone preview's synthetic data is confined to its own browser origin.
