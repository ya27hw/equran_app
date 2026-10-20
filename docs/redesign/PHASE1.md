# Phase 1 shared widgets

Branch: `redesign/p1-widgets`, based on beta after Phase 0 PR #93 was merged.
No shared widget is connected to production navigation or a real page.

## Debug gallery

From this checkout, run:

```sh
flutter run -d chrome -t lib/debug/redesign_gallery_main.dart
```

Use a 390 logical px viewport. The gallery controls switch emerald-dark,
emerald-light, AMOLED black and red-light, text scale 1 / 1.3 and LTR / RTL.
The standalone entry point and gallery render only in debug mode. They do not
initialize application settings, repositories, prayer calculations or audio.

The Newsreader specimen shows upright 400, 500 and 600, and italic 400, each
at 16, 24, 36 and 40 px. Every specimen explicitly sets `wght` and `opsz`.
`DisplayNumeral` explicitly passes height 1 to the existing style helper and
keeps clock punctuation and fractions in numeric order in RTL.

## Shared API

Import `package:equran/widgets/redesign/redesign_widgets.dart` for the shared
widgets. Styling comes from the existing `EquranColors` and `EquranTokens`
extensions; use the Phase 0 theme when integrating in a later phase.

- `HairlineCard` and `HeroPanel` accept a child and directional padding.
  Hero children inherit the fixed light foreground; use `featText2` for
  secondary text and pass the inherited foreground to explicit display styles.
- `PillTag` is metadata, with normal, selected and gold variants. `ChipButton`
  receives selection and callback from the caller. Labels are minimum 28 / 36
  px high and grow vertically at larger text scales.
- `IconButton44` receives a localized tooltip and nullable callback; ghost
  and disabled variants retain the 44 px target.
- `FloatingDock` receives items, selected index and callback. It owns its
  14 px horizontal margins and 72 px height; callers own safe-area positioning.
  Blur is disabled for lite profiles, reduced motion or `enableBlur: false`,
  using the opaque source surface instead. It has no navigation dependencies.
- `SalahGlyph` receives a presentation state and localized semantic label.
  Every state has a distinct shape; caller data models stay unchanged.
- `ProgressRing` keeps its one-ring API. Supply `innerValue` and `innerColor`
  for an independently animated inner ring. `ringGap` is the space between
  painted edges; both values clamp to 0–1 and honour reduced motion.
- `PrayerArch` receives the existing asset path and localized semantic label.
  The branch's prayer illustrations are WebP, rather than PNG. They are reused
  without redrawing and decoded at display size through `EquranAssetImage`.

Inter is bundled under SIL OFL for the new shared labels and gallery. Existing
body typography is untouched. Newsreader uses the fonts from Phase 0.

## Visual checks

```sh
flutter test --no-pub test/redesign
flutter test --no-pub --update-goldens test/redesign/shared_widgets_golden_test.dart
```

The 54 checked-in images in `test/redesign/goldens/` cover every shared widget
(including single and concentric progress rings, all five salah states, all
six prayer illustrations, and control variants) and the complete gallery in
all four palettes. Extra complete-gallery images cover text scale 1.3 in LTR
and RTL. Tests load bundled Newsreader, Inter and Material icons explicitly;
they capture at 390 logical px and fail on layout exceptions.

Goldens are Flutter widget-test renders, not device screenshots. They were
generated with Flutter 3.44.8 / Dart 3.12.2 on macOS. Review intended changes
visually before updating them. The local HTML preview URL was blocked by the
browser's file-protocol policy; reference dimensions came from the inline CSS.

To roll back Phase 1, revert its commit. It adds no persisted data or migration,
and does not enable any redesign widget on existing pages.
