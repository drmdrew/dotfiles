// Render an Excalidraw diagram to .excalidraw.svg / .excalidraw.png with the
// scene embedded, so it previews as an image and reopens in Excalidraw.
//
//   render.mjs <input.json> <output.excalidraw.svg|png> [--new] [--preview out.png] [--theme auto|light|dark] [--fit default|slide|github|doc]
//   render.mjs --extract <file.excalidraw|svg|png> [--out <x.excalidraw|scene.json>]
//
// <input.json> is either an element skeleton ({ "elements": [...] }, see
// SKILL.md) or a full scene ({ "type": "excalidraw", ... }).
import { setAssetPath } from "./globals.mjs";

import { existsSync, lstatSync, mkdirSync, readdirSync, readFileSync, realpathSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
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
// Where the diagram will be shown. `box` is the space it's scaled down to fit
// (CSS px; points for a slide), `minText` the smallest readable text there,
// `ratio` the width:height range and `maxHeight` the tallest it should show.
const SCREEN = { box: [830, Infinity], minText: 14, unit: "px" };
const FITS = {
  default: { ...SCREEN, ratio: [1.2, 2], maxHeight: 700 },
  slide: { box: [880, 470], minText: 18, unit: "pt", ratio: [1.4, 2.1] },
  github: { ...SCREEN, maxHeight: 700 },
  doc: SCREEN,
};
const fit = flag("--fit") ?? "default";
if (!Object.hasOwn(FITS, fit)) fail(`--fit must be ${Object.keys(FITS).join(", ")}`);
let [input, output] = args;

// Create parent directories so callers never need a separate mkdir.
const ensureDir = (file) => mkdirSync(dirname(file), { recursive: true });

// --- write guard ---------------------------------------------------------------

// The helper runs without a permission prompt, so it limits what it can write.
const lstat = (file) => lstatSync(file, { throwIfNoEntry: false });
const within = (root, file) => {
  const rel = relative(root, file);
  return rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel);
};
const WRITE_ROOTS = [process.cwd(), tmpdir(), "/tmp"].map((dir) => realpathSync(dir));

// Returns the symlink-free path to write to, or exits.
const safeTarget = (file) => {
  let dir = resolve(file);
  if (lstat(dir)?.isSymbolicLink()) fail(`refusing to write through a symlink: ${file}`);
  const missing = [];
  while (!lstat(dir)) {
    missing.unshift(basename(dir));
    dir = dirname(dir);
  }
  const real = join(realpathSync(dir), ...missing);
  if (real.split(sep).some((part) => part.startsWith("."))) {
    fail(`refusing to write to a hidden file or directory: ${real}`);
  }
  if (!WRITE_ROOTS.some((root) => within(root, real))) {
    fail(`refusing to write outside the current or a temp directory: ${real}`);
  }
  return real;
};

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

const decodeScene = (file) => {
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

const isScene = (scene) => scene?.type === "excalidraw" && Array.isArray(scene.elements);
const readScene = (file) => {
  if (![file, realpathSync(file)].every((f) => /\.(excalidraw|svg|png)$/.test(f))) {
    fail("--extract takes a .excalidraw, .svg or .png file");
  }
  const scene = decodeScene(file);
  if (!isScene(scene)) fail(`${file} is not a valid Excalidraw scene`);
  return scene;
};

// A flag given without a value must not fall through to another mode.
for (const name of ["--extract", "--out", "--preview", "--theme", "--fit"]) {
  if (process.argv.at(-1) === name) fail(`${name} needs a value`);
}

if (extract !== undefined) {
  const json = JSON.stringify(readScene(extract), null, 2) + "\n";
  if (out !== undefined) {
    const target = safeTarget(out);
    if (!target.endsWith(".excalidraw") && basename(target) !== "scene.json") {
      fail("--out must be a .excalidraw file or scene.json");
    }
    if (existsSync(target)) {
      let old;
      try {
        old = JSON.parse(readFileSync(target, "utf8"));
      } catch {}
      if (!isScene(old)) fail(`refusing to overwrite a file that is not a scene: ${out}`);
    }
    ensureDir(target);
    writeFileSync(target, json);
    console.log(out);
  } else {
    process.stdout.write(json);
  }
  process.exit(0);
}

if (!input || !output || !/\.excalidraw\.(svg|png)$/.test(output)) {
  fail("usage: render.mjs <input.json> <out.excalidraw.svg|png> [--new] [--preview out.png] [--theme auto|light|dark] [--fit default|slide|github|doc]");
}
if (isNew) output = freeName(output);
// check every target before writing any of them
const outputPath = safeTarget(output);
const previewPath = preview === undefined ? undefined : safeTarget(preview);
if (!/\.excalidraw\.(svg|png)$/.test(outputPath)) fail("output must be .excalidraw.svg or .excalidraw.png");
if (previewPath && !previewPath.endsWith(".png")) fail("--preview must be a .png file");
ensureDir(outputPath);
if (previewPath) ensureDir(previewPath);

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
    // excalidraw replaces a width of 0 with its default (100), which would
    // slant a vertical arrow
    Object.assign(el, { x: sx, y: sy, width: ex - sx || 0.001, height: ey - sy });
  }
  return skeleton;
};

