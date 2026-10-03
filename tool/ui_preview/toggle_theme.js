// Flips light/dark through More -> Theme. The choice is stored in the profile,
// so later runs start in the new mode (the colorScheme flag alone is ignored by
// the app once a mode is saved).
const { open } = require('./lib.js');
(async () => {
  const s = await open();
  const p = s.page;
  await p.goto(`http://localhost:${process.env.UI_PREVIEW_PORT || 8099}/`, { waitUntil: 'load' });
  await p.waitForTimeout(10000);
  await p.mouse.click(351, 810); await p.waitForTimeout(2500);   // More tab
  await p.mouse.move(195, 500); await p.mouse.wheel(0, 3500); await p.waitForTimeout(1200);
  await p.mouse.click(195, 448); await p.waitForTimeout(2000);   // Theme tile
  await s.close();
})();
