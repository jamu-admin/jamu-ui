# Jamu

**AI-Powered Music Production Assistant for Ableton Live**

Jamu is a specialized fork of [Zed Editor](https://github.com/zed-industries/zed) focused on AI-assisted music production through integration with Ableton Live.

## Features

- 🎵 **AI Music Assistant** - Expert music production guidance powered by Claude
- 🎛️ **Ableton Live Integration** - Control Ableton directly through MCP tools
- 🎹 **Music-Focused System Prompt** - Optimized for arrangement, mixing, and sound design
- ⚡ **Prompt Caching** - Reduced API costs with intelligent caching
- 🔧 **Dynamic Model Selection** - Models fetched based on your subscription tier

## Installation

### macOS

1. Download the latest release from [Releases](https://github.com/jamu-admin/jamu-ui/releases)
2. Move `Jamu.app` to `/Applications`
3. Launch Jamu and enter your API key

### Building from Source

```bash
# Clone the repository
git clone https://github.com/jamu-admin/jamu-ui.git
cd jamu-ui

# Build
cargo build --release

# Package (macOS)
./scripts/package-jamu-standalone.sh
```

**Requirements:**
- Rust toolchain
- macOS 10.15+ (for macOS builds)
- Ableton Live 12 (for MCP integration)

## Configuration

On first launch, Jamu creates configuration at `~/.config/zed/settings.json`:

- **API Key**: Enter your Jamu API key in Settings
- **System Prompt**: Customize at `~/.config/zed/jamu_system_prompt.txt`
- **MCP Server**: Automatically configured for Ableton integration

## How It Works

Jamu connects to Ableton Live through the MCP (Model Context Protocol) server, allowing the AI assistant to:

- Query session information (tracks, clips, devices)
- Create and edit MIDI clips
- Load instruments and effects
- Adjust device parameters
- Control transport and arrangement

## License

This software is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

### Attribution

Jamu is based on [Zed Editor](https://github.com/zed-industries/zed) by Zed Industries, Inc.

- **Original Work**: Copyright © 2022-2025 Zed Industries, Inc.
- **Modifications**: Copyright © 2024-2025 Jamu

All modifications from the original Zed code are documented in [JAMU_MODIFICATIONS.md](JAMU_MODIFICATIONS.md).

## Links

- **Website**: [jamu.ai](https://jamu.ai)
- **Original Zed**: [github.com/zed-industries/zed](https://github.com/zed-industries/zed)
