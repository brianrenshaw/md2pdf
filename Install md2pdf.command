#!/bin/bash
# md2pdf — Double-click installer for macOS
# Downloads Node.js automatically if not already installed.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Clear quarantine attribute to prevent repeated Gatekeeper dialogs
xattr -d com.apple.quarantine "$0" 2>/dev/null || true

echo "═══════════════════════════════════════════"
echo "  md2pdf Installer"
echo "═══════════════════════════════════════════"
echo ""

# ── Check for existing Node.js ──────────────────────────────────────────
NODE_CMD=""

# Check local .node/ first
if [ -x "$SCRIPT_DIR/.node/bin/node" ]; then
  NODE_CMD="$SCRIPT_DIR/.node/bin/node"
# Then check system Node.js (must be v18+)
elif command -v node &>/dev/null; then
  SYSTEM_NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
  if [ "$SYSTEM_NODE_MAJOR" -ge 18 ] 2>/dev/null; then
    NODE_CMD="$(command -v node)"
  fi
fi

# ── Download Node.js if needed ──────────────────────────────────────────
if [ -z "$NODE_CMD" ]; then
  echo "Node.js not found. Downloading..."
  echo ""

  ARCH=$(uname -m)
  if [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
  else
    NODE_ARCH="x64"
  fi

  NODE_VERSION="v22.14.0"
  NODE_TARBALL="node-${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
  NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_TARBALL}"

  echo "Downloading Node.js ${NODE_VERSION} for ${NODE_ARCH}..."
  curl -#fL "$NODE_URL" -o "/tmp/$NODE_TARBALL"

  echo "Extracting..."
  mkdir -p "$SCRIPT_DIR/.node"
  tar -xzf "/tmp/$NODE_TARBALL" -C "$SCRIPT_DIR/.node" --strip-components=1
  rm -f "/tmp/$NODE_TARBALL"

  NODE_CMD="$SCRIPT_DIR/.node/bin/node"
  echo "Node.js installed locally."
  echo ""
fi

echo "Using Node.js $($NODE_CMD --version)"
echo ""

# ── Determine npm path ──────────────────────────────────────────────────
NODE_DIR="$(dirname "$NODE_CMD")"
if [ -x "$NODE_DIR/npm" ]; then
  NPM_CMD="$NODE_DIR/npm"
else
  NPM_CMD="npm"
fi

# ── Run install.sh in non-interactive mode ──────────────────────────────
export MD2PDF_NODE_PATH="$NODE_CMD"
export MD2PDF_NPM_PATH="$NPM_CMD"
bash "$SCRIPT_DIR/install.sh" --non-interactive

echo ""
echo "You can close this window."
