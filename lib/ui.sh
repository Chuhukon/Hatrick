# shellcheck shell=bash
#
# Hatrick — interactive selection UI (whiptail).
#
# One checklist per plugin group, in group-directory order. Everything the user
# ticks gets installed; everything else is left alone. Mandatory plugins are not
# offered, they always run.

HATRICK_UI_TITLE="Hatrick"

# ui_ensure — whiptail lives in the 'newt' package and is not on a stock Fedora
# Workstation, so install it before we need to ask the user anything.
ui_ensure() {
    have whiptail && return 0
    log_info "Installing whiptail (newt) for the selection menu..."
    sudo_prime || { log_error "sudo is required to install 'newt'"; return 1; }
    pkg_install newt >/dev/null 2>&1 || {
        log_error "could not install 'newt'; whiptail is required for the menu"
        return 1
    }
    have whiptail
}

# _ui_size — pick dialog dimensions that fit the current terminal.
_ui_size() {
    local rows cols
    rows=$(tput lines 2>/dev/null || echo 24)
    cols=$(tput cols 2>/dev/null || echo 80)
    UI_HEIGHT=$(( rows - 4 )); [ "$UI_HEIGHT" -lt 12 ] && UI_HEIGHT=12; [ "$UI_HEIGHT" -gt 30 ] && UI_HEIGHT=30
    UI_WIDTH=$(( cols - 6 ));  [ "$UI_WIDTH" -lt 60 ] && UI_WIDTH=60;  [ "$UI_WIDTH" -gt 100 ] && UI_WIDTH=100
    UI_LIST=$(( UI_HEIGHT - 8 )); [ "$UI_LIST" -lt 4 ] && UI_LIST=4
}

# ui_intro — explain the flow before the first checklist appears.
ui_intro() {
    _ui_size
    whiptail --title "$HATRICK_UI_TITLE" --yesno \
        "Hatrick installs an opinionated developer stack on this Fedora system.

You will be shown one checklist per category. Use SPACE to tick or untick an entry, TAB to reach the buttons, and ENTER to confirm.

Nothing is installed until you confirm the final summary.

Continue?" 18 "$UI_WIDTH" 3>&1 1>&2 2>&3
}

# ui_select_group <output-array-name> <group> <name...>
# Show one checklist and append the ticked plugin names to the output array.
ui_select_group() {
    local out=$1 group=$2
    shift 2
    local -n _grp_out="$out"

    local -a entries=()
    local name status marker
    for name in "$@"; do
        status="${HP_DEFAULT[$name]}"
        marker=""
        if plugin_is_installed "$name"; then
            marker="  [already installed]"
        fi
        entries+=("$name" "${HP_DESC[$name]}${marker}" "$status")
    done

    _ui_size
    local list=$UI_LIST
    [ "$#" -lt "$list" ] && list=$#
    [ "$list" -lt 1 ] && list=1

    local chosen
    chosen=$(whiptail --title "$HATRICK_UI_TITLE — $group" \
        --separate-output --checklist \
        "Select what to install from '$group'. SPACE toggles, ENTER confirms." \
        "$UI_HEIGHT" "$UI_WIDTH" "$list" \
        "${entries[@]}" 3>&1 1>&2 2>&3) || return 1

    while IFS= read -r name; do
        [ -n "$name" ] && _grp_out+=("$name")
    done <<<"$chosen"
    return 0
}

# ui_select_plugins <output-array-name> — walk every group, collect the selection.
# Returns non-zero when the user cancels.
ui_select_plugins() {
    local out=$1
    local -n _sel_out="$out"
    _sel_out=()

    local group name
    local -a members
    for group in "${HP_GROUPS[@]}"; do
        members=()
        for name in "${HP_ORDER[@]}"; do
            [ "${HP_GROUP[$name]}" = "$group" ] || continue
            # Mandatory plugins are not up for discussion.
            if [ "${HP_MANDATORY[$name]}" = "yes" ]; then
                _sel_out+=("$name")
                continue
            fi
            members+=("$name")
        done
        [ "${#members[@]}" -gt 0 ] || continue
        ui_select_group "$out" "$group" "${members[@]}" || return 1
    done
    return 0
}

# ui_resolve_deps <array-name> — offer to pull in missing dependencies; drop the
# dependent plugins when the user says no.
ui_resolve_deps() {
    local -n _dep_sel="$1"
    local -a missing=()
    plugins_missing_deps missing ${_dep_sel[@]+"${_dep_sel[@]}"}
    [ "${#missing[@]}" -gt 0 ] || return 0

    local name text=""
    for name in "${missing[@]}"; do
        text+="  • ${name} — ${HP_DESC[$name]}"$'\n'
    done

    _ui_size
    if whiptail --title "$HATRICK_UI_TITLE — dependencies" --yesno \
        "Some of your selections depend on plugins you did not tick:

${text}
Install these as well?

Choosing No will skip the plugins that need them." \
        "$UI_HEIGHT" "$UI_WIDTH" 3>&1 1>&2 2>&3
    then
        _dep_sel+=("${missing[@]}")
    else
        plugins_drop_unsatisfied "$1"
    fi
    return 0
}

# ui_confirm_plan <name...> — final summary, the last chance to back out.
ui_confirm_plan() {
    local name text=""
    for name in "$@"; do
        text+="  • ${HP_DESC[$name]}"$'\n'
    done

    _ui_size
    whiptail --title "$HATRICK_UI_TITLE — ready" --scrolltext --defaultno --yesno \
        "Hatrick will install $# plugin(s):

${text}
Start the installation?" \
        "$UI_HEIGHT" "$UI_WIDTH" 3>&1 1>&2 2>&3
}

# ui_reboot_prompt — plain read, not whiptail: by this point the user wants to
# see the summary that was just printed, not another dialog covering it.
ui_reboot_prompt() {
    local reply
    printf '\n%s' "${HATRICK_C_BOLD}Reboot now? [y/N] ${HATRICK_C_RESET}"
    read -r reply
    case "$reply" in
        [Yy]*) log_info "Rebooting..."; as_root systemctl reboot ;;
        *)     log_info "Not rebooting. Remember to reboot before using VirtualBox or Docker." ;;
    esac
}
