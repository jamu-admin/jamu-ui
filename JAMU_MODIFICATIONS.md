# Jamu - Modifications from Original Zed Code

**Based on:** Zed Editor (https://github.com/zed-industries/zed)  
**Original License:** GNU Affero General Public License v3.0 (AGPL-3.0)  
**Original Copyright:** Copyright 2022 - 2025 Zed Industries, Inc.  
**Fork Name:** Jamu  
**Fork Maintainer:** Jamu (https://jamu.ai)  
**Modification Date:** December 2024  

---

## License Compliance Notice

This software is a modified version of Zed Editor, licensed under the GNU Affero General Public License v3.0. In accordance with the AGPL-3.0 license requirements:

1. This document lists all modifications made to the original source code
2. The complete modified source code is available
3. The original license and copyright notices are preserved
4. Users are informed that this is modified software

---

## Summary of Modifications

Jamu is a specialized fork of Zed focused on providing AI-assisted music production through integration with Ableton Live. The modifications create a streamlined, single-purpose application for AI-powered music creation.

---

## Detailed Modification List

### 1. Branding Changes

#### Files Modified:
- `crates/zed/Cargo.toml` - Changed binary name from "zed" to "jamu"
- `assets/themes/jamu.json` - Added custom Jamu theme
- `assets/icons/tool_hammer.svg` - Modified icon
- Various UI files - Changed "Zed" references to "Jamu"

#### Changes:
- Application name changed from "Zed" to "Jamu"
- Custom app icon and branding
- Custom theme colors

---

### 2. Jamu Agent Mode (`JAMU_AGENT_MODE` Environment Variable)

A new operational mode that creates a simplified, focused AI assistant interface.

#### Files Modified:

**`crates/language_models/src/language_models.rs`**
- Added conditional provider registration
- In Jamu mode, skips registration of Cloud, Anthropic, and other built-in providers
- Only allows `openai_compatible` providers (for Jamu LLM gateway)

```rust
// In Jamu mode, skip Cloud and Anthropic providers - only use openai_compatible
let jamu_mode = std::env::var("JAMU_AGENT_MODE").unwrap_or_default() == "true";
if jamu_mode {
    return;
}
```

**`crates/title_bar/src/title_bar.rs`**
- Hidden "Sign In" button in Jamu mode
- Hidden user menu dropdown (arrow button with Sign Out) in Jamu mode

```rust
.when(
    std::env::var("JAMU_AGENT_MODE").unwrap_or_default() != "true",
    |el| el.child(self.render_app_menu_button(cx)),
)
```

**`crates/agent_ui/src/agent_configuration.rs`**
- Hidden "General Settings" section (toggle switches) in Jamu mode
- Hidden "External Agents" section in Jamu mode
- Hidden "Add Provider" button in Jamu mode

**`crates/agent_ui/src/agent_panel.rs`**
- Hidden "External Agents" menu items (Claude Code, Codex, Gemini CLI) in Jamu mode
- Hidden "Rules..." menu item in Jamu mode
- Hidden "Enable Full Screen" menu item in Jamu mode
- Changed "Zed Agent" label to "Jamu Agent"

**`crates/zed/src/zed.rs`**
- Modified `load_default_keymap()` to load minimal keybindings in Jamu mode
- Only essential keys bound: copy, paste, cut, undo, redo, select all, backspace, delete, enter

```rust
if std::env::var("JAMU_AGENT_MODE").unwrap_or_default() == "true" {
    cx.bind_keys(vec![
        KeyBinding::new("cmd-c", editor::actions::Copy, None),
        KeyBinding::new("cmd-x", editor::actions::Cut, None),
        KeyBinding::new("cmd-v", editor::actions::Paste, None),
        KeyBinding::new("cmd-z", editor::actions::Undo, None),
        KeyBinding::new("cmd-shift-z", editor::actions::Redo, None),
        KeyBinding::new("cmd-a", editor::actions::SelectAll, None),
        KeyBinding::new("enter", editor::actions::Newline, None),
        KeyBinding::new("backspace", editor::actions::Backspace, None),
        KeyBinding::new("delete", editor::actions::Delete, None),
    ]);
    return;
}
```

---

### 3. MCP Tool Display Changes

#### Files Modified:

**`crates/agent/src/context_server_tool.rs`**
- Changed MCP tool display text from "Run MCP tool" to "Jamming..."
- Added support for displaying tool annotation titles

```rust
fn ui_text(&self, _input: &serde_json::Value) -> String {
    let display_name = self
        .tool
        .annotations
        .as_ref()
        .and_then(|a| a.title.as_ref())
        .unwrap_or(&self.tool.name);
    format!("Jamming... `{}`", display_name)
}
```

**`crates/agent2/src/tools/context_server_registry.rs`**
- Same changes as above for agent2

---

### 4. Token Usage Display Enhancement

#### Files Modified:

**`crates/agent_ui/src/acp/thread_view.rs`**
- Added fallback for token usage display when API doesn't return usage data
- Shows "? / 200k" format when exact usage is unknown but model max tokens is known
- Helps users understand context window limits even with providers that don't report usage

```rust
let (used, max) = if let Some(usage) = acp_thread.token_usage() {
    // Show actual usage
    (humanize_token_count(usage.used_tokens), humanize_token_count(usage.max_tokens))
} else {
    // Fallback: show model's max context window when no usage data available
    let model = self.as_native_thread(cx)?.read(cx).model()?.clone();
    ("?".to_string(), humanize_token_count(model.max_token_count()))
};
```

---

### 5. Model Configuration Changes

#### Files Modified:

**`crates/anthropic/src/anthropic.rs`**
- Increased Claude Sonnet 4.5 max token count from 200,000 to 500,000

```rust
Self::ClaudeSonnet4_5 | Self::ClaudeSonnet4_5Thinking => 500_000,
```

---

### 6. UI Text Changes

#### Files Modified:

**`crates/language_models/src/provider/open_ai_compatible.rs`**
- Changed "To use Zed's agent" to "To use Jamu"
- Changed "restart Zed" to "restart Jamu"

**`crates/language_models/src/provider/google.rs`**
- Changed "Jamu's agent with Google AI" reference

---

### 7. Onboarding Changes

#### Files Modified:
- `crates/onboarding/src/onboarding.rs` - Modified onboarding flow
- `crates/onboarding/src/welcome.rs` - Modified welcome screen
- `crates/ai_onboarding/src/ai_onboarding.rs` - Modified AI onboarding
- `crates/edit_prediction_button/src/edit_prediction_button.rs` - UI modifications

---

### 8. Default Settings Changes

#### Files Modified:

**`assets/settings/default.json`**
- Default Anthropic API URL remains `https://api.anthropic.com` (Jamu URL set via launcher)

---

### 9. Packaging and Distribution

#### Files Added:
- `scripts/package-jamu-standalone.sh` - Build and packaging script
- `scripts/jamu-launcher-template.sh` - Launcher script template
- `scripts/create-jamu-icon.sh` - Icon creation script

#### Launcher Script Features:
- Sets `JAMU_AGENT_MODE=true` environment variable
- Configures Jamu LLM provider (`https://llm.jamu.ai/v1`)
- Configures MCP server (ableton-cloud) with Ableton Live integration
- Auto-installs AbletonEMCP remote script to Ableton Live 12

#### Default Jamu Provider Configuration:
```json
{
  "language_models": {
    "openai_compatible": {
      "Jamu": {
        "api_url": "https://llm.jamu.ai/v1",
        "available_models": [
          {
            "name": "claude-haiku-4.5",
            "display_name": "Jamu Fast",
            "max_tokens": 200000,
            "max_output_tokens": 8192
          },
          {
            "name": "claude-sonnet-4.5",
            "display_name": "Jamu Thinking",
            "max_tokens": 500000,
            "max_output_tokens": 64000
          }
        ]
      }
    }
  }
}
```

---

### 10. MCP Server Integration

#### Files Added:
- `mcp-servers/ableton-cloud/` - Ableton Live MCP server
  - `ableton-bridge` - MCP bridge binary
  - `AbletonEMCP/` - Ableton Live remote script

#### Purpose:
Enables AI-assisted control of Ableton Live for music production tasks.

---

### 11. Documentation

#### Files Added:
- `JAMU_MODIFICATIONS.md` - This file (license-required modification documentation)
- `JAMU_CHANGES_SUMMARY.md` - Summary of changes
- `JAMU_REBRANDING_GUIDE.md` - Rebranding guide
- `JAMU_STANDALONE.md` - Standalone build documentation

---

### 12. Dynamic Model Fetching

#### Files Modified:

**`crates/language_models/src/provider/open_ai_compatible.rs`**
- Added dynamic model fetching from `/model/info` endpoint (Jamu/LiteLLM specific)
- Models are fetched after authentication when `JAMU_AGENT_MODE=true`
- Only shows models the user's API key has access to
- Falls back to settings.available_models if API call fails

#### New Structs:
```rust
struct ModelInfoResponse { data: Vec<ModelInfoEntry> }
struct ModelInfoEntry { model_name: String, model_info: ModelInfoDetails }
struct ModelInfoDetails { display_name, max_input_tokens, max_output_tokens, supports_vision, supports_function_calling }
```

#### Behavior:
1. User enters API key
2. App calls `https://llm.jamu.ai/model/info` with Bearer token
3. API returns models user has access to (based on subscription tier)
4. UI shows only those models

#### Benefits:
- Users only see models they can use (no confusing errors)
- New models appear automatically without app updates
- Model capabilities (images, tools) set correctly from API

---

### 13. Custom System Prompt for Music Production

#### Files Added:
- `crates/agent2/src/templates/jamu_system_prompt.hbs` - Custom system prompt for Ableton assistant

#### Files Modified:

**`crates/agent2/src/templates.rs`**
- Added `render_for_mode()` method to conditionally select system prompt template
- In Jamu mode, uses `jamu_system_prompt.hbs` (optimized for music production)
- In normal mode, uses standard `system_prompt.hbs`

**`crates/agent2/src/thread.rs`**
- Changed to use `render_for_mode()` instead of `render()` for system prompt

#### Key Differences (Jamu vs Standard prompt):

| Standard Zed Prompt | Jamu Prompt |
|---------------------|-------------|
| "skilled software engineer" | "expert music producer and Ableton Live specialist" |
| Code block formatting rules (~60 lines) | Removed |
| Debugging/diagnostics sections | Removed |
| grep/find_path file search instructions | Removed |
| External API/package guidelines | Removed |
| **Token count: ~1,500-2,000** | **Token count: ~300-400** |

#### Token Savings:
~80% reduction in system prompt tokens, sent with every message.

---

## Files Modified Summary

| File Path | Type of Change |
|-----------|----------------|
| `crates/language_models/src/language_models.rs` | Provider registration logic |
| `crates/language_models/src/provider/open_ai_compatible.rs` | UI text, dynamic model fetching |
| `crates/language_models/src/provider/google.rs` | UI text |
| `crates/title_bar/src/title_bar.rs` | Hidden UI elements |
| `crates/agent_ui/src/agent_configuration.rs` | Hidden UI sections |
| `crates/agent_ui/src/agent_panel.rs` | Hidden menu items, labels |
| `crates/agent/src/context_server_tool.rs` | Tool display text |
| `crates/agent2/src/tools/context_server_registry.rs` | Tool display text |
| `crates/agent_ui/src/acp/thread_view.rs` | Token usage fallback, feedback hiding |
| `crates/anthropic/src/anthropic.rs` | Token limits |
| `crates/zed/src/zed.rs` | Keymap loading |
| `crates/zed/src/zed/open_listener.rs` | Various |
| `crates/onboarding/src/onboarding.rs` | Onboarding flow |
| `crates/onboarding/src/welcome.rs` | Welcome screen |
| `crates/ai_onboarding/src/ai_onboarding.rs` | AI onboarding |
| `crates/theme/src/settings.rs` | Theme settings |
| `assets/settings/default.json` | Default settings |
| `assets/themes/jamu.json` | Custom theme (new) |
| `scripts/package-jamu-standalone.sh` | Build script (new) |
| `crates/agent2/src/templates/jamu_system_prompt.hbs` | Custom system prompt (new) |
| `crates/agent2/src/templates.rs` | Template selection logic |
| `crates/agent2/src/thread.rs` | Uses `render_for_mode()` |

---

## How to Identify Modified Code

All Jamu-specific conditional code can be found by searching for:
```
JAMU_AGENT_MODE
```

This environment variable controls all Jamu-specific behavior modifications.

---

## Source Code Availability

The complete modified source code is available at the same location as the distributed binary, in compliance with AGPL-3.0 Section 6.

---

## Original Zed License

The original Zed Editor is licensed under the GNU Affero General Public License v3.0. A copy of this license is included in the `LICENSE-AGPL` file.

This modified version (Jamu) is also distributed under the same AGPL-3.0 license terms.

