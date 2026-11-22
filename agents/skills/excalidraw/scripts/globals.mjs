// Browser globals the published @excalidraw/excalidraw bundle expects at
// import time and during export. Must be imported before it.
import { readFile } from "node:fs/promises";
import { fileURLToPath, pathToFileURL } from "node:url";

import { createCanvas, Image, Path2D } from "@napi-rs/canvas";
import { parseHTML } from "linkedom";

const win = parseHTML("<!doctype html><html><head></head><body></body></html>");
for (const key of [
  "window",
  "document",
  "Element",
  "HTMLElement",
  "SVGElement",
  "Node",
  "DocumentFragment",
  "Event",
  "CustomEvent",
  "navigator",
  "HTMLCanvasElement",
  "HTMLImageElement",
]) {
  if (!(key in globalThis) && win[key] !== undefined) {
    try {
      globalThis[key] = win[key];
    } catch {}
  }
}

globalThis.window.devicePixelRatio = 1;
globalThis.window.EXCALIDRAW_EXPORT_SOURCE = "https://excalidraw.com";

// linkedom's <canvas> has no 2D context; text is measured on one.
const createElement = globalThis.document.createElement.bind(globalThis.document);
globalThis.document.createElement = (tag, ...rest) =>
  String(tag).toLowerCase() === "canvas"
    ? createCanvas(1, 1)
    : createElement(tag, ...rest);
globalThis.Image ??= Image;
globalThis.Path2D ??= Path2D;

// Only used to describe fonts; the SVG export reads their files via fetch.
globalThis.FontFace ??= class FontFace {
  constructor(family, source, descriptors = {}) {
    Object.assign(this, {
      family,
      source,
      style: "normal",
      weight: "400",
      display: "swap",
      unicodeRange: "U+0-10FFFF",
      ...descriptors,
      status: "loaded",
    });
  }
  load() {
    return Promise.resolve(this);
  }
};

// Serve fonts from the local package; never hit the network.
globalThis.fetch = async (url) => {
  const href = String(url);
  if (href.startsWith("file:")) {
    return new Response(await readFile(fileURLToPath(href)), { status: 200 });
  }
  throw new Error(`network disabled: ${href}`);
};

export const setAssetPath = (dir) => {
  globalThis.window.EXCALIDRAW_ASSET_PATH = pathToFileURL(dir + "/").href;
};
