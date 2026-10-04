# Newsreader assets

Variable TTFs (glyph-subset, see below) from [Production Type's Newsreader repository](https://github.com/productiontype/Newsreader/tree/cfcb4f7af0e52c25e8df2a2431814c8e5fe2e155/fonts/variable/ttf), revision `cfcb4f7af0e52c25e8df2a2431814c8e5fe2e155`.

- `Newsreader.ttf`: upstream `Newsreader[opsz,wght].ttf`; registered for upright weights 400, 500 and 600.
- `Newsreader-Italic.ttf`: upstream `Newsreader-Italic[opsz,wght].ttf`; registered for italic weight 400.

The variable fonts retain optical sizing; display styles set `opsz` to their font size, matching the preview's automatic optical sizing. The upstream SIL Open Font License is included in `OFL.txt`. Fonts load from Flutter assets without runtime downloads.

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

SHA-256 of the bundled files:
- `Newsreader.ttf`: `1c220cb65c76a47a78617d2b1537cfe66200d45c7744f41f4540f261d2dd0f23`
- `Newsreader-Italic.ttf`: `e6828dea6fe1d90e15e767e5b5c48ecd5010972810969a53980030bcb746ce77`
