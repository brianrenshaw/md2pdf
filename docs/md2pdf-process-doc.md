# md2pdf Process Documentation

## Why This Exists

Markdown is a great writing format, but it looks plain when printed or shared as a PDF. Most Markdown-to-PDF tools produce generic output with no control over typography, colors, or branding. If you want a polished, professionally styled PDF, you either hand-format it in a word processor or fight with LaTeX.

md2pdf solves this by converting Markdown files into styled PDFs using CSS. You write in Markdown, pick a visual style, and get a PDF that looks like it was designed on purpose. Seven styles are included, each with distinct typography and color palettes. The same rendering engine powers all of them, so adding a new style means writing one CSS file.

The tool runs from the terminal, Raycast, Obsidian, Drafts (Mac and iOS), and Marked 2. The rendering output is identical regardless of how you invoke it.

## What It Produces

Each conversion produces a single PDF file with these characteristics:

* **Format:** US Letter (8.5 x 11 inches)
* **Margins:** 0.75 inches on all sides
* **Header:** Document title in the top-left corner (suppressible via `[[no-header]]`)
* **Footer:** Custom text bottom-left, "Page X of Y" bottom-right (suppressible via `[[no-footer]]`)
* **Bookmarks:** Navigable PDF outline auto-generated from headings
* **Background colors:** Rendered (callout boxes, code blocks retain their backgrounds)

The output filename matches the input filename with a `.pdf` extension. For example, `report.md` becomes `report.pdf`.

By default, the PDF is saved next to the source file. You can override this with a second argument (output directory) or by using the Obsidian/Drafts wrappers, which default to `~/Documents/MDpdf`.

## How the Rendering Engine Works

The engine lives in two files: `md2pdf.mjs` (entry point / style dispatcher) and `core.mjs` (all conversion logic).

### The Pipeline

```
Markdown file
    |
    v
Read file from disk
    |
    v
Strip YAML frontmatter (regex: /^---\n...\n---/)
    |
    v
Extract directives ([[foot-left]], [[no-header]], [[no-footer]], [[toc-levels]])
    |
    v
Parse Markdown with markdown-it + 6 plugins
    |
    v
Wrap parsed HTML in a full <html> document with embedded <style> block
    |
    v
Launch headless Chromium via Puppeteer
    |
    v
Render HTML to PDF with configured margins, headers, footers, bookmarks
    |
    v
Save PDF, close browser
```

### Markdown Parsing

The parser is markdown-it configured with `html: true`, `typographer: true`, and `linkify: true`. Six plugins extend it:

| Plugin | What It Adds |
|--------|-------------|
| `markdown-it-footnote` | Footnote syntax (`[^1]`) with auto-numbered rendering |
| `markdown-it-anchor` | Heading IDs (used for PDF bookmarks) |
| `markdown-it-table-of-contents` | `[[toc]]` placeholder expands to a linked TOC |
| `markdown-it-deflist` | Definition list syntax (`Term` / `:   Definition`) |
| `markdown-it-container` | Fenced callout boxes (`::: note`, `::: warning`, `::: tip`) |

The TOC plugin respects the `[[toc-levels]]` directive. Default levels are H2, H3, and H4. You can override with a comma list or a range.

Place `[[toc]]` on its own line to generate the TOC. To control which heading levels are included, add `[[toc-levels]]` before `[[toc]]`. Both are required for custom levels.

| Directive | Headings Included |
|-----------|-------------------|
| `[[toc-levels:2]]` | H2 only |
| `[[toc-levels:2,3]]` | H2 + H3 |
| `[[toc-levels:1-3]]` | H1 + H2 + H3 |
| `[[toc-levels:1,2]]` | H1 + H2 |
| *(no directive)* | H2 + H3 + H4 (default) |

Basic usage (default levels H2-H4):

```markdown
# Report Title

[[toc]]

## First Section
```

Custom levels (H2 and H3 only):

```markdown
[[toc-levels:2,3]]
[[toc]]

# Main Title (excluded from TOC)
## Section One
### Subsection
#### Sub-subsection (excluded from TOC)
```

Range syntax (H1 through H3):

