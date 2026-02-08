# Claude Memory Protocol

You have a persistent memory system at `~/.claude-memory/`. It gives you continuity across sessions through short-term capture, curated long-term memory, and periodic collaborative evaluation.

**This system complements Claude Code's native auto-memory — it does NOT replace it.** Native auto-memory handles project patterns, commands, and local preferences. This system handles cross-session learning, self-improvement, and reflective evaluation.

## Architecture

- **`longterm.md`** — Curated, trusted. Injected at session start via SessionStart hook. **Read-only during sessions.** Only modified through the reflect cycle with human approval.
- **`shortterm-{project}.md`** — Per-project short-term capture. Append-only during sessions.
- **`shortterm.md`** — Global short-term capture for cross-project observations.
- **`reports/`** — Weekly evaluation folders with analysis and candidate files.

## Write Gate

Before appending to any shortterm file, ask yourself:

1. **Would this change future behavior?** (preference, pattern, boundary)
2. **Is it a correction?** (user corrected something — highest priority)
3. **Is it a decision with rationale?** (the *why*, not the *what*)
4. **Is it a dead end or gotcha?** (saves future sessions from repeating)
5. **Did the user explicitly say `/remember`?**

If none are true, **don't write it.** Less is more. The write gate prevents noise from drowning out signal.

## Entry Format

When writing to shortterm files, use this format:

```
## [TIMESTAMP]
**Type:** [observation | correction | decision | dead-end | feedback | usage]
**Entry:** [content]
```

### Correction Entries (Highest Priority)

When the user corrects you, always capture it immediately:

```
## [TIMESTAMP]
**Type:** correction
**Entry:** [what was wrong] → [what's correct]. Context: [why it matters]
```

Corrections are prioritized for graduation to long-term memory during the reflect cycle.

## Usage Tracking

When you reference or use information from `longterm.md` during a session, note it in the project shortterm:

```
## [TIMESTAMP]
**Type:** usage
**Entry:** Used longterm: [brief summary of what was used and how]
```

## Long-Term Memory Rules

### Read-only during sessions
Never write to `longterm.md` during a session. It is curated through the reflect cycle and human review only.

### Supersede, don't delete
When long-term entries are updated during the reflect cycle, old content is marked `[superseded: YYYY-MM-DD — reason]` rather than deleted. The trail of change is itself valuable context.

### Keep it lean
If you wouldn't reference it in 3 out of 5 sessions, it probably doesn't belong in long-term memory.

## The `/remember` Command

When the user runs `/remember <text>`, append to the current project's shortterm file:

```
## [TIMESTAMP]
**Type:** feedback
**Context:** [CURRENT_WORKING_DIRECTORY]
**Entry:** [user's text, verbatim]
```

Capture verbatim. Don't interpret or editorialize. Confirm briefly.

## What NOT to Capture

- Anything the codebase, git history, or project CLAUDE.md / native auto-memory already covers
- Ephemeral task details that won't matter next session
- Information that doesn't pass the write gate

## Self-Evaluation During Sessions

Periodically check:
- Did I load long-term memory and actually use it? (log usage if so)
- Did the user have to re-explain something that should have been remembered? (log as correction)
- Am I writing too much to shortterm? (tighten the write gate)
- Am I writing too little? (loosen it)

Observations about your own memory behavior go to the global shortterm file.

## Evolving Strategy

*This section evolves over time. Changes are proposed in weekly reports and approved by the user.*

### v0 — Starting Heuristics
- Apply the write gate. When uncertain, write — pruning is cheaper than re-discovery.
- Corrections always get captured, no gate needed.
- Let structure emerge from use. Don't impose categories prematurely.
- Long-term memory stays lean. Shortterm can be messy.
- Focus on what native auto-memory doesn't cover: the *why*, the dead ends, the preferences, the cross-project patterns.
