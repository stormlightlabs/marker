import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { APIRoute } from 'astro';
import { Resvg } from '@resvg/resvg-js';

const width = 1200;
const height = 630;

const colors = {
  ink: '#111111',
  inkSoft: '#42413d',
  inkMuted: '#77736b',
  surface: '#ffffff',
  raised: '#f6f5f0',
  highlight: '#ffd85a',
  accent: '#2d6cdf',
};

type Rect = { x: number; y: number; w: number; h: number };
type Point = [number, number];

type RoughStrokeOptions = { seed: number; roughness?: number; bowing?: number; passes?: number };

const loraFontPath = join(process.cwd(), 'public', 'fonts', 'lora.ttf');
const soraFontPath = join(process.cwd(), 'public', 'fonts', 'sora.ttf');

function fontDataUri(fileName: string) {
  const font = readFileSync(join(process.cwd(), 'public', 'fonts', fileName));
  return `data:font/ttf;base64,${font.toString('base64')}`;
}

const loraFont = fontDataUri('lora.ttf');
const soraFont = fontDataUri('sora.ttf');

function escapeHtml(value: string) {
  return value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}

function seeded(seed: number) {
  let state = seed >>> 0;
  return () => {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 0xffffffff;
  };
}

function jitter(value: number, amount: number, rand: () => number) {
  return value + (rand() - 0.5) * amount * 2;
}

function roughLine([x1, y1]: Point, [x2, y2]: Point, options: RoughStrokeOptions) {
  const roughness = options.roughness ?? 2;
  const bowing = options.bowing ?? 1;
  const passes = options.passes ?? 2;
  const rand = seeded(options.seed);
  const length = Math.hypot(x2 - x1, y2 - y1);
  const offset = Math.min(roughness * 2.4, length * 0.06);
  const paths: string[] = [];

  for (let i = 0; i < passes; i += 1) {
    const midX = (x1 + x2) / 2;
    const midY = (y1 + y2) / 2;
    const controlDrift = Math.min(28, length * 0.08) * bowing;
    const c1x = jitter(midX, controlDrift, rand);
    const c1y = jitter(midY, controlDrift, rand);
    paths.push(
      `M${jitter(x1, offset, rand).toFixed(1)} ${jitter(y1, offset, rand).toFixed(1)} ` +
        `Q${c1x.toFixed(1)} ${c1y.toFixed(1)} ${jitter(x2, offset, rand).toFixed(1)} ${jitter(y2, offset, rand).toFixed(1)}`,
    );
  }

  return paths;
}

function roughRectangle(rect: Rect, options: RoughStrokeOptions) {
  const { x, y, w, h } = rect;
  return [
    ...roughLine([x, y], [x + w, y], { ...options, seed: options.seed + 1 }),
    ...roughLine([x + w, y], [x + w, y + h], { ...options, seed: options.seed + 2 }),
    ...roughLine([x + w, y + h], [x, y + h], { ...options, seed: options.seed + 3 }),
    ...roughLine([x, y + h], [x, y], { ...options, seed: options.seed + 4 }),
  ];
}

function roughEllipse(cx: number, cy: number, rx: number, ry: number, options: RoughStrokeOptions) {
  const rand = seeded(options.seed);
  const paths: string[] = [];
  const passes = options.passes ?? 2;
  for (let i = 0; i < passes; i += 1) {
    const k = 0.5522847498;
    const ox = rx * k;
    const oy = ry * k;
    const n = (value: number) => jitter(value, options.roughness ?? 2, rand).toFixed(1);
    paths.push(
      `M${n(cx - rx)} ${n(cy)} ` +
        `C${n(cx - rx)} ${n(cy - oy)} ${n(cx - ox)} ${n(cy - ry)} ${n(cx)} ${n(cy - ry)} ` +
        `C${n(cx + ox)} ${n(cy - ry)} ${n(cx + rx)} ${n(cy - oy)} ${n(cx + rx)} ${n(cy)} ` +
        `C${n(cx + rx)} ${n(cy + oy)} ${n(cx + ox)} ${n(cy + ry)} ${n(cx)} ${n(cy + ry)} ` +
        `C${n(cx - ox)} ${n(cy + ry)} ${n(cx - rx)} ${n(cy + oy)} ${n(cx - rx)} ${n(cy)}`,
    );
  }
  return paths;
}

