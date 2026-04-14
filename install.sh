#!/usr/bin/env bash
# install.sh — llm-primer installer
# Usage: curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash

set -euo pipefail

REPO="asakin/llm-primer"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
PRIMER_DIR="${PRIMER_DIR:-$HOME/.llm-primer}"
LAUNCHD="${LAUNCHD:-}"        # set to "yes" to install launchd auto-start (macOS only)
VERSION="${VERSION:-main}"    # git ref to install from (tag, branch, or commit)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}→${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# ── checks ────────────────────────────────────────────────────────────────────

try_install_tmux() {
  # Offer to install tmux via the system package manager. Returns 0 if installed.
  if command -v brew &>/dev/null; then
    info "tmux not found. Installing via Homebrew..."
    brew install tmux && return 0
  elif command -v apt-get &>/dev/null; then
    info "tmux not found. Installing via apt-get (requires sudo)..."
    sudo apt-get update && sudo apt-get install -y tmux && return 0
  elif command -v dnf &>/dev/null; then
    info "tmux not found. Installing via dnf (requires sudo)..."
    sudo dnf install -y tmux && return 0
  elif command -v pacman &>/dev/null; then
    info "tmux not found. Installing via pacman (requires sudo)..."
    sudo pacman -S --noconfirm tmux && return 0
  fi
  return 1
}

check_deps() {
  if ! command -v tmux &>/dev/null; then
    if ! try_install_tmux; then
      error "tmux is required but not installed, and no supported package manager (brew/apt/dnf/pacman) was found. Install tmux manually and re-run."
    fi
  fi

  if ! command -v curl &>/dev/null; then
    error "Missing required dependency: curl"
  fi

  # Check for the configured CLI (defaults to claude if PRIMER_CLI isn't set yet).
  local cli_cmd="${PRIMER_CLI:-claude}"
  local cli_bin="${cli_cmd%% *}"
  if ! command -v "$cli_bin" &>/dev/null; then
    warn "'$cli_bin' not found in PATH."
    warn "llm-primer will install, but your configured LLM CLI must be"
    warn "available before it works. Set PRIMER_CLI in ~/.llm-primer/config"
    warn "to use a different tool (aider, ollama, gemini, etc.)."
  fi
}

# ── download ──────────────────────────────────────────────────────────────────

download_files() {
  local base_url="https://raw.githubusercontent.com/${REPO}/${VERSION}"
  info "Installing from ${VERSION}"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  info "Downloading llm-primer..."
  local bins=(primer primerd primer-gc primer-selftest)
  for bin in "${bins[@]}"; do
    curl -fsSL "${base_url}/bin/${bin}" -o "$tmp_dir/${bin}"
    chmod +x "$tmp_dir/${bin}"
  done

  if [[ -w "$INSTALL_DIR" ]]; then
    for bin in "${bins[@]}"; do cp "$tmp_dir/${bin}" "$INSTALL_DIR/"; done
  else
    info "Installing to $INSTALL_DIR (requires sudo)..."
    for bin in "${bins[@]}"; do sudo cp "$tmp_dir/${bin}" "$INSTALL_DIR/"; done
  fi

  for bin in "${bins[@]}"; do info "Installed: $INSTALL_DIR/${bin}"; done
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

  # Note: no PRIMER_MODE / PRIMER_POOL_SIZE injected here. Let ~/.llm-primer/config
  # drive those so edits in one place don't need a plist regeneration.
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

Next steps:
  1. Generate a config file:
     primerd config-template > ~/.llm-primer/config

  2. Edit it to set PRIMER_CLI (and optionally PRIMER_ALT_CLI).

  3. Start the pool:
     primerd start                   # manual, or skip if launchd is set up

Quick start:
  primer attach          # attach to a warm session
  primer alt             # attach to the alt slot (if configured)
  primer switch          # pre-warm a replacement when context gets heavy
  primer status          # check pool health
  primer selftest --fast # verify the install

Recommended shell aliases ($shell_rc):
  alias cc='primer attach'    # warm session in two keystrokes
  alias ca='primer alt'       # jump to alt slot

iTerm2: Preferences → Profiles → [your profile] → General → Command
  Set to: ${INSTALL_DIR}/primer attach
  Every new tab opens directly into a warm session.

Obsidian embedded terminal (ObsidianTerminal plugin):
  Set "Custom Shell Command" to: primer attach

Both require primerd to already be running. The launchd agent (macOS)
starts it automatically on login.

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
