PLUGIN_DESC="NetPad - C# editor and playground"

VERSION="0.12.0"

plugin_detect() { rpm -q netpad >/dev/null 2>&1; }

plugin_install() {
    curl -fsSL -o "$HATRICK_TMP/netpad.rpm" \
        "https://github.com/tareqimbasher/NetPad/releases/download/v${VERSION}/netpad-${VERSION}-linux-x86_64.rpm"

    # Upstream RPM is unsigned, so install with --nogpgcheck.
    sudo dnf install -y --nogpgcheck "$HATRICK_TMP/netpad.rpm"

    sudo ln -sf /opt/NetPad/netpad /usr/local/bin/netpad

    echo "NetPad installed. Run 'netpad' or launch it from the application menu."
}
