PLUGIN_DESC="Oracle VirtualBox"

# Oracle does not build for every Fedora release, so the build they *did* make
# is pinned separately from the VirtualBox version. Bump both to upgrade.
VERSION="7.2.12_174389"
SERIES="7.2"
FEDORA_BUILD="40"

plugin_detect() { command -v VirtualBox >/dev/null 2>&1; }

plugin_install() {
    # Kernel modules are compiled on install, so the toolchain has to be there.
    sudo dnf install -y @development-tools
    sudo dnf install -y kernel-devel kernel-headers dkms

    curl -fsSL -o "$HATRICK_TMP/virtualbox.rpm" \
        "https://download.virtualbox.org/virtualbox/rpm/fedora/${FEDORA_BUILD}/x86_64/VirtualBox-${SERIES}-${VERSION}_fedora${FEDORA_BUILD}-1.x86_64.rpm"
    sudo dnf install -y "$HATRICK_TMP/virtualbox.rpm"

    getent group vboxusers >/dev/null || sudo groupadd vboxusers
    sudo usermod -aG vboxusers "$USER"

    sudo /sbin/vboxconfig

    echo "Log out and back in for vboxusers group access."
    echo "Secure Boot blocks unsigned VirtualBox modules: disable it or sign them."
}
