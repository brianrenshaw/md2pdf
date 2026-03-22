#!/usr/bin/env node
// md2pdf — Unified Markdown-to-PDF converter
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { run } from "./core.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const stylesDir = path.join(__dirname, "styles");

const styleName = process.argv[2];

const available = fs.readdirSync(stylesDir)
  .filter(f => f.endsWith(".css") && !f.includes("-ios"))
  .map(f => f.replace(".css", ""));

if (!styleName || !available.includes(styleName)) {
  console.error("Usage: md2pdf <style> <file.md | folder> [output-dir]");
  console.error(`\nAvailable styles: ${available.join(", ")}`);
  process.exit(1);
}

run(`${styleName}.css`, 3);
