// Render an Excalidraw diagram to .excalidraw.svg / .excalidraw.png with the
// scene embedded, so it previews as an image and reopens in Excalidraw.
//
//   render.mjs <input.json> <output.excalidraw.svg|png> [--new] [--preview out.png] [--theme auto|light|dark]
//   render.mjs --extract <file.excalidraw.svg|png|excalidraw>   (prints scene JSON)
//
// <input.json> is either an element skeleton ({ "elements": [...] }, see
// SKILL.md) or a full scene ({ "type": "excalidraw", ... }).
import { setAssetPath } from "./globals.mjs";

import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { inflateSync } from "node:zlib";

import { GlobalFonts, createCanvas, Image, Path2D } from "@napi-rs/canvas";
import {
  convertToExcalidrawElements,
  exportScene,
} from "@excalidraw/excalidraw";

const fail = (msg) => {
  console.error(`error: ${msg}`);
  process.exit(1);
};

// --- args --------------------------------------------------------------------

const args = process.argv.slice(2);
const flag = (name) => {
  const i = args.indexOf(name);
  if (i === -1) return undefined;
  const [, value] = args.splice(i, 2);
  return value;
};
const bool = (name) => {
  const i = args.indexOf(name);
  if (i !== -1) args.splice(i, 1);
  return i !== -1;
};
const extract = flag("--extract");
const out = flag("--out");
const preview = flag("--preview");
// auto (default): an SVG that is light, and switches to Excalidraw's dark look
// when the viewer prefers dark. PNGs can't switch, so auto renders them light.
const theme = flag("--theme") ?? "auto";
if (!["auto", "light", "dark"].includes(theme)) fail(`--theme must be auto, light or dark`);
const isNew = bool("--new");
let [input, output] = args;

// Create parent directories so callers never need a separate mkdir.
const ensureDir = (file) => mkdirSync(dirname(file), { recursive: true });

// --new: never overwrite; foo.excalidraw.svg -> foo-2.excalidraw.svg, -3, ...
const freeName = (file) => {
  const m = file.match(/^(.*?)((?:\.excalidraw)?\.(?:svg|png))$/);
  for (let n = 1; ; n++) {
    const f = n === 1 ? file : `${m[1]}-${n}${m[2]}`;
    if (!existsSync(f)) return f;
  }
};

// --- scene decoding (for --extract) -------------------------------------------

const decodeEncoded = (data) => {
  if (!("encoded" in data)) return data; // legacy, un-encoded scene
  const bytes = Buffer.from(data.encoded, "latin1");
  return JSON.parse((data.compressed ? inflateSync(bytes) : bytes).toString());
};

const readScene = (file) => {
  const buf = readFileSync(file);
  if (file.endsWith(".png")) {
    for (let o = 8; o < buf.length; ) {
      const len = buf.readUInt32BE(o);
      if (buf.toString("latin1", o + 4, o + 8) === "tEXt") {
        const chunk = buf.subarray(o + 8, o + 8 + len);
        const nul = chunk.indexOf(0);
        if (chunk.toString("latin1", 0, nul) === "application/vnd.excalidraw+json") {
          return decodeEncoded(JSON.parse(chunk.toString("latin1", nul + 1)));
        }
      }
      o += 12 + len;
    }
    fail(`${file} has no embedded Excalidraw scene`);
  }
  const text = buf.toString("utf8");
  if (file.endsWith(".svg")) {
    const m = text.match(/<!-- payload-start -->\s*(.+?)\s*<!-- payload-end -->/s);
    if (!m) fail(`${file} has no embedded Excalidraw scene`);
    const version = text.match(/<!-- payload-version:(\d+) -->/)?.[1] ?? "1";
    const json = Buffer.from(m[1], "base64").toString(version === "1" ? "utf8" : "latin1");
    return decodeEncoded(JSON.parse(json));
  }
  return JSON.parse(text);
};

if (extract) {
  const json = JSON.stringify(readScene(extract), null, 2) + "\n";
  if (out) {
    ensureDir(out);
    writeFileSync(out, json);
    console.log(out);
  } else {
    process.stdout.write(json);
  }
  process.exit(0);
}

if (!input || !output || !/\.(svg|png)$/.test(output)) {
  fail("usage: render.mjs <input.json> <out.excalidraw.svg|png> [--new] [--preview out.png] [--theme auto|light|dark]");
}
if (isNew) output = freeName(output);
ensureDir(output);
if (preview) ensureDir(preview);

// --- fonts -------------------------------------------------------------------

const pkgDir = join(dirname(new URL(import.meta.url).pathname), "..", "node_modules", "@excalidraw", "excalidraw", "dist", "prod");
const fontsDir = join(pkgDir, "fonts");
const FAMILY = {
  ComicShanns: "Comic Shanns",
  Lilita: "Lilita One",
  Liberation: "Liberation Sans",
};
for (const dir of readdirSync(fontsDir)) {
  for (const file of readdirSync(join(fontsDir, dir))) {
    if (/\.(woff2|ttf|otf)$/.test(file)) {
      GlobalFonts.registerFromPath(join(fontsDir, dir, file), FAMILY[dir] ?? dir);
    }
  }
}
setAssetPath(pkgDir);

// --- arrows ------------------------------------------------------------------

