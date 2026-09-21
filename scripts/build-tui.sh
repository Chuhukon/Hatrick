#!/usr/bin/env bash
#
# scripts/build-tui.sh - compile the OpenTUI application into a standalone binary
#

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd)"

BUN_BIN="bun"
if ! command -v "$BUN_BIN" >/dev/null 2>&1; then
    if [ -x "$HOME/.bun/bin/bun" ]; then
        BUN_BIN="$HOME/.bun/bin/bun"
    else
        echo "error: bun is required to compile the TUI binary" >&2
        exit 1
    fi
fi

echo "==> Building OpenTUI application..."
cd "$ROOT/tui"

"$BUN_BIN" install --frozen-lockfile 2>/dev/null || "$BUN_BIN" install

mkdir -p "$ROOT/bin"
echo "==> Compiling standalone binary with Bun..."
"$BUN_BIN" build --compile ./src/index.tsx --outfile "$ROOT/bin/hatrick-tui"

chmod +x "$ROOT/bin/hatrick-tui"
echo "==> Binary successfully created at $ROOT/bin/hatrick-tui"
