#!/usr/bin/env bash

set -euo pipefail

# Check dependencies
for cmd in wine wrestool icotool convert; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Missing required tool '$cmd'." >&2
        echo "Please install icoutils, imagemagick, and wine." >&2
        exit 1
    fi
done

# Prompt for EXE path if not provided as argument
EXE_PATH="${1:-}"
if [[ -z "$EXE_PATH" ]]; then
    read -rp "Enter path to .exe file: " EXE_PATH
fi

# Expand relative paths to absolute
EXE_PATH="$(realpath "$EXE_PATH")"

if [[ ! -f "$EXE_PATH" ]]; then
    echo "Error: File '$EXE_PATH' does not exist." >&2
    exit 1
fi

# Defaults & derived values
APP_DIR="$(dirname "$EXE_PATH")"
DEFAULT_NAME="$(basename "$EXE_PATH" .exe)"
DEFAULT_NAME="${DEFAULT_NAME^}" # Capitalize first letter

read -rp "App Name [$DEFAULT_NAME]: " APP_NAME
APP_NAME="${APP_NAME:-$DEFAULT_NAME}"

read -rp "Wine Prefix [${WINEPREFIX:-$HOME/.wine}]: " TARGET_PREFIX
TARGET_PREFIX="${TARGET_PREFIX:-${WINEPREFIX:-$HOME/.wine}}"

# Prepare output locations
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
APP_DIR_TARGET="$HOME/.local/share/applications"
mkdir -p "$ICON_DIR" "$APP_DIR_TARGET"

SLUG="$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-')"
ICON_PATH="$ICON_DIR/$SLUG.png"
DESKTOP_FILE="$APP_DIR_TARGET/wine-$SLUG.desktop"

# Icon extraction step
echo "Extracting icon from executable..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if wrestool -x -t14 "$EXE_PATH" -o "$TMP_DIR/extracted.ico" &>/dev/null; then
    icotool -x -o "$TMP_DIR" "$TMP_DIR/extracted.ico" &>/dev/null
    # Pick the largest extracted PNG frame
    LARGEST_PNG="$(ls -S "$TMP_DIR"/*.png 2>/dev/null | head -n 1)"
    if [[ -n "$LARGEST_PNG" ]]; then
        cp "$LARGEST_PNG" "$ICON_PATH"
        echo "Icon saved to: $ICON_PATH"
    fi
fi

if [[ ! -f "$ICON_PATH" ]]; then
    echo "Warning: Could not extract icon. Using default Wine icon."
    ICON_PATH="wine"
fi

# Write .desktop entry
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=env WINEPREFIX="$TARGET_PREFIX" wine "$EXE_PATH"
Path=$APP_DIR
Icon=$ICON_PATH
Terminal=false
Categories=Wine;Utility;
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
echo "Successfully created: $DESKTOP_FILE"
