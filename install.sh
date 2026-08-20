#!/usr/bin/env bash
#
# Hatrick bootstrap.
#
#   curl -fsSL https://raw.githubusercontent.com/Chuhukon/Hatrick/main/install.sh | bash
#
# Hatrick is a script plus a plugins/ tree; hatrick.sh alone is useless, it
# looks next to itself for lib/ and plugins/. So this fetches the whole thing
# into ~/.local/share/hatrick, links it into ~/.local/bin, and starts the menu.
#
# Run it as your normal user, not with sudo. Same reason as Hatrick itself.

set -euo pipefail

REPO="${HATRICK_REPO:-Chuhukon/Hatrick}"
REF="${HATRICK_REF:-main}"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/hatrick"
BIN="$HOME/.local/bin/hatrick"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    B=$'\e[1m'; CYAN=$'\e[36m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; R=$'\e[0m'
else
    B=""; CYAN=""; YELLOW=""; RED=""; R=""
fi

say()  { printf '%s==>%s %s\n' "$CYAN" "$R" "$*"; }
warn() { printf '%s!!%s  %s\n' "$YELLOW" "$R" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$RED" "$R" "$*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
    die "do not install Hatrick as root. Run this as your normal user; the plugins
call sudo themselves, so group membership, GNOME settings, flatpaks and \$HOME
end up on your account instead of root's."
fi

for tool in curl tar; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool is required: sudo dnf install -y $tool"
done

# Unpack into scratch first, so a half-finished download never replaces a
# working install.
TMP="$(mktemp -d -t hatrick-install-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

say "Downloading ${B}${REPO}${R} (${REF})"
curl -fsSL "https://codeload.github.com/${REPO}/tar.gz/refs/heads/${REF}" |
    tar -xzf - -C "$TMP" --strip-components=1 ||
    die "could not download ${REPO}@${REF}"

[ -f "$TMP/hatrick.sh" ] || die "download looks wrong: no hatrick.sh in it"
# shellcheck disable=SC2012
[ "$(ls "$TMP"/plugins/*/*.sh 2>/dev/null | wc -l)" -gt 0 ] ||
    die "download looks wrong: no plugins in it"

say "Installing to ${B}${DEST}${R}"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mv "$TMP" "$DEST"
trap - EXIT
chmod +x "$DEST/hatrick.sh"

mkdir -p "$HOME/.local/bin"
ln -sfn "$DEST/hatrick.sh" "$BIN"
say "Linked ${B}${BIN}${R}"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) warn "$HOME/.local/bin is not in your PATH. Add this to ~/.bashrc:"
       warn '  export PATH="$HOME/.local/bin:$PATH"' ;;
esac

printf '\n'

# Under `curl ... | bash` stdin is the pipe, and every prompt in the menu would
# read EOF straight away. Hand it the terminal instead.
# `test -r /dev/tty` is not enough - with no controlling terminal the file is
# there but opening it fails, so try the open itself.
if (exec 3< /dev/tty) 2>/dev/null; then
    exec "$DEST/hatrick.sh" < /dev/tty
else
    say "Installed. Run: ${B}hatrick${R}"
fi
