# Prompts for the coding agent

Give the agent **one phase at a time**. Do not paste the whole plan and say "implement it". Review each phase before starting the next.
Work on a branch off `beta` per phase (for example `redesign/p0-tokens`) and open a PR into `beta`.

## Master prompt (use at the start of every phase)

```
You are implementing part of a UI redesign in this Flutter app.

Read these first, in order, before writing any code:
1. AGENTS.md (project rules; they are mandatory)
2. docs/redesign/IMPLEMENTATION.md (the brief; follow the phase I name below)
3. docs/redesign/tokens.json (exact colours; your code must reproduce the derived values)
4. The static previews named for the phase in docs/redesign/previews/ (open them in a browser at 390px wide and read the inline CSS for exact paddings, radii and font sizes)

Rules:
- Presentation only. Do not change repositories, data models, services or business logic.
- No hardcoded colour hex in widgets. Colours come from EquranColors or EquranTokens.
- If the preview HTML and IMPLEMENTATION.md disagree, the preview HTML wins. If tokens.json and a preview disagree on a colour, tokens.json wins.
- Bundle fonts as assets. No runtime font fetching. No GMS, Firebase or proprietary SDKs (F-Droid).
- Never delete or untrack pubspec.lock.
- Run `dart format .`, `flutter analyze` (zero warnings) and `flutter test` before saying you are done.
- Do not start any phase other than the one I name. Do not "improve" things outside the phase.
- If something in the brief is ambiguous or needs a product decision, stop and ask. Do not guess.

When finished, report: files changed, what you verified and how, anything you could not do or had to decide, and screenshots (see the phase).
```

## Phase 0: tokens

```
Phase: 0 (tokens). Nothing else.

Implement lib/theme/equran_tokens.dart (EquranTokens ThemeExtension, derived from EquranColors by the rules in
docs/redesign/derive_tokens.py), add the Newsreader display styles to equran_text_styles.dart, bundle the font assets, and add
EquranRadii for 28. Register the extension in equran_theme.dart for all 11 palettes.

Required tests:
1. For every palette in docs/redesign/tokens.json, derive EquranTokens from the matching Dart EquranColors constant and assert each
   colour equals the JSON value within 1/255 per channel. Read the JSON in the test; do not copy numbers into the test file.
2. Assert all 13 contrast pairs in derive_tokens.py's report() pass for all 11 palettes.

No UI changes in this phase. Report which font weights you bundled and the test output.
```

## Phase 1: shared widgets

```
Phase: 1 (shared widgets). Nothing else. Phase 0 is merged.

Build the shared widgets listed in the Phase 1 table of docs/redesign/IMPLEMENTATION.md. Add a golden test for each widget in emerald-dark,
emerald-light, AMOLED black and red-light. Add one small debug-only gallery page that shows them all, so I can eyeball them.
Do not wire them into any real page yet.

Attach golden images or screenshots of the gallery in two palettes.
```

## Phases 2 to 5: one page each

```
Phase: <2 Saved tab | 3 Duas | 4 Prayer | 5 Statistics>. Nothing else. Earlier phases are merged.

Rebuild this page using the shared widgets so it matches docs/redesign/previews/<page>.dark.html and .light.html. Keep every existing
interaction and all existing data wiring. Follow the section for this phase in IMPLEMENTATION.md, including its "needs a decision" notes:
if one applies, stop and ask me before building that part.

Verify at 390px width in emerald-dark, emerald-light, AMOLED black and red-dark, then at text scale 1.3, then with the Arabic locale (RTL).
Attach a screenshot for each of those. List any visual difference from the preview that you chose to leave, and why.
```

## How I review (so you know what to send me)

Paste or attach, per phase: the PR link or diff, and the screenshots the phase asks for. I compare them against the previews and the
brief and list differences. Fixes go back to the agent as a short list, not a rewrite.
