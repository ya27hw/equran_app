# Prayer page sky hero

The redesigned Prayer page uses the approved compact solar arc: prayer name
and next-prayer countdown, no endpoint labels, icons or clocks, a layered
landscape, and a sky that follows the saved location's daylight. Its header,
date selection, prayer rows, night details, navigation and calculation rules
remain intact. Home and the no-location setup retain their existing hero.

## Time and motion

PrayerDay starts at the previous Maghrib. The sky uses its sunrise and Dhuhr
and the following PrayerDay's Maghrib, using absolute calculated instants
instead of adding 24 hours. The sun peaks at Dhuhr. Night transitions through
Fajr into dawn and sunrise, including across midnight. Invalid solar ordering
uses a static night scene; invalid prayer palette anchors are repaired only
for decoration without changing prayer data.

Minute updates interpolate for 350 ms, with no repeating animation or
accelerated day loop. The page stops its refresh timer while inactive and
refreshes on resume. Reduced motion, disabled tickers and lite devices use
immediate updates. Lite devices omit glow, cloud gradients and grain.
Historical dates show a static noon scene and selected-date subtitle.

Height is 176 logical pixels on compact layouts, 200 on wider layouts, with
extra space for accessibility text scaling. Typography uses the app's existing
redesign display and localized font styles; no fonts or dependencies are added.

## Verification and rollback

Run the quality gates in CLAUDE.md. Focused regression coverage:
`flutter test test/prayer_sky_scene_test.dart test/prayer_sky_hero_test.dart test/redesign/prayer_page_test.dart`.
The redesigned page's golden fixtures cover its day, night and night-details
states in four palettes, Arabic and enlarged text. Optional `PRAYER_SKY_SHOTS`
exports dawn, sunrise, noon, sunset and night hero images from the widget test.

There is no storage migration. Revert this change to restore the prior hero
and golden fixtures. Keep the shared Newsreader and other font assets, which
are already used throughout the redesigned app.
