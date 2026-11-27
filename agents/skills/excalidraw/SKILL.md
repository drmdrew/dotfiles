---
name: excalidraw
description: Draw a hand-drawn style Excalidraw diagram from a description and save it as an image with the editable scene embedded (images/YYYY-MM-DD-slug.excalidraw.svg or .png), ready to link from Markdown notes. Use when asked for an excalidraw diagram, sketch or drawing, or to change an existing .excalidraw.svg/.png.
allowed-tools:
  - Bash(~/.claude/skills/excalidraw/scripts/excalidraw:*)
  - Read
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
pre-approved. Everything else uses file tools (Write and Edit are not
pre-approved by this skill):

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
longest line: allow about 0.55 x font size per character, plus 40px (more for
diamonds and ellipses). With a fixed `height`, allow 1.25 x font size per
line, plus 30px.

**Arrows / lines:** an `arrow` with `start: { "id" }` and `end: { "id" }`
connects two shapes and is routed between their outlines automatically: leave
out `x`, `y`, `width`, `height`. Optional: `label`, `strokeStyle: "dashed"`,
`startArrowhead`/`endArrowhead` (`"arrow"`, `"triangle"`, `"dot"`, `"bar"`,
`null`). For a free arrow or `line`, give `x`, `y` and
`points: [[0,0],[dx,dy],...]` instead. Use a free arrow for a loop back to an
earlier step, which a straight arrow would draw through the shapes in between:
run it out to a clear margin, up, and back in, ending at the target's edge.

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

**Layout: fit the destination.** Pick a `--fit` target from the request, and
use `default` if it doesn't say. Canvas sizes include a 20px margin all round.

| `--fit` | Use for | Shape | Canvas | Text |
|---|---|---|---|---|
| `default` | anything unspecified | about 3:2 | up to 1000x670 | 20px |
| `slide` | slides, presentations | about 16:9 | up to 1100x620 | 24px (`label.fontSize` too) |
| `github` | PRs, issues, READMEs | 4:3 to 16:9 | up to 1000 wide, under 700 tall if possible | 20px |
| `doc` | long, scrolling pages, only when asked for portrait | taller than wide | up to 1000 wide | 20px |

- **Limit the content:** aim for about 12 shapes or fewer. Merge minor steps,
  drop implementation detail, or split into two diagrams. Don't shrink text to
  make more fit.
- **One main path:** make it easy to follow, with side branches off it.
- **Wrap long flows** instead of making one long column or row: 2-3 rows of
  3-4 shapes, each read left to right, or lanes grouped by who does the work.
  For `doc`, flow top to bottom instead.
- **Break long labels** with `\n`.

**Routing:**

- Avoid crossing arrows first; then use as few bends as possible. Reorder
  shapes before adding bends.
- Align shapes before connecting them: neighbours that share a center line get
  a straight arrow.
- To wrap from the end of one row to the start of the next, use a free arrow
  with right-angle `points` through the gap between the rows.
- Run a loop back around the outside, and try to have only one.

**No explanatory text unless asked.** Don't add footnotes, captions, legends
or side notes that explain the diagram. If it needs a paragraph to be
understood, redraw it so the shapes, labels, arrows and colours carry the
meaning. A title, and short headings that name a group or lane, are fine.
If the user asks for notes, put them below the diagram, not in a right-hand
margin.

Keep a clear grid: rows and columns aligned, about 60-100px between shapes
(a labelled horizontal arrow needs about 100px, more for long labels).
Fewer, larger elements beat dense ones. Use colour to group, not to decorate.

## 3. Render and check it

```sh
~/.claude/skills/excalidraw/scripts/excalidraw <tmp>/diagram.json images/<name>.excalidraw.svg --new --preview <tmp>/preview.png --fit default
```

Use an absolute output path (or one relative to the current directory). The
helper only writes inside the current directory or a temp directory, never to
hidden files or directories or through a symlinked file. Output names must end
in `.excalidraw.svg` or `.excalidraw.png`, `--preview` in `.png`, and `--out`
must be a `.excalidraw` file or `scene.json`. If it refuses a path, tell the
user; don't work around it. The
helper prints the path it wrote; a render takes a second or two.

If the helper says the renderer is not built or out of date, stop: tell the
user to run the `mise ... run setup` command it names, and render once they
have. Don't run `mise`, `npm` or the build yourself.
The default `--theme auto` makes an SVG that is light, and switches to
Excalidraw's dark look when the viewer prefers dark (VS Code dark themes, OS
dark mode). Use `--theme light` or `--theme dark` only when the user asks for a
fixed look. PNGs can't switch, so `auto` renders them, and the preview, light.

Look at the preview PNG with the Read tool. To fix something, Edit the JSON
file and re-render without `--new`. Fix and re-render if text is clipped or wrapped
awkwardly, shapes overlap, arrows cross shapes or labels, or the layout is
unbalanced. The helper stops with an error if an arrow names an `id` that
doesn't exist. A `warning: arrow "a->b": end is not bound to "b"` means the
arrow doesn't reach that shape: check its `points`, or whether the two shapes
overlap. (Arrows without an `id` are named after the shapes they connect.)

The helper also prints how the diagram will look at its `--fit` target (`size:
1000x640 (1.56:1); fit default: shown at 830x531px, smallest text 16.6px`).
Fix any warning about text size, shape or height per **Layout** and re-render,
unless the user asked for that shape. If it can't be fixed without losing
content the user asked for, say so in the report. Pass the same `--fit` on every
render.

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
