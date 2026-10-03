# UI preview tooling

Screenshots of the app from a Flutter **web build**, driven by Playwright. It
exists because the cloud sandbox has no emulator, and it is how the UI polish
work was checked and how the README screenshots were produced. It is a preview,
not a device: it renders with CanvasKit, has no status bar, and prayer times
come from the machine clock.

## Requirements

- The current **stable** Flutter SDK (CI builds on latest stable; check
  `.github/workflows`). If the sandbox git complains about "dubious ownership",
  run `git config --global --add safe.directory <flutter-sdk-path>`.
- Node with Playwright and a Chromium build (in the Claude cloud sandbox:
  `PLAYWRIGHT_MODULE=/opt/node-tools/node_modules/playwright`, Chromium under
  `/opt/pw-browsers`). Do not run `playwright install`.
- Network access for fonts. The browser cannot reach the CDN through the
  sandbox proxy, but `curl` can, so `lib.js` downloads Google Fonts once with
  `curl` and serves them from a cache folder. CanvasKit is served from the
  build output. Map tiles are blocked (the map picker stays blank).

## Environment variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `UI_PREVIEW_DIR` | `/tmp/ui_preview` | Work folder: `shots/`, `fonts/`, `profile/` |
| `UI_PREVIEW_BUILD` | `$UI_PREVIEW_DIR/webbuild` | Folder holding the web build |
| `UI_PREVIEW_CHROME` | `/opt/pw-browsers/chromium-1194/chrome-linux/chrome` | Chromium binary |
| `UI_PREVIEW_PORT` | `8099` | Local port for the static server |
| `PLAYWRIGHT_MODULE` | `playwright` | Where to `require` Playwright from |

## Workflow

```bash
# 1. Build (revert the files the Flutter tool touches afterwards)
flutter pub get
flutter build web --release --no-pub -o "$UI_PREVIEW_DIR/webbuild"
git checkout pubspec.lock analysis_options.yaml

# 2. Seed a fresh profile once (location "Makkah" + a few verses read)
node tool/ui_preview/seed.js

# 3. Capture
node tool/ui_preview/capture.js dark1 dark              # Home x3, Quran, Prayer, Duas, More
node tool/ui_preview/capture.js ar1 dark ar-SA          # Arabic / RTL
node tool/ui_preview/reader.js reader1 dark             # the reader
node tool/ui_preview/capture.js wide1 dark en-US 1100 800   # wide layout (Home only is meaningful)

# 4. Light mode: the app stores the chosen theme in the profile, so flip it
node tool/ui_preview/toggle_theme.js
node tool/ui_preview/capture.js light1 light

# 5. Optional side-by-side sheet
node tool/ui_preview/sheet.js out.png "Before=a.png" "After=b.png"
```

Screenshots land in `$UI_PREVIEW_DIR/shots/<tag>-<name>.png` at 780x1688
(390x844 at 2x).

## Gotchas

- The tap coordinates assume the **390x844 phone layout** with the 5-item
  bottom bar (labels at x = 39, 117, 195, 273, 351 and y = 810). Other sizes or
  a customised navigation bar need different coordinates.
- Flutter web draws to a canvas, so there are no DOM selectors. The scripts
  click coordinates and rely on fixed waits. If a screenshot looks half-loaded,
  raise the wait.
- The app ignores the browser colour scheme once a theme is saved in the
  profile. Use `toggle_theme.js` (More -> Theme tile at about y = 448 after
  scrolling to the bottom). Deleting the profile folder resets to dark.
- Deleting the profile also deletes the seeded location and reading history;
  run `seed.js` again.
- Without a saved prayer location the Prayer tab opens the map picker, which
  pushes a route and breaks every later tap. Always seed first.
- Run `flutter analyze` / `flutter build` from a clean tree and revert
  `analysis_options.yaml` and `pubspec.lock` before committing.