// Give unnamed arrows an id that says what they connect, so warnings can be
// traced back to the input.
const nameArrows = (skeleton) => {
  const used = new Set(skeleton.map((el) => el.id));
  for (const el of skeleton) {
    if (el.type !== "arrow" || el.id) continue;
    const base = `${el.start?.id ?? "free"}->${el.end?.id ?? "free"}`;
    let id = base;
    for (let n = 2; used.has(id); n++) id = `${base}#${n}`;
    used.add(id);
    el.id = id;
  }
};

// --- convert -----------------------------------------------------------------

const src = JSON.parse(readFileSync(input, "utf8"));
let elements;
// arrow ends the skeleton asked to bind: [arrow id, "start"|"end", shape id]
const requested = [];
if (src.type === "excalidraw") {
  elements = src.elements;
} else {
  const skeleton = src.elements ?? src;
  if (!Array.isArray(skeleton)) fail("input must be { \"elements\": [...] } or a full scene");
  nameArrows(skeleton);
  const ids = new Set(skeleton.map((el) => el.id));
  for (const el of skeleton) {
    if (el.type !== "arrow") continue;
    for (const end of ["start", "end"]) {
      const shape = el[end]?.id;
      if (shape === undefined) continue;
      // excalidraw would carry on and produce broken geometry
      if (!ids.has(shape)) fail(`arrow "${el.id}": ${end} id "${shape}" doesn't match any element`);
      requested.push([el.id, end, shape]);
    }
  }
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
const PADDING = 20;
const config = {
  embedScene: true,
  environment,
  theme: theme === "auto" ? "light" : theme,
  exportPadding: PADDING,
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
  writeFileSync(outputPath, theme === "auto" ? withAutoTheme(svg.outerHTML) : svg.outerHTML);
} else {
  await writePng(outputPath);
}
if (previewPath) await writePng(previewPath);

const finalById = new Map(elements.map((el) => [el.id, el]));
for (const [arrow, end, shape] of requested) {
  if (finalById.get(arrow)?.[`${end}Binding`]?.elementId !== shape) {
    console.error(`warning: arrow "${arrow}": ${end} is not bound to "${shape}"`);
  }
}

// How the diagram will look at its destination, so a poor shape or tiny text
// gets noticed. Lines and arrows span their points; everything else its box.
const xs = [];
const ys = [];
const fontSizes = [];
for (const el of elements) {
  if (el.isDeleted) continue;
  if (el.type === "text") fontSizes.push(el.fontSize);
  const pts = el.points ?? [[0, 0], [el.width, el.height]];
  for (const [px, py] of pts) {
    xs.push(el.x + px);
    ys.push(el.y + py);
  }
}
const w = Math.round(Math.max(...xs) - Math.min(...xs)) + 2 * PADDING;
const h = Math.round(Math.max(...ys) - Math.min(...ys)) + 2 * PADDING;
const { box, minText, unit, ratio, maxHeight } = FITS[fit];
// slides scale to fill their space; web pages never enlarge an image
const scale = Math.min(box[0] / w, box[1] / h, unit === "pt" ? Infinity : 1);
const shape = w / h;
const text = fontSizes.length ? Math.min(...fontSizes) * scale : undefined;
const shown = `${Math.round(w * scale)}x${Math.round(h * scale)}${unit}`;
console.error(
  `size: ${w}x${h} (${shape.toFixed(2)}:1); fit ${fit}: shown at ${shown}` +
    (text === undefined ? "" : `, smallest text ${text.toFixed(1)}${unit}`),
);
if (text < minText) {
  console.error(`warning: text too small for ${fit} (under ${minText}${unit}): shrink the canvas or enlarge the text`);
}
if (ratio && (shape < ratio[0] || shape > ratio[1])) {
  const problem = shape < ratio[0] ? "too tall" : "too wide";
  console.error(`warning: ${problem} for ${fit} (aim for ${ratio[0]}:1 to ${ratio[1]}:1)`);
}
if (maxHeight && h * scale > maxHeight) {
  console.error(`warning: shown over ${maxHeight}px tall, so readers have to scroll`);
}

console.log(output);
// the bundle leaves handles open that keep Node alive for ~a minute
process.exit(0);
