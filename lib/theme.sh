# lib/theme.sh - the theme engine.
#
# A theme is a plugin that only *declares* what it wants and then calls
# theme_detect / theme_apply. Everything below is what turns those declarations
# into a desktop. See "Writing a theme" in README.md for the contract.
#
# No sudo anywhere in here except inside font_install: fonts are system-wide,
# but wallpapers and gsettings belong to your account.

# ---------------------------------------------------------------------------
# Small guarded helpers. Every one of them is a no-op when the thing it touches
# is not present, so a theme can mention a GNOME 47 key or a Dash to Dock
# setting without failing on a machine that has neither.
# ---------------------------------------------------------------------------

_theme_has_schema() { gsettings list-schemas 2>/dev/null | grep -qx "$1"; }
_theme_has_key()    { gsettings list-keys "$1" 2>/dev/null | grep -qx "$2"; }

# _theme_set <schema> <key> <value>
_theme_set() {
    _theme_has_schema "$1" || { echo "  skip ${1} ${2}: schema not installed"; return 0; }
    _theme_has_key "$1" "$2" || { echo "  skip ${1} ${2}: key not in this GNOME"; return 0; }
    gsettings set "$1" "$2" "$3"
    echo "  ${2} = ${3}"
}

# _theme_get <schema> <key> - the raw gsettings value, quotes and all.
_theme_get() { gsettings get "$1" "$2" 2>/dev/null; }

# _theme_is <schema> <key> <value> - true when the key already holds value.
_theme_is() { [ "$(_theme_get "$1" "$2")" = "'$3'" ]; }

# _theme_file_uri <path> - file:// URI with the characters that would otherwise
# break URI parsing escaped. Home directories with spaces in them are rare, but
# a wallpaper that silently does not apply is worse than four lines of sed.
_theme_file_uri() {
    local p="$1"
    p="${p//%/%25}"
    p="${p// /%20}"
    p="${p//\#/%23}"
    p="${p//\?/%3F}"
    printf 'file://%s' "$p"
}

# _theme_wallpaper_path - where the theme's image is copied to. Outside the
# Hatrick checkout on purpose: gsettings keeps this path forever, and the
# checkout may be moved or thrown away once the machine is set up.
_theme_wallpaper_path() {
    printf '%s/backgrounds/hatrick/%s' \
        "${XDG_DATA_HOME:-$HOME/.local/share}" "${THEME_NAME}.${THEME_BACKGROUND##*.}"
}

# ---------------------------------------------------------------------------
# Detection
# ---------------------------------------------------------------------------

