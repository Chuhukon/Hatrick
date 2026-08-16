# shellcheck shell=bash
# Hatrick plugin — Oracle VirtualBox. Oracle does not build for every Fedora
# release, so the Fedora build number is pinned separately from the version.

PLUGIN_NAME="virtualbox"
PLUGIN_DESC="Oracle VirtualBox"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=off

# Bump these to move to a newer release. VBOX_FEDORA_BUILD is the Fedora release
# Oracle built against, which may lag behind the release you are running.
PLUGIN_VERSION="7.2.12_174389"
VBOX_SERIES="7.2"
VBOX_FEDORA_BUILD="40"

VBOX_URL="https://download.virtualbox.org/virtualbox/rpm/fedora/${VBOX_FEDORA_BUILD}/x86_64/VirtualBox-${VBOX_SERIES}-${PLUGIN_VERSION}_fedora${VBOX_FEDORA_BUILD}-1.x86_64.rpm"

plugin_detect() {
    have VirtualBox
}

plugin_install() {
    # Kernel modules are built on install, so the toolchain has to be there first.
    pkg_install @development-tools
    pkg_install kernel-devel kernel-headers dkms

    local rpm="${HATRICK_TMP}/virtualbox.rpm"
    fetch "$VBOX_URL" "$rpm"
    pkg_install "$rpm"

    add_user_to_group vboxusers

    if [ -x /sbin/vboxconfig ]; then
        as_root /sbin/vboxconfig
    else
        log_warn "vboxconfig not found"
        plugin_note "Run '/sbin/vboxconfig' manually to build the VirtualBox kernel modules."
    fi

    plugin_note "Secure Boot signs no VirtualBox modules: disable it or sign them yourself."
}
