#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="$HOME/.claude-memory"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[yamc]${NC} $1"; }
warn() { echo -e "${YELLOW}[yamc]${NC} $1"; }
err()  { echo -e "${RED}[yamc]${NC} $1"; }

# -------------------------------------------------------------------
# 1. Remove scheduler
# -------------------------------------------------------------------
remove_scheduler() {
    info "Removing scheduler..."

    # systemd
    local unit_dir="$HOME/.config/systemd/user"
    if [ -f "$unit_dir/yamc-reflect.timer" ]; then
        systemctl --user disable --now yamc-reflect.timer 2>/dev/null || true
        rm -f "$unit_dir/yamc-reflect.timer" "$unit_dir/yamc-reflect.service"
        systemctl --user daemon-reload 2>/dev/null || true
        info "Removed systemd timer and service"
    fi

    # launchd
    local plist="$HOME/Library/LaunchAgents/com.yamc.reflect.plist"
    if [ -f "$plist" ]; then
        launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || true
        rm -f "$plist"
        info "Removed launchd agent"
    fi

    # cron
    if crontab -l 2>/dev/null | grep -q "yamc.*reflect\|claude-memory.*reflect"; then
        crontab -l 2>/dev/null | grep -v "yamc.*reflect\|claude-memory.*reflect" | crontab -
        info "Removed cron job"
    fi
}

# -------------------------------------------------------------------
# 2. Remove memory directory
# -------------------------------------------------------------------
remove_memory_dir() {
    if [ ! -d "$MEMORY_DIR" ]; then
        warn "Memory directory not found, nothing to remove"
        return
    fi

    echo ""
    err "This will permanently delete $MEMORY_DIR and all memory data."

    # Check if there's a remote (data might be backed up)
    if git -C "$MEMORY_DIR" remote -v 2>/dev/null | grep -q .; then
        info "Note: a git remote is configured, so your data may be backed up."
    else
        err "There is no remote — this data is local only and cannot be recovered."
    fi

    echo ""
    read -rp "Delete $MEMORY_DIR? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$MEMORY_DIR"
        info "Removed $MEMORY_DIR"
    else
        warn "Kept $MEMORY_DIR"
    fi
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
main() {
    echo ""
    info "Uninstalling YAMC (Yet Another Memory for Claude)"
    echo ""

    remove_scheduler
    remove_memory_dir

    echo ""
    info "Scheduler and memory data handled."
    echo ""
    info "To remove the plugin from Claude Code, run in a session:"
    info "  /plugin uninstall yamc"
    echo ""
    info "You can also delete the plugin directory itself if no longer needed."
}

main "$@"