# theme_detect - true when this theme is already the one in effect. Cheap and
# sudo-free: the menu re-runs it on every redraw.
theme_detect() {
    command -v gsettings >/dev/null 2>&1 || return 1

    [ -z "${THEME_FONT_INTERFACE:-}" ] ||
        _theme_is org.gnome.desktop.interface font-name "$THEME_FONT_INTERFACE" || return 1
    [ -z "${THEME_FONT_DOCUMENT:-}" ] ||
        _theme_is org.gnome.desktop.interface document-font-name "$THEME_FONT_DOCUMENT" || return 1
    [ -z "${THEME_FONT_MONOSPACE:-}" ] ||
        _theme_is org.gnome.desktop.interface monospace-font-name "$THEME_FONT_MONOSPACE" || return 1
    [ -z "${THEME_COLOR_SCHEME:-}" ] ||
        _theme_is org.gnome.desktop.interface color-scheme "$THEME_COLOR_SCHEME" || return 1

    if [ -n "${THEME_BACKGROUND:-}" ]; then
        _theme_is org.gnome.desktop.background picture-uri \
            "$(_theme_file_uri "$(_theme_wallpaper_path)")" || return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# The steps
# ---------------------------------------------------------------------------

theme_fonts() {
    local key
    for key in ${THEME_FONTS:-}; do
        font_install "$key"
    done
}

theme_wallpaper() {
    [ -n "${THEME_BACKGROUND:-}" ] || return 0

    local src="${PLUGIN_ASSETS}/${THEME_BACKGROUND}"
    if [ ! -f "$src" ]; then
        echo "  skip wallpaper: ${src} is missing"
        return 0
    fi

    local dest uri
    dest="$(_theme_wallpaper_path)"
    mkdir -p "${dest%/*}"
    install -m 0644 "$src" "$dest"
    uri="$(_theme_file_uri "$dest")"
    echo "  wallpaper -> ${dest}"

    _theme_set org.gnome.desktop.background picture-uri      "$uri"
    _theme_set org.gnome.desktop.background picture-uri-dark "$uri"
    _theme_set org.gnome.desktop.background picture-options  "${THEME_BACKGROUND_STYLE:-zoom}"
    _theme_set org.gnome.desktop.screensaver picture-uri     "$uri"
    _theme_set org.gnome.desktop.screensaver picture-options "${THEME_BACKGROUND_STYLE:-zoom}"
    return 0
}

theme_gnome_fonts() {
    [ -n "${THEME_FONT_INTERFACE:-}" ] &&
        _theme_set org.gnome.desktop.interface font-name           "$THEME_FONT_INTERFACE"
    [ -n "${THEME_FONT_DOCUMENT:-}" ] &&
        _theme_set org.gnome.desktop.interface document-font-name  "$THEME_FONT_DOCUMENT"
    [ -n "${THEME_FONT_MONOSPACE:-}" ] &&
        _theme_set org.gnome.desktop.interface monospace-font-name "$THEME_FONT_MONOSPACE"
    return 0
}

theme_appearance() {
    [ -n "${THEME_COLOR_SCHEME:-}" ] &&
        _theme_set org.gnome.desktop.interface color-scheme  "$THEME_COLOR_SCHEME"
    # Legacy GTK3 applications follow gtk-theme rather than color-scheme.
    [ -n "${THEME_GTK_THEME:-}" ] &&
        _theme_set org.gnome.desktop.interface gtk-theme     "$THEME_GTK_THEME"
    [ -n "${THEME_ICON_THEME:-}" ] &&
        _theme_set org.gnome.desktop.interface icon-theme    "$THEME_ICON_THEME"
    return 0
}

theme_extensions() {
    command -v gnome-extensions >/dev/null 2>&1 || {
        [ -n "${THEME_EXTENSIONS_OFF[*]:-}${THEME_EXTENSIONS_ON[*]:-}" ] &&
            echo "  skip extensions: gnome-extensions is not installed"
        return 0
    }

    local uuid
    for uuid in ${THEME_EXTENSIONS_OFF[@]+"${THEME_EXTENSIONS_OFF[@]}"}; do
        if gnome-extensions list 2>/dev/null | grep -qx "$uuid"; then
            gnome-extensions disable "$uuid" && echo "  disabled ${uuid}"
        else
            echo "  skip ${uuid}: not installed"
        fi
    done
    for uuid in ${THEME_EXTENSIONS_ON[@]+"${THEME_EXTENSIONS_ON[@]}"}; do
        if gnome-extensions list 2>/dev/null | grep -qx "$uuid"; then
            gnome-extensions enable "$uuid" && echo "  enabled ${uuid}"
        else
            echo "  skip ${uuid}: not installed"
        fi
    done
    return 0
}

# Everything a theme wants that does not have a dedicated variable yet. One
# "schema key value" per entry; the value may contain spaces.
theme_extras() {
    local line schema key value
    for line in ${THEME_GSETTINGS[@]+"${THEME_GSETTINGS[@]}"}; do
        read -r schema key value <<<"$line"
        [ -n "$schema" ] && [ -n "$key" ] || continue
        _theme_set "$schema" "$key" "$value"
    done
    return 0
}

# ---------------------------------------------------------------------------

# theme_apply - the whole theme, in order.
theme_apply() {
    theme_fonts
    theme_wallpaper
    theme_gnome_fonts
    theme_appearance
    theme_extensions
    theme_extras
}
