// Renderiza los diagramas de la Fase II a PNG con la identidad de Cupo.
// Requiere Microsoft Edge y `npm install` en esta carpeta. Desde PowerShell:
//   node render.mjs ../diagramas ../diagramas/png [archivo.mmd]
// Uso: node render.mjs <carpeta-fuentes> <carpeta-salida> [archivo...]
//   *.mmd  -> Mermaid (tema base con los tokens de CLAUDE.md)
//   *.json -> diagrama de casos de uso UML dibujado a mano en SVG
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer-core';

const here = path.dirname(fileURLToPath(import.meta.url));
const [, , srcDir, outDir, ...only] = process.argv;
fs.mkdirSync(outDir, { recursive: true });

const EDGE = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
const MERMAID = path.join(here, 'node_modules/mermaid/dist/mermaid.min.js');

const C = {
  primary: '#007C8A', primaryDeep: '#005F6C', primaryDarkest: '#003D4B',
  primarySoft: '#E7F4F5', ink: '#1C2224', textSecondary: '#5F6A6C',
  textSupport: '#798487', border: '#DDE0E0', background: '#F9FCFC',
  backgroundAlt: '#F6F9F9', backgroundMuted: '#E3EEEE', surface: '#FFFFFF',
  warning: '#C98A00', warningSoft: '#FFEAC2',
};

const mermaidConfig = {
  startOnLoad: false,
  theme: 'base',
  fontFamily: 'Manrope, sans-serif',
  themeVariables: {
    fontFamily: 'Manrope, sans-serif', fontSize: '15px',
    primaryColor: C.primarySoft, primaryTextColor: C.ink, primaryBorderColor: C.primary,
    secondaryColor: C.backgroundMuted, tertiaryColor: C.background,
    lineColor: C.textSecondary, background: C.surface, mainBkg: C.primarySoft,
    nodeBorder: C.primary, clusterBkg: C.background, clusterBorder: C.border,
    titleColor: C.primaryDarkest, edgeLabelBackground: C.surface,
    actorBkg: C.primarySoft, actorBorder: C.primary, actorTextColor: C.ink,
    actorLineColor: C.textSupport, signalColor: C.ink, signalTextColor: C.ink,
    labelBoxBkgColor: C.backgroundMuted, labelBoxBorderColor: C.primary,
    labelTextColor: C.ink, loopTextColor: C.ink,
    noteBkgColor: C.warningSoft, noteBorderColor: C.warning, noteTextColor: C.ink,
    activationBkgColor: C.primarySoft, activationBorderColor: C.primary,
    sequenceNumberColor: C.surface,
    attributeBackgroundColorOdd: C.surface, attributeBackgroundColorEven: C.backgroundAlt,
  },
  flowchart: { useMaxWidth: false, htmlLabels: true, curve: 'basis', padding: 12 },
  sequence: { useMaxWidth: false, mirrorActors: false, actorMargin: 60, messageMargin: 36 },
  er: { useMaxWidth: false },
  class: { useMaxWidth: false },
  state: { useMaxWidth: false },
};

const html = `<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Teko:wght@500;600&display=block" rel="stylesheet">
<style>
  body { margin: 0; background: ${C.surface}; font-family: Manrope, sans-serif; }
  #lienzo { display: inline-block; padding: 28px; background: ${C.surface}; }
</style></head><body><div id="lienzo"></div></body></html>`;

