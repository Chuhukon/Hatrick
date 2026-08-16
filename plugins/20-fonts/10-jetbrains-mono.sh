# shellcheck shell=bash
# Hatrick plugin — JetBrains Mono, the monospace face used across the stack.

PLUGIN_NAME="jetbrains-mono"
PLUGIN_DESC="JetBrains Mono font"
PLUGIN_GROUP="Fonts"
PLUGIN_DEFAULT=on

# Bump this one line to move to a newer release.
PLUGIN_VERSION="2.304"

JETBRAINS_MONO_URL="https://github.com/JetBrains/JetBrainsMono/releases/download/v${PLUGIN_VERSION}/JetBrainsMono-${PLUGIN_VERSION}.zip"
JETBRAINS_MONO_DIR="/usr/share/fonts/jetbrains-mono"

plugin_detect() {
    fc-list 2>/dev/null | grep -qi "JetBrains Mono"
}

plugin_install() {
    install_fonts_from_zip "$JETBRAINS_MONO_URL" "$JETBRAINS_MONO_DIR" "fonts/ttf/*.ttf"
}
