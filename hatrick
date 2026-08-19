#!/usr/bin/env bash
#
# Hatrick - an opinionated stack for a vanilla Fedora.
#
# Run as your normal user, not with sudo. Plugins call sudo themselves for the
# system-wide parts, which is what keeps $USER, $HOME, gsettings and flatpak
# pointing at your account instead of root's.
#
#   ./hatrick        pick plugins from a menu, then install them
#   ./hatrick list   show every plugin and exit
#
# A plugin is one file: plugins/<group>/<name>.sh. See README.md.

set -uo pipefail

VERSION="0.4.0"
ROOT="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"
export HATRICK_ROOT="$ROOT"

# Shared helpers, loaded before any plugin is read so that plugin_detect and
# plugin_install can both use them. Plugins are still sourced one per subshell;
# this is a library the program provides, not a plugin leaking into the next.
for _lib in "$ROOT"/lib/*.sh; do
    # shellcheck source=/dev/null
    [ -f "$_lib" ] && . "$_lib"
done
unset _lib

# Packages installed before anything else, because several plugins assume them.
BASE_PACKAGES="curl wget git unzip tar fontconfig flatpak dnf-plugins-core"

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    B=$'\e[1m'; DIM=$'\e[2m'; CYAN=$'\e[36m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; R=$'\e[0m'
else
    B=""; DIM=""; CYAN=""; GREEN=""; YELLOW=""; RED=""; R=""
fi

say()  { printf '%s\n' "$*"; }
step() { printf '\n%s\n' "${B}${CYAN}==> $*${R}"; }
warn() { printf '%s\n' "${YELLOW}warning: $*${R}" >&2; }
die()  { printf '%s\n' "${RED}error: $*${R}" >&2; exit 1; }

banner() {
    printf '%s' "$CYAN"
    cat <<'EOF'
 ██╗  ██╗ █████╗ ████████╗██████╗ ██╗ ██████╗██╗  ██╗
 ██║  ██║██╔══██╗╚══██╔══╝██╔══██╗██║██╔════╝██║ ██╔╝
 ███████║███████║   ██║   ██████╔╝██║██║     █████╔╝
 ██╔══██║██╔══██║   ██║   ██╔══██╗██║██║     ██╔═██╗
 ██║  ██║██║  ██║   ██║   ██║  ██║██║╚██████╗██║  ██╗
 ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
    printf '%s\n\n' "${R}${DIM} an opinionated stack for a vanilla Fedora${R}"
}

# ---------------------------------------------------------------------------
# Plugins
#
# Five arrays, all indexed by position: the number shown in the menu is the
# index. Metadata is read by sourcing each plugin in a subshell, so one plugin's
# variables and functions can never leak into the next.
# ---------------------------------------------------------------------------

P_NAME=(); P_GROUP=(); P_DESC=(); P_REQ=(); P_SEL=(); P_FILE=()

discover() {
    local file name group desc reqs
    for file in "$ROOT"/plugins/*/*.sh; do
        [ -f "$file" ] || continue

        IFS='|' read -r desc reqs < <(
            unset PLUGIN_DESC PLUGIN_REQUIRES
            # shellcheck source=/dev/null
            . "$file" >/dev/null 2>&1
            printf '%s|%s\n' "${PLUGIN_DESC:-}" "${PLUGIN_REQUIRES:-}"
        )
        if [ -z "$desc" ]; then
            warn "skipping ${file#"$ROOT"/}: no PLUGIN_DESC"
            continue
        fi

        # Name comes from the filename, group from the directory. The NN-
        # prefixes only control the order things are listed and installed in.
        name="${file##*/}"; name="${name%.sh}"; name="${name#[0-9][0-9]-}"
        group="${file%/*}"; group="${group##*/}"; group="${group#[0-9][0-9]-}"

        P_NAME+=("$name")
        P_GROUP+=("${group^}")
        P_DESC+=("$desc")
        P_REQ+=("$reqs")
        P_FILE+=("$file")
        # Ticked means "not here yet": ENTER installs exactly what is missing.
        # HATRICK_FORCE=1 means reinstall regardless, so it ticks everything.
        if [ -z "${HATRICK_FORCE:-}" ] && is_installed "$(( ${#P_FILE[@]} - 1 ))"; then
            P_SEL+=(0)
        else
            P_SEL+=(1)
        fi
    done
    [ "${#P_NAME[@]}" -gt 0 ] || die "no plugins found in $ROOT/plugins"
}

