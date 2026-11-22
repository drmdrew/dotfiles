---
name: excalidraw
description: Draw a hand-drawn style Excalidraw diagram from a description and save it as an image with the editable scene embedded (images/YYYY-MM-DD-slug.excalidraw.svg or .png), ready to link from Markdown notes. Use when asked for an excalidraw diagram, sketch or drawing, or to change an existing .excalidraw.svg/.png.
allowed-tools:
  - Bash(~/.claude/skills/excalidraw/scripts/excalidraw:*)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Excalidraw diagrams

Turn the user's description into an Excalidraw diagram and save it as
`images/YYYY-MM-DD-<slug>.excalidraw.svg` (or `.png`). The file previews as an
image in Markdown and still opens for editing in excalidraw.com or the VS Code
Excalidraw extension, because the scene is embedded in it.

The request: $ARGUMENTS

**No ad-hoc shell commands.** The only shell command this skill runs is the
helper, invoked exactly as `~/.claude/skills/excalidraw/scripts/excalidraw ...`
(one command: no `cd`, `&&`, pipes, redirects or heredocs), which is
pre-approved. Everything else uses file tools:

- To learn about the subject (a repo, config, notes), use Read, Glob and Grep,
  not `ls`, `cat`, `find` or `grep` in the shell.
- Write the diagram JSON with the Write tool, into the session's scratchpad
  directory (or another temp directory), never with a script that generates it.
- Don't `mkdir` or check whether files exist: the helper creates directories,
  and `--new` picks a free filename.

## 1. Decide the output file

- **Format:** `.excalidraw.svg` unless the user asks for PNG. SVG is sharp at
  any size, small, and has its fonts embedded.
- **Directory:** `images/` in the current directory. If the user names a note
  the diagram is for, use the `images/` directory next to that note. The helper
  creates it if needed.
- **Name:** today's date and a short, descriptive, lowercase, hyphenated slug of
  2-5 words: `images/2026-11-14-agent-config-layout.excalidraw.svg`. For a new
  diagram, pass `--new` on the first render: if the file exists, the helper
  appends `-2`, `-3`, ... and prints the path it used. Re-render to that
  printed path, without `--new`.

## 2. Write the diagram as JSON

Write `{ "elements": [...] }` with the Write tool to a temporary file (not in
`images/`). Elements
use Excalidraw's simplified skeleton format; the renderer fills in everything
else.

```json
{ "elements": [
  { "type": "rectangle", "id": "api", "x": 0, "y": 0,
    "label": { "text": "API" } },
  { "type": "ellipse", "id": "db", "x": 300, "y": 0,
    "backgroundColor": "#b2f2bb", "fillStyle": "solid",
    "label": { "text": "Postgres" } },
  { "type": "arrow", "start": { "id": "api" }, "end": { "id": "db" },
    "label": { "text": "SQL" } },
  { "type": "text", "x": 0, "y": 140, "text": "Title or note", "fontSize": 28 }
]}
```

**Shapes:** `rectangle`, `ellipse`, `diamond`. Give each an `id` and `x`/`y`
(top-left, pixels, y grows down). With a `label` and no `width`/`height`, the
shape sizes itself to the text; give `width`/`height` to make shapes in a row
the same size. Labels wrap to the shape's width, so make it wide enough for the
longest line.

**Arrows / lines:** an `arrow` with `start: { "id" }` and `end: { "id" }`
connects two shapes and is routed between their outlines automatically: leave
out `x`, `y`, `width`, `height`. Optional: `label`, `strokeStyle: "dashed"`,
`startArrowhead`/`endArrowhead` (`"arrow"`, `"triangle"`, `"dot"`, `"bar"`,
`null`). For a free arrow or `line`, give `x`, `y` and
`points: [[0,0],[dx,dy],...]` instead.

**Text:** `text` elements need `x`, `y`, `text`; optional `fontSize` (default
20), `textAlign`. Use `\n` for line breaks.

