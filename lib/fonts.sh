# lib/fonts.sh - the fonts a theme can ask for.
#
# Sourced by hatrick before any plugin, so font_install/font_installed are
# available inside every plugin_install and plugin_detect.
#
# Adding a font is one arm in each case statement. Nothing else needs to know.

JETBRAINS_MONO_VERSION="2.304"   # bump this line to move to a newer release
MONA_SANS_VERSION="2.0.27"       # bump this line to move to a newer release

# font_installed <key> - true when fontconfig already knows the family.
# Must never need sudo: it runs during `hatrick list` too.
font_installed() {
    case "$1" in
        jetbrains-mono) fc-list | grep -qi "JetBrains Mono" ;;
        mona-sans)      fc-list | grep -qi "Mona Sans" ;;
        *)              return 1 ;;
    esac
}

# font_install <key> - download and install one font, system-wide. Idempotent:
# a font that fontconfig already has is left alone.
font_install() {
    local key="$1"

    if font_installed "$key"; then
        echo "  font ${key} already installed"
        return 0
    fi

    echo "  installing font ${key}"
    case "$key" in
        jetbrains-mono)
            curl -fsSL -o "$HATRICK_TMP/jetbrains-mono.zip" \
                "https://github.com/JetBrains/JetBrainsMono/releases/download/v${JETBRAINS_MONO_VERSION}/JetBrainsMono-${JETBRAINS_MONO_VERSION}.zip"
            unzip -qo "$HATRICK_TMP/jetbrains-mono.zip" -d "$HATRICK_TMP/jetbrains-mono"

            sudo mkdir -p /usr/share/fonts/jetbrains-mono
            sudo cp "$HATRICK_TMP"/jetbrains-mono/fonts/ttf/*.ttf /usr/share/fonts/jetbrains-mono/
            sudo fc-cache -f /usr/share/fonts/jetbrains-mono
            ;;
        mona-sans)
            curl -fsSL -o "$HATRICK_TMP/mona-sans.zip" \
                "https://github.com/github/mona-sans/releases/download/v${MONA_SANS_VERSION}/mona-sans-complete-v${MONA_SANS_VERSION}.zip"
            unzip -qo "$HATRICK_TMP/mona-sans.zip" -d "$HATRICK_TMP/mona-sans"

            sudo mkdir -p /usr/share/fonts/mona-sans
            sudo cp "$HATRICK_TMP"/mona-sans/fonts/static/ttf/*.ttf /usr/share/fonts/mona-sans/
            sudo cp "$HATRICK_TMP"/mona-sans/fonts/variable/*.ttf /usr/share/fonts/mona-sans/
            sudo fc-cache -f /usr/share/fonts/mona-sans
            ;;
        *)
            echo "unknown font '${key}'" >&2
            return 1
            ;;
    esac
}
