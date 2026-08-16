# shellcheck shell=bash
#
# Hatrick — plugin discovery, metadata, dependency resolution and execution.
#
# A plugin is a bash file under plugins/<NN-group>/<name>.sh that sets PLUGIN_*
# metadata variables and defines plugin_install (plus optional plugin_detect and
# plugin_postinstall). Nothing registers a plugin: dropping the file in is enough.
#
# Metadata is read, and plugins are executed, in subshells, so PLUGIN_* variables
# and functions from one plugin can never leak into the next. Hatrick's own
# tables use an HP_ prefix so the entire PLUGIN_* namespace belongs to authors.

declare -A HP_FILE=()       # name -> file path
declare -A HP_GROUP=()      # name -> display group
declare -A HP_DESC=()       # name -> one-line description
declare -A HP_DEFAULT=()    # name -> on|off
declare -A HP_REQ=()        # name -> space-separated dependency names
declare -A HP_MANDATORY=()  # name -> yes|no
declare -a HP_ORDER=()      # discovery order (group dir, then file name)
declare -a HP_GROUPS=()     # unique groups, in group-directory order

# plugin_note <text> — queue a message for the end-of-run summary. Safe to call
# from inside a plugin subshell; the note file is shared with the parent.
plugin_note() {
    [ -n "${HATRICK_NOTES:-}" ] || return 0
    printf '%s\n' "$*" >>"$HATRICK_NOTES"
}

# Field separator for metadata transfer. Deliberately not a tab: bash treats
# tabs as IFS whitespace, which collapses empty fields (an empty PLUGIN_REQUIRES
# would shift every later field one place to the left).
HP_FS=$'\x1f'

# _hp_read_meta <file> — echo the metadata as HP_FS-separated fields, or fail.
_hp_read_meta() {
    (
        unset PLUGIN_NAME PLUGIN_DESC PLUGIN_GROUP PLUGIN_DEFAULT \
              PLUGIN_REQUIRES PLUGIN_VERSION PLUGIN_MANDATORY
        # shellcheck source=/dev/null
        . "$1" || exit 1
        [ -n "${PLUGIN_NAME:-}" ] && [ -n "${PLUGIN_DESC:-}" ] || exit 2
        printf "%s${HP_FS}%s${HP_FS}%s${HP_FS}%s${HP_FS}%s${HP_FS}%s\n" \
            "$PLUGIN_NAME" \
            "${PLUGIN_GROUP:-Other}" \
            "$PLUGIN_DESC" \
            "${PLUGIN_DEFAULT:-on}" \
            "${PLUGIN_REQUIRES:-}" \
            "${PLUGIN_MANDATORY:-no}"
    )
}

