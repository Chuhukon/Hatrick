# shellcheck shell=bash
#
# Hatrick — system helpers.
#
# This is the vocabulary plugins are written against. Plugins should never call
# dnf, rpm, curl, usermod or systemctl directly: go through these helpers so the
# privilege handling, retries and logging stay in one place.

# ---------------------------------------------------------------------------
# Privileges
# ---------------------------------------------------------------------------

# HATRICK_USER / HATRICK_HOME are the *invoking* user, even if we later escalate.
HATRICK_USER="${HATRICK_USER:-${SUDO_USER:-$(id -un)}}"
HATRICK_HOME="${HATRICK_HOME:-$(getent passwd "$HATRICK_USER" | cut -d: -f6)}"

# as_root <cmd...> — run a command with root privileges.
as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo -- "$@"
    fi
}

# as_user <cmd...> — run a command as the invoking (non-root) user.
as_user() {
    if [ "$(id -un)" = "$HATRICK_USER" ]; then
        "$@"
    else
        as_root runuser -u "$HATRICK_USER" -- "$@"
    fi
}

# sudo_prime — ask for the password once, then keep the timestamp warm so the
# rest of the run does not stop halfway to prompt again.
sudo_prime() {
    [ "$(id -u)" -eq 0 ] && return 0
    # Idempotent: a second call must not leave a second keepalive running.
    [ -n "${HATRICK_SUDO_KEEPALIVE:-}" ] && return 0
    log_info "Hatrick needs sudo for system-wide changes."
    sudo -v || return 1
    ( while true; do sudo -n true 2>/dev/null; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
    HATRICK_SUDO_KEEPALIVE=$!
    return 0
}

sudo_release() {
    [ -n "${HATRICK_SUDO_KEEPALIVE:-}" ] && kill "$HATRICK_SUDO_KEEPALIVE" 2>/dev/null
    return 0
}

# ---------------------------------------------------------------------------
# Packages and repositories
# ---------------------------------------------------------------------------

pkg_install() {
    log_debug "dnf install $*"
    as_root dnf install -y "$@"
}

# pkg_remove — never fails the plugin when a package simply is not installed.
pkg_remove() {
    log_debug "dnf remove $*"
    as_root dnf remove -y "$@" 2>/dev/null || true
}

pkg_installed() { rpm -q "$1" >/dev/null 2>&1; }

pkg_update() { as_root dnf update -y; }

pkg_autoremove() { as_root dnf autoremove -y || true; }

# add_repofile <url> — register a vendor-provided .repo file.
add_repofile() {
    local url=$1
    log_debug "adding repo from $url"
    if dnf --version 2>/dev/null | grep -q '^dnf5'; then
        as_root dnf config-manager addrepo --overwrite --from-repofile="$url"
    else
        as_root dnf config-manager --add-repo "$url"
    fi
}

# write_repofile <name> <content> — for vendors that publish no .repo file.
write_repofile() {
    local name=$1 content=$2
    printf '%s\n' "$content" | as_root tee "/etc/yum.repos.d/${name}.repo" >/dev/null
}

# add_repo_rpm <url> — install a release/config RPM that carries its own repo.
add_repo_rpm() { as_root dnf install -y "$1"; }

import_rpm_key() { as_root rpm --import "$1"; }

# ---------------------------------------------------------------------------
# Downloads
# ---------------------------------------------------------------------------

# HATRICK_TMP is created by the entrypoint and removed by a single trap, so no
# plugin has to clean up after itself.
: "${HATRICK_TMP:=${TMPDIR:-/tmp}}"

# fetch <url> <destination>
fetch() {
    local url=$1 dest=$2
    log_debug "fetching $url"
    curl -fsSL --retry 3 --retry-delay 2 -o "$dest" "$url"
}

# ---------------------------------------------------------------------------
# Users, groups, services
# ---------------------------------------------------------------------------

# add_user_to_group <group> — creates the group if needed, adds the invoking user.
add_user_to_group() {
    local group=$1
    getent group "$group" >/dev/null 2>&1 || as_root groupadd "$group"
    as_root usermod -aG "$group" "$HATRICK_USER"
    plugin_note "Log out and back in for '$group' group membership to take effect."
}

enable_service() { as_root systemctl enable --now "$1"; }

# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------

# install_fonts_from_zip <url> <target-dir> <glob> [<glob>...]
# Downloads a font archive and copies every file matching the globs (relative to
# the archive root) into a system font directory, then refreshes the font cache.
install_fonts_from_zip() {
    local url=$1 target=$2
    shift 2
    local work="$HATRICK_TMP/fonts-$$-${RANDOM}"
    mkdir -p "$work"
    fetch "$url" "$work/fonts.zip"
    unzip -q -o "$work/fonts.zip" -d "$work/extracted"

    as_root mkdir -p "$target"
    local glob file found=0
    for glob in "$@"; do
        # shellcheck disable=SC2086 # globs are intentionally expanded here
        for file in $work/extracted/$glob; do
            [ -f "$file" ] || continue
            as_root cp "$file" "$target/"
            found=1
        done
    done
    [ "$found" -eq 1 ] || { log_error "no fonts matched in $url"; return 1; }
    as_root fc-cache -f "$target" >/dev/null
}

# ---------------------------------------------------------------------------
# Flatpak
# ---------------------------------------------------------------------------

# ensure_flathub — a vanilla Fedora has flatpak but not always the flathub
# remote, which is why plain `flatpak install flathub ...` fails on a fresh box.
ensure_flathub() {
    command -v flatpak >/dev/null 2>&1 || pkg_install flatpak
    as_user flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# flatpak_install <app-id...> — installs into the user's flatpak scope.
flatpak_install() {
    ensure_flathub
    as_user flatpak install --user -y flathub "$@"
}

# ---------------------------------------------------------------------------
# GNOME
# ---------------------------------------------------------------------------

# gsettings_set <schema> <key> <value> — always applied to the user's session,
# never root's, which is what the original script got wrong.
gsettings_set() {
    if ! command -v gsettings >/dev/null 2>&1; then
        log_warn "gsettings not available, skipping $1 $2"
        return 0
    fi
    as_user gsettings set "$1" "$2" "$3"
}

# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

# is_gnome — true when a GNOME session is what the user actually runs.
is_gnome() {
    case "${XDG_CURRENT_DESKTOP:-}" in *GNOME*) return 0 ;; esac
    have gnome-shell
}
