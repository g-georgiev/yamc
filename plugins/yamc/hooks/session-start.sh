#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="$HOME/.claude-memory"
LONGTERM="$MEMORY_DIR/longterm.md"

# Ensure memory directory exists with git
if [ ! -d "$MEMORY_DIR" ]; then
    mkdir -p "$MEMORY_DIR/reports"
    git -C "$MEMORY_DIR" init --quiet 2>/dev/null || true
fi

# Ensure longterm.md exists
if [ ! -f "$LONGTERM" ]; then
    cat > "$LONGTERM" << 'EOF'
# Long-Term Memory

*Curated memory. Modified only through the reflect cycle with human approval.*
EOF
    git -C "$MEMORY_DIR" add -A && git -C "$MEMORY_DIR" commit -m "yamc: init longterm.md" --quiet 2>/dev/null || true
fi

# Detect current project context
PROJECT_TAG="global"
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    PROJECT_TAG=$(basename "$CLAUDE_PROJECT_DIR")
elif git rev-parse --show-toplevel &>/dev/null; then
    PROJECT_TAG=$(basename "$(git rev-parse --show-toplevel)")
fi

# Ensure project-specific shortterm exists
PROJECT_SHORTTERM="$MEMORY_DIR/shortterm-${PROJECT_TAG}.md"
if [ ! -f "$PROJECT_SHORTTERM" ]; then
    cat > "$PROJECT_SHORTTERM" << EOF
# Short-Term Memory: ${PROJECT_TAG}

*Append-only capture for project: ${PROJECT_TAG}*
EOF
fi

# Also ensure global shortterm exists
if [ ! -f "$MEMORY_DIR/shortterm.md" ]; then
    cat > "$MEMORY_DIR/shortterm.md" << 'EOF'
# Short-Term Memory: Global

*Append-only capture for cross-project observations.*
EOF
fi

# Output is injected as model-visible context
echo "=== YAMC: Long-Term Memory ==="
cat "$LONGTERM"
echo ""
echo "=== YAMC: Session Context ==="
echo "Project: ${PROJECT_TAG}"
echo "Shortterm (project): ${PROJECT_SHORTTERM}"
echo "Shortterm (global): ${MEMORY_DIR}/shortterm.md"
echo "Memory dir: ${MEMORY_DIR} (git-versioned)"
