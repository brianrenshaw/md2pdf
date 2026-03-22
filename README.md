# md2pdf — Styled Markdown to PDF

Convert Markdown files to professionally styled PDFs using Puppeteer. Includes five styles with a shared rendering engine.

| Command | Style | Sample | Description |
|---------|-------|--------|-------------|
| `alumni-chapel` | Alumni Chapel | [**View PDF**](samples/css-test-document-alumni-chapel.pdf?raw=true) | Navy, gold, and green — inspired by Southern Seminary's brand palette |
| `minion-noir` | Minion Noir | [**View PDF**](samples/css-test-document-minion-noir.pdf?raw=true) | Monochrome — all black and gray |
| `sage` | Sage | [**View PDF**](samples/sage-sample.pdf?raw=true) | Clean Swiss minimalist — cool blue-gray sans-serif |
| `oxford` | Oxford | [**View PDF**](samples/oxford-sample.pdf?raw=true) | Warm serif academic — navy and burgundy with New York typeface |
| `noir-plus` | Noir Plus | [**View PDF**](samples/noir-plus-sample.pdf?raw=true) | Modern dark mode — dark background with vibrant accents |

All styles support callout boxes, auto-generated table of contents, definition lists, footnotes, and PDF bookmarks.

### Why multiple integrations?

Markdown lives everywhere — in code editors, note-taking apps, and writing tools. Rather than locking PDF generation to one workflow, md2pdf meets you where you write. Run it from the terminal after a build script, trigger it from Raycast while browsing files in Finder, convert a note directly from Obsidian, or print a styled draft from your phone. The same rendering engine and CSS produce identical output regardless of how you invoke it.

## Installation

### Step 1: Download

1. Click the green **Code** button at the top of this page
2. Click **Download ZIP**
3. Unzip the downloaded file
4. Move the `md2pdf-main` folder somewhere permanent (e.g., your home folder or a Projects folder)

### Step 2: Install fonts

Three font families are required. Download each one, then double-click the font files to install.

