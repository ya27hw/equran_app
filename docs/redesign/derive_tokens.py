"""Reference implementation. Run: python3 docs/redesign/derive_tokens.py

Derive every redesign token from the app's existing EquranColors fields.

Reads lib/theme/equran_colors.dart, applies fixed rules (no hand-tuned per-theme values),
checks WCAG contrast, and emits (a) CSS classes for the design canvas, (b) tokens.json that the
Flutter implementation must reproduce, (c) a contrast report.
"""
import re, json

import os
DART = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'lib', 'theme', 'equran_colors.dart')
NAMES = [  # (css palette, mode, dart const)
    ('emerald', 'light', 'light'), ('emerald', 'dark', 'dark'),
    ('blue', 'light', 'fancyBlueLight'), ('blue', 'dark', 'fancyBlueDark'),
    ('purple', 'light', 'fancyPurpleLight'), ('purple', 'dark', 'fancyPurpleDark'),
    ('sepia', 'light', 'sepiaLight'), ('sepia', 'dark', 'sepiaDark'),
    ('red', 'light', 'redLight'), ('red', 'dark', 'redDark'),
    ('black', 'dark', 'blackDark'),
]
LABEL = {'emerald': 'Emerald', 'blue': 'Blue', 'purple': 'Purple', 'sepia': 'Sepia', 'red': 'Red', 'black': 'AMOLED black'}

def parse():
    src = open(DART).read()
    out = {}
    for pal, mode, const in NAMES:
        m = re.search(r'static const EquranColors %s = EquranColors\((.*?)\n  \);' % const, src, re.S)
        fields = dict(re.findall(r'(\w+): Color\(0x([0-9A-Fa-f]{8})\)', m.group(1)))
        out[(pal, mode)] = {k: '#' + v[2:].upper() for k, v in fields.items()}
    return out

def rgb(h):
    h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
def hexs(c): return '#%02X%02X%02X' % tuple(max(0, min(255, round(v))) for v in c)
def mix(a, b, t):
    A, B = rgb(a), rgb(b); return hexs([A[i] + (B[i] - A[i]) * t for i in range(3)])
def lum(h):
    def f(v):
        v /= 255; return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4
    r, g, b = rgb(h); return .2126 * f(r) + .7152 * f(g) + .0722 * f(b)
def contrast(a, b):
    la, lb = lum(a), lum(b); hi, lo = max(la, lb), min(la, lb); return (hi + .05) / (lo + .05)
def over(fg, alpha, bg): return mix(bg, fg, alpha)
def rgba(h, a): r, g, b = rgb(h); return f'rgba({r},{g},{b},{a})'

def ensure(color, against, target, toward, steps=40):
    """mix `color` toward `toward` in small steps until it reaches `target` contrast on every bg in `against`."""
    against = against if isinstance(against, (list, tuple)) else [against]
    c = color
    for i in range(steps + 1):
        c = mix(color, toward, i / steps)
        if all(contrast(c, a) >= target for a in against):
            return c
    return c

def derive(pal, mode, p):
    dark = mode == 'dark'
    ink, white, black = p['textPrimary'], '#FFFFFF', '#000000'
    bgs = [p['surface'], p['surfaceAlt'], p['background']]
    t = {}
    t['bg'], t['surface'], t['surface2'] = p['background'], p['surface'], p['surfaceAlt']
    t['text'] = ink
    t['text2'] = ensure(p['textSecondary'], bgs, 4.5, ink)
    t['muted'] = ensure(p['textMuted'], bgs, 4.5, t['text2'])
    t['hair'] = rgba(ink, .10 if dark else .09)
    t['hair2'] = rgba(ink, .20 if dark else .17)
    # filled primary (white text on it)
    fill = p['primary']
    if contrast(fill, white) < 4.5:
        fill = p['primaryStrong']
    if contrast(fill, white) < 4.5:
        fill = ensure(fill, [white], 4.5, black)
    t['em'] = fill
    emtext = p['primarySoft'] if dark else p['primary']
    t['emText'] = ensure(emtext, [p['surface'], p['surfaceAlt']], 4.5, white if dark else black)
    t['emWash'] = rgba(t['emText'] if dark else p['primary'], .10 if dark else .09)
    t['gold'] = p['accentGold'] if dark else ensure(p['accentGold'], [p['surface']], 3.0, black)
    gw = .12 if dark else .14
    wash_bg = over(p['accentGold'], gw, p['surface'])
    goldtext = mix(p['accentGold'], white, .15) if dark else p['accentGold']
    t['goldText'] = ensure(goldtext, [p['surface'], wash_bg, p['background']], 4.5, white if dark else black)
    t['goldWash'] = rgba(p['accentGold'], gw)
    t['danger'] = ensure('#E69A8B' if dark else '#B04B38', [p['surface'], p['surfaceAlt']], 4.5, white if dark else black)
    t['featA'] = p['primaryGradientStart']
    t['featB'] = mix(p['primaryGradientStart'], black, .45)
    t['featText2'] = ensure('#C5D5CD', [t['featA'], t['featB']], 4.5, white)
    t['glow'] = 'rgba(0,0,0,0)' if pal == 'black' else rgba(p['primary'], .20 if dark else .09)
    t['shadow'] = '0 14px 34px rgba(0,0,0,.40)' if dark else f'0 10px 26px {rgba(p["shadow"], .10)}'
    t['dock'] = rgba(p['surface'], .84 if dark else .88)
    t['scrim'] = 'rgba(0,0,0,.62)' if dark else rgba(p['shadow'], .42)
    return t

