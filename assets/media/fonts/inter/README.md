# Inter for Phase 1 shared widgets

Bundled variable upright font (weight and optical-size axes), registered at
400, 500 and 600. Used by the opt-in shared labels and standalone debug gallery;
existing pages keep their current typography.

Source: https://github.com/google/fonts/tree/main/ofl/inter
Downloaded 2026-10-03. Licensed under SIL OFL 1.1; see OFL.txt.

SHA-256 of the unmodified upstream Inter.ttf:
`29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031`

SHA-256 of the bundled (subset) Inter.ttf:
`f9c7a07ff72b40bc98c5c65484b072cd832be35a3e9b125a6351a9f73c16f28c`

## Subsetting (2026-10-04)

Glyph-subset to Latin (Basic, Latin-1, Extended-A/B, IPA schwa, modifier letters,
combining marks, Extended Additional, general punctuation, currency, arrows, minus)
with fonttools 4.66 `pyftsubset`. The `opsz`/`wght` axes and every layout feature are kept.
Cyrillic and Greek (and anything else outside those ranges) are dropped, so text in
those scripts falls back to the platform font. No bundled string needs them.

```
pyftsubset <original>.ttf \
  --unicodes="U+0020-007E,U+00A0-024F,U+0259,U+02B0-036F,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2190-21FF,U+2212,U+2215,U+FEFF" \
  --layout-features='*' --name-IDs='*' --notdef-outline \
  --no-recalc-bounds --no-recalc-timestamp --no-prune-unicode-ranges --no-prune-codepage-ranges \
  --glyph-names --legacy-kern --output-file=<font>.ttf
```

Keep layout closure ON (the default): `--no-layout-closure` drops Inter's raised hyphen
for capitals ("AL-THANI") and changes the Home date header.
Acceptance check: every golden test passes unchanged.
