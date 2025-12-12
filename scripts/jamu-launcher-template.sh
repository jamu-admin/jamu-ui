#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$DIR/../Resources"

# Enable Jamu agent mode (minimal UI, locked layout)
export JAMU_AGENT_MODE=true

# Load API key from bundled config
if [ -f "$RESOURCES_DIR/config/initial_user_settings.json" ]; then
    export ANTHROPIC_API_KEY=$(grep -o '"api_key": "[^"]*"' "$RESOURCES_DIR/config/initial_user_settings.json" | cut -d'"' -f4)
fi

# Create user config directory if it doesn't exist
ZED_CONFIG_DIR="$HOME/.config/zed"
ZED_SETTINGS_FILE="$ZED_CONFIG_DIR/settings.json"
mkdir -p "$ZED_CONFIG_DIR"

# Create or update settings file on first launch
if [ ! -f "$ZED_SETTINGS_FILE" ]; then
    cat > "$ZED_SETTINGS_FILE" << 'EOF'
{
  "assistant": {
    "default_model": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-5"
    }
  },
  "language_models": {
    "anthropic": {
      "api_key": "API_KEY_PLACEHOLDER"
    }
  },
  "agent_servers": {
    "ableton-cloud": {
      "command": "/Applications/Jamu.app/Contents/Resources/mcp-servers/ableton-cloud/ableton-bridge",
      "args": [],
      "env": {
        "USER_ID": "jamu-user-v2",
        "CLOUD_URL": "https://cloud.jamu.ai",
        "ABLETON_PORT": "9877",
        "MCP_MODE": "api-only",
        "MCP_TOOL_BASE": "efficient",
        "MCP_TOOL_FEATURES": "coral",
        "USE_SKILL_DISCOVERY": "true",
        "USE_PERSONAS": "true",
        "USE_WORKFLOWS": "true",
        "FALLBACK_ON_ERROR": "true"
      }
    }
  }
}
EOF
    # Replace API key placeholder with actual key
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        sed -i '' "s/API_KEY_PLACEHOLDER/$ANTHROPIC_API_KEY/" "$ZED_SETTINGS_FILE"
    fi
fi

exec "$DIR/zed-bin" "$@"

