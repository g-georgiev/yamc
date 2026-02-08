# YAMC — Yet Another Memory for Claude (Plugin)

This is a Claude Code plugin. Structure follows CC plugin conventions.

## Key files
- `.claude-plugin/marketplace.json` — marketplace manifest
- `plugins/yamc/.claude-plugin/plugin.json` — plugin manifest
- `plugins/yamc/hooks/hooks.json` — lifecycle hook configuration
- `plugins/yamc/hooks/session-start.sh` — injects longterm.md at session start (stdout is model-visible)
- `plugins/yamc/hooks/pre-compact.sh` — commits memory changes before compaction (stdout is NOT model-visible)
- `plugins/yamc/rules/memory-protocol.md` — auto-loaded behavior rules
- `plugins/yamc/skills/remember/SKILL.md` — /remember slash command
- `reflect.sh` — weekly evaluation script (runs via systemd/launchd, uses `claude -p`)
- `install.sh` — one-time setup of ~/.claude-memory and scheduler
- `uninstall.sh` — removes scheduler and optionally ~/.claude-memory

## Conventions
- All hook scripts must fail open (never block Claude Code)
- Memory data lives in ~/.claude-memory/, NOT in the plugin directory
- Plugin is stateless — all state is in the memory directory
