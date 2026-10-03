// Opens a surah from the Quran tab and captures the reader.
// Usage: node reader.js <tag> [dark|light]
const { open, SHOTS } = require('./lib.js');
const [tag = 'r', scheme = 'dark'] = process.argv.slice(2);
(async () => {
  const s = await open({ scheme });
  const p = s.page;
  await p.goto(`http://localhost:${process.env.UI_PREVIEW_PORT || 8099}/`, { waitUntil: 'load' });
  await p.waitForTimeout(10000);
  await p.mouse.click(117, 810); await p.waitForTimeout(2500);   // Quran tab
  await p.mouse.click(300, 420); await p.waitForTimeout(6000);   // second surah row
  await p.screenshot({ path: `${SHOTS}/${tag}-read0.png` });
  await s.close();
})().catch((e) => { console.error(e); process.exit(1); });
