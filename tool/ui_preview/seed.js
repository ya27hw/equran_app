// One-time seeding for a fresh profile: saves a prayer location labelled
// "Makkah" (so Home and Prayer show the real, non-empty hero) and reads a few
// verses of Al-Fatiha (so the Journey ring, last-read card and stats have data).
const { open, SHOTS } = require('./lib.js');
(async () => {
  const s = await open();
  const p = s.page;
  await p.goto(`http://localhost:${process.env.UI_PREVIEW_PORT || 8099}/`, { waitUntil: 'load' });
  await p.waitForTimeout(12000);
  await p.mouse.click(195, 810); await p.waitForTimeout(3000);   // Prayer tab -> map picker
  await p.mouse.click(195, 797); await p.waitForTimeout(2500);   // "Enter coordinates manually"
  await p.mouse.click(195, 196); await p.keyboard.press('Control+A'); await p.keyboard.type('Makkah');
  await p.mouse.click(195, 257); await p.keyboard.press('Control+A'); await p.keyboard.type('21.4225');
  await p.mouse.click(195, 340); await p.keyboard.press('Control+A'); await p.keyboard.type('39.8262');
  await p.mouse.click(195, 512); await p.waitForTimeout(3000);   // Save location
  await p.mouse.click(117, 810); await p.waitForTimeout(2500);   // Quran tab
  await p.mouse.click(300, 339); await p.waitForTimeout(6000);   // Al-Fatiha
  for (let i = 0; i < 6; i++) { await p.mouse.click(345, 812); await p.waitForTimeout(1200); }  // next ayah
  await p.screenshot({ path: `${SHOTS}/seed.png` });
  await s.close();
})();
