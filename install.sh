#!/bin/bash

# Simple install script for Fractal Clock
SAVER_NAME="FractalClockAbsolute.saver"
DEST_DIR="$HOME/Library/Screen Savers"

echo "🚀 Installing Fractal Clock..."

if [ ! -d "$SAVER_NAME" ]; then
    echo "❌ Error: $SAVER_NAME not found in current directory."
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "📂 Copying to $DEST_DIR..."
cp -R "$SAVER_NAME" "$DEST_DIR/"

echo "🛡️ Clearing macOS quarantine flags (to bypass 'malware' warning)..."
xattr -rd com.apple.quarantine "$DEST_DIR/$SAVER_NAME"

echo "✅ Done! You can now select 'FractalClockAbsolute' in System Settings -> Wallpapers & Screen Saver."
open "/System/Library/CoreServices/ScreenSaverEngine.app" --args -show
