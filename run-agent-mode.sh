#!/bin/bash
# Launch Jamu in Agent Mode
# This script runs Jamu with the agent-only interface

set -e

cd "$(dirname "$0")"

echo "🚀 Starting Jamu in Agent Mode..."
echo ""

# Set agent mode environment variable
export JAMU_AGENT_MODE=true

# Build if needed
if [ ! -f "dist/Jamu.app/Contents/MacOS/jamu" ]; then
    echo "📦 Building Jamu first..."
    ./scripts/build-jamu.sh
    echo ""
fi

# Run the application
echo "✨ Launching Jamu Agent..."
echo "   - Agent mode enabled (JAMU_AGENT_MODE=true)"
echo "   - Minimal UI with Agent Panel only"
echo "   - Login UI shown if not authenticated"
echo ""

# Launch directly
dist/Jamu.app/Contents/MacOS/jamu

echo ""
echo "👋 Jamu Agent closed"

