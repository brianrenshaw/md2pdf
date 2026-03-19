# md2pdf — Styled Markdown to PDF

Convert Markdown files to professionally styled PDFs using Puppeteer. Includes two styles with a shared rendering engine.

| Command | Style | Description |
|---------|-------|-------------|
| `sbts-md2pdf` | SBTS Brand | Navy, gold, and green — Southern Seminary brand colors |
| `minion-noir` | Minion Noir | Monochrome — all black and gray |

Both styles use Minion Pro as the body typeface with full support for callout boxes, auto-generated table of contents, definition lists, footnotes, and PDF bookmarks.

## Installation

### Step 1: Install Node.js (if you don't have it)

Node.js is a free tool that runs the conversion script. To check if you already have it, open **Terminal** (search for "Terminal" in Spotlight) and type:

```
node --version
```

If you see a version number (e.g., `v20.11.0`), you're good — skip to Step 2.

If you get "command not found," install Node.js:

1. Go to [nodejs.org](https://nodejs.org)
2. Download the macOS installer (the LTS version is fine)
3. Run the installer and follow the prompts

### Step 2: Download this project

**Option A — Download as ZIP (easiest):**

1. Click the green **Code** button at the top of this page
2. Click **Download ZIP**
3. Unzip the downloaded file
4. Move the `md2pdf` folder somewhere permanent (e.g., your home folder or a Projects folder)

**Option B — Clone with Git (if you use Git):**

```bash
git clone https://github.com/YOUR_USERNAME/md2pdf.git
```

### Step 3: Install fonts

Three font families are included in the `fonts/` folder. All three must be installed before the styles will render correctly.

1. Open the `fonts/` folder inside the project
2. Double-click each `.otf` and `.ttf` file
3. Click **Install Font** in the Font Book preview that appears
4. Repeat for all font files

### Step 4: Run the setup script

1. Open **Terminal**
2. Type `cd ` (with a space after it), then drag the `md2pdf` folder from Finder into the Terminal window — this fills in the path for you
3. Press Enter
4. Type `./install.sh` and press Enter

The setup script will walk you through a few questions:

* **Where should PDFs be saved?** — Press Enter to accept the default (`~/Documents/MDpdf`), or type a different folder path
* **Symlink CSS files for Marked 2?** — If you use Marked 2, type `Y` to make the styles available in Marked 2 automatically

When it finishes, you'll see a summary with your terminal commands and Obsidian/Drafts setup instructions.

### Requirements Summary

* **macOS** (uses Puppeteer with Chromium for PDF rendering)
* **Node.js** v18 or later ([nodejs.org](https://nodejs.org))
* **Fonts** — Minion Pro, Lato, STIX (all included in `fonts/`)

## Usage

```bash
# Single file — PDF saved next to the source
sbts-md2pdf report.md

# Single file — PDF saved to a specific directory
sbts-md2pdf report.md ~/Documents/MDpdf

# All Markdown files in a folder
sbts-md2pdf ~/reports/

# Monochrome style
minion-noir report.md
```

Supported file extensions: `.md`, `.markdown`, `.txt`

## PDF Output

* **Format:** US Letter (8.5 x 11 in)
* **Margins:** 0.75 inches on all sides
* **Header:** Document title (top left)
* **Footer:** Custom text (bottom left), Page X of Y (bottom right)
* **Bookmarks:** Navigable PDF outline generated from headings

## Standard Markdown

All standard Markdown is supported: headings, paragraphs, bold, italic, links, images, lists, blockquotes, code blocks, horizontal rules, tables, and footnotes.

### Footnotes

```markdown
This claim requires a citation.[^1]

[^1]: Source: Institutional Report, 2026.
```

## Extended Features

These features go beyond standard Markdown. They work in both styles.

### Callout Boxes

```markdown
::: note
Key takeaway or important context.
:::

::: warning
This data has not been verified against the source system.
:::

::: tip
Run the automated system first, then compare against the baseline.
:::
```

Override the default title:

```markdown
::: tip Best Practice
Always compare against the previous term's baseline.
:::
```

**SBTS Brand callout colors:**

| Type | Accent | Background |
|------|--------|------------|
| note | Navy (#072643) | Light blue-gray |
| warning | Gold (#BB902D) | Light gold |
| tip | Green (#37765B) | Light green |

**Minion Noir callout colors:**

| Type | Accent | Background |
|------|--------|------------|
| note | Dark gray (#333) | Light gray |
| warning | Medium gray (#666) | Light gray |
| tip | Light gray (#999) | Light gray |

### Table of Contents

Place `[[toc]]` on its own line to auto-generate a table of contents from H2, H3, and H4 headings. If omitted, no TOC appears.

```markdown
# Report Title

[[toc]]

## First Section
```

### Definition Lists

```markdown
Load Credit
:   The weighted teaching hours assigned to a course section

Cross-listed Course
:   A single course offered under multiple catalog numbers
```

### Directives

Directives are special inline commands that control PDF output. They are stripped from the rendered document.

| Directive | Effect |
|-----------|--------|
| `[[foot-left]] Your text` | Places custom text in the bottom-left footer of every page |
| `[[no-header]]` | Removes the document title from the top-left header |

```markdown
[[foot-left]] Updated: 2026-03-19 v2.1
[[no-header]]
```

## Integration

### Terminal

```bash
sbts-md2pdf report.md
minion-noir report.md
```

### Raycast

Add the `raycast/` directory as a Script Command directory in Raycast:

Raycast > Settings > Extensions > Script Commands > Add Script Directory

Two commands will appear: **SBTS Markdown PDF** and **Minion Noir PDF**.

### Obsidian

Install the [Shell Commands](https://github.com/Taitava/obsidian-shellcommands) community plugin. Create commands using the paths shown at the end of `./install.sh` output.

### Drafts (Mac only)

Create an action with a **Script** step. The filename is derived from the first H1 heading (H2 fallback, then "Untitled").

```javascript
let title = "Untitled";
let lines = draft.content.split("\n");
for (let line of lines) {
    let m1 = line.match(/^#\s+(.+)/);
    if (m1) { title = m1[1].trim(); break; }
    let m2 = line.match(/^##\s+(.+)/);
    if (m2 && title === "Untitled") { title = m2[1].trim(); }
}
let safeName = title.replace(/[\/\\:*?"<>|]/g, "").replace(/\s+/g, " ").substring(0, 100);
let tmpPath = "/tmp/" + safeName + ".md";

let writer = ShellScript.create('#!/bin/bash\nprintf "%s" "$1" > "$2"');
writer.execute([draft.content, tmpPath]);

// Change the path below to match your install location
let runner = ShellScript.create('#!/bin/bash\nnode /path/to/md2pdf/sbts-md2pdf.mjs "$1" "$HOME/Documents/MDpdf" && rm -f "$1"');
if (runner.execute([tmpPath])) {
    app.displaySuccessMessage(safeName + ".pdf saved");
} else {
    app.displayErrorMessage(runner.standardError);
}
```

For Minion Noir, change `sbts-md2pdf.mjs` to `minion-noir.mjs`.

### Marked 2

If you use Marked 2, the install script can symlink the CSS files into Marked's custom style directory. Both styles will appear in Marked 2's style dropdown. Changes to the CSS in this repo are automatically reflected in Marked 2.

## File Structure

```
md2pdf/
  core.mjs                  Shared rendering engine
  sbts-md2pdf.mjs           Entry point — SBTS Brand
  minion-noir.mjs           Entry point — Minion Noir
  install.sh                Interactive setup
  config.json               Generated per-user (gitignored)
  styles/
    sbts-brand.css           SBTS Brand stylesheet
    minion-noir.css          Monochrome stylesheet
  fonts/                    Font files for installation
  raycast/
    sbts-md2pdf.sh           Raycast command (SBTS)
    minion-noir.sh           Raycast command (Noir)
  package.json              Dependencies
```

## Customization

### Creating a New Style

1. Copy an existing CSS file in `styles/` and modify it
2. Create a new entry point (copy `sbts-md2pdf.mjs`, change the CSS filename)
3. Run `./install.sh` to regenerate wrapper scripts

### Changing the Output Directory

Run `./install.sh` again, or edit `config.json` directly and re-run the install to regenerate wrappers.

## Dependencies

* [markdown-it](https://github.com/markdown-it/markdown-it) — Markdown parser
* [markdown-it-footnote](https://github.com/markdown-it/markdown-it-footnote) — Footnotes
* [markdown-it-container](https://github.com/markdown-it/markdown-it-container) — Callout boxes
* [markdown-it-anchor](https://github.com/valeriangalliat/markdown-it-anchor) — Heading anchors
* [markdown-it-table-of-contents](https://github.com/cmaas/markdown-it-table-of-contents) — Auto TOC
* [markdown-it-deflist](https://github.com/markdown-it/markdown-it-deflist) — Definition lists
* [puppeteer](https://pptr.dev) — Headless Chromium for PDF rendering
