#!/bin/bash
# md2pdf — Interactive setup script

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

echo "═══════════════════════════════════════════"
echo "  md2pdf — Markdown to PDF Setup"
echo "═══════════════════════════════════════════"
echo ""

# ── Check Node.js ────────────────────────────────────────────────────────
NODE_PATH=$(which node 2>/dev/null || true)
if [ -z "$NODE_PATH" ]; then
  echo "Error: Node.js is not installed or not in PATH."
  echo "Install it from https://nodejs.org or via Homebrew: brew install node"
  exit 1
fi
NODE_VERSION=$($NODE_PATH --version)
echo "Found Node.js $NODE_VERSION at $NODE_PATH"

# ── Install dependencies ────────────────────────────────────────────────
echo ""
echo "Installing dependencies..."
cd "$SCRIPT_DIR"
npm install --silent
echo "Dependencies installed."

# ── Output directory ────────────────────────────────────────────────────
echo ""
DEFAULT_OUTPUT="$HOME/Documents/MDpdf"
read -p "Where should PDFs be saved? [$DEFAULT_OUTPUT]: " OUTPUT_DIR
OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT}"

# Expand ~ if used
OUTPUT_DIR="${OUTPUT_DIR/#\~/$HOME}"

mkdir -p "$OUTPUT_DIR"
echo "Output directory: $OUTPUT_DIR"

# ── Write config ────────────────────────────────────────────────────────
cat > "$CONFIG_FILE" << EOF
{
  "outputDir": "$OUTPUT_DIR",
  "nodePath": "$NODE_PATH"
}
EOF
echo "Config saved to config.json"

# ── Generate wrapper scripts ────────────────────────────────────────────
echo ""
echo "Generating wrapper scripts..."

# Terminal wrappers
cat > "$SCRIPT_DIR/alumni-chapel.sh" << EOF
#!/bin/bash
exec "$NODE_PATH" "$SCRIPT_DIR/alumni-chapel.mjs" "\$@"
EOF

cat > "$SCRIPT_DIR/minion-noir.sh" << EOF
#!/bin/bash
exec "$NODE_PATH" "$SCRIPT_DIR/minion-noir.mjs" "\$@"
EOF

# Obsidian wrappers
cat > "$SCRIPT_DIR/obsidian-alumni-chapel.sh" << EOF
#!/bin/bash
mkdir -p "$OUTPUT_DIR"
"$NODE_PATH" "$SCRIPT_DIR/alumni-chapel.mjs" "\$1" "$OUTPUT_DIR"
EOF

cat > "$SCRIPT_DIR/obsidian-minion-noir.sh" << EOF
#!/bin/bash
mkdir -p "$OUTPUT_DIR"
"$NODE_PATH" "$SCRIPT_DIR/minion-noir.mjs" "\$1" "$OUTPUT_DIR"
EOF

chmod +x "$SCRIPT_DIR"/*.sh

echo "Wrapper scripts generated."

# ── Symlinks ────────────────────────────────────────────────────────────
echo ""
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

ln -sf "$SCRIPT_DIR/alumni-chapel.sh" "$BIN_DIR/alumni-chapel"
ln -sf "$SCRIPT_DIR/minion-noir.sh" "$BIN_DIR/minion-noir"

if echo "$PATH" | tr ':' '\n' | grep -q "$BIN_DIR"; then
  echo "Commands linked: alumni-chapel, minion-noir"
else
  echo "Commands linked to $BIN_DIR"
  echo "Add this to your shell profile to use them:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
fi

# ── Marked 2 integration ────────────────────────────────────────────────
echo ""
MARKED_CSS_DIR="$HOME/Library/Application Support/Marked/Custom CSS"
if [ -d "$MARKED_CSS_DIR" ]; then
  read -p "Marked 2 detected. Symlink CSS files for Marked 2? [Y/n]: " MARKED_ANSWER
  MARKED_ANSWER="${MARKED_ANSWER:-Y}"
  if [[ "$MARKED_ANSWER" =~ ^[Yy] ]]; then
    ln -sf "$SCRIPT_DIR/styles/alumni-chapel.css" "$MARKED_CSS_DIR/Alumni Chapel.css"
    ln -sf "$SCRIPT_DIR/styles/minion-noir.css" "$MARKED_CSS_DIR/Minion Noir.css"
    echo "CSS files symlinked to Marked 2."
  fi
else
  echo "Marked 2 not detected (optional — not required for md2pdf)."
fi

# ── Font check ──────────────────────────────────────────────────────────
echo ""
echo "Checking fonts..."
MISSING_FONTS=0

check_font() {
  local font_name="$1"
  if command -v fc-list &>/dev/null; then
    # Linux
    fc-list | grep -qi "$font_name"
  elif [ "$(uname)" = "Darwin" ]; then
    # macOS — check system font directories
    find ~/Library/Fonts /Library/Fonts /System/Library/Fonts -iname "*${font_name}*" 2>/dev/null | grep -q .
  else
    return 1
  fi
}

if ! check_font "Minion Pro"; then
  echo "  Missing: Minion Pro (required)"
  MISSING_FONTS=1
fi
if ! check_font "Lato"; then
  echo "  Missing: Lato (required for Alumni Chapel)"
  MISSING_FONTS=1
fi
if ! check_font "STIX"; then
  echo "  Missing: STIX (required for Alumni Chapel)"
  MISSING_FONTS=1
fi

if [ $MISSING_FONTS -eq 1 ]; then
  echo ""
  echo "Download and install the missing fonts:"
  echo "  Minion Pro: https://font.download/font/minion-pro"
  echo "  Lato:       https://fonts.google.com/specimen/Lato"
  echo "  STIX:       https://github.com/stipub/stixfonts"
  echo ""
  echo "Double-click each downloaded font file and click 'Install Font.'"
else
  echo "  All required fonts are installed."
fi

# ── Raycast ─────────────────────────────────────────────────────────────
echo ""
echo "Raycast: Add $SCRIPT_DIR/raycast/ as a Script Command directory"
echo "  Raycast > Settings > Extensions > Script Commands > Add Script Directory"

# ── Summary ─────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "  Setup complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "  Terminal:   alumni-chapel report.md"
echo "              minion-noir report.md"
echo ""
echo "  Output:     $OUTPUT_DIR"
echo ""
echo "  Obsidian:   Add Shell Commands with:"
echo "    $SCRIPT_DIR/obsidian-alumni-chapel.sh {{file_path:absolute}}"
echo "    $SCRIPT_DIR/obsidian-minion-noir.sh {{file_path:absolute}}"
echo ""
echo "  Drafts:     See README.md for action scripts"
echo ""
