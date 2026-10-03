// Captures Home (top + two scroll positions) and the Quran, Prayer, Duas and
// More tabs. Usage: node capture.js <tag> [dark|light] [locale] [width] [height]
// Taps assume the 5-item bottom bar of the phone layout (use 390x844).
const { open, SHOTS } = require('./lib.js');
const [tag = 'x', scheme = 'dark', locale = 'en-US', w = '390', h = '844'] = process.argv.slice(2);
const width = +w, height = +h;
(async () => {
  const s = await open({ scheme, locale, width, height });
  const p = s.page;
  const shot = (n) => p.screenshot({ path: `${SHOTS}/${tag}-${n}.png` });
  await p.goto(`http://localhost:${process.env.UI_PREVIEW_PORT || 8099}/`, { waitUntil: 'load' });
  await p.waitForTimeout(11000);
  await shot('home0');
  await p.mouse.move(width / 2, height / 2);
  await p.mouse.wheel(0, 620); await p.waitForTimeout(1200); await shot('home1');
  await p.mouse.wheel(0, 700); await p.waitForTimeout(1200); await shot('home2');
  const cx = (i) => (width * (i * 2 + 1)) / 10, ny = height - 34;
  const names = ['', 'quran', 'prayer', 'duas', 'more'];
  for (let i = 1; i < 5; i++) {
    await p.mouse.click(cx(i), ny); await p.waitForTimeout(2500); await shot(names[i]);
  }
  await s.close();
})().catch((e) => { console.error(e); process.exit(1); });
