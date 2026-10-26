"""Generates the README's SVGs into docs/readme/. Run from the project root."""
import math
import sys
from pathlib import Path

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/readme")
OUT.mkdir(parents=True, exist_ok=True)

FONT = "font-family=\"'Segoe UI', system-ui, -apple-system, Helvetica, Arial, sans-serif\""
MONO = "font-family=\"'Cascadia Code', Consolas, 'SFMono-Regular', Menlo, monospace\""
BLUE, GREEN, ORANGE = "#4A7BD0", "#2FA371", "#D9822B"
INK, SOFT, DIM = "#EEF1FF", "#AEB8E8", "#6E7AB5"


def bg(w, h, gid="bg"):
    return f"""<defs>
  <radialGradient id="{gid}" cx="30%" cy="20%" r="95%">
    <stop offset="0" stop-color="#27336B"/><stop offset=".5" stop-color="#151B3A"/><stop offset="1" stop-color="#0B0E1C"/>
  </radialGradient>
  <pattern id="{gid}grid" width="32" height="32" patternUnits="userSpaceOnUse">
    <path d="M32 0H0V32" fill="none" stroke="#8FA2FF" stroke-opacity=".07"/>
  </pattern>
</defs>
<rect width="{w}" height="{h}" rx="24" fill="url(#{gid})"/>
<rect width="{w}" height="{h}" rx="24" fill="url(#{gid}grid)"/>"""


# ───────────────────────────── hero: an isometric MSP430F149 (QFP-64)

def iso(cx, cy, s):
    c, k = math.cos(math.radians(30)) * s, 0.5 * s
    return lambda u, v, z=0: (cx + (u - v) * c, cy + (u + v) * k - z * s)


def poly(pts, **attrs):
    a = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in attrs.items())
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return f'<polygon points="{p}" {a}/>'


