// Shared helpers for the UI preview scripts. See README.md in this folder.
const fs = require('fs');
const path = require('path');
const http = require('http');
const cp = require('child_process');
const crypto = require('crypto');

const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

const WORK = process.env.UI_PREVIEW_DIR || '/tmp/ui_preview';
const BUILD = process.env.UI_PREVIEW_BUILD || path.join(WORK, 'webbuild');
const SHOTS = path.join(WORK, 'shots');
const FONTS = path.join(WORK, 'fonts');
const PROFILE = path.join(WORK, 'profile');
const CHROME =
  process.env.UI_PREVIEW_CHROME ||
  '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';
const PORT = Number(process.env.UI_PREVIEW_PORT || 8099);
// Prayer times are computed in the browser's time zone, so match the seeded
// location (Makkah) or the times look wrong.
const TIMEZONE = process.env.UI_PREVIEW_TZ || 'Asia/Riyadh';

for (const d of [WORK, SHOTS, FONTS, PROFILE]) fs.mkdirSync(d, { recursive: true });

const types = {
  '.html': 'text/html', '.js': 'application/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.ttf': 'font/ttf',
  '.otf': 'font/otf', '.webp': 'image/webp', '.svg': 'image/svg+xml',
};

function serve() {
  return new Promise((resolve) => {
    const srv = http.createServer((req, res) => {
      let p = decodeURIComponent(req.url.split('?')[0]);
      if (p === '/') p = '/index.html';
      const f = path.join(BUILD, p);
      fs.readFile(f, (e, d) => {
        if (e) { res.writeHead(404); res.end(); return; }
        res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' });
        res.end(d);
      });
    }).listen(PORT, () => resolve(srv));
  });
}

// The browser cannot reach the CDN through the sandbox proxy, but curl can, so
// fonts are downloaded once with curl and then served from a local cache.
function fetchCached(url) {
  const f = path.join(FONTS, crypto.createHash('md5').update(url).digest('hex'));
  if (!fs.existsSync(f) || fs.statSync(f).size < 1000) {
    try { cp.execFileSync('curl', ['-sS', '-m', '40', '-o', f, url]); } catch (e) { return null; }
  }
  return fs.existsSync(f) && fs.statSync(f).size > 1000 ? fs.readFileSync(f) : null;
}

// Opens the built web app in a persistent profile (so Hive/IndexedDB data such
// as the seeded prayer location and the chosen theme survive between runs).
async function open({ locale = 'en-US', scheme = 'dark', width = 390, height = 844 } = {}) {
  const srv = await serve();
  const ctx = await chromium.launchPersistentContext(PROFILE, {
    executablePath: CHROME,
    args: ['--no-sandbox', '--use-gl=swiftshader', '--enable-unsafe-swiftshader'],
    viewport: { width, height }, deviceScaleFactor: 2, colorScheme: scheme, locale, timezoneId: TIMEZONE,
  });
  await ctx.route(/^https?:\/\/(?!localhost)/, async (route) => {
    const u = route.request().url();
    const m = u.match(/flutter-canvaskit\/[^/]+\/(.+)$/);
    if (m) {
      const f = path.join(BUILD, 'canvaskit', m[1].split('?')[0]);
      if (fs.existsSync(f)) {
        return route.fulfill({
          body: fs.readFileSync(f),
          contentType: f.endsWith('.wasm') ? 'application/wasm' : 'application/javascript',
          headers: { 'access-control-allow-origin': '*' },
        });
      }
    }
    if (/fonts\.gstatic\.com/.test(u)) {
      const b = fetchCached(u);
      if (b) return route.fulfill({ body: b, contentType: 'font/ttf', headers: { 'access-control-allow-origin': '*' } });
    }
    return route.abort(); // map tiles etc.
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  return { ctx, page, srv, close: async () => { await ctx.close(); srv.close(); } };
}

module.exports = { open, SHOTS, WORK };