// Where the ray from a shape's center towards `toward` leaves its outline.
const edgePoint = (el, toward) => {
  const cx = el.x + el.width / 2;
  const cy = el.y + el.height / 2;
  const dx = toward[0] - cx;
  const dy = toward[1] - cy;
  if (!dx && !dy) return [cx, cy];
  const rx = el.width / 2;
  const ry = el.height / 2;
  let t;
  if (el.type === "ellipse") {
    t = 1 / Math.hypot(dx / rx, dy / ry);
  } else if (el.type === "diamond") {
    t = 1 / (Math.abs(dx) / rx + Math.abs(dy) / ry);
  } else {
    t = Math.min(dx ? rx / Math.abs(dx) : Infinity, dy ? ry / Math.abs(dy) : Infinity);
  }
  return [cx + dx * t, cy + dy * t];
};
const center = (el) => [el.x + el.width / 2, el.y + el.height / 2];

// Excalidraw keeps an arrow's given geometry and drops an end binding that
// doesn't reach its element, so route arrows given only `start`/`end` ids
// straight between the outlines of the (already laid out) elements.
const routeArrows = (skeleton, laidOut) => {
  const byId = new Map(laidOut.map((el) => [el.id, el]));
  for (const el of skeleton) {
    if (el.type !== "arrow" || el.points) continue;
    const from = byId.get(el.start?.id);
    const to = byId.get(el.end?.id);
    if (!from || !to) continue;
    const [sx, sy] = edgePoint(from, center(to));
    const [ex, ey] = edgePoint(to, center(from));
    Object.assign(el, { x: sx, y: sy, width: ex - sx, height: ey - sy });
  }
  return skeleton;
};

// --- convert -----------------------------------------------------------------

const src = JSON.parse(readFileSync(input, "utf8"));
let elements;
if (src.type === "excalidraw") {
  elements = src.elements;
} else {
  const skeleton = src.elements ?? src;
  if (!Array.isArray(skeleton)) fail("input must be { \"elements\": [...] } or a full scene");
  // pass 1 sizes shapes around their labels (snugly, so pad them), pass 2
  // routes arrows between the final shapes
  const laidOut = convertToExcalidrawElements(
    structuredClone(skeleton).map((el) =>
      el.type === "arrow" ? { ...el, start: undefined, end: undefined } : el,
    ),
    { regenerateIds: false },
  );
  const byId = new Map(laidOut.map((el) => [el.id, el]));
  const final = structuredClone(skeleton);
  for (const el of final) {
    const sized = byId.get(el.id);
    if (!sized || !el.label || el.width != null || el.height != null) continue;
    // excalidraw already grows ellipses/diamonds to fit; only pad
    Object.assign(el, { width: sized.width + 48, height: sized.height + 32 });
    Object.assign(sized, { width: el.width, height: el.height });
  }
  elements = convertToExcalidrawElements(routeArrows(final, laidOut), { regenerateIds: false });
}

const data = {
  elements,
  appState: { viewBackgroundColor: "#ffffff", ...(src.appState ?? {}) },
  files: src.files ?? {},
};
const environment = {
  createCanvas: () => createCanvas(1, 1),
  createImage: () => new Image(),
  createPath: (d) => new Path2D(d),
  document: globalThis.document,
  loadFonts: async () => {},
};
const config = {
  embedScene: true,
  environment,
  theme: theme === "auto" ? "light" : theme,
  exportPadding: 20,
};

// Excalidraw's own dark export is the light drawing under this filter, so
// applying it on prefers-color-scheme: dark gives the same look, automatically.
const AUTO_THEME_CSS =
  "<style class=\"auto-theme\">@media (prefers-color-scheme: dark) {" +
  " svg { filter: invert(93%) hue-rotate(180deg); } }</style>";
const withAutoTheme = (svg) => svg.replace(/<svg\b[^>]*>/, (open) => open + AUTO_THEME_CSS);

// --- export ------------------------------------------------------------------

const writePng = async (file) => {
  const blob = await exportScene({ type: "png", data, config: { ...config, scale: 2 } });
  writeFileSync(file, Buffer.from(await blob.arrayBuffer()));
};

if (output.endsWith(".svg")) {
  const svg = await exportScene({ type: "svg", data, config });
  writeFileSync(output, theme === "auto" ? withAutoTheme(svg.outerHTML) : svg.outerHTML);
} else {
  await writePng(output);
}
if (preview) await writePng(preview);

const unbound = elements.filter(
  (el) => el.type === "arrow" && ((el.startBinding == null) !== (el.endBinding == null)),
);
if (unbound.length) {
  console.error(`warning: arrows bound at only one end: ${unbound.map((el) => el.id).join(", ")}`);
}

// Scene size, so a too-wide (landscape) layout gets noticed. Lines and arrows
// span their points; everything else its box.
const xs = [];
const ys = [];
for (const el of elements) {
  if (el.isDeleted) continue;
  const pts = el.points ?? [[0, 0], [el.width, el.height]];
  for (const [px, py] of pts) {
    xs.push(el.x + px);
    ys.push(el.y + py);
  }
}
const w = Math.round(Math.max(...xs) - Math.min(...xs));
const h = Math.round(Math.max(...ys) - Math.min(...ys));
console.error(`size: ${w}x${h} (${w > h ? "landscape" : "portrait"})`);
if (w > h) console.error("warning: landscape - the skill prefers portrait diagrams (taller than wide)");

console.log(output);
// the bundle leaves handles open that keep Node alive for ~a minute
process.exit(0);