```markdown
[[toc-levels:1-3]]
[[toc]]

# Top-Level Heading (included)
## Section
### Subsection
#### Deep Heading (excluded)
```

If you use `[[toc-levels]]` without `[[toc]]`, no TOC appears. If you use `[[toc]]` without `[[toc-levels]]`, the default levels (H2-H4) are used.

### Directives

Directives are custom syntax that controls PDF output. They are extracted from the source and stripped before rendering. The parser uses regex matching on each directive pattern.

| Directive | What It Does | Default |
|-----------|-------------|---------|
| `[[foot-left]] Your text` | Sets bottom-left footer text on every page | Empty |
| `[[no-header]]` | Removes the document title from the header | Header shown |
| `[[no-footer]]` | Removes the entire footer (page numbers and custom text) | Footer shown |
| `[[toc-levels:N]]` | Controls which heading levels appear in the TOC | H2, H3, H4 |

Directives go on their own line, anywhere in the document.

### Why Puppeteer?

Puppeteer (headless Chromium) was chosen because it renders CSS exactly as a browser would. This means:

* **Full CSS support:** Flexbox, grid, custom properties, `@import` for Google Fonts, `@media print` rules all work.
* **Pixel-perfect output:** What you see in Chrome is what you get in the PDF.
* **No template language:** Styles are pure CSS files. Anyone who knows CSS can create or modify a style.
* **Built-in PDF features:** Puppeteer's `page.pdf()` natively supports headers, footers, page numbers, margins, and PDF outline/bookmarks.

The tradeoff is that Puppeteer downloads a Chromium binary (~170 MB) on first install. This is a one-time cost.

### Why Embedded CSS?

All CSS is read from the style file and injected into the HTML as an inline `<style>` block. No external stylesheet references. This means the HTML sent to Puppeteer is completely self-contained. There is no dependency on file paths or network access during rendering (except for styles that `@import` Google Fonts, like Cardinals and Anthropic).

### Why Custom Directive Syntax?

The `[[directive]]` syntax was chosen because:

* It does not conflict with standard Markdown syntax.
* It is visually distinct in source files.
* It is easy to strip with a single regex per directive.
* Double brackets are not rendered by any common Markdown parser, so if directives are accidentally left in, they appear as plain text rather than causing rendering errors.

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| `core.mjs` | repo root | Rendering engine: Markdown parsing, HTML generation, Puppeteer PDF conversion |
| `md2pdf.mjs` | repo root | Unified CLI entry point; validates style name and dispatches to `core.mjs` |
| `install.sh` | repo root | Interactive/non-interactive setup: installs deps, generates wrappers, symlinks commands |
| `Install md2pdf.command` | repo root | macOS double-click installer (downloads Node.js if needed, calls `install.sh`) |
| `Install md2pdf.bat` | repo root | Windows double-click installer |
| `config.json` | repo root (gitignored) | Per-user config: `outputDir` and `nodePath` |
| `package.json` | repo root | npm metadata and dependency list |
| `alumni-chapel.css` | `styles/` | Alumni Chapel style: navy, gold, green (Southern Seminary brand) |
| `minion-noir.css` | `styles/` | Minion Noir style: monochrome black and gray |
| `sage.css` | `styles/` | Sage style: cool blue-gray Swiss minimalist |
| `oxford.css` | `styles/` | Oxford style: navy and burgundy warm academic |
| `noir-plus.css` | `styles/` | Noir Plus style: dark background with vibrant accents |
| `cardinals.css` | `styles/` | Cardinals style: red, navy, gold (St. Louis Cardinals heritage) |
| `anthropic.css` | `styles/` | Anthropic style: terra cotta, sand, ink tones |
| `*-ios.css` | `styles/` | iOS variants of each style for Drafts app preview (7 files) |
| `alumni-chapel.sh` | repo root (generated) | Terminal wrapper: calls `md2pdf.mjs` with `alumni-chapel` style |
| `obsidian-alumni-chapel.sh` | repo root (generated) | Obsidian wrapper: creates output dir, converts file |
| `raycast/alumni-chapel.sh` | `raycast/` | Raycast Script Command with `@raycast.*` metadata |
| `css-test-document.md` | `samples/` | Comprehensive test file exercising every Markdown feature |
| `*.pdf` | `samples/` | Sample PDF output for each style |
| `fonts/README.md` | `fonts/` | Font download links and requirements |
| `README.md` | repo root | User-facing documentation |