function roughHighlight(rect: Rect, options: RoughStrokeOptions) {
  const y = rect.y + rect.h / 2;
  const paths: string[] = [];
  const iterations = options.passes ?? 2;
  for (let i = 0; i < iterations; i += 1) {
    const forward = i % 2 === 0;
    paths.push(
      ...roughLine(forward ? [rect.x, y] : [rect.x + rect.w, y], forward ? [rect.x + rect.w, y] : [rect.x, y], {
        ...options,
        seed: options.seed + i * 13,
        passes: 1,
        roughness: options.roughness ?? 5,
        bowing: 1.2,
      }),
    );
  }
  return paths;
}

function pathsMarkup(paths: string[], color: string, strokeWidth: number, extra = '') {
  return paths
    .map(
      (d) =>
        `<path d="${d}" fill="none" stroke="${color}" stroke-width="${strokeWidth}" stroke-linecap="round" stroke-linejoin="round" ${extra}/>`,
    )
    .join('\n');
}

function renderOgSvg() {
  const copy = escapeHtml('A mobile browser for reading and thinking.');
  const site = escapeHtml('marker.stormlightlabs.org');

  const intentionHighlight = roughHighlight({ x: 130, y: 318, w: 472, h: 104 }, { seed: 442, passes: 3, roughness: 7 });
  const cardBox = roughRectangle({ x: 74, y: 66, w: 1052, h: 498 }, { seed: 1301, passes: 2, roughness: 2.2 });
  const siteCircle = roughEllipse(273, 532, 180, 35, { seed: 901, passes: 2, roughness: 3.1 });

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      @font-face {
        font-family: 'MarkerLora';
        src: url('${loraFont}') format('truetype');
        font-weight: 400 700;
      }
      @font-face {
        font-family: 'MarkerSora';
        src: url('${soraFont}') format('truetype');
        font-weight: 100 800;
      }
    </style>
    <pattern id="minor-grid" width="12" height="12" patternUnits="userSpaceOnUse">
      <rect width="12" height="12" fill="${colors.surface}"/>
      <path d="M12 0H0V12" fill="none" stroke="#111111" stroke-opacity="0.035" stroke-width="1"/>
    </pattern>
    <pattern id="major-grid" width="96" height="96" patternUnits="userSpaceOnUse">
      <rect width="96" height="96" fill="url(#minor-grid)"/>
      <path d="M96 0H0V96" fill="none" stroke="#111111" stroke-opacity="0.07" stroke-width="1.2"/>
    </pattern>
  </defs>

  <rect width="1200" height="630" fill="url(#major-grid)"/>

  <rect x="74" y="66" width="1052" height="498" rx="28" fill="${colors.raised}" opacity="0.9"/>
  ${pathsMarkup(cardBox, colors.ink, 2, 'opacity="0.25"')}

  <text x="116" y="124" fill="${colors.inkMuted}" font-family="Sora, sans-serif" font-size="22" font-weight="650" letter-spacing="0">github.com/stormlightlabs/marker</text>

  <text x="112" y="286" fill="${colors.ink}" font-family="Lora, serif" font-size="104" font-weight="650" letter-spacing="-1.5">Read with</text>
  ${pathsMarkup(intentionHighlight, colors.highlight, 78, 'opacity="0.82"')}
  <text x="112" y="410" fill="${colors.ink}" font-family="Lora, serif" font-size="104" font-weight="650" letter-spacing="-1.5">intention.</text>

  <text x="116" y="486" fill="${colors.inkSoft}" font-family="Sora, sans-serif" font-size="34" font-weight="430">${copy}</text>
  ${pathsMarkup(siteCircle, colors.accent, 4)}
  <text x="116" y="540" fill="${colors.ink}" font-family="Sora, sans-serif" font-size="24" font-weight="600">${site}</text>
</svg>`;
}

export const GET: APIRoute = async () => {
  const renderer = new Resvg(renderOgSvg(), {
    fitTo: { mode: 'width', value: width },
    font: { fontFiles: [loraFontPath, soraFontPath], loadSystemFonts: false },
  });
  const png = renderer.render().asPng();

  return new Response(new Uint8Array(png), {
    headers: { 'Content-Type': 'image/png', 'Cache-Control': 'public, max-age=31536000, immutable' },
  });
};

export function getStaticPaths() {
  return [{}];
}

export const prerender = true;