# plugins_discover — populate the tables from $HATRICK_ROOT/plugins.
plugins_discover() {
    local root="$HATRICK_ROOT/plugins"
    [ -d "$root" ] || { log_error "no plugins directory at $root"; return 1; }

    local dir file meta name group desc default reqs mandatory g seen
    # Group directories are numerically prefixed, so their order on disk is the
    # order in which the user is asked about them.
    for dir in "$root"/*/; do
        [ -d "$dir" ] || continue
        for file in "$dir"*.sh; do
            [ -f "$file" ] || continue
            if ! meta=$(_hp_read_meta "$file"); then
                log_warn "skipping invalid plugin ${file#"$HATRICK_ROOT"/} (missing PLUGIN_NAME or PLUGIN_DESC)"
                continue
            fi
            IFS="$HP_FS" read -r name group desc default reqs mandatory <<<"$meta"

            if [ -n "${HP_FILE[$name]:-}" ]; then
                log_warn "duplicate plugin name '$name' in ${file#"$HATRICK_ROOT"/}, keeping ${HP_FILE[$name]#"$HATRICK_ROOT"/}"
                continue
            fi

            HP_FILE[$name]="$file"
            HP_GROUP[$name]="$group"
            HP_DESC[$name]="$desc"
            HP_DEFAULT[$name]="$default"
            HP_REQ[$name]="$reqs"
            HP_MANDATORY[$name]="$mandatory"
            HP_ORDER+=("$name")

            seen=0
            for g in ${HP_GROUPS[@]+"${HP_GROUPS[@]}"}; do
                [ "$g" = "$group" ] && { seen=1; break; }
            done
            [ "$seen" -eq 0 ] && HP_GROUPS+=("$group")
        done
    done

    [ "${#HP_ORDER[@]}" -gt 0 ] || { log_error "no valid plugins found in $root"; return 1; }
    plugins_validate
}

# plugins_validate — catch unknown dependencies and cycles before anything runs.
plugins_validate() {
    local name dep rc=0
    for name in "${HP_ORDER[@]}"; do
        for dep in ${HP_REQ[$name]}; do
            if [ -z "${HP_FILE[$dep]:-}" ]; then
                log_error "plugin '$name' requires unknown plugin '$dep'"
                rc=1
            fi
        done
    done
    [ "$rc" -eq 0 ] || return 1

    local -A _mark=()
    for name in "${HP_ORDER[@]}"; do
        _hp_visit "$name" _sink || return 1
    done
    return 0
}

# _hp_visit <name> <output-array-name> — DFS helper for the topological sort.
# Uses the caller's _mark associative array: unset = unvisited, 1 = in progress,
# 2 = done. Appends to the named array unless it is called "_sink".
_hp_visit() {
    local name=$1 out=$2 dep

    case "${_mark[$name]:-}" in
        2) return 0 ;;
        1) log_error "dependency cycle involving plugin '$name'"; return 1 ;;
    esac
    _mark[$name]=1
    for dep in ${HP_REQ[$name]}; do
        [ -n "${HP_FILE[$dep]:-}" ] || continue
        _hp_visit "$dep" "$out" || return 1
    done
    _mark[$name]=2
    if [ "$out" != "_sink" ]; then
        local -n _visit_out="$out"
        _visit_out+=("$name")
    fi
    return 0
}

# plugins_sort <output-array-name> <name...> — dependency order, with discovery
# order as the tie-break and dependencies always ahead of their dependents.
plugins_sort() {
    local out=$1
    shift
    local -A _wanted=() _mark=()
    local name
    for name in "$@"; do _wanted[$name]=1; done

    local -a _all=()
    # Walk in discovery order so the result is stable from run to run.
    for name in "${HP_ORDER[@]}"; do
        [ -n "${_wanted[$name]:-}" ] || continue
        _hp_visit "$name" _all || return 1
    done

    # _hp_visit pulls dependencies in transitively; keep only the wanted ones.
    local -n _sort_out="$out"
    _sort_out=()
    for name in ${_all[@]+"${_all[@]}"}; do
        [ -n "${_wanted[$name]:-}" ] && _sort_out+=("$name")
    done
    return 0
}

# plugins_missing_deps <output-array-name> <selected...> — transitive dependencies
# of the selection that are not themselves selected.
plugins_missing_deps() {
    local out=$1
    shift
    local -A _have=() _added=()
    local -a _queue=("$@")
    local name dep
    for name in "$@"; do _have[$name]=1; done

    local -n _miss_out="$out"
    _miss_out=()
    while [ "${#_queue[@]}" -gt 0 ]; do
        name="${_queue[0]}"
        _queue=("${_queue[@]:1}")
        for dep in ${HP_REQ[$name]}; do
            [ -n "${HP_FILE[$dep]:-}" ] || continue
            [ -n "${_have[$dep]:-}" ] && continue
            [ -n "${_added[$dep]:-}" ] && continue
            _added[$dep]=1
            _miss_out+=("$dep")
            _queue+=("$dep")
        done
    done
    return 0
}

# plugins_drop_unsatisfied <array-name> — remove every plugin whose dependencies
# are not in the selection, transitively. Used when the user declines to pull a
# dependency in: the dependent is dropped rather than failing mid-install.
plugins_drop_unsatisfied() {
    local -n _drop_sel="$1"
    local changed=1 name dep keep
    local -a kept

    while [ "$changed" -eq 1 ]; do
        changed=0
        kept=()
        local -A _have=()
        for name in ${_drop_sel[@]+"${_drop_sel[@]}"}; do _have[$name]=1; done
        for name in ${_drop_sel[@]+"${_drop_sel[@]}"}; do
            keep=1
            for dep in ${HP_REQ[$name]}; do
                [ -n "${HP_FILE[$dep]:-}" ] || continue
                [ -n "${_have[$dep]:-}" ] || { keep=0; break; }
            done
            if [ "$keep" -eq 1 ]; then
                kept+=("$name")
            else
                log_warn "skipping '$name': dependency '$dep' was not selected"
                changed=1
            fi
        done
        _drop_sel=(${kept[@]+"${kept[@]}"})
    done
    return 0
}

# plugin_is_installed <name> — run the plugin's own detection, if it has one.
plugin_is_installed() {
    local name=$1
    (
        # shellcheck source=/dev/null
        . "${HP_FILE[$name]}" >/dev/null 2>&1
        declare -F plugin_detect >/dev/null || exit 1
        plugin_detect >/dev/null 2>&1
    )
}

# plugin_run <name> — execute one plugin in an isolated subshell, tee'ing all of
# its output into the run log. A failure is reported but never aborts the run.
plugin_run() {
    local name=$1 rc=0

    log_step "${HP_DESC[$name]} (${name})"
    if [ -n "${HATRICK_LOG:-}" ]; then
        (
            set -o pipefail
            set -e
            # shellcheck source=/dev/null
            . "${HP_FILE[$name]}"
            plugin_install
        ) 2>&1 | tee -a "$HATRICK_LOG"
        rc=${PIPESTATUS[0]}
    else
        (
            set -e
            # shellcheck source=/dev/null
            . "${HP_FILE[$name]}"
            plugin_install
        )
        rc=$?
    fi
    return "$rc"
}

# plugin_run_post <name> — optional plugin_postinstall hook, run after every
# selected plugin has been installed.
plugin_run_post() {
    local name=$1
    (
        set -e
        # shellcheck source=/dev/null
        . "${HP_FILE[$name]}"
        declare -F plugin_postinstall >/dev/null || exit 0
        plugin_postinstall
    ) >>"${HATRICK_LOG:-/dev/null}" 2>&1
}
