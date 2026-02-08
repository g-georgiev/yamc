#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="$HOME/.claude-memory"

# Skip if memory dir doesn't exist
[ -d "$MEMORY_DIR" ] || exit 0

# Detect project context
PROJECT_TAG="global"
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    PROJECT_TAG=$(basename "$CLAUDE_PROJECT_DIR")
elif git rev-parse --show-toplevel &>/dev/null; then
    PROJECT_TAG=$(basename "$(git rev-parse --show-toplevel)")
fi

# Write compaction marker to project shortterm
PROJECT_SHORTTERM="$MEMORY_DIR/shortterm-${PROJECT_TAG}.md"
if [ -f "$PROJECT_SHORTTERM" ]; then
    echo "" >> "$PROJECT_SHORTTERM"
    echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROJECT_SHORTTERM"
    echo "**Type:** session-marker" >> "$PROJECT_SHORTTERM"
    echo "**Entry:** Session compacted for project: ${PROJECT_TAG}" >> "$PROJECT_SHORTTERM"
fi

# Git commit any changes
cd "$MEMORY_DIR"
if [ -d .git ]; then
    git add -A 2>/dev/null || true
    git commit -m "yamc: session ${PROJECT_TAG} $(date -u +%Y-%m-%dT%H:%M:%SZ)" --quiet 2>/dev/null || true
fi

# PreCompact output is NOT visible to the model — file writes only
