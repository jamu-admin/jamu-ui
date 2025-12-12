#!/bin/bash
set -euo pipefail

APP_NAME="Jamu"
APP_IDENTIFIER="dev.zed.Jamu"
APP_VERSION="0.0.1"
BUILD_TARGET="release"
DIST_DIR="dist"
APP_BUNDLE_PATH="$DIST_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE_PATH/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE_PATH/Contents/Resources"

echo "Building Jamu.app standalone package..."
echo "Using Jamu LLM gateway: https://llm.jamu.ai/v1"

# Build the app (use 'jamu' binary, not 'zed')
echo "Building release binary..."
cargo build --release --bin jamu

# Create app bundle structure
echo "Creating app bundle structure..."
rm -rf "$APP_BUNDLE_PATH"
mkdir -p "$DIST_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy main binary (jamu, not zed)
echo "Copying binaries..."
cp target/$BUILD_TARGET/jamu "$MACOS_DIR/zed-bin"
chmod +x "$MACOS_DIR/zed-bin"

# Jamu config version - bump this when config structure changes
JAMU_CONFIG_VERSION="6"

# Create launcher script that injects API key and creates initial settings
cat > "$MACOS_DIR/zed" << LAUNCHER_SCRIPT
#!/bin/bash
DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="\$DIR/../Resources"

# Enable Jamu agent mode (minimal UI, locked layout)
export JAMU_AGENT_MODE=true

# Create user config directory if it doesn't exist
ZED_CONFIG_DIR="\$HOME/.config/zed"
ZED_SETTINGS_FILE="\$ZED_CONFIG_DIR/settings.json"
mkdir -p "\$ZED_CONFIG_DIR"

# Config version for this release
JAMU_CONFIG_VERSION="$JAMU_CONFIG_VERSION"

# Ensure settings file has required configuration
python3 - "\$ZED_SETTINGS_FILE" "\$JAMU_CONFIG_VERSION" << 'PYTHON_CONFIG_EOF'
import json
import sys
import os

settings_file = sys.argv[1]
config_version = sys.argv[2]

# Read existing settings or start fresh
try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except:
    settings = {}

# Track if we made changes
changed = False

# Get current Jamu config version from settings
current_version = settings.get('_jamu_config_version', '0')

# --- AGENT DEFAULTS ---
# Only set if missing (don't override user choice)
if 'agent' not in settings:
    settings['agent'] = {}
    changed = True

if 'default_model' not in settings['agent']:
    settings['agent']['default_model'] = {
        "provider": "Jamu",
        "model": "claude-haiku-4.5"
    }
    changed = True

# --- JAMU PROVIDER ---
# Ensure the Jamu provider exists with correct API URL
# Models are fetched dynamically from /model/info, so we only need minimal config
if 'language_models' not in settings:
    settings['language_models'] = {}
    changed = True

if 'openai_compatible' not in settings['language_models']:
    settings['language_models']['openai_compatible'] = {}
    changed = True

# Always ensure Jamu provider has correct API URL and minimal model config
jamu_config = settings['language_models']['openai_compatible'].get('Jamu', {})
if jamu_config.get('api_url') != 'https://llm.jamu.ai/v1' or 'available_models' not in jamu_config:
    settings['language_models']['openai_compatible']['Jamu'] = {
        "api_url": "https://llm.jamu.ai/v1",
        "available_models": [
            {
                "name": "claude-haiku-4.5",
                "display_name": "Jamu Fast",
                "max_tokens": 200000,
                "max_output_tokens": 8192,
                "max_completion_tokens": 8192,
                "capabilities": {"tools": True, "images": True, "parallel_tool_calls": False, "prompt_cache_key": False}
            }
        ]
    }
    changed = True

# Remove anthropic section if present (we use Jamu gateway instead)
if 'anthropic' in settings.get('language_models', {}):
    del settings['language_models']['anthropic']
    changed = True

# --- MCP SERVER (ABLETON-CLOUD) ---
if 'context_servers' not in settings:
    settings['context_servers'] = {}
    changed = True

# MCP config - update if version is older or missing
mcp_config = {
    "command": "/Applications/Jamu.app/Contents/Resources/ableton-bridge",
    "args": [],
    "env": {
        "USER_ID": "jamu-user",
        "CLOUD_URL": "https://cloud.jamu.ai",
        "ABLETON_PORT": "9877",
        "MCP_TOOL_BASE": "efficient"
    }
}

existing_mcp = settings.get('context_servers', {}).get('ableton-cloud', {})
existing_mcp_version = existing_mcp.get('env', {}).get('_version', '0')

