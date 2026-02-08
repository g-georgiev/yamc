# YAMC — Yet Another Memory for Claude (Plugin)

This is a Claude Code plugin. Structure follows CC plugin conventions.

## Key files
- `.claude-plugin/plugin.json` — manifest
- `hooks/hooks.json` — lifecycle hook configuration
- `hooks/session-start.sh` — injects longterm.md at session start (stdout is model-visible)
- `hooks/pre-compact.sh` — commits memory changes before compaction (stdout is NOT model-visible)
- `rules/memory-protocol.md` — auto-loaded behavior rules
- `skills/remember/SKILL.md` — /remember slash command
- `reflect.sh` — weekly evaluation script (runs via cron, uses `claude --print`)
- `install.sh` — one-time setup of ~/.claude-memory and cron

## Conventions
- All hook scripts must fail open (never block Claude Code)
- Memory data lives in ~/.claude-memory/, NOT in the plugin directory
- Plugin is stateless — all state is in the memory directory
