#!/bin/bash
mkdir -p "/Users/brianrenshaw/Documents/MDpdf"
"/opt/homebrew/bin/node" "/Users/brianrenshaw/Projects/md2pdf/oxford.mjs" "$1" "/Users/brianrenshaw/Documents/MDpdf"
