# shellcheck shell=bash
#
# Hatrick — logging and terminal output.
#
# Every message goes to the terminal and, once hatrick_log_open has run, to the
# run log file as well. Plugin output is tee'd into the same file by run_plugin.

HATRICK_C_RESET=$'\e[0m'
HATRICK_C_CYAN=$'\e[36m'
HATRICK_C_GREEN=$'\e[32m'
HATRICK_C_YELLOW=$'\e[33m'
HATRICK_C_RED=$'\e[31m'
HATRICK_C_DIM=$'\e[2m'
HATRICK_C_BOLD=$'\e[1m'

if [ ! -t 1 ] || [ -n "${NO_COLOR:-}" ]; then
    HATRICK_C_RESET="" HATRICK_C_CYAN="" HATRICK_C_GREEN="" HATRICK_C_YELLOW=""
    HATRICK_C_RED="" HATRICK_C_DIM="" HATRICK_C_BOLD=""
fi

HATRICK_LOG="${HATRICK_LOG:-}"

# hatrick_log_open — create the run log under $XDG_STATE_HOME/hatrick.
hatrick_log_open() {
    local dir="${XDG_STATE_HOME:-$HOME/.local/state}/hatrick"
    mkdir -p "$dir" 2>/dev/null || return 0
    HATRICK_LOG="$dir/hatrick-$(date +%Y%m%d-%H%M%S).log"
    : >"$HATRICK_LOG"
    printf 'Hatrick run started %s on %s\n' "$(date -Is)" "$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")" >>"$HATRICK_LOG"
}

# _log_file <text> — append a decoration-free copy to the log file.
_log_file() {
    [ -n "$HATRICK_LOG" ] || return 0
    printf '%s %s\n' "$(date +%H:%M:%S)" "$1" >>"$HATRICK_LOG"
}

log_info()  { printf '%s\n' "${HATRICK_C_CYAN}$*${HATRICK_C_RESET}";              _log_file "$*"; }
log_ok()    { printf '%s\n' "${HATRICK_C_GREEN}$*${HATRICK_C_RESET}";             _log_file "$*"; }
log_warn()  { printf '%s\n' "${HATRICK_C_YELLOW}warning: $*${HATRICK_C_RESET}" >&2; _log_file "warning: $*"; }
log_error() { printf '%s\n' "${HATRICK_C_RED}error: $*${HATRICK_C_RESET}" >&2;    _log_file "error: $*"; }
log_debug() { [ -n "${HATRICK_DEBUG:-}" ] && printf '%s\n' "${HATRICK_C_DIM}$*${HATRICK_C_RESET}"; _log_file "debug: $*"; }

# log_step <text> — headline for a unit of work.
log_step() {
    printf '\n%s\n' "${HATRICK_C_BOLD}${HATRICK_C_CYAN}==> $*${HATRICK_C_RESET}"
    _log_file "==> $*"
}

# log_banner — the Hatrick wordmark, printed once at startup.
log_banner() {
    printf '%s' "$HATRICK_C_CYAN"
    cat <<'BANNER'
 ██╗  ██╗ █████╗ ████████╗██████╗ ██╗ ██████╗██╗  ██╗
 ██║  ██║██╔══██╗╚══██╔══╝██╔══██╗██║██╔════╝██║ ██╔╝
 ███████║███████║   ██║   ██████╔╝██║██║     █████╔╝
 ██╔══██║██╔══██║   ██║   ██╔══██╗██║██║     ██╔═██╗
 ██║  ██║██║  ██║   ██║   ██║  ██║██║╚██████╗██║  ██╗
 ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝
BANNER
    printf '%s\n\n' "${HATRICK_C_RESET}${HATRICK_C_DIM} an opinionated stack for a vanilla Fedora${HATRICK_C_RESET}"
}