def hero():
    W, H = 1200, 460
    P = iso(870, 150, 1.0)
    half, z = 120, 18
    parts = []
    # board traces fanning out from the pins
    traces = []
    pins = []
    n = 16
    for i in range(n):
        t = -half + 16 + i * (2 * half - 32) / (n - 1)
        for side in range(4):
            if side == 0:   # +u edge
                a, b, o = (half, t), (half + 14, t), (half + 120 + i * 3, t * 1.4)
            elif side == 1:  # +v edge
                a, b, o = (t, half), (t, half + 14), (t * 1.4, half + 120 + i * 3)
            elif side == 2:
                a, b, o = (-half, t), (-half - 14, t), (-half - 120 - i * 3, t * 1.4)
            else:
                a, b, o = (t, -half), (t, -half - 14), (t * 1.4, -half - 120 - i * 3)
            # trace to the board (only the two visible sides glow)
            if side in (0, 1) and i % 3 == 0:
                x1, y1 = P(*b)
                x2, y2 = P(*o)
                col = [BLUE, GREEN, ORANGE][(i // 3 + side) % 3]
                d = f"M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}"
                traces.append(f'<path d="{d}" stroke="#8FA2FF" stroke-opacity=".18" stroke-width="2" fill="none"/>')
                delay = (i * 0.37 + side * 0.9) % 3
                traces.append(
                    f'<path class="sig" style="animation-delay:-{delay:.2f}s" d="{d}" stroke="{col}" '
                    f'stroke-width="2.5" stroke-linecap="round" fill="none" pathLength="100"/>')
                traces.append(f'<circle cx="{x2:.1f}" cy="{y2:.1f}" r="4" fill="{col}" class="pad" style="animation-delay:-{delay:.2f}s"/>')
            # the pin: a small bent lead
            w = 3.2
            if side in (0, 2):
                q = [(a[0], t - w), (b[0], t - w), (b[0], t + w), (a[0], t + w)]
            else:
                q = [(t - w, a[1]), (t - w, b[1]), (t + w, b[1]), (t + w, a[1])]
            pins.append((side, poly([P(u, v, 4) for u, v in q], fill="#C9D1E8", stroke="#7F8BB8", stroke_width=".6")))

    # back pins first, front pins after the body
    back = [p for s, p in pins if s in (2, 3)]
    front = [p for s, p in pins if s in (0, 1)]
    top = [P(-half, -half, z), P(half, -half, z), P(half, half, z), P(-half, half, z)]
    right = [P(half, -half, z), P(half, half, z), P(half, half, 0), P(half, -half, 0)]
    left = [P(-half, half, z), P(half, half, z), P(half, half, 0), P(-half, half, 0)]
    dot = P(-half + 26, -half + 26, z)
    label = P(-8, 98, z)

    # topic dots on the die, numbered 1–12, pulsing in turn
    dots = []
    spots = [(-70, -70), (-20, -78), (35, -72), (80, -60), (-78, -15), (-25, -20),
             (28, -12), (78, 5), (-72, 45), (-20, 55), (32, 62), (78, 70)]
    cols = [BLUE] * 4 + [GREEN] * 4 + [ORANGE] * 4
    for i, ((u, v), c) in enumerate(zip(spots, cols)):
        x, y = P(u, v, z)
        dots.append(
            f'<g class="dot" style="animation-delay:{i * 0.25:.2f}s">'
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="13" fill="{c}" fill-opacity=".25"/>'
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="9" fill="{c}" stroke="#0B0E1C" stroke-width="1.5"/>'
            f'<text x="{x:.1f}" y="{y + 3.6:.1f}" text-anchor="middle" font-size="10" font-weight="700" fill="#fff" {FONT}>{i + 1}</text></g>')

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-label="MSP430 Lab — an interactive 3D explainer for the TI MSP430F149">
<style>
  .sig {{ stroke-dasharray: 14 86; animation: run 3s linear infinite; }}
  @keyframes run {{ from {{ stroke-dashoffset: 100; }} to {{ stroke-dashoffset: 0; }} }}
  .pad {{ animation: blink 3s ease-in-out infinite; }}
  @keyframes blink {{ 0%,70% {{ opacity: .35; }} 85% {{ opacity: 1; }} 100% {{ opacity: .35; }} }}
  .dot {{ animation: pop 3s ease-in-out infinite; transform-box: fill-box; transform-origin: center; }}
  @keyframes pop {{ 0%,100% {{ opacity: .75; }} 8% {{ opacity: 1; transform: translateY(-4px); }} 16% {{ transform: translateY(0); }} }}
  .chip {{ animation: float 6s ease-in-out infinite; }}
  @keyframes float {{ 0%,100% {{ transform: translateY(0); }} 50% {{ transform: translateY(-8px); }} }}
  .fade {{ animation: in 1s ease-out both; }}
  .d1 {{ animation-delay: .15s; }} .d2 {{ animation-delay: .3s; }} .d3 {{ animation-delay: .45s; }}
  @keyframes in {{ from {{ opacity: 0; transform: translateY(10px); }} to {{ opacity: 1; transform: none; }} }}
  .caret {{ animation: caret 1.1s steps(1) infinite; }}
  @keyframes caret {{ 50% {{ opacity: 0; }} }}
  @media (prefers-reduced-motion: reduce) {{ * {{ animation: none !important; }} }}
</style>
{bg(W, H)}
<defs>
  <radialGradient id="glow"><stop offset="0" stop-color="#5A70FF" stop-opacity=".45"/><stop offset="1" stop-color="#5A70FF" stop-opacity="0"/></radialGradient>
  <linearGradient id="top" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2A2F45"/><stop offset="1" stop-color="#14172A"/></linearGradient>
  <linearGradient id="title" x1="0" x2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#9DB0FF"/></linearGradient>
</defs>
<ellipse cx="870" cy="250" rx="330" ry="190" fill="url(#glow)"/>
{''.join(traces)}
<g class="chip">
  {''.join(back)}
  {poly(right, fill="#0E1020")}
  {poly(left, fill="#171A2E")}
  {poly(top, fill="url(#top)", stroke="#3A4270", stroke_width="1")}
  <circle cx="{dot[0]:.1f}" cy="{dot[1]:.1f}" r="6" fill="#0B0E1C" stroke="#3A4270"/>
  <text x="0" y="0" text-anchor="middle" font-size="15" font-weight="700" fill="#C9D1E8" fill-opacity=".55" letter-spacing="2" {MONO} transform="matrix(.866 .5 -.866 .5 {label[0]:.1f} {label[1]:.1f})">MSP430F149</text>
  {''.join(front)}
  {''.join(dots)}
</g>

<g {FONT}>
  <g class="fade"><rect x="64" y="70" width="210" height="30" rx="15" fill="#5A70FF" fill-opacity=".16" stroke="#8FA2FF" stroke-opacity=".4"/>
  <circle cx="84" cy="85" r="5" fill="{GREEN}"><animate attributeName="opacity" values="1;.3;1" dur="1.6s" repeatCount="indefinite"/></circle>
  <text x="98" y="90" font-size="14" fill="{SOFT}" font-weight="600">TI MSP430F149 · 16-bit RISC</text></g>
  <text class="fade d1" x="62" y="168" font-size="64" font-weight="800" fill="url(#title)" letter-spacing="-1">MSP430 Lab</text>
  <text class="fade d2" x="64" y="214" font-size="22" fill="{SOFT}">Turn the chip in 3D. Open twelve topics.</text>
  <text class="fade d2" x="64" y="244" font-size="22" fill="{SOFT}">Flip the bits yourself.</text>
  <g class="fade d3" {MONO} font-size="15">
    <rect x="64" y="284" width="380" height="44" rx="10" fill="#0B0E1C" fill-opacity=".7" stroke="#3A4270"/>
    <text x="84" y="311" fill="{DIM}">$</text>
    <text x="102" y="311" fill="{INK}">flutter run -d windows</text>
    <rect class="caret" x="300" y="297" width="9" height="18" fill="#9DB0FF"/>
  </g>
  <g class="fade d3" font-size="13" font-weight="600">
    <rect x="64" y="352" width="104" height="28" rx="14" fill="{BLUE}" fill-opacity=".2" stroke="{BLUE}"/><text x="116" y="371" text-anchor="middle" fill="{INK}">Architecture</text>
    <rect x="178" y="352" width="140" height="28" rx="14" fill="{GREEN}" fill-opacity=".2" stroke="{GREEN}"/><text x="248" y="371" text-anchor="middle" fill="{INK}">Peripherals &amp; timing</text>
    <rect x="328" y="352" width="168" height="28" rx="14" fill="{ORANGE}" fill-opacity=".2" stroke="{ORANGE}"/><text x="412" y="371" text-anchor="middle" fill="{INK}">Analog &amp; communication</text>
  </g>
</g>
</svg>
"""
    (OUT / "hero.svg").write_text(svg, encoding="utf-8")


# ───────────────────────────── topics: the twelve labs as cards

TOPICS = [
    # (part, number, English, Arabic, what the scene does, icon)
    (0, "1.1", "Architecture", "بنية MSP430", "The die, its 12 blocks, the MAB and MDB buses", "arch"),
    (0, "1.2", "Memory map", "تنظيم الذاكرة", "Address space as a tower, 0x0000 at the bottom", "mem"),
    (0, "1.3", "Registers", "المسجلات", "R0–R15 as 16×16 bits running 5+4+3+2+1", "reg"),
    (0, "1.4", "Addressing modes", "أنماط العنونة", "Where the operand comes from, in all seven", "addr"),
    (1, "2.1", "Pinout", "مخطط الأطراف", "All 64 pins, coloured by port", "pins"),
    (1, "2.2", "GPIO", "الدخل والخرج العام", "LED on P1.0, button on P1.1, P1DIR/OUT/IN", "gpio"),
    (1, "2.3", "Clock system", "نظام الساعة", "Three sources, three clocks, low-power modes", "clock"),
    (1, "2.4", "Timer_A & PWM", "المؤقتات", "Count to TACCR0, reset at TACCR1, motor speed", "timer"),
    (2, "3.1", "Pros & cons", "المزايا والعيوب", "Green and red balls orbiting the chip", "pros"),
    (2, "3.2", "12-bit ADC", "المحول ADC", "A potentiometer filling a column to 4095", "adc"),
    (2, "3.3", "UART · SPI · I²C", "واجهات الاتصال", "A byte sent bit by bit on the wires", "comm"),
    (2, "3.4", "Interrupts", "المقاطعات", "PC and SR on the stack, vector, RETI", "irq"),
]
PARTS = [("Part 1 · Architecture", "المعمارية", BLUE),
         ("Part 2 · Pins & timing", "الأطراف والتوقيت", GREEN),
         ("Part 3 · ADC & comms", "التحليل والاتصال", ORANGE)]


def icon(kind, c):
    import re
    raw = _icon(kind, c)
    # an element with its own fill drops the shared fill="none"
    return re.sub(r'<(\w+)([^<>]*?) fill="(?!none)[^"]*"([^<>]*?) fill="none"', lambda m: m.group(0).replace(' fill="none"', ''), raw)


def _icon(kind, c):
    s = f'stroke="{c}" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"'
    return {
        "arch": f'<rect x="4" y="4" width="24" height="24" rx="3" {s}/><rect x="10" y="10" width="12" height="12" rx="1" fill="{c}" fill-opacity=".3" {s}/><path d="M10 4V0M16 4V0M22 4V0M10 32v-4M16 32v-4M22 32v-4" {s}/>',
        "mem": f'<rect x="6" y="2" width="20" height="7" rx="1.5" {s}/><rect x="6" y="12" width="20" height="7" rx="1.5" {s}/><rect x="6" y="22" width="20" height="7" rx="1.5" fill="{c}" fill-opacity=".35" {s}/>',
        "reg": f'<path d="M4 6h24M4 12h24M4 18h24M4 24h24M10 3v24M16 3v24M22 3v24" {s}/><rect x="16" y="12" width="6" height="6" fill="{c}"/>',
        "addr": f'<path d="M4 16h10M18 16h10M22 10l6 6-6 6" {s}/><circle cx="16" cy="16" r="3" fill="{c}"/><path d="M8 6l4 4M8 26l4-4" {s}/>',
        "pins": f'<rect x="8" y="8" width="16" height="16" rx="2" {s}/><path d="M12 8V3M16 8V3M20 8V3M12 29v-5M16 29v-5M20 29v-5M8 12H3M8 16H3M8 20H3M29 12h-5M29 16h-5M29 20h-5" {s}/>',
        "gpio": f'<circle cx="10" cy="12" r="6" fill="{c}" fill-opacity=".35" {s}><animate attributeName="fill-opacity" values=".1;.9;.1" dur="1.4s" repeatCount="indefinite"/></circle><path d="M10 18v8M22 6v6M18 12h8M22 26v-8" {s}/><rect x="17" y="18" width="10" height="6" rx="2" {s}/>',
        "clock": f'<circle cx="16" cy="16" r="12" {s}/><path d="M16 9v7l5 3" {s}><animateTransform attributeName="transform" type="rotate" from="0 16 16" to="360 16 16" dur="6s" repeatCount="indefinite"/></path>',
        "timer": f'<path d="M3 24V8h6v16h4V8h10v16h6" {s}/>',
        "pros": f'<circle cx="16" cy="16" r="5" {s}/><circle cx="6" cy="8" r="3" fill="{GREEN}"/><circle cx="27" cy="11" r="3" fill="#E5484D"/><circle cx="10" cy="27" r="3" fill="#E5484D"/><circle cx="25" cy="26" r="3" fill="{GREEN}"/>',
        "adc": f'<path d="M3 20c4-10 8-10 12 0s8 10 14-4" {s}/><rect x="24" y="4" width="5" height="24" rx="1" {s}/><rect x="24" y="14" width="5" height="14" fill="{c}"><animate attributeName="y" values="24;8;24" dur="3s" repeatCount="indefinite"/><animate attributeName="height" values="4;20;4" dur="3s" repeatCount="indefinite"/></rect>',
        "comm": f'<path d="M3 10h4v-4h4v4h4v-4h4v4h4v-4h4M3 24h26" {s}/><circle cx="3" cy="24" r="2.5" fill="{c}"><animate attributeName="cx" values="3;29;3" dur="2.4s" repeatCount="indefinite"/></circle>',
        "irq": f'<path d="M18 2L6 18h9l-2 12 13-17h-9z" fill="{c}" fill-opacity=".3" {s}/>',
    }[kind]


def topics():
    W, colw, gap, cardh = 1200, 360, 30, 96
    x0 = (W - 3 * colw - 2 * gap) // 2
    H = 120 + 4 * (cardh + 16) + 40
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-label="The twelve topics, in three parts">',
           """<style>
  .card { animation: up .7s cubic-bezier(.2,.8,.2,1) both; }
  @keyframes up { from { opacity: 0; transform: translateY(14px); } to { opacity: 1; transform: none; } }
  .bar { animation: grow 1.2s cubic-bezier(.2,.8,.2,1) both; transform-box: fill-box; transform-origin: left; }
  @keyframes grow { from { transform: scaleX(0); } }
  @media (prefers-reduced-motion: reduce) { * { animation: none !important; } }
</style>""", bg(W, H, "tbg"), f'<g {FONT}>']
    for p, (name, ar, c) in enumerate(PARTS):
        x = x0 + p * (colw + gap)
        out.append(f'<text x="{x}" y="58" font-size="18" font-weight="700" fill="{INK}">{name.replace("&", "&amp;")}</text>')
        out.append(f'<text x="{x + colw}" y="58" font-size="16" fill="{c}" text-anchor="start" direction="rtl">{ar}</text>')
        out.append(f'<rect class="bar" style="animation-delay:{p * .15:.2f}s" x="{x}" y="72" width="{colw}" height="4" rx="2" fill="{c}"/>')
        for i in range(4):
            t = TOPICS[p * 4 + i]
            y = 100 + i * (cardh + 16)
            d = (p * 4 + i) * 0.08
            out.append(f'''<g class="card" style="animation-delay:{d:.2f}s">
  <rect x="{x}" y="{y}" width="{colw}" height="{cardh}" rx="14" fill="#1A2045" stroke="{c}" stroke-opacity=".45"/>
  <rect x="{x}" y="{y}" width="5" height="{cardh}" rx="2.5" fill="{c}"/>
  <text x="{x + 24}" y="{y + 32}" font-size="12" font-weight="700" fill="{c}" {MONO}>{t[1]}</text>
  <text x="{x + colw - 16}" y="{y + 32}" font-size="13" fill="{SOFT}" text-anchor="start" direction="rtl">{t[3]}</text>
  <text x="{x + 24}" y="{y + 56}" font-size="18" font-weight="700" fill="{INK}">{t[2].replace("&", "&amp;")}</text>
  <text x="{x + 24}" y="{y + 78}" font-size="12.5" fill="{SOFT}">{t[4]}</text>
</g>''')
    out.append("</g></svg>")
    (OUT / "topics.svg").write_text("\n".join(out), encoding="utf-8")


# ───────────────────────────── how a topic is drawn

def pipeline():
    W, H = 1200, 300
    boxes = [
        ("Topic data", "topics_local_datasource.dart", "theory · tour · book page", BLUE),
        ("Lab", "presentation/labs/*_lab.dart", "builds the scene each tick", GREEN),
        ("Scene3D", "core/scene3d/", "orbit camera · painter · hit test", ORANGE),
        ("Topic screen", "topic_screen.dart", "tour bar · try-it controls", "#9DB0FF"),
    ]
    bw, gap = 240, 46
    x0 = (W - 4 * bw - 3 * gap) // 2
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-label="How a topic is drawn: data, lab, 3D scene, screen">',
           """<style>
  .flow { stroke-dasharray: 6 8; animation: flow 1s linear infinite; }
  @keyframes flow { to { stroke-dashoffset: -14; } }
  .pkt { animation: hop 4s cubic-bezier(.6,0,.4,1) infinite; }
  @keyframes hop { 0% { transform: translateX(0); opacity: 0; } 5% { opacity: 1; } 95% { opacity: 1; } 100% { transform: translateX(858px); opacity: 0; } }
  .box { animation: up .7s ease-out both; }
  @keyframes up { from { opacity: 0; transform: translateY(12px); } }
  @media (prefers-reduced-motion: reduce) { * { animation: none !important; } }
</style>""", bg(W, H, "pbg"), f'<g {FONT}>',
           f'<text x="{W // 2}" y="52" text-anchor="middle" font-size="20" font-weight="700" fill="{INK}">How a topic is drawn</text>',
           f'<text x="{W // 2}" y="78" text-anchor="middle" font-size="14" fill="{SOFT}">Pure Dart and CustomPainter — no game engine, no network. Everything ships with the app.</text>']
    cy = 170
    for i, (t, f, s, c) in enumerate(boxes):
        x = x0 + i * (bw + gap)
        if i:
            out.append(f'<path class="flow" d="M{x - gap + 4} {cy} H{x - 6}" stroke="{SOFT}" stroke-width="2"/>'
                       f'<path d="M{x - 12} {cy - 6} L{x - 4} {cy} L{x - 12} {cy + 6}" fill="none" stroke="{SOFT}" stroke-width="2"/>')
        out.append(f'''<g class="box" style="animation-delay:{i * .15:.2f}s">
  <rect x="{x}" y="{cy - 56}" width="{bw}" height="112" rx="16" fill="#1A2045" stroke="{c}" stroke-opacity=".6"/>
  <circle cx="{x + 26}" cy="{cy - 28}" r="12" fill="{c}" fill-opacity=".2" stroke="{c}"/>
  <text x="{x + 26}" y="{cy - 23.5}" text-anchor="middle" font-size="12" font-weight="700" fill="{c}">{i + 1}</text>
  <text x="{x + 46}" y="{cy - 22}" font-size="18" font-weight="700" fill="{INK}">{t}</text>
  <text x="{x + 18}" y="{cy + 10}" font-size="12" fill="{c}" {MONO}>{f}</text>
  <text x="{x + 18}" y="{cy + 34}" font-size="13" fill="{SOFT}">{s}</text>
</g>''')
    out.append(f'<circle class="pkt" cx="{x0 + bw - 4}" cy="{cy}" r="5" fill="#fff"/>')
    out.append(f'<text x="{W // 2}" y="{H - 30}" text-anchor="middle" font-size="13" fill="{DIM}">A Ticker advances the lab and the camera every frame; the painter projects each shape and keeps a hit list for taps.</text>')
    out.append("</g></svg>")
    (OUT / "pipeline.svg").write_text("\n".join(out), encoding="utf-8")


# ───────────────────────────── controls: keys and gestures

def key(x, y, w, label, sub, delay):
    return f'''<g class="key" style="animation-delay:{delay}s">
  <rect x="{x}" y="{y + 4}" width="{w}" height="52" rx="10" fill="#070914"/>
  <rect class="cap" style="animation-delay:{delay}s" x="{x}" y="{y}" width="{w}" height="52" rx="10" fill="#232A55" stroke="#4A5596"/>
  <text x="{x + w / 2}" y="{y + 33}" text-anchor="middle" font-size="18" font-weight="700" fill="{INK}">{label}</text>
  <text x="{x + w / 2}" y="{y + 82}" text-anchor="middle" font-size="13" fill="{SOFT}">{sub}</text>
</g>'''


def controls():
    W, H = 1200, 330
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-label="Keyboard shortcuts and gestures">',
           """<style>
  .cap { animation: press 6s ease-in-out infinite; }
  @keyframes press { 0%,8%,100% { transform: translateY(0); fill: #232A55; } 4% { transform: translateY(4px); fill: #3B4A9A; } }
  .drag { animation: drag 3s ease-in-out infinite; }
  @keyframes drag { 0%,100% { transform: translateX(-28px); } 50% { transform: translateX(28px); } }
  .spin { animation: spin 3s ease-in-out infinite; transform-box: fill-box; transform-origin: center; }
  @keyframes spin { 0%,100% { transform: rotate(-25deg); } 50% { transform: rotate(25deg); } }
  .wheel { animation: wheel 1.2s ease-in-out infinite; }
  @keyframes wheel { 0% { transform: translateY(-4px); opacity: 1; } 100% { transform: translateY(6px); opacity: 0; } }
  .pinch1 { animation: p1 2.4s ease-in-out infinite; } .pinch2 { animation: p2 2.4s ease-in-out infinite; }
  @keyframes p1 { 50% { transform: translate(-12px,-12px); } } @keyframes p2 { 50% { transform: translate(12px,12px); } }
  .ring { animation: ring 2.4s ease-out infinite; transform-box: fill-box; transform-origin: center; }
  @keyframes ring { 0% { transform: scale(.4); opacity: .9; } 100% { transform: scale(1.6); opacity: 0; } }
  @media (prefers-reduced-motion: reduce) { * { animation: none !important; } }
</style>""", bg(W, H, "cbg"), f'<g {FONT}>',
           f'<text x="64" y="56" font-size="20" font-weight="700" fill="{INK}">Keyboard</text>',
           f'<text x="700" y="56" font-size="20" font-weight="700" fill="{INK}">Mouse, touchpad, touch</text>']
    ks = [("←", "next", 64), ("→", "previous", 146), ("Space", "play tour", 228), ("Esc", "back", 360), ("R", "reset camera", 442)]
    for i, (l, s, x) in enumerate(ks):
        out.append(key(x, 90, 120 if l == "Space" else 70, l, s, i * 1.2))
    out.append(f'<text x="64" y="250" font-size="13" fill="{DIM}">Arrows follow reading direction: the app is Arabic first (RTL).</text>')
    out.append(f'<text x="64" y="272" font-size="13" fill="{DIM}">PageUp / PageDown work too.</text>')

    # gestures
    g = [
        (720, "Drag", "turn the chip",
         f'<g class="drag"><circle cx="0" cy="0" r="10" fill="#9DB0FF"/><circle cx="0" cy="0" r="18" fill="none" stroke="#9DB0FF" stroke-opacity=".4"/></g>'
         f'<path d="M-40 0h-14l5-5m-5 5l5 5M40 0h14l-5-5m5 5l-5 5" stroke="{SOFT}" stroke-width="2" fill="none"/>'),
        (880, "Wheel · pinch", "zoom in and out",
         f'<rect x="-16" y="-26" width="32" height="52" rx="16" fill="none" stroke="{SOFT}" stroke-width="2"/>'
         f'<rect class="wheel" x="-3" y="-16" width="6" height="12" rx="3" fill="#9DB0FF"/>'
         f'<g transform="translate(46 0)"><circle class="pinch1" cx="-6" cy="-6" r="6" fill="{GREEN}"/><circle class="pinch2" cx="6" cy="6" r="6" fill="{GREEN}"/></g>'),
        (1050, "Tap", "a part: name + topic",
         f'<circle class="ring" cx="0" cy="0" r="22" fill="none" stroke="{ORANGE}" stroke-width="2"/><circle cx="0" cy="0" r="8" fill="{ORANGE}"/>'),
    ]
    for x, t, s, art in g:
        out.append(f'<rect x="{x - 70}" y="84" width="140" height="120" rx="16" fill="#1A2045" stroke="#3A4270"/>')
        out.append(f'<g transform="translate({x} 144)">{art}</g>')
        out.append(f'<text x="{x}" y="236" text-anchor="middle" font-size="16" font-weight="700" fill="{INK}">{t}</text>')
        out.append(f'<text x="{x}" y="258" text-anchor="middle" font-size="13" fill="{SOFT}">{s}</text>')
    out.append("</g></svg>")
    (OUT / "controls.svg").write_text("\n".join(out), encoding="utf-8")


# ───────────────────────────── the Windows installer, step by step

def installer():
    W, H = 1200, 250
    steps = [("flutter build windows", "Release folder", BLUE),
             ("write msp430_lab.iss", "Inno Setup script", GREEN),
             ("ISCC.exe", "compile + LZMA2", ORANGE),
             ("setup.exe", "wizard · Start menu · uninstaller", "#9DB0FF")]
    bw, gap = 250, 36
    x0 = (W - 4 * bw - 3 * gap) // 2
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-label="Building the Windows installer">',
           """<style>
  .fill { animation: fill 8s cubic-bezier(.4,0,.2,1) infinite; transform-box: fill-box; transform-origin: left; }
  @keyframes fill { 0% { transform: scaleX(0); } 85%,100% { transform: scaleX(1); } }
  .tick { opacity: 0; animation: tick 8s steps(1) infinite; }
  @keyframes tick { 0% { opacity: 0; } 85% { opacity: 1; } }
  @media (prefers-reduced-motion: reduce) { * { animation: none !important; } .tick { opacity: 1; } }
</style>""", bg(W, H, "ibg"), f'<g {FONT}>',
           f'<rect x="{x0}" y="36" width="{4 * bw + 3 * gap}" height="44" rx="10" fill="#0B0E1C" fill-opacity=".7" stroke="#3A4270"/>',
           f'<text x="{x0 + 20}" y="64" font-size="15" fill="{DIM}" {MONO}>$</text>',
           f'<text x="{x0 + 38}" y="64" font-size="15" fill="{INK}" {MONO}>dart run tool/build_windows_installer.dart</text>']
    for i, (cmd, sub, c) in enumerate(steps):
        x = x0 + i * (bw + gap)
        out.append(f'''<rect x="{x}" y="104" width="{bw}" height="90" rx="14" fill="#1A2045" stroke="{c}" stroke-opacity=".5"/>
<text x="{x + 18}" y="136" font-size="15" font-weight="700" fill="{INK}" {MONO}>{cmd}</text>
<text x="{x + 18}" y="160" font-size="13" fill="{SOFT}">{sub}</text>
<rect x="{x + 18}" y="174" width="{bw - 36}" height="6" rx="3" fill="#0B0E1C"/>
<rect class="fill" style="animation-delay:{i * 2}s" x="{x + 18}" y="174" width="{bw - 36}" height="6" rx="3" fill="{c}"/>
<g class="tick" style="animation-delay:{i * 2}s"><circle cx="{x + bw - 24}" cy="130" r="10" fill="{c}"/><path d="M{x + bw - 29} 130l4 4 7-8" stroke="#0B0E1C" stroke-width="2.4" fill="none" stroke-linecap="round"/></g>''')
        if i:
            out.append(f'<path d="M{x - gap + 8} 149h{gap - 16}m-6-6l6 6-6 6" stroke="{SOFT}" stroke-width="2" fill="none"/>')
    out.append(f'<text x="{W // 2}" y="226" text-anchor="middle" font-size="13" fill="{DIM}">→ build/installer/msp430_lab-&lt;version&gt;-setup.exe</text>')
    out.append("</g></svg>")
    (OUT / "installer.svg").write_text("\n".join(out), encoding="utf-8")


hero(); topics(); pipeline(); controls(); installer()
print("ok", sorted(p.name for p in OUT.iterdir()))