def report(pal, mode, p, t):
    """contrast of every text pairing the design uses; returns list of (label, ratio, need, ok)."""
    featA, featB = t['featA'], t['featB']
    wash_surface = over(p['accentGold'], .12 if mode == 'dark' else .14, p['surface'])
    rows = [
        ('text on surface', contrast(t['text'], p['surface']), 4.5),
        ('text2 on surface', contrast(t['text2'], p['surface']), 4.5),
        ('muted on surface', contrast(t['muted'], p['surface']), 4.5),
        ('muted on surfaceAlt', contrast(t['muted'], p['surfaceAlt']), 4.5),
        ('white on filled primary', contrast('#FFFFFF', t['em']), 4.5),
        ('emText on surface', contrast(t['emText'], p['surface']), 4.5),
        ('goldText on surface', contrast(t['goldText'], p['surface']), 4.5),
        ('goldText on goldWash', contrast(t['goldText'], wash_surface), 4.5),
        ('danger on surface', contrast(t['danger'], p['surface']), 4.5),
        ('hero text #F3F7F4 on featA', contrast('#F3F7F4', featA), 4.5),
        ('hero caption on featA', contrast(t['featText2'], featA), 4.5),
        ('hero gold #E2BC6B on featB', contrast('#E2BC6B', featB), 4.5),
        ('gold hairline/graphics on surface', contrast(t['gold'], p['surface']), 3.0),
    ]
    return [(n, round(r, 2), need, r >= need) for n, r, need in rows]

def build():
    pals = parse()
    css, tokens, rep = [], {}, {}
    for pal, mode, _ in NAMES:
        p = pals[(pal, mode)]
        t = derive(pal, mode, p)
        tokens[f'{pal}-{mode}'] = {'source': p, 'derived': t}
        rep[f'{pal}-{mode}'] = report(pal, mode, p, t)
        v = {'bg': t['bg'], 'surface': t['surface'], 'surface2': t['surface2'], 'hair': t['hair'], 'hair2': t['hair2'], 'text': t['text'],
             'text2': t['text2'], 'muted': t['muted'], 'em': t['em'], 'em-text': t['emText'], 'em-wash': t['emWash'], 'gold': t['gold'],
             'gold-text': t['goldText'], 'gold-wash': t['goldWash'], 'danger': t['danger'], 'feat-a': t['featA'], 'feat-b': t['featB'], 'feat-text2': t['featText2'],
             'glow': t['glow'], 'shadow': t['shadow'], 'dock': t['dock'], 'scrim': t['scrim']}
        css.append(f'.root.pal-{pal}.{mode}{{' + ';'.join(f'--{k}:{val}' for k, val in v.items()) + '}')
    return '\n'.join(css), tokens, rep

if __name__ == '__main__':
    css, tokens, rep = build()
    bad = 0
    for k, rows in rep.items():
        fails = [r for r in rows if not r[3]]
        bad += len(fails)
        print(k, 'OK' if not fails else fails)
    print('failing pairs:', bad)
