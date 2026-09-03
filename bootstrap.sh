#!/bin/bash
# ─────────────────────────────────────────────────────────────
# bootstrap.sh — One-command setup for teachme
# ─────────────────────────────────────────────────────────────
#
# Usage:
#   ./bootstrap.sh                # install everything
#   ./bootstrap.sh --check        # verify only (no changes)
#   ./bootstrap.sh --uninstall    # remove the agent
#
# Does, in order:
#   1. Node.js >= 18        (skipped if present)
#   2. Freebuff             (npm install -g freebuff, skipped if present)
#   3. Python               (used to generate/sync the agent)
#   4. Installs the agent   (copies or generates ~/.agents/teachme.ts)
#   5. Verifies             (node --check + sync check)
#
# Idempotent: safe to run any number of times.
# ─────────────────────────────────────────────────────────────

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="$HOME/.agents"
AGENT_FILE="$AGENTS_DIR/teachme.ts"
SOURCE_FILE="$SCRIPT_DIR/.agents/teachme.ts"
HELPER="$SCRIPT_DIR/sync_helper.py"

print_ok()    { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
print_info()  { echo -e "${CYAN}→${NC} $1"; }

have() { command -v "$1" &> /dev/null; }

# ─── Step 1: Node.js ─────────────────────────────────────────
ensure_node() {
    if have node; then
        local major
        major=$(node -v | sed 's/^v//' | cut -d. -f1)
        if [ "$major" -ge 18 ]; then
            print_ok "Node.js $(node -v)"
            return 0
        fi
        print_warn "Node.js $(node -v) is too old (need >= 18); trying to upgrade"
    else
        print_info "Node.js not found; installing"
    fi

    if have winget; then
        winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements && return 0
    elif have brew; then
        brew install node && return 0
    elif have apt-get; then
        sudo apt-get update && sudo apt-get install -y nodejs npm && return 0
    elif have dnf; then
        sudo dnf install -y nodejs && return 0
    elif have pacman; then
        sudo pacman -S --noconfirm nodejs npm && return 0
    fi

    print_error "Could not install Node.js automatically."
    echo "  Install it from https://nodejs.org (>= 18), then re-run this script."
    return 1
}

# ─── Step 2: Freebuff ────────────────────────────────────────
ensure_freebuff() {
    if have freebuff; then
        print_ok "Freebuff installed"
        return 0
    fi
    print_info "Installing Freebuff (npm install -g freebuff)..."
    if npm install -g freebuff; then
        print_ok "Freebuff installed"
        return 0
    fi
    print_error "npm install -g freebuff failed (try with sudo, or fix npm permissions)."
    return 1
}

# ─── Step 3: Python (required for generation/sync) ───────────
ensure_python() {
    if have python || have python3; then
        print_ok "Python available"
        return 0
    fi
    print_error "Python not found — it is required to generate/sync the agent"
    return 1
}

python_cmd() {
    if have python; then
        command -v python
    elif have python3; then
        command -v python3
    else
        return 1
    fi
}

# ─── Step 4: install the agent ───────────────────────────────
install_agent() {
    mkdir -p "$AGENTS_DIR"
    if [ -f "$SOURCE_FILE" ]; then
        cp "$SOURCE_FILE" "$AGENT_FILE"
    else
        local py
        py=$(python_cmd) || {
            print_error "Python not found — cannot generate the agent"
            exit 1
        }
        if ! "$py" "$HELPER" --generate --output "$AGENT_FILE"; then
            print_error "Could not generate the agent from: $SCRIPT_DIR/.agents/teachme.md"
            exit 1
        fi
    fi
    print_ok "Agent installed: $AGENT_FILE"

    if node --check "$AGENT_FILE" 2>/dev/null; then
        print_ok "Agent syntax valid"
    else
        print_error "Agent syntax check FAILED — Freebuff may not load it"
        exit 1
    fi
}

# ─── Main paths ──────────────────────────────────────────────
do_install() {
    echo ""
    echo -e "${CYAN}═══ teachme bootstrap ═══${NC}"
    echo ""
    ensure_node     || exit 1
    ensure_freebuff || exit 1
    ensure_python || exit 1
    install_agent
    
    # Stamp/show version
    local py=""
    py=$(python_cmd 2>/dev/null || true)
    if [ -n "$py" ]; then
        local ver
        ver=$("$py" "$HELPER" --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        [ -n "$ver" ] && print_ok "Agent version: ${ver}"
    fi

    echo ""
    do_check || true
    echo ""
    echo -e "${GREEN}Ready to go.${NC}"
    echo ""
    echo "Try it:"
    echo "  cd $SCRIPT_DIR && freebuff"
    echo "  then type: @teachme enséñame qué es un hash"
    echo ""
    echo "(If Freebuff was already open, start a NEW session to load the agent.)"
}

do_check() {
    local ok=1
    have node     && print_ok "Node.js $(node -v)"   || { print_error "Node.js missing";  ok=0; }
    have freebuff && print_ok "Freebuff installed"   || { print_error "Freebuff missing"; ok=0; }
    if [ -f "$AGENT_FILE" ]; then
        print_ok "Agent installed: $AGENT_FILE"
        node --check "$AGENT_FILE" 2>/dev/null && print_ok "Agent syntax valid" || { print_error "Agent syntax invalid"; ok=0; }
    else
        print_error "Agent not installed (run: ./bootstrap.sh)"
        ok=0
    fi
    # Sync check (needs Python)
    local py=""
    py=$(python_cmd 2>/dev/null || true)
    if [ -n "$py" ] && [ -f "$HELPER" ]; then
        if "$py" "$HELPER" --check --output "$AGENT_FILE" >/dev/null 2>&1; then
            print_ok ".md and .ts are in sync"
        else
            print_warn ".md and .ts are OUT of sync — run: ./sync-md-ts.sh"
        fi
    fi
    return $((1 - ok))
}

do_version() {
    local py=""
    py=$(python_cmd 2>/dev/null || true)
    if [ -z "$py" ]; then
        print_error "Python no encontrado — no puedo leer la version"
        exit 1
    fi
    "$py" "$HELPER" --version
}

do_uninstall() {
    if [ -f "$AGENT_FILE" ]; then
        rm "$AGENT_FILE"
        print_ok "Agent removed: $AGENT_FILE"
    else
        print_warn "Agent was not installed"
    fi
    echo "Done. Learning data (LEARNING_LOG.md, vaults) was not touched."
}

case "${1:-}" in
    --check|-c)     do_check ;;
    --version|-v)   do_version ;;
    --uninstall|-u) do_uninstall ;;
    --help|-h)
        echo "Usage: ./bootstrap.sh [option]"
        echo ""
        echo "Options:"
        echo "  (no args)        Install everything (Node, Freebuff, agent)"
        echo "  --check, -c      Verify installation only"
        echo "  --version, -v    Show source/installed agent version"
        echo "  --uninstall, -u  Remove the agent"
        echo "  --help, -h       This help"
        ;;
    *) do_install ;;
esac