Wrapper scripts (`*.sh`, `obsidian-*.sh`) are generated by `install.sh` for all seven styles. The table above shows one example of each type. The Raycast directory contains one script per style, also following the same pattern.

**Links:**

* GitHub repository: https://github.com/brianrenshaw/md2pdf

## Directory Layout

```
md2pdf/
  core.mjs                         Rendering engine (shared by all styles)
  md2pdf.mjs                       Unified CLI entry point
  install.sh                       Setup script (interactive or non-interactive)
  Install md2pdf.command            macOS double-click installer
  Install md2pdf.bat                Windows double-click installer
  config.json                       Per-user config (generated, gitignored)
  package.json                      npm dependencies and metadata
  package-lock.json                 npm lockfile
  LICENSE                           MIT license
  README.md                         User-facing documentation
  styles/
    alumni-chapel.css               Alumni Chapel PDF style
    alumni-chapel-ios.css           Alumni Chapel iOS/Drafts preview style
    minion-noir.css                 Minion Noir PDF style
    minion-noir-ios.css             Minion Noir iOS/Drafts preview style
    sage.css                        Sage PDF style
    sage-ios.css                    Sage iOS/Drafts preview style
    oxford.css                      Oxford PDF style
    oxford-ios.css                  Oxford iOS/Drafts preview style
    noir-plus.css                   Noir Plus PDF style
    noir-plus-ios.css               Noir Plus iOS/Drafts preview style
    cardinals.css                   Cardinals PDF style
    cardinals-ios.css               Cardinals iOS/Drafts preview style
    anthropic.css                   Anthropic PDF style
    anthropic-ios.css               Anthropic iOS/Drafts preview style
  raycast/
    alumni-chapel.sh                Raycast Script Command (one per style)
    minion-noir.sh
    sage.sh
    oxford.sh
    noir-plus.sh
    cardinals.sh
    anthropic.sh
  samples/
    css-test-document.md            Test document exercising all features
    css-test-document-*.pdf         Sample output PDFs (one per style)
  fonts/
    README.md                       Font download links
  inspiration/
    anthropic-design-system.html    Design reference for the Anthropic style
  docs/
    md2pdf-process-doc.md           This file
```

Generated files (gitignored, created by `install.sh`):

```
  alumni-chapel.sh                  Terminal wrapper (one per style)
  obsidian-alumni-chapel.sh         Obsidian wrapper (one per style)
```

Symlinks created in `~/.local/bin/`:

```
  alumni-chapel -> /path/to/md2pdf/alumni-chapel.sh
  minion-noir   -> /path/to/md2pdf/minion-noir.sh
  sage          -> /path/to/md2pdf/sage.sh
  oxford        -> /path/to/md2pdf/oxford.sh
  noir-plus     -> /path/to/md2pdf/noir-plus.sh
  cardinals     -> /path/to/md2pdf/cardinals.sh
  anthropic     -> /path/to/md2pdf/anthropic.sh
```

## How to Run Operations

### Convert a single file from the terminal

```bash
alumni-chapel report.md
```

This saves `report.pdf` in the same directory as `report.md`.

### Convert to a specific output directory

```bash
alumni-chapel report.md ~/Documents/MDpdf
```

### Batch convert all Markdown files in a folder

```bash
alumni-chapel ~/reports/
```

Processes every `.md`, `.markdown`, and `.txt` file in the folder. PDFs are saved in the same folder.

### Use a different style

Replace `alumni-chapel` with any style name:

```bash
minion-noir report.md
sage report.md
oxford report.md
noir-plus report.md
cardinals report.md
anthropic report.md
```

### Run via the unified entry point

If you prefer not to use the wrapper scripts:

```bash
node md2pdf.mjs alumni-chapel report.md ~/Documents/MDpdf
```

### Raycast

Open Raycast, search for the style name (e.g., "Alumni Chapel PDF"). It detects the file selected in Finder or accepts a path as input. The PDF is saved to the configured output directory.

**Setup:** Raycast > Settings > Extensions > Script Commands > Add Script Directory > select the `raycast/` folder.

