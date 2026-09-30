#!/usr/bin/env bash
# Preserve the existing POSIX launcher for development. The swap backend is Windows-only.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
WITH_BUN_INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --with-bun-install|-B) WITH_BUN_INSTALL=1 ;;
    -h|--help) echo 'Usage: install.sh [target_bin_dir] [--with-bun-install|-B]'; exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done
if [[ "$WITH_BUN_INSTALL" -eq 1 ]]; then
  command -v bun >/dev/null || { echo 'Install Bun from https://bun.sh first.' >&2; exit 1; }
  (cd "$REPO_DIR" && bun install)
fi
mkdir -p "$TARGET_DIR"
chmod +x "$REPO_DIR/face-swap"
ln -sf "$REPO_DIR/face-swap" "$TARGET_DIR/face-swap"
echo "Installed $TARGET_DIR/face-swap -> $REPO_DIR/face-swap"
echo 'The existing swap backend requires Windows; this launcher is for development on macOS.'
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) echo "Add $TARGET_DIR to PATH in ~/.zshrc or ~/.bashrc." ;;
esac