// Casos de uso: actor a la izquierda, límite del sistema, elipses apiladas.
function dibujarCasosDeUso(spec, C) {
  const NS = 'http://www.w3.org/2000/svg';
  const medir = document.createElementNS(NS, 'svg');
  document.body.appendChild(medir);
  const ancho = (txt, peso, tam) => {
    const t = document.createElementNS(NS, 'text');
    t.setAttribute('font-family', 'Manrope'); t.setAttribute('font-weight', peso);
    t.setAttribute('font-size', tam); t.textContent = txt; medir.appendChild(t);
    const w = t.getComputedTextLength(); t.remove(); return w;
  };
  const ry = 24, gap = 14, padX = 30, top = 70;
  const rxs = spec.casos.map((c) => ancho(c, 500, 15) / 2 + 30);
  const maxRx = Math.max(...rxs);
  const bx = 220, bw = maxRx * 2 + padX * 2;
  const bh = top + spec.casos.length * (2 * ry + gap) + 10;
  const W = bx + bw + 20, H = bh + 20;
  const cx = bx + bw / 2;
  const actorY = H / 2 - 30;
  let s = `<svg xmlns="${NS}" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">`;
  s += `<rect x="${bx}" y="10" width="${bw}" height="${bh}" rx="12" fill="${C.background}" stroke="${C.border}" stroke-width="1.5"/>`;
  s += `<text x="${cx}" y="50" text-anchor="middle" font-family="Teko" font-weight="600" font-size="28" fill="${C.primaryDarkest}">${spec.sistema}</text>`;
  const ax = 90, hand = actorY + 34;
  spec.casos.forEach((c, i) => {
    const cy = top + 10 + ry + i * (2 * ry + gap);
    s += `<line x1="${ax + 22}" y1="${hand}" x2="${cx - rxs[i]}" y2="${cy}" stroke="${C.textSupport}" stroke-width="1.3"/>`;
  });
  spec.casos.forEach((c, i) => {
    const cy = top + 10 + ry + i * (2 * ry + gap);
    s += `<ellipse cx="${cx}" cy="${cy}" rx="${rxs[i]}" ry="${ry}" fill="${C.primarySoft}" stroke="${C.primary}" stroke-width="1.5"/>`;
    s += `<text x="${cx}" y="${cy + 5}" text-anchor="middle" font-family="Manrope" font-weight="500" font-size="15" fill="${C.ink}">${c}</text>`;
  });
  const st = `stroke="${C.ink}" stroke-width="2.2" fill="none" stroke-linecap="round"`;
  s += `<circle cx="${ax}" cy="${actorY}" r="15" ${st} fill="${C.surface}"/>`;
  s += `<line x1="${ax}" y1="${actorY + 15}" x2="${ax}" y2="${actorY + 62}" ${st}/>`;
  s += `<line x1="${ax - 24}" y1="${actorY + 34}" x2="${ax + 24}" y2="${actorY + 34}" ${st}/>`;
  s += `<line x1="${ax}" y1="${actorY + 62}" x2="${ax - 20}" y2="${actorY + 96}" ${st}/>`;
  s += `<line x1="${ax}" y1="${actorY + 62}" x2="${ax + 20}" y2="${actorY + 96}" ${st}/>`;
  s += `<text x="${ax}" y="${actorY + 122}" text-anchor="middle" font-family="Manrope" font-weight="700" font-size="16" fill="${C.ink}">${spec.actor}</text>`;
  s += `</svg>`;
  medir.remove();
  return s;
}

const browser = await puppeteer.launch({ executablePath: EDGE, headless: true, userDataDir: path.join(here, 'perfiles', String(Date.now())), args: ['--no-first-run', '--no-default-browser-check', '--disable-extensions'] });
const page = await browser.newPage();
await page.setViewport({ width: 4000, height: 3000, deviceScaleFactor: 2.5 });
await page.setContent(html, { waitUntil: 'networkidle0' });
await page.addScriptTag({ path: MERMAID });
await page.evaluate(async () => {
  await Promise.all(['400 16px Manrope', '500 16px Manrope', '600 16px Manrope',
    '700 16px Manrope', '600 28px Teko'].map((f) => document.fonts.load(f)));
  await document.fonts.ready;
});
const cargadas = await page.evaluate(() => ({
  manrope: document.fonts.check('500 16px Manrope'),
  teko: document.fonts.check('600 28px Teko'),
}));
console.log('fuentes', JSON.stringify(cargadas));
await page.evaluate((cfg) => window.mermaid.initialize(cfg), mermaidConfig);

const archivos = fs.readdirSync(srcDir)
  .filter((f) => /\.(mmd|json)$/.test(f))
  .filter((f) => only.length === 0 || only.includes(f))
  .sort();

for (const f of archivos) {
  const texto = fs.readFileSync(path.join(srcDir, f), 'utf8');
  const salida = path.join(outDir, f.replace(/\.(mmd|json)$/, '.png'));
  try {
    if (f.endsWith('.json')) {
      await page.evaluate((spec, C, fn) => {
        const dibujar = new Function(`return (${fn})`)();
        document.getElementById('lienzo').innerHTML = dibujar(spec, C);
      }, JSON.parse(texto), C, dibujarCasosDeUso.toString());
    } else {
      await page.evaluate(async (code, id) => {
        const { svg } = await window.mermaid.render(id, code);
        document.getElementById('lienzo').innerHTML = svg;
      }, texto, 'd' + f.replace(/\W/g, ''));
    }
    const el = await page.$('#lienzo');
    await el.screenshot({ path: salida });
    console.log('ok', f);
  } catch (e) {
    console.log('ERROR', f, e.message.split('\n')[0]);
  }
}
await browser.close();