# Update MCP config if missing or version changed
if 'ableton-cloud' not in settings['context_servers'] or int(current_version) < int(config_version):
    settings['context_servers']['ableton-cloud'] = mcp_config
    changed = True

# --- VERSION TRACKING ---
if current_version != config_version:
    settings['_jamu_config_version'] = config_version
    changed = True

# Write back only if changes were made
if changed:
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=2)
    print(f"Jamu config updated to version {config_version}")
PYTHON_CONFIG_EOF

# Install custom system prompt if not exists
JAMU_PROMPT_FILE="\$ZED_CONFIG_DIR/jamu_system_prompt.txt"
if [ ! -f "\$JAMU_PROMPT_FILE" ]; then
    # Copy system prompt from Resources if available
    if [ -f "\$RESOURCES_DIR/jamu_system_prompt.txt" ]; then
        cp "\$RESOURCES_DIR/jamu_system_prompt.txt" "\$JAMU_PROMPT_FILE"
        echo "Installed Jamu system prompt"
    fi
fi

# Auto-install AbletonEMCP to Ableton Live 12 if it exists
ABLETON_EMCP_SOURCE="\$RESOURCES_DIR/AbletonEMCP"
ABLETON_APP="/Applications/Ableton Live 12 Suite.app"
ABLETON_SCRIPTS="\$ABLETON_APP/Contents/App-Resources/MIDI Remote Scripts"

if [ -d "\$ABLETON_EMCP_SOURCE" ] && [ -d "\$ABLETON_APP" ]; then
    if [ -d "\$ABLETON_SCRIPTS" ]; then
        # Always update AbletonEMCP to the latest version from Jamu
        rm -rf "\$ABLETON_SCRIPTS/AbletonEMCP" 2>/dev/null
        cp -r "\$ABLETON_EMCP_SOURCE" "\$ABLETON_SCRIPTS/" 2>/dev/null
    fi
fi

exec "\$DIR/zed-bin" "\$@"
LAUNCHER_SCRIPT
chmod +x "$MACOS_DIR/zed"

# Create Info.plist
echo "Creating Info.plist..."
cat > "$APP_BUNDLE_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>zed</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$APP_IDENTIFIER</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.15</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE_PATH/Contents/PkgInfo"

# Copy app icon (if it exists)
if [ -f logo.icns ]; then
  echo "Copying app icon..."
  cp logo.icns "$RESOURCES_DIR/AppIcon.icns"
else
  echo "Warning: logo.icns not found, skipping icon..."
fi

# Copy MCP server files (binary and Ableton remote script) to Resources
echo "Copying MCP server and Ableton remote script..."
cp mcp-servers/ableton-cloud/ableton-bridge "$RESOURCES_DIR/"
cp -r mcp-servers/ableton-cloud/AbletonEMCP "$RESOURCES_DIR/"
chmod +x "$RESOURCES_DIR/ableton-bridge"

# Copy custom system prompt file
if [ -f "assets/jamu_system_prompt.txt" ]; then
    cp assets/jamu_system_prompt.txt "$RESOURCES_DIR/"
    echo "✅ Custom system prompt included in package"
fi

# Verify AbletonEMCP was copied
if [ -d "$RESOURCES_DIR/AbletonEMCP" ]; then
  echo "✅ AbletonEMCP remote script included in package"
else
  echo "⚠️  Warning: AbletonEMCP folder not found in source"
fi

# Ad-hoc code signing (helps with macOS Sequoia Gatekeeper)
echo "Code signing binaries..."
codesign --force --deep --sign - "$MACOS_DIR/zed-bin" 2>/dev/null || echo "Warning: Could not sign zed-bin"
codesign --force --sign - "$RESOURCES_DIR/ableton-bridge" 2>/dev/null || echo "Warning: Could not sign ableton-bridge"
codesign --force --deep --sign - "$APP_BUNDLE_PATH" 2>/dev/null || echo "Warning: Could not sign app bundle"

echo ""
echo "✅ Successfully packaged: $APP_BUNDLE_PATH"
echo ""
echo "To install:"
echo "  cp -r $APP_BUNDLE_PATH /Applications/"
echo ""
echo "The app will launch with:"
echo "  - Jamu LLM gateway: https://llm.jamu.ai/v1"
echo "  - ableton-cloud MCP server enabled"
echo "  - Minimal agent-only interface"
echo ""
echo "⚠️  Users must provide their own API key in Jamu settings"
echo ""
echo "MCP server location in package:"
echo "  /Applications/Jamu.app/Contents/Resources/"
echo "    ├── ableton-bridge (MCP binary)"
echo "    └── AbletonEMCP/ (Ableton remote script)"

