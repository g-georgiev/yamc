# YAMC — Yet Another Memory for Claude

A self-improving memory system for Claude Code. YAMC gives Claude short-term capture, curated long-term memory, and an evolutionary evaluation loop where memory behavior itself gets better over time — through collaborative weekly reflection between Claude and you.

## How It Works

YAMC is built around a simple cycle inspired by genetic algorithms: capture freely, evaluate periodically, keep what works, discard what doesn't, and let the strategy itself evolve.

```
Session (ephemeral)
    │
    ▼ WRITE GATE: "Would this matter to a future session?"
    │
Short-Term Memory (shortterm-{project}.md, shortterm.md)
    Append-only. Per-project + global. Raw, timestamped.
    Corrections tagged as highest priority.
    │
    ▼ REFLECT CYCLE: weekly, proposes changes, human approves
    │
Long-Term Memory (longterm.md)
    Curated. Auto-loaded every session.
    Read-only during sessions. Supersede, don't delete.
    │
    ▼ GIT
    │
Full history of how memory evolved over time.
```

**Short-term memory** is the inbox. Claude writes to it during sessions — either via `/remember` or at its own discretion — filtered through a write gate that asks "would this matter to a future session?" Per-project files keep context separate. Corrections from the user are always captured and flagged as highest priority.

**Long-term memory** is curated and trusted. It loads automatically at every session start and is strictly read-only during sessions. Entries only get added, modified, or removed through the weekly reflect cycle — and only with human approval. Old entries are superseded, not deleted, because the trail of change is itself useful context.

**The reflect cycle** runs weekly (via systemd timer on Linux, launchd on macOS). It reads everything, analyzes patterns, tracks which long-term memories are actually being used, and produces a report on `main` with a branch containing proposed changes. You review the diff and merge or discard — same workflow as a PR. Over time, this selection pressure shapes better curation instincts and the "Evolving Strategy" section in the protocol gets updated to reflect what's working.

YAMC complements Claude Code's native auto-memory rather than replacing it. Native auto-memory handles project patterns, commands, and local preferences. YAMC focuses on the reflective meta-layer: the *why* behind decisions, dead ends worth avoiding, cross-project patterns, corrections, and self-improvement of memory behavior itself.

## Install

```bash
# 1. Clone and run install script
# Sets up ~/.claude-memory (git-versioned, local-only) and a weekly scheduler
git clone https://github.com/g-georgiev/yamc.git
cd yamc
./install.sh
```

Then in any Claude Code session, register the marketplace and install at user scope (global):

```
/plugin marketplace add g-georgiev/yamc
/plugin install yamc@yamc
```

Select **User** scope when prompted — this makes it load in every session regardless of project.

For development/testing without the marketplace:

```bash
claude --plugin-dir /path/to/yamc
```

The installer detects your OS and sets up the appropriate scheduler:
- **Linux:** systemd user timer with `Persistent=true` (catches up after sleep/reboot)
- **macOS:** launchd agent (native catch-up on wake)
- **Fallback:** cron (no catch-up for missed runs)

Memory data lives in `~/.claude-memory/` — a local git repo. Nothing is pushed by default. The git history is for rollback safety.

### Optional: sync across devices

The memory repo is just git. To sync it, point it at a private remote:

```bash
# On your first machine
cd ~/.claude-memory
git remote add origin git@github.com:you/claude-memory-private.git
git push -u origin main

# On a second machine — clone instead of running install.sh's dir setup
git clone git@github.com:you/claude-memory-private.git ~/.claude-memory
```

After that, pull before sessions and push after reflects — or automate it however you like. YAMC never pushes for you; sync is entirely opt-in.

## Usage

### During sessions

Long-term memory loads automatically at session start via the SessionStart hook.

**`/remember <anything>`** — Captures to short-term memory with a timestamp and project context.

Claude also writes to short-term memory at its own discretion, filtered through the **write gate**:

1. Would this change future behavior? (preference, pattern, boundary)
2. Is it a correction? (always captured, highest priority)
3. Is it a decision with rationale? (the *why*, not the *what*)
4. Is it a dead end or gotcha? (saves future sessions from repeating)
5. Did the user explicitly say `/remember`?

If none are true, it doesn't get saved.

When Claude uses information from long-term memory, it logs the usage — entries that never get referenced become pruning candidates.

### Weekly reflect cycle

Runs every Monday at 9 AM. The reflect script:

1. **Writes a report on `main`** — activity summary, usage patterns, corrections review, strategy assessment. Always kept.
2. **Creates a `reflect/YYYY-MM-DD` branch** (if there are changes to propose) — actual edits to longterm.md and shortterm pruning.