| Font | Used By | Download |
|------|---------|----------|
| [Minion Pro](https://font.download/font/minion-pro) | Alumni Chapel, Minion Noir (body text) | [font.download](https://font.download/font/minion-pro) |
| [Lato](https://fonts.google.com/specimen/Lato) | Alumni Chapel (tables, subheadings) | [Google Fonts](https://fonts.google.com/specimen/Lato) |
| [STIX](https://github.com/stipub/stixfonts) | Alumni Chapel (H1, blockquotes) | [GitHub](https://github.com/stipub/stixfonts) |
| [New York](https://developer.apple.com/fonts/) | Oxford (body text, headings) | [Apple Fonts](https://developer.apple.com/fonts/) |

**Which fonts do I need?**

| Style | Required Fonts |
|-------|---------------|
| Alumni Chapel | Minion Pro, Lato, STIX |
| Minion Noir | Minion Pro |
| Sage | None (uses system fonts) |
| Oxford | New York (+ Minion Pro fallback) |
| Noir Plus | None (uses system fonts) |

### Step 3: Run the installer

#### macOS

Double-click **Install md2pdf.command** in the md2pdf folder.

> **First-time security note:** macOS may block the file because it was downloaded from the internet. If you see a warning:
> 1. Right-click (or Control-click) the file
> 2. Choose **Open**
> 3. Click **Open** in the dialog
>
> You only need to do this once.

#### Windows

Double-click **Install md2pdf.bat** in the md2pdf folder.

---

The installer will automatically:

* Download and install Node.js locally (if not already on your system)
* Install all dependencies
* Set up terminal commands
* Configure Marked 2 CSS if installed (macOS only)
* Check for required fonts

PDFs will be saved to `~/Documents/MDpdf` (macOS) or `Documents\MDpdf` (Windows) by default.

### Advanced Installation

If you prefer to run the setup interactively (choose a custom output directory, etc.):

```bash
git clone https://github.com/brianrenshaw/md2pdf.git
cd md2pdf
./install.sh
```

This requires Node.js v18+ to be installed already ([nodejs.org](https://nodejs.org)).

### Requirements Summary

* **macOS** or **Windows**
* **Fonts** — must be downloaded and installed separately (see above)
* **Internet connection** — required on first run to download Node.js and dependencies

## Usage

```bash
# Single file — PDF saved next to the source
alumni-chapel report.md

# Single file — PDF saved to a specific directory
alumni-chapel report.md ~/Documents/MDpdf

# All Markdown files in a folder
alumni-chapel ~/reports/

# Other styles
minion-noir report.md
sage report.md
oxford report.md
noir-plus report.md
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

**Alumni Chapel callout colors:**

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

**Sage callout colors:**

| Type | Accent | Background |
|------|--------|------------|
| note | Indigo (#5a67d8) | Light blue |
| warning | Amber (#d69e2e) | Light yellow |
| tip | Green (#38a169) | Light green |

**Oxford callout colors:**

| Type | Accent | Background |
|------|--------|------------|
| note | Navy (#1f3a5d) | Light blue-gray |
| warning | Burgundy (#8b4513) | Warm cream |
| tip | Green (#37765B) | Light green |

**Noir Plus callout colors:**

| Type | Accent | Background |
|------|--------|------------|
| note | Cyan (#4a9eff) | Dark blue |
| warning | Orange (#ff8c00) | Dark amber |
| tip | Mint (#52d273) | Dark green |

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
| `[[no-footer]]` | Removes the entire footer (page numbers and foot-left text) |

```markdown
[[foot-left]] Updated: 2026-03-19 v2.1
[[no-header]]
[[no-footer]]
```

Place directives on their own line, anywhere in the document. These are md2pdf-only — remove them before previewing in Drafts on iOS.

## Integration

### Terminal

```bash
alumni-chapel report.md
minion-noir report.md
sage report.md
oxford report.md
noir-plus report.md
```

### Raycast

Add the `raycast/` directory as a Script Command directory in Raycast:

Raycast > Settings > Extensions > Script Commands > Add Script Directory

Five commands will appear: **Alumni Chapel PDF**, **Minion Noir PDF**, **Sage PDF**, **Oxford PDF**, and **Noir Plus PDF**.

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
let runner = ShellScript.create('#!/bin/bash\nnode /path/to/md2pdf/alumni-chapel.mjs "$1" "$HOME/Documents/MDpdf" && rm -f "$1"');
if (runner.execute([tmpPath])) {
    app.displaySuccessMessage(safeName + ".pdf saved");
} else {
    app.displayErrorMessage(runner.standardError);
}
```

For other styles, change `alumni-chapel.mjs` to `minion-noir.mjs`, `sage.mjs`, `oxford.mjs`, or `noir-plus.mjs`.

### Drafts (iOS / iPadOS)

Drafts on iOS cannot run shell scripts, but you can preview and print styled documents using the [Preview/Print with CSS](https://directory.getdrafts.com/a/1JN) action from the Drafts Directory.

**Setup:**

1. Install the action from the link above
2. Create a new draft for each style you want, tagged with `css`:
   * Title the first line `Alumni Chapel iOS` or `Minion Noir iOS`
   * Paste the contents of `styles/alumni-chapel-ios.css` or `styles/minion-noir-ios.css` below the title
3. Open any markdown draft, run the action, and select your CSS from the picker

**iOS limitations:**

The following md2pdf features do not work in Drafts on iOS and should be removed from your document before previewing:

| Feature | Syntax to remove |
|---------|-----------------|
| Directives | `[[foot-left]] ...`, `[[no-header]]`, `[[no-footer]]` |
| Callout boxes | `::: note`, `::: warning`, `::: tip`, and closing `:::` |
| Auto table of contents | `[[toc]]` |
| Definition lists | `Term` / `:   Definition` (unless using MultiMarkdown parser) |

The content between callout fences will render as normal paragraphs. The fence lines themselves (`::: note`, `:::`) will appear as plain text.

Standard Markdown (headings, bold, italic, links, images, lists, blockquotes, tables, footnotes, code blocks) works fully on iOS.

### Marked 2

If you use Marked 2, the install script can symlink the CSS files into Marked's custom style directory. Both styles will appear in Marked 2's style dropdown. Changes to the CSS in this repo are automatically reflected in Marked 2.

## File Structure

```
md2pdf/
  Install md2pdf.command    Double-click installer (macOS)
  Install md2pdf.bat        Double-click installer (Windows)
  install.sh                Interactive setup (advanced)
  core.mjs                  Shared rendering engine
  alumni-chapel.mjs         Entry point — Alumni Chapel
  minion-noir.mjs           Entry point — Minion Noir
  sage.mjs                  Entry point — Sage
  oxford.mjs                Entry point — Oxford
  noir-plus.mjs             Entry point — Noir Plus
  config.json               Generated per-user (gitignored)
  samples/
    css-test-document.md     Test document with all features
    *.pdf                    Sample output for each style
  styles/
    alumni-chapel.css        Alumni Chapel stylesheet
    minion-noir.css          Minion Noir stylesheet
    sage.css                 Sage stylesheet
    oxford.css               Oxford stylesheet
    noir-plus.css            Noir Plus stylesheet
    alumni-chapel-ios.css    Alumni Chapel for Drafts (iOS)
    minion-noir-ios.css      Minion Noir for Drafts (iOS)
  fonts/README.md           Font download links
  raycast/
    alumni-chapel.sh         Raycast command (Alumni Chapel)
    minion-noir.sh           Raycast command (Minion Noir)
    sage.sh                  Raycast command (Sage)
    oxford.sh                Raycast command (Oxford)
    noir-plus.sh             Raycast command (Noir Plus)
  package.json              Dependencies
```

## Customization

### Creating a New Style

1. Copy an existing CSS file in `styles/` and modify it
2. Create a new entry point (copy `alumni-chapel.mjs`, change the CSS filename)
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

## Acknowledgments

Built with [Claude Code](https://claude.ai/claude-code) by Anthropic.

## License

[MIT](LICENSE)
