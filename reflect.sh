#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="$HOME/.claude-memory"
REPORT_DIR="$MEMORY_DIR/reports"
DATE=$(date +%Y-%m-%d)
REPORT_FOLDER="$REPORT_DIR/$DATE"

# Ensure report folder exists
mkdir -p "$REPORT_FOLDER"

BRANCH="reflect/$DATE"

PROMPT=$(cat << PROMPT_END
You are reviewing your memory system for a weekly evaluation.
You have tool access (Read, Glob, Grep, Bash for git, Write, Edit). Use them.
Working directory: $MEMORY_DIR

## Phase 1 — Gather context

Read these files using your tools:
1. Read $MEMORY_DIR/longterm.md — curated long-term memory
2. Glob $MEMORY_DIR/shortterm*.md, then read each — short-term captures from recent sessions
3. Read the "Evolving Strategy" section from the memory protocol (find it via Glob in the yamc plugin directory under rules/)
4. Glob $MEMORY_DIR/reports/*/report.md, read the most recent one (if any prior to today)
5. Run: git -C $MEMORY_DIR log --oneline -20

## Phase 2 — Write report on main

Write $REPORT_FOLDER/report.md with these sections:

### Short-Term Activity
- Number of new entries across all shortterm files since last report
- Breakdown by project and by type (observation, correction, decision, dead-end, feedback, usage)

### Usage Patterns
- Which longterm.md entries were used (look for "Type: usage" entries)
- Which longterm.md entries were NOT referenced at all
- Ratio of used vs unused long-term memories

### Corrections Review
- All correction entries since last report — these are highest priority
- Assessment: should each correction graduate to longterm.md?

### Patterns and Insights
- Recurring themes across short-term entries and projects
- Cross-project patterns worth noting
- Anything surprising or noteworthy

### Questions for Human
- Anything uncertain that needs human judgment
- Ambiguous entries or conflicting signals

### Strategy Assessment
- Is the current write gate calibrated well? (too much noise? too few entries?)
- Is longterm.md the right size? (bloated? sparse?)
- Proposed changes to the Evolving Strategy section (describe only, don't apply)

### Self-Assessment
- Honest evaluation: is the memory system producing value?
- Git history analysis: how has memory evolved over time?

After writing the report, commit on main:
  git -C $MEMORY_DIR add -A && git -C $MEMORY_DIR commit -m "yamc reflect: report $DATE"

## Phase 3 — Apply proposed changes on a branch

If (and only if) there are changes to propose (longterm graduations, longterm modifications, or shortterm pruning), do the following:

1. Create and switch to branch: git -C $MEMORY_DIR checkout -b $BRANCH
2. Apply the changes directly to the actual files:
   - Graduate entries to longterm.md (append new entries)
   - Modify longterm.md entries (mark old content with [superseded: $DATE — reason], add new wording)
   - Prune shortterm entries that are safe to remove (graduated, ephemeral, redundant)
3. Commit: git -C $MEMORY_DIR add -A && git -C $MEMORY_DIR commit -m "yamc reflect: proposed changes $DATE"
4. Switch back to main: git -C $MEMORY_DIR checkout main

If there are no changes to propose, skip this phase entirely.

## Rules
- Phase 2 (report) is committed on main — it's always kept
- Phase 3 (changes) is committed on a branch — it's only merged if the human approves
- Be concise. The human will skim this over coffee.
PROMPT_END
)

# Run Claude headlessly with tool access
if command -v claude &> /dev/null; then
    echo "$PROMPT" | claude -p \
        --allowedTools "Read,Glob,Grep,Bash(git *),Write,Edit" \
        2>/dev/null

    echo ""
    echo "[yamc] Report: $REPORT_FOLDER/report.md"
    if git -C "$MEMORY_DIR" rev-parse --verify "$BRANCH" &>/dev/null; then
        echo "[yamc] Proposed changes on branch: $BRANCH"
        echo "[yamc] Review:  git -C $MEMORY_DIR diff main..$BRANCH"
        echo "[yamc] Accept:  git -C $MEMORY_DIR merge $BRANCH"
        echo "[yamc] Reject:  git -C $MEMORY_DIR branch -D $BRANCH"
    else
        echo "[yamc] No changes proposed this week."
    fi
else
    echo "[yamc] Error: claude command not found" >&2
    exit 1
fi
