PLUGIN_DESC="OpenLogi (Logitech mouse and keyboard control)"

# https://openlogi.org - a local-first replacement for Logitech Options+.
# Upstream ships the RPM on GitHub only. Bump this line for a newer release.
VERSION="0.8.3"

plugin_detect() { rpm -q openlogi >/dev/null 2>&1; }

plugin_install() {
    curl -fsSL -o "$HATRICK_TMP/openlogi.rpm" \
        "https://github.com/AprilNEA/OpenLogi/releases/download/v${VERSION}/openlogi-v${VERSION}-linux-amd64.rpm"

    # The release is signed with minisign, not GPG, so the RPM carries no
    # signature dnf could check.
    sudo dnf install -y --nogpgcheck "$HATRICK_TMP/openlogi.rpm"

    # The package installs the udev rules that hand the device over, but leaves
    # the background agent to each user. It wants a graphical session, so this
    # is never fatal from a TTY.
    systemctl --user enable --now openlogi-agent.service ||
        echo "Start the agent from your desktop session: systemctl --user enable --now openlogi-agent.service"

    echo "OpenLogi drives Logitech devices over HID++; the agent must be running for settings to apply."
}
