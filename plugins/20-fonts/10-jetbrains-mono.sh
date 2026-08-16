PLUGIN_DESC="JetBrains Mono font"

VERSION="2.304"   # bump this line to move to a newer release

plugin_detect() { fc-list | grep -qi "JetBrains Mono"; }

plugin_install() {
    curl -fsSL -o "$HATRICK_TMP/jetbrains-mono.zip" \
        "https://github.com/JetBrains/JetBrainsMono/releases/download/v${VERSION}/JetBrainsMono-${VERSION}.zip"
    unzip -qo "$HATRICK_TMP/jetbrains-mono.zip" -d "$HATRICK_TMP/jetbrains-mono"

    sudo mkdir -p /usr/share/fonts/jetbrains-mono
    sudo cp "$HATRICK_TMP"/jetbrains-mono/fonts/ttf/*.ttf /usr/share/fonts/jetbrains-mono/
    sudo fc-cache -f /usr/share/fonts/jetbrains-mono
}
