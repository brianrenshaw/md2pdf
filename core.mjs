// core.mjs — Shared Markdown-to-PDF conversion logic
// Used by alumni-chapel.mjs and minion-noir.mjs

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import puppeteer from "puppeteer";
import markdownit from "markdown-it";
import footnote from "markdown-it-footnote";
import anchor from "markdown-it-anchor";
import toc from "markdown-it-table-of-contents";
import deflist from "markdown-it-deflist";
import container from "markdown-it-container";

// ── Config ──────────────────────────────────────────────────────────────
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CONFIG_PATH = path.join(__dirname, "config.json");
const MARGIN = { top: "0.75in", right: "0.75in", bottom: "0.75in", left: "0.75in" };

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    console.error("No config.json found. Run ./install.sh first.");
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(CONFIG_PATH, "utf-8"));
}

export function stylePath(name) {
  return path.join(__dirname, "styles", name);
}

// ── Markdown parser ─────────────────────────────────────────────────────
function createParser(tocLevels) {
  const includeLevel = tocLevels || [2, 3, 4];

  const md = markdownit({ html: true, typographer: true, linkify: true })
    .use(footnote)
    .use(anchor, { permalink: false })
    .use(toc, { includeLevel })
    .use(deflist);

  // Register callout container types: note, warning, tip
  for (const type of ["note", "warning", "tip"]) {
    const defaultTitle = type.charAt(0).toUpperCase() + type.slice(1);
    md.use(container, type, {
      render(tokens, idx) {
        if (tokens[idx].nesting === 1) {
          const info = tokens[idx].info.trim().slice(type.length).trim();
          const title = info || defaultTitle;
          return `<div class="callout callout-${type}"><div class="callout-title">${title}</div>\n`;
        }
        return "</div>\n";
      },
    });
  }

  return md;
}

// ── Helpers ─────────────────────────────────────────────────────────────
function collectMarkdownFiles(target) {
  const stat = fs.statSync(target);
  if (stat.isFile() && /\.(md|markdown|txt)$/i.test(target)) {
    return [path.resolve(target)];
  }
  if (stat.isDirectory()) {
    return fs
      .readdirSync(target)
      .filter((f) => /\.(md|markdown|txt)$/i.test(f))
      .sort()
      .map((f) => path.resolve(target, f));
  }
  return [];
}

function stripFrontmatter(source) {
  return source.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/, "");
}

function extractDirectives(source) {
  source = stripFrontmatter(source);
  let footLeft = "";
  let showHeader = true;

  const footMatch = source.match(/^\[\[foot-left\]\]\s*(.+)$/m);
  if (footMatch) {
    footLeft = footMatch[1].trim();
    source = source.replace(footMatch[0], "");
  }

  const headerMatch = source.match(/^\[\[no-header\]\]\s*$/m);
  if (headerMatch) {
    showHeader = false;
    source = source.replace(headerMatch[0], "");
  }

  const footerMatch = source.match(/^\[\[no-footer\]\]\s*$/m);
  let showFooter = true;
  if (footerMatch) {
    showFooter = false;
    source = source.replace(footerMatch[0], "");
  }

  let tocLevels = null;
  const tocMatch = source.match(/^\[\[toc-levels:([1-6,\s-]+)\]\]\s*$/m);
  if (tocMatch) {
    const spec = tocMatch[1].replace(/\s/g, "");
    const rangeMatch = spec.match(/^(\d)-(\d)$/);
    if (rangeMatch) {
      const start = parseInt(rangeMatch[1], 10);
      const end = parseInt(rangeMatch[2], 10);
      tocLevels = Array.from({ length: end - start + 1 }, (_, i) => start + i);
    } else {
      tocLevels = spec.split(",").map(Number);
    }
    source = source.replace(tocMatch[0], "");
  }

  return { footLeft, showHeader, showFooter, tocLevels, source: source.trim() };
}

function buildHTML(markdownSource, title, css, md) {
  const body = md.render(markdownSource);

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${title}</title>
  <style>${css}</style>
  <style>
    /* Override screen-only wrapper styles for PDF rendering */
    body { margin: 0; }
    #wrapper {
      max-width: none !important;
      padding: 0 !important;
      margin: 0 !important;
    }
  </style>
</head>
<body>
  <div id="wrapper">${body}</div>
</body>
</html>`;
}

// ── Convert ─────────────────────────────────────────────────────────────
async function convert(inputPath, outputPath, css) {
  const raw = fs.readFileSync(inputPath, "utf-8");
  const { footLeft, showHeader, showFooter, tocLevels, source } = extractDirectives(raw);
  const title = path.basename(inputPath, path.extname(inputPath));
  const md = createParser(tocLevels);
  const html = buildHTML(source, title, css, md);

  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: "networkidle0" });

  const footerStyle = `font-family: Lato, Helvetica, sans-serif; font-size: 9px; color: #999;`;

  await page.pdf({
    path: outputPath,
    format: "Letter",
    margin: MARGIN,
    printBackground: true,
    outline: true,
    displayHeaderFooter: true,
    headerTemplate: showHeader
      ? `<div style="${footerStyle} width: 100%; padding: 0 0.5in;">
          <span>${title}</span>
        </div>`
      : `<div></div>`,
    footerTemplate: showFooter
      ? `<div style="${footerStyle} width: 100%; padding: 0 0.5in; display: flex; justify-content: space-between;">
          <span>${footLeft}</span>
          <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
        </div>`
      : `<div></div>`,
  });

  await browser.close();
  return outputPath;
}

// ── Public entry point ──────────────────────────────────────────────────
export async function run(cssFilename, argOffset = 2) {
  const config = loadConfig();
  const cssPath = stylePath(cssFilename);
  const args = process.argv.slice(argOffset);
  if (args.length === 0) {
    const scriptName = path.basename(process.argv[1], ".mjs");
    console.error(`Usage: ${scriptName} <file.md | folder> [output-dir]`);
    process.exit(1);
  }

  const cleanPath = (p) => p.replace(/\\(.)/g, "$1");
  const target = path.resolve(cleanPath(args[0]));
  const outputDir = args[1] ? path.resolve(cleanPath(args[1])) : path.dirname(target);
  const files = collectMarkdownFiles(target);

  if (files.length === 0) {
    console.error(`No Markdown files found in: ${target}`);
    process.exit(1);
  }

  const css = fs.readFileSync(cssPath, "utf-8");

  for (const file of files) {
    const outName = path.basename(file, path.extname(file)) + ".pdf";
    const outPath = path.join(outputDir, outName);
    const result = await convert(file, outPath, css);
    console.log(`✓ ${result}`);
  }
}
