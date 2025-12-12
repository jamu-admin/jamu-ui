#!/bin/bash
set -euo pipefail

LOGO_DIR="Jamu_macos_26_tahoe_logos"
SOURCE_IMAGE="$LOGO_DIR/Jamu_macos_26_tahoe-macOS-Default-1024x1024@1x.png"
ICONSET_DIR="Jamu.iconset"

if [ ! -f "$SOURCE_IMAGE" ]; then
  echo "Error: Source image not found at $SOURCE_IMAGE"
  exit 1
fi

echo "Creating iconset folder..."
mkdir -p "$ICONSET_DIR"

echo "Generating icon sizes..."
sips -z 16 16     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16.png"
sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png"
sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32.png"
sips -z 64 64     "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png"
sips -z 128 128   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128.png"
sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png"
sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256.png"
sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png"
sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512.png"
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png"

echo "Converting to icns..."
iconutil -c icns "$ICONSET_DIR" -o logo.icns

echo "Cleaning up..."
rm -rf "$ICONSET_DIR"

echo "✅ Successfully created logo.icns"
ls -lh logo.icns








