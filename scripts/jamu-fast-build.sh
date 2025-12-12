#!/bin/bash
set -euo pipefail

echo "🚀 Jamu Fast Build Script"
echo "========================="
echo ""

# Check if we should use minimal build
USE_MINIMAL=${USE_MINIMAL:-"yes"}

if [ "$USE_MINIMAL" = "yes" ]; then
    echo "📦 Using MINIMAL dependencies (2-3 min build)"
    echo "   Disabled: vim, collab, project_panel, debugger, etc."
    echo ""
    
    # Backup original
    if [ ! -f "crates/zed/Cargo.toml.full" ]; then
        cp crates/zed/Cargo.toml crates/zed/Cargo.toml.full
        echo "✅ Backed up full Cargo.toml"
    fi
    
    # Use minimal
    cp crates/zed/Cargo.toml.minimal crates/zed/Cargo.toml
    echo "✅ Switched to minimal Cargo.toml"
    echo ""
else
    echo "📦 Using FULL dependencies (12-15 min build)"
    echo "   All features enabled"
    echo ""
    
    # Restore full if available
    if [ -f "crates/zed/Cargo.toml.full" ]; then
        cp crates/zed/Cargo.toml.full crates/zed/Cargo.toml
        echo "✅ Restored full Cargo.toml"
        echo ""
    fi
fi

# Clean only necessary packages for incremental build
echo "🧹 Cleaning affected packages..."
cargo clean -p zed -p agent_ui --release

# Build
echo ""
echo "🔨 Building jamu binary..."
time cargo build --release --bin jamu

# Copy to installed app if it exists
if [ -d "/Applications/Jamu.app" ]; then
    echo ""
    echo "📲 Installing to /Applications/Jamu.app..."
    cp target/release/jamu /Applications/Jamu.app/Contents/MacOS/zed-bin
    chmod +x /Applications/Jamu.app/Contents/MacOS/zed-bin
    echo "✅ Installed!"
fi

echo ""
echo "✨ Build complete!"
echo ""
echo "To run: open /Applications/Jamu.app"
echo "Or:     ./target/release/jamu"
echo ""
echo "To switch to FULL build:"
echo "  USE_MINIMAL=no ./scripts/jamu-fast-build.sh"

