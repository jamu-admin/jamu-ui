#!/bin/bash
# Jamu Build Script
# Copyright (c) 2025 Jamu Team

set -e

APP_NAME="Jamu"
VERSION="0.0.1"
BUNDLE_ID="com.jamu.app"

echo "Building $APP_NAME v$VERSION for macOS..."

# Build release binary
export JAMU_AGENT_MODE=true
cargo build --release

echo "✅ Binary built: target/release/jamu"

# Create app bundle
APP_DIR="dist/$APP_NAME.app"
rm -rf dist
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp target/release/jamu "$APP_DIR/Contents/MacOS/"
chmod +x "$APP_DIR/Contents/MacOS/jamu"

# Copy MCP servers
cp -r mcp-servers "$APP_DIR/Contents/Resources/"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>jamu</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>Jamu Protocol</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>jamu</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "✅ App bundle created: $APP_DIR"
echo "📦 Ready to test: open dist/$APP_NAME.app"

