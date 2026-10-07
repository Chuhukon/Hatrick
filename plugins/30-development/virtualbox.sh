PLUGIN_DESC="Oracle VirtualBox (via RPM Fusion akmods)"

# RPM Fusion's akmod-VirtualBox auto-rebuilds kernel modules on every kernel
# install, surviving Fedora kernel updates without manual intervention.

plugin_detect() { command -v VirtualBox >/dev/null 2>&1; }

plugin_install() {
    # Kernel module building requires the development toolchain.
    sudo dnf install -y @development-tools
    sudo dnf install -y kernel-devel kernel-headers gcc make

    # Enable RPM Fusion free repo if not already present.
    if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi

    # Remove conflicting Oracle RPM if installed.
    sudo dnf remove -y 'VirtualBox-*' 2>/dev/null || true

    # Install akmod-VirtualBox and VirtualBox from RPM Fusion.
    # akmods will auto-rebuild on kernel updates.
    sudo dnf install -y akmod-VirtualBox VirtualBox

    # Force build for the current kernel now (don't wait).
    sudo akmods --force --kernels "$(uname -r)"
    sudo modprobe vboxdrv

    # Set up vboxusers group for non-root VM access.
    getent group vboxusers >/dev/null || sudo groupadd vboxusers
    sudo usermod -aG vboxusers "$USER"

    echo "Log out and back in for vboxusers group access."
    echo "Secure Boot blocks unsigned VirtualBox modules: disable it or sign them."
    echo "Kernel modules will auto-rebuild on future kernel updates via akmods."
}