# index_of <name> - echo the array index of a plugin, or nothing.
index_of() {
    local i
    for i in "${!P_NAME[@]}"; do
        [ "${P_NAME[$i]}" = "$1" ] && { printf '%s' "$i"; return 0; }
    done
    return 1
}

# is_installed <index> - true when the plugin reports itself as already present.
# Runs in a subshell, and must never need sudo: `hatrick list` calls it too.
is_installed() {
    ( PLUGIN_ASSETS="${P_FILE[$1]%.sh}"
      # shellcheck source=/dev/null
      . "${P_FILE[$1]}" >/dev/null 2>&1
      declare -F plugin_detect >/dev/null || exit 1
      plugin_detect >/dev/null 2>&1 )
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------

menu() {
    local i group="" reply mark note
    while true; do
        printf '\n'
        for i in "${!P_NAME[@]}"; do
            if [ "${P_GROUP[$i]}" != "$group" ]; then
                group="${P_GROUP[$i]}"
                printf '\n%s\n' "${B}${group}${R}"
            fi
            [ "${P_SEL[$i]}" -eq 1 ] && mark="x" || mark=" "
            note=""
            is_installed "$i" && note="${DIM}(installed)${R}"
            printf '  %2d) [%s] %-22s %-42s %s\n' \
                "$((i + 1))" "$mark" "${P_NAME[$i]}" "${P_DESC[$i]}" "$note"
        done
        group=""

        printf '\n%s\n' "${DIM} numbers/ranges toggle (3 5-7) · a=all · n=none · ENTER=install · q=quit${R}"
        printf ' > '
        read -r reply || reply="q"

        case "$reply" in
            "")  return 0 ;;
            q|Q) return 1 ;;
            a|A) for i in "${!P_SEL[@]}"; do P_SEL[i]=1; done ;;
            n|N) for i in "${!P_SEL[@]}"; do P_SEL[i]=0; done ;;
            *)   toggle $reply ;;
        esac
    done
}

# toggle <token...> - flip the plugins named by numbers and NN-NN ranges.
toggle() {
    local token start end i
    for token in "$@"; do
        case "$token" in
            [0-9]*-[0-9]*) start="${token%%-*}"; end="${token##*-}" ;;
            [0-9]*)        start="$token"; end="$token" ;;
            *)             warn "ignoring '$token'"; continue ;;
        esac
        if [ "$start" -lt 1 ] || [ "$end" -gt "${#P_NAME[@]}" ] || [ "$start" -gt "$end" ]; then
            warn "ignoring '$token': out of range"
            continue
        fi
        for (( i = start - 1; i < end; i++ )); do
            [ "${P_SEL[$i]}" -eq 1 ] && P_SEL[i]=0 || P_SEL[i]=1
        done
    done
}

# add_requires - tick anything a selected plugin needs but the user left out.
add_requires() {
    local changed=1 i dep j
    while [ "$changed" -eq 1 ]; do
        changed=0
        for i in "${!P_NAME[@]}"; do
            [ "${P_SEL[$i]}" -eq 1 ] || continue
            for dep in ${P_REQ[$i]}; do
                j="$(index_of "$dep")" || { warn "${P_NAME[$i]} requires unknown plugin '$dep'"; continue; }
                [ "${P_SEL[$j]}" -eq 1 ] && continue
                is_installed "$j" && continue
                P_SEL[j]=1
                changed=1
                say "  ${GREEN}+${R} ${dep} ${DIM}(required by ${P_NAME[$i]})${R}"
            done
        done
    done
}

# ---------------------------------------------------------------------------
# Running
# ---------------------------------------------------------------------------

# run_plugin <index> - execute one plugin, isolated, output copied to the log.
run_plugin() {
    ( set -o pipefail
      set -e
      # Files a plugin ships with: the plugin's own path, minus the .sh. The
      # discovery glob is plugins/*/*.sh, so such a directory is never a plugin.
      PLUGIN_ASSETS="${P_FILE[$1]%.sh}"
      # shellcheck source=/dev/null
      . "${P_FILE[$1]}"
      plugin_install ) 2>&1 | tee -a "$LOG"
    return "${PIPESTATUS[0]}"
}

