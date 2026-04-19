#!/usr/bin/env bash
# llm-primer installer — downloads primer and primerd into /usr/local/bin.
# For Homebrew installs, use: brew tap asakin/llm-primer && brew install llm-primer.

set -euo pipefail

VERSION="${VERSION:-v0.2.0}"
BASE="https://raw.githubusercontent.com/asakin/llm-primer/${VERSION}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

die() { echo "error: $*" >&2; exit 1; }

command -v curl &>/dev/null || die "curl is required"
command -v tmux &>/dev/null || echo "warning: tmux not found — install it before running primerd"

echo "→ Installing llm-primer ${VERSION} to ${INSTALL_DIR}"

[[ -w "$INSTALL_DIR" ]] || die "Cannot write to $INSTALL_DIR. Re-run with sudo or set INSTALL_DIR to a writable path."

for bin in primer primerd primer-log-filter; do
  echo "  downloading $bin"
  curl -fsSL "$BASE/bin/$bin" -o "$INSTALL_DIR/$bin"
  chmod +x "$INSTALL_DIR/$bin"
done

echo ""
echo "✓ Installed."
echo ""
echo "Quick start:"
echo "  primer start"
echo "  primer"
echo ""
echo "Uninstall: rm $INSTALL_DIR/primer $INSTALL_DIR/primerd"
