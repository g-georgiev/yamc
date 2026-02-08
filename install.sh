#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="$HOME/.claude-memory"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFLECT_SCRIPT="$MEMORY_DIR/reflect.sh"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[claude-memory]${NC} $1"; }
warn() { echo -e "${YELLOW}[claude-memory]${NC} $1"; }

# -------------------------------------------------------------------
# 1. Create memory directory with git
# -------------------------------------------------------------------
setup_memory_dir() {
    info "Setting up memory directory..."

    mkdir -p "$MEMORY_DIR/reports"

    if [ ! -d "$MEMORY_DIR/.git" ]; then
        git -C "$MEMORY_DIR" init --quiet
        info "Initialized git in $MEMORY_DIR"
    else
        warn "Git already initialized"
    fi

    # Create .gitignore
    cat > "$MEMORY_DIR/.gitignore" << 'EOF'
# Reflect script is managed by the plugin, not memory content
reflect.sh
EOF

    # Seed longterm.md
    if [ ! -f "$MEMORY_DIR/longterm.md" ]; then
        cat > "$MEMORY_DIR/longterm.md" << 'EOF'
# Long-Term Memory

*Curated memory. Modified only through the reflect cycle with human approval.*
*Entries marked [superseded] are kept for context — the trail of change matters.*
EOF
        info "Created longterm.md"
    else
        warn "longterm.md already exists"
    fi

    # Seed global shortterm.md
    if [ ! -f "$MEMORY_DIR/shortterm.md" ]; then
        cat > "$MEMORY_DIR/shortterm.md" << 'EOF'
# Short-Term Memory: Global

*Append-only capture for cross-project observations.*
*Reviewed during the weekly reflect cycle.*
EOF
        info "Created shortterm.md"
    else
        warn "shortterm.md already exists"
    fi

    # Initial commit
    cd "$MEMORY_DIR"
    git add -A
    git commit -m "init: yamc v0.1.0" --quiet 2>/dev/null || warn "Nothing to commit"
}

# -------------------------------------------------------------------
# 2. Install reflect script and scheduler
# -------------------------------------------------------------------
setup_reflect_script() {
    cp "$SCRIPT_DIR/reflect.sh" "$REFLECT_SCRIPT"
    chmod +x "$REFLECT_SCRIPT"
}

setup_scheduler_systemd() {
    local unit_dir="$HOME/.config/systemd/user"
    mkdir -p "$unit_dir"

    cat > "$unit_dir/yamc-reflect.service" << EOF
[Unit]
Description=YAMC weekly memory reflection

[Service]
Type=oneshot
ExecStart=$REFLECT_SCRIPT
Environment=HOME=$HOME
Environment=PATH=$PATH
EOF

    cat > "$unit_dir/yamc-reflect.timer" << EOF
[Unit]
Description=Run YAMC reflect weekly on Monday 9 AM

[Timer]
OnCalendar=Mon *-*-* 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now yamc-reflect.timer
    info "systemd timer installed: weekly Monday 9 AM (Persistent=true)"
}

setup_scheduler_launchd() {
    local plist_dir="$HOME/Library/LaunchAgents"
    local plist="$plist_dir/com.yamc.reflect.plist"
    mkdir -p "$plist_dir"

    cat > "$plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yamc.reflect</string>
    <key>ProgramArguments</key>
    <array>
        <string>$REFLECT_SCRIPT</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$MEMORY_DIR/reflect-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$MEMORY_DIR/reflect-stderr.log</string>
</dict>
</plist>
EOF

    launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist"
    info "launchd agent installed: weekly Monday 9 AM"
}

setup_scheduler_cron() {
    local cron_schedule="0 9 * * 1"
    if crontab -l 2>/dev/null | grep -q "yamc.*reflect\|claude-memory.*reflect"; then
        warn "Cron job already exists"
    else
        (crontab -l 2>/dev/null; echo "$cron_schedule $REFLECT_SCRIPT # yamc weekly reflect") | crontab -
        info "Cron fallback: installed via crontab (Monday 9 AM)"
        warn "Note: cron won't catch up on missed runs if machine was asleep"
    fi
}

setup_scheduler() {
    info "Installing reflect script and scheduler..."
    setup_reflect_script

    case "$(uname -s)" in
        Linux)
            if systemctl --user status >/dev/null 2>&1; then
                setup_scheduler_systemd
            else
                warn "systemd user session not available, falling back to cron"
                setup_scheduler_cron
            fi
            ;;
        Darwin)
            setup_scheduler_launchd
            ;;
        *)
            warn "Unknown OS: $(uname -s), falling back to cron"
            setup_scheduler_cron
            ;;
    esac
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
main() {
    info "Installing YAMC (Yet Another Memory for Claude) v0.1.0"
    echo ""

    setup_memory_dir
    echo ""

    setup_scheduler
    echo ""

    info "Done!"
    echo ""
    info "Plugin setup — run these in any Claude Code session:"
    info "  1. /plugin marketplace add g-georgiev/yamc"
    info "  2. /plugin install yamc@yamc"
    info "  Select 'User' scope when prompted for global activation."
    echo ""
    info "For development/testing without marketplace:"
    info "  claude --plugin-dir $SCRIPT_DIR"
    echo ""
    info "Usage:"
    info "  /remember <anything>  — capture to short-term memory"
    info "  Long-term memory loads automatically at session start"
    info "  Weekly reports appear in ~/.claude-memory/reports/"
    echo ""
    info "Memory directory: $MEMORY_DIR (local git repo, nothing pushed)"
}

main "$@"
