# lib/gnome.sh - GNOME Shell extension helpers.
#
# Guarded like lib/theme.sh: nothing in here is fatal and everything returns 0,
# so a plugin running under `set -e` cannot be cut short by a GNOME that is not
# there, not running, or not the one we expected.

# gnome_extension_enable <uuid> [<uuid>...]
#
# `gnome-extensions enable` only reaches extensions the *running* shell has
# already loaded, so it fails for anything installed in this same run - which
# is exactly when a plugin wants to call it. Writing the UUID into
# enabled-extensions works either way: a shell that knows the extension picks
# it up at once, any other one at the next login.
gnome_extension_enable() {
    local uuid list new
    gsettings list-schemas 2>/dev/null | grep -qx org.gnome.shell || return 0

    for uuid in "$@"; do
        gnome-extensions list 2>/dev/null | grep -qx "$uuid" || {
            echo "  skip ${uuid}: not installed"
            continue
        }

        list=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null) || continue
        case "$list" in
            *"'${uuid}'"*) echo "  ${uuid} already enabled"; continue ;;
            "@as []"|"[]") new="['${uuid}']" ;;   # both spellings of the empty array
            *)             new="${list%]}, '${uuid}']" ;;
        esac

        if gsettings set org.gnome.shell enabled-extensions "$new" 2>/dev/null; then
            echo "  enabled ${uuid}"
        else
            echo "  ! could not enable ${uuid}"
        fi

        # A shell that does already know it can take effect without a re-login.
        gnome-extensions enable "$uuid" 2>/dev/null || true
    done

    # An extension list means nothing while user extensions are switched off.
    gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true
    return 0
}
