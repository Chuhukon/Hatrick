PLUGIN_DESC="LocalSend (share files over the LAN)"

plugin_detect() { flatpak info org.localsend.localsend_app >/dev/null 2>&1; }

plugin_install() {
    # A vanilla Fedora has flatpak but no flathub remote, so add it first.
    flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y flathub org.localsend.localsend_app

    # Fedora blocks incoming connections, so without this you can send but
    # never be discovered or receive. 53317 is LocalSend's port, tcp for the
    # transfer and udp for the multicast announcements.
    sudo firewall-cmd --permanent --add-port=53317/tcp
    sudo firewall-cmd --permanent --add-port=53317/udp
    sudo firewall-cmd --reload

    echo "LocalSend listens on 53317; the other device must be on the same network."
}