Review and act on proposals with standard git:

```bash
# Read the report
cat ~/.claude-memory/reports/YYYY-MM-DD/report.md

# Review proposed changes
git -C ~/.claude-memory diff main..reflect/YYYY-MM-DD

# Accept
git -C ~/.claude-memory merge reflect/YYYY-MM-DD

# Reject
git -C ~/.claude-memory branch -D reflect/YYYY-MM-DD
```

Your steering is the selection pressure that shapes how memory evolves.

### Manual reflection

```bash
~/.claude-memory/reflect.sh
```

## Uninstall

```bash
cd /path/to/yamc
./uninstall.sh
```

This removes the scheduler (systemd/launchd/cron) and optionally deletes `~/.claude-memory/`. To also remove the plugin from Claude Code, run `/plugin uninstall yamc` in a session.

## File Structure

```
yamc/                             # Repo root (marketplace)
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest
├── plugins/
│   └── yamc/                     # Plugin root
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin manifest
│       ├── hooks/
│       │   ├── hooks.json        # Hook configuration
│       │   ├── session-start.sh  # Injects longterm.md at session start
│       │   └── pre-compact.sh    # Commits memory changes before compaction
│       ├── rules/
│       │   └── memory-protocol.md  # Memory behavior protocol (auto-loaded)
│       └── skills/
│           └── remember/
│               └── SKILL.md      # /remember slash command
├── reflect.sh                    # Weekly evaluation script (runs via systemd/launchd)
├── install.sh                    # One-time setup (~/.claude-memory + scheduler)
├── uninstall.sh                  # Removes scheduler and optionally ~/.claude-memory
└── README.md

~/.claude-memory/                 # Memory data (local-only git repo)
├── longterm.md                   # Curated long-term memory
├── shortterm.md                  # Global short-term capture
├── shortterm-{project}.md        # Per-project short-term capture
├── reports/
│   └── YYYY-MM-DD/
│       └── report.md             # Weekly analysis (committed on main)
├── reflect.sh                    # Installed reflect script
└── .git/                         # reflect/YYYY-MM-DD branches hold proposed changes
```

## Design Principles

- **Self-improving.** The curation strategy itself evolves through the reflect cycle.
- **Claude proposes, you decide.** Reports suggest, never mutate autonomously.
- **Write gate over write-everything.** Memory that doesn't change future behavior shouldn't exist.
- **Corrections are king.** Human corrections get highest priority for long-term graduation.
- **Supersede, don't delete.** Old entries are marked, not removed. The trail of change matters.
- **Git-versioned.** Full history of how memory evolved, with free rollback.
- **Complement, don't compete.** Works alongside Claude Code's native auto-memory.
- **Start dumb, iterate.** v0 strategy is intentionally minimal. Selection pressure shapes better.

## Alternatives Worth Checking Out

YAMC stands on the shoulders of these projects. If you're looking for a memory solution for Claude Code, they're all worth evaluating — each takes a different approach:

- **[total-recall](https://github.com/davegoldblatt/total-recall)** — Tiered memory with a write gate, correction propagation, and a contradiction protocol. Clean, disciplined, focused on reliable storage. YAMC borrowed the write gate concept, correction priority, supersede-don't-delete pattern, and the CC plugin architecture from here.

- **[mnemonic](https://github.com/zircote/mnemonic)** — The most thorough implementation. MIF-compliant with YAML frontmatter, bi-temporal tracking, decay modeling, custom ontologies, and multi-tool support (works with Copilot, Cursor, Aider, and more). Research-validated: filesystem-based memory scored 74.0% on the LoCoMo benchmark vs 68.5% for graph-based approaches. YAMC borrowed the git-versioning approach and the confidence in filesystem-over-databases.

- **[claude-mem](https://github.com/thedotmack/claude-mem)** — Automatic capture of everything Claude does, with SQLite storage, vector search, progressive disclosure, and a web viewer UI. The heaviest solution but also the most hands-off — good if you want zero-effort memory.

- **[claude-supermemory](https://github.com/supermemoryai/claude-supermemory)** — SaaS-backed with team memory sharing. Requires an API key. Good for teams that want shared persistent context.

- **[Claude Code native auto-memory](https://code.claude.com/docs/en/memory)** — Built into Claude Code itself. Per-project memory at `~/.claude/projects/<project>/memory/`. Handles project patterns and preferences. YAMC is designed to complement this, not replace it.

## License

MIT