install_selected() {
    local i rc
    local -a ok=() skip=() fail=()

    step "Preparing the system"
    { sudo dnf update -y && sudo dnf install -y $BASE_PACKAGES; } 2>&1 | tee -a "$LOG" \
        || warn "preparation had problems, continuing anyway"

    for i in "${!P_NAME[@]}"; do
        [ "${P_SEL[$i]}" -eq 1 ] || continue

        if [ -z "${HATRICK_FORCE:-}" ] && is_installed "$i"; then
            say "${DIM}skipping ${P_NAME[$i]}: already installed${R}"
            skip+=("${P_NAME[$i]}")
            continue
        fi

        step "${P_DESC[$i]} (${P_NAME[$i]})"
        # Called plainly, never as an `if` condition: bash suppresses errexit for
        # the whole dynamic extent of a condition, subshells included, which would
        # let a plugin run on past its first failing command.
        run_plugin "$i"
        rc=$?
        if [ "$rc" -eq 0 ]; then
            say "${GREEN}✓ ${P_NAME[$i]}${R}"
            ok+=("${P_NAME[$i]}")
        else
            say "${RED}✗ ${P_NAME[$i]} failed${R}"
            fail+=("${P_NAME[$i]}")
        fi
    done

    printf '\n%s\n' "${B}────────── summary ──────────${R}"
    printf '  %sinstalled%s %s\n' "$GREEN" "$R" "${ok[*]-}"
    printf '  %sskipped%s   %s\n' "$DIM"   "$R" "${skip[*]-}"
    printf '  %sfailed%s    %s\n' "$RED"   "$R" "${fail[*]-}"
    printf '\n%slog: %s%s\n' "$DIM" "$LOG" "$R"

    [ "${#fail[@]}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_list() {
    discover
    local i group=""
    for i in "${!P_NAME[@]}"; do
        if [ "${P_GROUP[$i]}" != "$group" ]; then
            group="${P_GROUP[$i]}"
            printf '\n%s\n' "${B}${group}${R}"
        fi
        printf '  %-22s %-42s %s%s%s\n' "${P_NAME[$i]}" "${P_DESC[$i]}" "$DIM" \
            "$( is_installed "$i" && printf 'installed '; \
                [ -n "${P_REQ[$i]}" ] && printf 'needs:%s' "${P_REQ[$i]// /,}" )" "$R"
    done
    printf '\n'
}

cmd_help() {
    cat <<EOF
Hatrick ${VERSION} - an opinionated stack for a vanilla Fedora.

  hatrick [install]   pick plugins from a menu, then install them
  hatrick list        show every plugin and exit
  hatrick help        this text

  HATRICK_FORCE=1     reinstall even when a plugin reports itself installed
  NO_COLOR=1          plain output

Plugins live in plugins/<group>/<name>.sh - drop a file in and it shows up.
EOF
}

cmd_install() {
    [ "$(id -u)" -eq 0 ] && die "do not run Hatrick as root. Run it as your normal
user; it calls sudo itself, so group membership, GNOME settings, flatpaks and
\$HOME end up on your account instead of root's."

    [ -r /etc/os-release ] && [ "$(. /etc/os-release && echo "$ID")" != "fedora" ] &&
        warn "this does not look like Fedora; continuing anyway"

    banner
    discover

    menu || { say "Nothing was changed."; return 0; }
    add_requires

    local i count=0
    for i in "${!P_SEL[@]}"; do [ "${P_SEL[$i]}" -eq 1 ] && count=$((count + 1)); done
    [ "$count" -eq 0 ] && { say "Nothing selected."; return 0; }

    # On EOF `read` leaves the variable untouched, so always reset it first:
    # a stale "y" from an earlier prompt must never be read as an answer here.
    printf '\n%s' "Install ${B}${count}${R} plugin(s)? [Y/n] "
    local reply=n; read -r reply || reply=n
    case "$reply" in [Nn]*) say "Nothing was changed."; return 0 ;; esac

    say "Asking for sudo once, up front."
    sudo -v || die "sudo is required"
    ( while sudo -n true 2>/dev/null; do sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
    local keepalive=$!

    install_selected
    local rc=$?
    kill "$keepalive" 2>/dev/null

    printf '\n%s' "Reboot now? [y/N] "
    reply=n; read -r reply || reply=n
    case "$reply" in [Yy]*) sudo systemctl reboot ;; esac
    return $rc
}

# ---------------------------------------------------------------------------

HATRICK_TMP="$(mktemp -d -t hatrick-XXXXXX)"
export HATRICK_TMP
trap 'rm -rf "$HATRICK_TMP"' EXIT

mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/hatrick"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hatrick/hatrick-$(date +%Y%m%d-%H%M%S).log"

case "${1:-install}" in
    install|"")     cmd_install ;;
    list|ls)        cmd_list ;;
    help|-h|--help) cmd_help ;;
    version|--version) say "hatrick $VERSION" ;;
    *)              cmd_help >&2; die "unknown command '$1'" ;;
esac
