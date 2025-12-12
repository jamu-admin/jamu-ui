# Jamu Standalone - Current State Summary

**Date:** October 28, 2025  
**Branch:** `new-try`  
**Status:** ✅ **Production Ready**

---

## 🎯 Recent Commits (Most Recent First)

1. **`0a0bfa649c`** - Add comprehensive Jamu Standalone documentation
2. **`896799d83a`** - Remove ableton-cloud from agent_servers  
3. **`a976c2b2fc`** - Fix: Use 'claude-sonnet-4-5-latest' for model selection  
4. **`145dea14f0`** - Fix packaging script: use 'agent' not 'assistant' for default model  
5. **`1e49ada7e8`** - Fix: Use context_servers (not agent_servers) and enable MCP by default  
6. **`ae09dd9961`** - Fix model to Sonnet 4.5, restore settings observers, add MCP server  
7. **`d3f2b77069`** - FIXED: Model switching now works (base commit from Oct 23)  

---

## ✅ What's Working

### Core Functionality
- ✅ **Model Selection**: Claude Sonnet 4.5 pre-selected on first launch
- ✅ **Persistence**: Model selection persists across app restarts
- ✅ **MCP Integration**: Ableton Cloud MCP server configured as context server
- ✅ **API Authentication**: Embedded Anthropic API key works

### User Interface
- ✅ **No Login Screen**: Removed authentication UI, direct to chat
- ✅ **Settings Menu**: Panel options menu (settings button) visible
- ✅ **Model Selector**: Always visible, user can change models
- ✅ **Token Counter**: Always visible, shows remaining tokens
- ✅ **Context Tools**: MCP tools accessible in chat interface
- ✅ **Minimal Layout**: Full-width left panel, locked non-resizable

### Build & Package
- ✅ **Builds Successfully**: No compilation errors or warnings
- ✅ **Packages Correctly**: .app bundle structure valid
- ✅ **Installs Cleanly**: No permission or signing issues
- ✅ **Launches Properly**: No crashes, all features load

---

## 📁 Configuration Files

### Build-time (Embedded in Binary)
**File:** `assets/settings/default.json`
```json
{
  "agent": {
    "default_model": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-5-latest"  // ✅ Fixed ID
    }
  },
  "context_servers": {},    // ✅ Empty by default
  "agent_servers": {}       // ✅ Ableton removed
}
```

### Runtime (Created on First Launch)
**File:** `~/.config/zed/settings.json`
```json
{
  "agent": {
    "default_model": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-5-latest"
    },
    "default_profile": "write"
  },
  "language_models": {
    "anthropic": {
      "api_key": "<injected by launcher>"
    }
  },
  "context_servers": {
    "ableton-cloud": {
      "command": "/Applications/Jamu.app/Contents/Resources/mcp-servers/ableton-cloud/ableton-bridge",
      // ... env config
    }
  }
}
```

---

## 🔧 Code Modifications Summary

### Files Changed (Core)
1. **`crates/agent_ui/src/agent_panel.rs`**
   - Removed login UI and authentication state
   - Re-enabled panel options menu (settings button)
   - Profile selector hidden via `JAMU_AGENT_MODE`

2. **`crates/agent_ui/src/text_thread_editor.rs`**
   - Re-enabled model selector (always visible)
   - Re-enabled token counter (always visible)
   - Re-enabled context and burn mode buttons

3. **`crates/agent_ui/src/acp/thread_view.rs`**
   - Re-enabled token counter (always visible)

4. **`crates/agent_ui/src/agent_ui.rs`**
   - Re-enabled settings observers (critical for model loading)

5. **`assets/settings/default.json`**
   - Fixed model ID: `"claude-sonnet-4-5-latest"`
   - Removed ableton from `agent_servers`

### Build Configuration
- **Binary Name:** `jamu` (not `zed`)
- **Build Command:** `cargo build --release --bin jamu`
- **Package Script:** `scripts/package-jamu-standalone.sh`

---

## 🔑 Key Technical Fixes

### 1. Model ID Mismatch (CRITICAL FIX)
**Problem:** Model not selected on startup  
**Cause:** Settings used `"claude-sonnet-4-5"` but `Model.id()` returns `"claude-sonnet-4-5-latest"`  
**Solution:** Changed all configs to use `"claude-sonnet-4-5-latest"`

### 2. Agent vs Context Servers
**Problem:** Ableton showed as external agent  
**Cause:** Configured in `agent_servers` section  
**Solution:** Removed from `agent_servers`, kept only in `context_servers`

### 3. Settings Not Loading
**Problem:** Model not loading from config  
**Cause:** Settings observers disabled in `agent_ui.rs`  
**Solution:** Re-enabled observers, removed `JAMU_AGENT_MODE` checks

