PLUGIN_DESC="Mona Sans font (static + variable)"

VERSION="2.0.27"   # bump this line to move to a newer release

plugin_detect() { fc-list | grep -qi "Mona Sans"; }

plugin_install() {
    curl -fsSL -o "$HATRICK_TMP/mona-sans.zip" \
        "https://github.com/github/mona-sans/releases/download/v${VERSION}/mona-sans-complete-v${VERSION}.zip"
    unzip -qo "$HATRICK_TMP/mona-sans.zip" -d "$HATRICK_TMP/mona-sans"

    sudo mkdir -p /usr/share/fonts/mona-sans
    sudo cp "$HATRICK_TMP"/mona-sans/fonts/static/ttf/*.ttf /usr/share/fonts/mona-sans/
    sudo cp "$HATRICK_TMP"/mona-sans/fonts/variable/*.ttf /usr/share/fonts/mona-sans/
    sudo fc-cache -f /usr/share/fonts/mona-sans
}
