#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Minion Noir PDF
# @raycast.mode fullOutput
# @raycast.packageName md2pdf

# Optional parameters:
# @raycast.icon 🖤
# @raycast.argument1 { "type": "text", "placeholder": "File or folder path", "optional": true }

# Documentation:
# @raycast.description Convert selected Markdown file(s) to monochrome Minion Pro PDF
# @raycast.author Brian Renshaw

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$SCRIPT_DIR/config.json"

NODE_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG'))['nodePath'])" 2>/dev/null || echo "node")

TARGET="${1}"

if [ -z "$TARGET" ]; then
  TARGET=$(osascript -e '
    tell application "Finder"
      set theSelection to selection
      if (count of theSelection) > 0 then
        return POSIX path of (item 1 of theSelection as alias)
      else
        return ""
      end if
    end tell
  ' 2>/dev/null)
fi

if [ -z "$TARGET" ]; then
  echo "Error: No file or folder selected."
  echo "Select a Markdown file or folder in Finder, or pass a path as an argument."
  exit 1
fi

TARGET="${TARGET%/}"

echo "Converting: $TARGET"
echo "---"

"$NODE_PATH" "$SCRIPT_DIR/md2pdf.mjs" "minion-noir" "$TARGET"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "---"
  echo "Done. PDF(s) saved next to the source file(s)."
else
  echo "---"
  echo "Conversion failed (exit code $EXIT_CODE)."
fi

exit $EXIT_CODE