### 4. Wrong Binary Built
**Problem:** App crashed on launch with duplicate action error  
**Cause:** Building `zed` binary instead of `jamu`  
**Solution:** Updated package script to build `--bin jamu`

### 5. Launcher Script Issues
**Problem:** Settings created under wrong key, escaping errors  
**Cause:** Used `"assistant"` instead of `"agent"`, shell escaping bugs  
**Solution:** Fixed key to `"agent"`, corrected shell escaping

---

## 🏗️ Build & Install Process

### Build from Source
```bash
cd /Users/admin/Dev/zed
./scripts/package-jamu-standalone.sh
```

### Install
```bash
cp -r dist/Jamu.app /Applications/
```

### Test Fresh Launch
```bash
killall zed-bin
rm ~/.config/zed/settings.json
open /Applications/Jamu.app
```

**Expected Results:**
1. App launches directly to chat (no login)
2. Sonnet 4.5 is pre-selected in model dropdown
3. Token counter shows remaining tokens
4. MCP tools available in context menu
5. Settings button accessible in top-right

---

## 📊 Configuration Hierarchy

Settings are loaded and merged in this order:

1. **Default Settings** (`assets/settings/default.json`)
   - Embedded in binary at compile time
   - Provides base configuration

2. **User Settings** (`~/.config/zed/settings.json`)
   - Created by launcher script on first launch
   - Overrides defaults with user-specific config

3. **Environment Variables**
   - `JAMU_AGENT_MODE=true` - Enables minimal UI
   - `ANTHROPIC_API_KEY` - API authentication

4. **Runtime State**
   - Model selection persisted to user settings
   - MCP server connections maintained

---

## 🎨 UI Behavior

### Always Visible (Essential Elements)
- ✅ Chat input and send button
- ✅ Model selector dropdown
- ✅ Token counter
- ✅ Settings menu button
- ✅ Context menu (MCP tools)
- ✅ New thread button

### Hidden in Agent Mode (`JAMU_AGENT_MODE=true`)
- ❌ Profile selector (write/code/etc.)
- ❌ Mode selector (ACP modes)
- ❌ Title bar customization
- ❌ Panel resizing handles
- ❌ External dock panels

### Layout Restrictions
- 🔒 Panel locked to left side
- 🔒 Full window width
- 🔒 Non-resizable panels
- 🔒 Always starts open

---

## 🐛 Known Limitations

1. **macOS Only** - Build script is macOS-specific
2. **Single API Key** - Embedded in launcher, not user-configurable via UI
3. **No Auto-Updates** - Inherited limitation from Zed
4. **Single MCP Server** - Only Ableton Cloud configured by default

---

## 📚 Documentation Files

- **`JAMU_STANDALONE.md`** - Comprehensive technical documentation
- **`CURRENT_STATE_SUMMARY.md`** - This file, current state overview
- **`scripts/package-jamu-standalone.sh`** - Build and packaging script
- **`assets/settings/default.json`** - Default configuration

---

## 🚀 Next Steps (If Needed)

### Potential Improvements
- [ ] Add UI for API key configuration
- [ ] Support multiple MCP servers
- [ ] Add Linux/Windows build scripts
- [ ] Implement auto-update mechanism
- [ ] Add more model providers

### Maintenance Tasks
- [ ] Monitor Zed upstream for breaking changes
- [ ] Update Anthropic model IDs if they change
- [ ] Test with new Zed releases
- [ ] Document any new config options

---

## ✅ Verification Checklist

Before distributing, verify:

- [x] `cargo build --release --bin jamu` succeeds
- [x] `./scripts/package-jamu-standalone.sh` completes
- [x] App installs to `/Applications/Jamu.app`
- [x] Fresh launch creates `~/.config/zed/settings.json`
- [x] Sonnet 4.5 is pre-selected on first launch
- [x] Model selection persists after restart
- [x] MCP server loads and tools are available
- [x] Settings menu is accessible
- [x] Token counter is visible
- [x] No login screen appears
- [x] No crashes or errors in console

---

## 📞 Support & Troubleshooting

### Common Issues

**Q: Model not selected on launch**  
A: Check that settings use `"claude-sonnet-4-5-latest"` (not `"claude-sonnet-4-5"`)

**Q: Ableton shows as external agent**  
A: Ensure it's only in `context_servers`, not `agent_servers`

**Q: App crashes on launch**  
A: Verify you built `jamu` binary, not `zed` binary

**Q: API key not working**  
A: Check `/Applications/Jamu.app/Contents/Resources/config/initial_user_settings.json` exists

**Q: MCP server not loading**  
A: Verify binary at `/Applications/Jamu.app/Contents/Resources/mcp-servers/ableton-cloud/ableton-bridge`

---

**Last Updated:** October 28, 2025, 21:30  
**Version:** v0.0.1  
**Build Target:** macOS (arm64/x86_64)  
**Status:** ✅ Production Ready - All features working as expected
