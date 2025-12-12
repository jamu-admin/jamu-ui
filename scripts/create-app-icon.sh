#!/bin/bash
# Create macOS app icon from logo image

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# The logo file should be provided as argument or use default
LOGO_FILE="${1:-$PROJECT_ROOT/jamu-logo.png}"

if [ ! -f "$LOGO_FILE" ]; then
    echo "❌ Logo file not found: $LOGO_FILE"
    echo ""
    echo "Usage: $0 /path/to/logo.png"
    echo ""
    echo "The logo image will be converted to .icns format for macOS"
    exit 1
fi

echo "🎨 Creating app icon from: $LOGO_FILE"

# Create temporary iconset directory
ICONSET_DIR="$PROJECT_ROOT/dist/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

# Generate different sizes using sips (built-in macOS tool)
for size in 16 32 64 128 256 512; do
    double=$((size * 2))
    
    echo "  Creating ${size}x${size} icon..."
    sips -z $size $size "$LOGO_FILE" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null 2>&1
    
    echo "  Creating ${size}x${size}@2x icon..."
    sips -z $double $double "$LOGO_FILE" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null 2>&1
done

# Convert iconset to icns
echo "🔨 Converting to .icns format..."
iconutil -c icns "$ICONSET_DIR" -o "$PROJECT_ROOT/dist/Jamu.app/Contents/Resources/AppIcon.icns"

# Clean up
rm -rf "$ICONSET_DIR"

echo "✅ App icon created: dist/Jamu.app/Contents/Resources/AppIcon.icns"
echo ""
echo "To apply:"
echo "  1. The icon is already in the right place"
echo "  2. Restart Jamu.app to see the new icon"
echo "  3. Or update Info.plist CFBundleIconFile to reference AppIcon"

