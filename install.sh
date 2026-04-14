#!/usr/bin/env bash
# install.sh — llm-primer installer
# Usage: curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash

set -euo pipefail

REPO="asakin/llm-primer"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
PRIMER_DIR="${PRIMER_DIR:-$HOME/.llm-primer}"
LAUNCHD="${LAUNCHD:-}"   # set to "yes" to install launchd auto-start (macOS only)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}→${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# ── checks ────────────────────────────────────────────────────────────────────

check_deps() {
  local missing=()
  for cmd in tmux curl; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required dependencies: ${missing[*]}"
  fi

  if ! command -v claude &>/dev/null; then
    warn "Claude Code ('claude') not found in PATH."
    warn "Install it from: https://claude.ai/code"
    warn "llm-primer will install, but won't work until claude is available."
  fi
}

# ── download ──────────────────────────────────────────────────────────────────

download_files() {
  local base_url="https://raw.githubusercontent.com/${REPO}/main"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  info "Downloading llm-primer..."
  curl -fsSL "${base_url}/bin/primer"    -o "$tmp_dir/primer"
  curl -fsSL "${base_url}/bin/primerd"   -o "$tmp_dir/primerd"
  curl -fsSL "${base_url}/bin/primer-gc" -o "$tmp_dir/primer-gc"

  chmod +x "$tmp_dir/primer" "$tmp_dir/primerd" "$tmp_dir/primer-gc"

  if [[ -w "$INSTALL_DIR" ]]; then
    cp "$tmp_dir/primer" "$tmp_dir/primerd" "$tmp_dir/primer-gc" "$INSTALL_DIR/"
  else
    info "Installing to $INSTALL_DIR (requires sudo)..."
    sudo cp "$tmp_dir/primer" "$tmp_dir/primerd" "$tmp_dir/primer-gc" "$INSTALL_DIR/"
  fi

  info "Installed: $INSTALL_DIR/primer"
  info "Installed: $INSTALL_DIR/primerd"
  info "Installed: $INSTALL_DIR/primer-gc"
}

# ── state dir ─────────────────────────────────────────────────────────────────

setup_dirs() {
  mkdir -p "$PRIMER_DIR/state"
  info "State directory: $PRIMER_DIR"
}

# ── launchd auto-start (macOS) ────────────────────────────────────────────────
#
# Installs a LaunchAgent so primerd starts automatically on login.
# Runs in lazy mode by default — zero idle cost until you need a session.
#
# Enable: LAUNCHD=yes ./install.sh
# Or manually: install.sh will offer to set it up.

install_launchd() {
  local plist_dir="$HOME/Library/LaunchAgents"
  local plist_file="$plist_dir/io.github.asakin.primerd.plist"
  local primer_log="$PRIMER_DIR/primerd.log"

  mkdir -p "$plist_dir"

  cat > "$plist_file" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>io.github.asakin.primerd</string>

  <key>ProgramArguments</key>
  <array>
    <string>${INSTALL_DIR}/primerd</string>
    <string>start</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <false/>

  <key>StandardOutPath</key>
  <string>${primer_log}</string>

  <key>StandardErrorPath</key>
  <string>${primer_log}</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PRIMER_MODE</key>
    <string>lazy</string>
    <key>PRIMER_POOL_SIZE</key>
    <string>3</string>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>${INSTALL_DIR}:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
</dict>
</plist>
PLIST

  launchctl load "$plist_file" 2>/dev/null || true
  info "LaunchAgent installed: $plist_file"
  info "primerd will start automatically on login (lazy mode)"
  info "To unload: launchctl unload $plist_file"
}

# ── shell integration ─────────────────────────────────────────────────────────

suggest_shell_setup() {
  local shell_rc=""
  case "${SHELL:-}" in
    */zsh)  shell_rc="~/.zshrc" ;;
    */bash) shell_rc="~/.bashrc" ;;
    *)      shell_rc="your shell config" ;;
  esac

  cat <<EOF

${GREEN}✓${NC} llm-primer installed!

Quick start:
  primerd start          # start the pool daemon
  primer attach          # attach to a warm claude session
  primer haiku           # attach to the cheap haiku session
  primer switch          # pre-warm a replacement when context gets heavy
  primer status          # check pool health

Recommended: add to $shell_rc

  # llm-primer
  export PRIMER_WATCH_DIR=~/path/to/your/vault/_config
  export PRIMER_GC_VAULT=~/path/to/your/vault
  alias cc='primer attach'      # warm claude session in two keystrokes
  alias ch='primer haiku'       # switch to haiku for quick tasks

iTerm2 auto-open setup:
  In iTerm2: Preferences → Profiles → [your profile] → General → Command
  Set to: /usr/local/bin/primer attach
  Now every new iTerm2 tab opens directly into a warm session.

  If you use the Obsidian embedded terminal (ObsidianTerminal plugin):
  Set the "Custom Shell Command" to: primer attach

  Both require primerd to already be running. With launchd (macOS), that's
  automatic on login. Otherwise run: primerd start

EOF
}

maybe_install_launchd() {
  [[ "$(uname)" != "Darwin" ]] && return

  if [[ "${LAUNCHD:-}" == "yes" ]]; then
    install_launchd
    return
  fi

  echo ""
  echo -n "Install launchd agent so primerd starts automatically on login? [y/N] "
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    install_launchd
  else
    warn "Skipped launchd. Run 'primerd start' manually each login, or re-run:"
    warn "  LAUNCHD=yes bash install.sh"
  fi
}

# ── main ──────────────────────────────────────────────────────────────────────

echo "llm-primer installer"
echo "────────────────────"
check_deps
download_files
setup_dirs
maybe_install_launchd
suggest_shell_setup
