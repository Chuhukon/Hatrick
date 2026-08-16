PLUGIN_DESC="JetBrains Toolbox"

VERSION="3.6.4.86641"   # bump this line to move to a newer release

plugin_detect() { [ -x /opt/jetbrains-toolbox/bin/jetbrains-toolbox ]; }

plugin_install() {
    curl -fsSL -o "$HATRICK_TMP/toolbox.tar.gz" \
        "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${VERSION}.tar.gz"

    mkdir -p "$HATRICK_TMP/toolbox"
    # Strip the versioned top directory so /opt/jetbrains-toolbox stays stable.
    tar -xzf "$HATRICK_TMP/toolbox.tar.gz" -C "$HATRICK_TMP/toolbox" --strip-components=1

    sudo rm -rf /opt/jetbrains-toolbox
    sudo cp -a "$HATRICK_TMP/toolbox" /opt/jetbrains-toolbox
    sudo ln -sf /opt/jetbrains-toolbox/bin/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox

    echo "Run 'jetbrains-toolbox' to sign in and install your IDEs."
}
