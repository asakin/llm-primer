#!/usr/bin/env bash
# install.sh — llm-primer installer
# Usage: curl -fsSL https://raw.githubusercontent.com/asakin/llm-primer/main/install.sh | bash

set -euo pipefail

REPO="asakin/llm-primer"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
PRIMER_DIR="${PRIMER_DIR:-$HOME/.llm-primer}"

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
  curl -fsSL "${base_url}/bin/primer" -o "$tmp_dir/primer"
  curl -fsSL "${base_url}/bin/primerd" -o "$tmp_dir/primerd"

  chmod +x "$tmp_dir/primer" "$tmp_dir/primerd"

  # Install to INSTALL_DIR (may need sudo)
  if [[ -w "$INSTALL_DIR" ]]; then
    cp "$tmp_dir/primer" "$tmp_dir/primerd" "$INSTALL_DIR/"
  else
    info "Installing to $INSTALL_DIR (requires sudo)..."
    sudo cp "$tmp_dir/primer" "$tmp_dir/primerd" "$INSTALL_DIR/"
  fi

  info "Installed: $INSTALL_DIR/primer"
  info "Installed: $INSTALL_DIR/primerd"
}

# ── state dir ─────────────────────────────────────────────────────────────────

setup_dirs() {
  mkdir -p "$PRIMER_DIR/state"
  info "State directory: $PRIMER_DIR"
}

# ── shell integration (optional) ──────────────────────────────────────────────

suggest_alias() {
  cat <<EOF

${GREEN}✓${NC} llm-primer installed!

Quick start:
  primerd start          # start the pool daemon
  primer attach          # attach to a warm session
  primer status          # check pool health

Optional: add to your shell config (~/.zshrc or ~/.bashrc):
  export PRIMER_WATCH_DIR=~/path/to/your/vault/_config
  export PRIMER_POOL_SIZE=3
  alias cc='primer attach'   # launch claude code instantly

EOF
}

# ── main ──────────────────────────────────────────────────────────────────────

echo "llm-primer installer"
echo "────────────────────"
check_deps
download_files
setup_dirs
suggest_alias
