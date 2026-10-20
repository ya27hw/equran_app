// Builds a side-by-side comparison image.
// Usage: node sheet.js out.png "Label=path.png" "Label=path.png" ...
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const CHROME = process.env.UI_PREVIEW_CHROME || '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';
const [, , out, ...pairs] = process.argv;
(async () => {
  const items = pairs.map((p) => { const i = p.indexOf('='); return [p.slice(0, i), p.slice(i + 1)]; });
  const html = '<body style="margin:0;background:#e9ece9"><div style="display:flex;gap:24px;padding:24px;width:max-content">' +
    items.map(([l, f]) => `<div><div style="font:600 22px sans-serif;margin:0 0 10px 4px;color:#222">${l}</div><img src="data:image/png;base64,${fs.readFileSync(f).toString('base64')}" style="width:390px;border-radius:14px;box-shadow:0 6px 24px #0003"></div>`).join('') +
    '</div></body>';
  const b = await chromium.launch({ executablePath: CHROME, args: ['--no-sandbox'] });
  const pg = await b.newPage({ viewport: { width: items.length * 414 + 48, height: 950 } });
  await pg.setContent(html); await pg.waitForTimeout(500);
  await pg.screenshot({ path: out, fullPage: true });
  await b.close();
})();