**Style (any element):** `strokeColor`, `backgroundColor`, `fillStyle`
(`"hachure"`, `"cross-hatch"`, `"solid"`), `strokeWidth` (1, 2, 4),
`strokeStyle` (`"solid"`, `"dashed"`, `"dotted"`), `roughness` (0 = neat,
1 = default, 2 = sketchy), `roundness: { "type": 3 }` for rounded rectangles,
`opacity` (0-100), `fontFamily` (5 = Excalifont, the default hand-drawn font;
6 = Nunito; 8 = Comic Shanns; 3 = Cascadia, monospace).

Palette that reads well: strokes `#1e1e1e`, `#e03131`, `#2f9e44`, `#1971c2`,
`#f08c00`; fills `#ffc9c9`, `#b2f2bb`, `#a5d8ff`, `#ffec99`, `#d0bfff`,
`#e9ecef`.

**Layout: portrait.** Make the diagram taller than it is wide, roughly 3:4 to
1:2 (width:height), and no more than about 1000px wide. A portrait diagram
zooms to a readable size with zoom-to-fit (Shift+1) in the Excalidraw editor;
a wide one ends up around 20%. To get there:

- Make top-to-bottom the main flow. Use left-to-right only within a row, and
  keep rows to 2-3 shapes.
- Stack groups (lanes, phases, alternatives) above one another, not side by
  side.
- Put the end of a flow (a shared destination, a result) below the rows that
  lead to it, not in a column to their right.
- Break long labels with `\n` (under about 50 characters per line).

**No explanatory text unless asked.** Don't add footnotes, captions, legends
or side notes that explain the diagram. If it needs a paragraph to be
understood, redraw it so the shapes, labels, arrows and colours carry the
meaning. A title, and short headings that name a group or lane, are fine.
If the user asks for notes, put them below the diagram, not in a right-hand
margin.

Keep a clear grid: about 80-120px between shapes, rows and columns aligned.
Fewer, larger elements beat dense ones. Use colour to group, not to decorate.

## 3. Render and check it

```sh
~/.claude/skills/excalidraw/scripts/excalidraw <tmp>/diagram.json images/<name>.excalidraw.svg --new --preview <tmp>/preview.png
```

Use an absolute output path (or one relative to the current directory). The
helper prints the path it wrote. The first run installs and builds the renderer
(needs `node` and `npm`, about a minute); later runs take a second or two.
The default `--theme auto` makes an SVG that is light, and switches to
Excalidraw's dark look when the viewer prefers dark (VS Code dark themes, OS
dark mode). Use `--theme light` or `--theme dark` only when the user asks for a
fixed look. PNGs can't switch, so `auto` renders them, and the preview, light.

Look at the preview PNG with the Read tool. To fix something, Edit the JSON
file and re-render without `--new`. Fix and re-render if text is clipped or wrapped
awkwardly, shapes overlap, arrows cross shapes or labels, or the layout is
unbalanced. A `warning: arrows bound at only one end` means an arrow `id`
didn't match a shape.

The helper also prints the diagram's size (`size: 820x1180 (portrait)`). A
`warning: landscape` means the diagram is wider than it is tall: rearrange it
per **Layout** and re-render, unless the user asked for a wide diagram.

## 4. Report

Give the saved path and a ready-to-paste Markdown link, relative to the note
it's for (or the current directory):

```markdown
![Agent config layout](images/2026-11-14-agent-config-layout.excalidraw.svg)
```

## Changing an existing diagram

```sh
~/.claude/skills/excalidraw/scripts/excalidraw --extract images/<name>.excalidraw.svg --out <tmp>/scene.json
```

This writes the full scene (`"type": "excalidraw"`) to `--out`. Without
`--out` it prints the scene to stdout, but don't redirect it with `>`: a
redirect is no longer the pre-approved command. Read the file, Edit its elements, keeping
their ids and the `boundElements`/`startBinding`/`endBinding` links consistent,
then render it back to the same file with the command in step 3. For a larger
rework, write a fresh skeleton instead.