### Obsidian

With the Shell Commands plugin installed, create a command pointing to the appropriate wrapper:

```
/path/to/md2pdf/obsidian-alumni-chapel.sh {{file_path:absolute}}
```

The PDF is saved to `~/Documents/MDpdf` (or whatever `config.json` specifies).

### Drafts (Mac)

Create an action with a Script step. The script writes the draft content to a temp file, calls `md2pdf.mjs`, and cleans up. See the README for the full JavaScript action code. The filename is derived from the first H1 heading (falls back to H2, then "Untitled").

### Drafts (iOS/iPadOS)

iOS cannot run shell scripts. Instead:

1. Install the "Preview/Print with CSS" action from the Drafts Directory.
2. Create drafts tagged `css` containing the contents of each `-ios.css` file.
3. Open any Markdown draft, run the action, and select your CSS style.

**Important:** Remove md2pdf-specific syntax before previewing on iOS. These features are not supported in Drafts' Markdown parser:

* Directives: `[[foot-left]]`, `[[no-header]]`, `[[no-footer]]`, `[[toc-levels:N]]`
* Callout boxes: `::: note`, `::: warning`, `::: tip`
* Auto table of contents: `[[toc]]`
* Definition lists (unless using MultiMarkdown parser)

### Marked 2

If Marked 2 is installed, `install.sh` symlinks all CSS files into `~/Library/Application Support/Marked/Custom CSS/`. The styles appear in Marked 2's style dropdown. CSS changes in the repo are automatically reflected in Marked 2 because the symlinks point to the repo files.

## How to Modify

### Add a new style

1. Copy an existing CSS file in `styles/` and rename it (e.g., `styles/my-style.css`).
2. Edit the CSS. The structure is standard: `:root` variables, body font, heading styles, callout colors, table styles, code block styles.
3. Optionally create a matching `-ios.css` variant for Drafts iOS.
4. Run `./install.sh` to regenerate wrapper scripts and symlinks. The install script auto-detects all `.css` files in `styles/` (excluding `-ios` variants) and generates wrappers for each one.

That is it. No code changes required. The `md2pdf.mjs` entry point dynamically reads the `styles/` directory.

### Change the default output directory

Either:

* Run `./install.sh` again and enter the new path when prompted.
* Edit `config.json` directly and change the `outputDir` value. Then re-run `./install.sh` to regenerate the Obsidian wrappers (they hard-code the output path).

### Change PDF margins

Edit the `MARGIN` constant in `core.mjs` (line 18):

```javascript
const MARGIN = { top: "0.75in", right: "0.75in", bottom: "0.75in", left: "0.75in" };
```

### Change header/footer styling

Edit the `headerTemplate` and `footerTemplate` strings in the `convert()` function in `core.mjs` (around line 168). These are HTML strings with inline CSS. Puppeteer renders them in a special context with a fixed 9px base font size.

### Add a new directive

1. In `core.mjs`, add a regex match in the `extractDirectives()` function (starts at line 80).
2. Strip the matched directive from the source string.
3. Return the extracted value in the returned object.
4. Use the value in the `convert()` function where the PDF options are set.

### Change the Markdown parser configuration

Edit the `createParser()` function in `core.mjs` (line 33). The markdown-it instance is created there with all plugins. To add a new plugin, `npm install` it and `.use()` it in the chain.

## Known Quirks and Edge Cases

### macOS security dialog for .command files

The first time you double-click `Install md2pdf.command`, macOS blocks it because it was downloaded from the internet. Right-click > Open > Open to bypass this. You only need to do this once.

### Font availability affects rendering

If a style's required fonts are not installed, Puppeteer falls back to system defaults. The PDF will render but will not match the intended design. The `install.sh` script checks for fonts and reports any that are missing.

Styles that require local fonts:

* **Alumni Chapel:** Minion Pro, Lato, STIX
* **Minion Noir:** Minion Pro
* **Oxford:** New York (falls back to Minion Pro)

Styles that load fonts from Google Fonts (no local install needed): Cardinals, Anthropic. Styles that use system fonts: Sage, Noir Plus.

### YAML frontmatter is always stripped

