# shellcheck shell=bash
# Hatrick plugin — Mona Sans, the UI face used across the stack.

PLUGIN_NAME="mona-sans"
PLUGIN_DESC="Mona Sans font (static + variable)"
PLUGIN_GROUP="Fonts"
PLUGIN_DEFAULT=on

# Bump this one line to move to a newer release.
PLUGIN_VERSION="2.0.27"

MONA_SANS_URL="https://github.com/github/mona-sans/releases/download/v${PLUGIN_VERSION}/mona-sans-complete-v${PLUGIN_VERSION}.zip"
MONA_SANS_DIR="/usr/share/fonts/mona-sans"

plugin_detect() {
    fc-list 2>/dev/null | grep -qi "Mona Sans"
}

plugin_install() {
    install_fonts_from_zip "$MONA_SANS_URL" "$MONA_SANS_DIR" \
        "fonts/static/ttf/*.ttf" \
        "fonts/variable/*.ttf"
}