Any content between `---` fences at the top of the file is removed before rendering. This is intentional so that Obsidian and other tools' frontmatter does not appear in the PDF. There is no way to preserve it.

### Directives must be on their own line

`[[foot-left]] Updated: 2026-03-19` works. Embedding a directive mid-paragraph does not. The regex matches from the start of a line.

### Code blocks never split across pages

CSS `break-inside: avoid` is applied to all code blocks. If a code block is too tall for the remaining space on a page, it moves to the next page. This can leave white space at the bottom of the previous page.

### The `[[toc]]` and `[[toc-levels]]` relationship

`[[toc-levels]]` configures which heading levels to include. `[[toc]]` places the TOC in the document. You need both for a custom-level TOC. Using `[[toc]]` alone gives default levels (H2-H4). Using `[[toc-levels]]` alone does nothing visible.

### Puppeteer header/footer font size

Puppeteer renders headers and footers in a special context where the root font size is locked. The templates use 9px inline. Changing this in CSS has no effect; it must be changed in the inline style within `core.mjs`.

### Batch mode processes one level deep

When you pass a folder, `collectMarkdownFiles()` reads the immediate contents of that directory. It does not recurse into subdirectories.

### The `#wrapper` div

All rendered HTML is wrapped in `<div id="wrapper">`. The PDF rendering overrides `#wrapper` to remove max-width and padding (which exist for screen preview in tools like Marked 2). If you are writing CSS for Marked 2 compatibility, do not put `#wrapper` overrides inside `@media print` in the style CSS. The engine handles this in `core.mjs`.

## If You Are Setting This Up From Scratch

### Prerequisites

* **macOS or Windows.** Tested on macOS (Apple Silicon and Intel) and Windows.
* **Internet connection** on first run (to download Node.js and Chromium).

### Step-by-step

1. Clone or download the repository:

```bash
git clone https://github.com/brianrenshaw/md2pdf.git
cd md2pdf
```

2. Install fonts. Download and install the fonts for whichever styles you plan to use. See the font table in the README or in `fonts/README.md`. Double-click each downloaded font file to install it.
3. Run the installer:
    * **macOS:** Double-click `Install md2pdf.command` (downloads Node.js if needed, fully automated).
    * **Windows:** Double-click `Install md2pdf.bat`.
    * **Advanced:** Run `./install.sh` for interactive setup (requires Node.js v18+ already installed).
4. Verify `~/.local/bin` is in your PATH. If not, add it:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Add this line to your `~/.zshrc` or `~/.bashrc` to make it permanent.

5. Test it:

```bash
alumni-chapel samples/css-test-document.md
```

This should produce a PDF in the `samples/` directory.

### Optional integrations

* **Raycast:** Raycast > Settings > Extensions > Script Commands > Add Script Directory > point to the `raycast/` folder inside the repo.
* **Obsidian:** Install the Shell Commands community plugin. Create one command per style using the paths printed at the end of `install.sh` output.
* **Marked 2:** The installer auto-symlinks CSS if Marked 2 is detected. Styles appear in Marked 2's style dropdown.
* **Drafts (Mac):** Create an action with a Script step. See the README for the JavaScript code.
* **Drafts (iOS):** Copy iOS CSS files into Drafts as `css`-tagged drafts. Use the "Preview/Print with CSS" action.

## History

| Date | What Changed |
|------|-------------|
| 2026-03-19 | Initial release with two styles: Alumni Chapel and Minion Noir |
| 2026-03-19 | Added sample PDFs, refined Minion Noir typography |
| 2026-03-21 | Added one-click installers for macOS and Windows |
| 2026-03-21 | Added three new styles: Sage, Oxford, Noir Plus |
| 2026-03-21 | Consolidated five separate entry points into a single `md2pdf.mjs` |
| 2026-03-24 | Added Cardinals style (St. Louis Cardinals heritage) |
| 2026-03-24 | Added per-file TOC level control (`[[toc-levels]]`) and iOS CSS for all styles |
| 2026-03-24 | Added Anthropic style (terra cotta, sand, ink) |
| 2026-03-24 | Fixed code block overflow in all CSS styles |
| 2026-03-26 | Prevented code blocks from splitting across pages |
