PLUGIN_DESC="VA-API video acceleration prerequisites (RPM Fusion freeworld Mesa)"
PLUGIN_DISABLED=1

# Prerequisites only, no apps. Fedora's own Mesa builds radeonsi_drv_video.so
# without H.264/HEVC; RPM Fusion's freeworld build adds them in
# /usr/lib64/dri-freeworld, which Fedora's libva searches before /usr/lib64/dri.
# It installs alongside mesa-dri-drivers: never `dnf swap mesa-va-drivers`,
# that package is gone in F44 and mesa-dri-drivers obsoletes it.

FREEWORLD_CONF="/etc/ld.so.conf.d/mesa-freeworld-lib64.conf"

plugin_detect() {
    rpm -q mesa-va-drivers-freeworld.x86_64 mesa-va-drivers-freeworld.i686 \
        libva-utils vulkan-tools >/dev/null 2>&1 &&
        [ -f "$FREEWORLD_CONF" ] && ! grep -q '[[:space:]]$' "$FREEWORLD_CONF" &&
        id -nG "$USER" | grep -qw render &&
        id -nG "$USER" | grep -qw video
}

plugin_install() {
    set -euo pipefail

    # Enable RPM Fusion free repo if not already present.
    if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi

    # pipewire, wireplumber and the GNOME portal are what Wayland screen capture
    # goes through.
    sudo dnf install -y libva libva-utils vulkan-tools \
        mesa-va-drivers-freeworld mesa-va-drivers-freeworld.i686 \
        pipewire wireplumber xdg-desktop-portal-gnome

    # The packaged file reads "/usr/lib64/dri-freeworld/ " with a trailing
    # space, so ldconfig skips the directory and the freeworld libgallium is
    # never what the soname resolves to. It is a plain %config file, so the fix
    # survives updates while the packaged content stays the same.
    if [ -f "$FREEWORLD_CONF" ] && grep -q '[[:space:]]$' "$FREEWORLD_CONF"; then
        sudo sed -i 's/[[:space:]]*$//' "$FREEWORLD_CONF"
    fi
    sudo ldconfig

    if [ ! -e /usr/lib64/dri-freeworld/radeonsi_drv_video.so ]; then
        echo "/usr/lib64/dri-freeworld/radeonsi_drv_video.so is missing: the freeworld driver did not install."
        return 1
    fi
    # By name, not --qf %{ARCH}: with the i686 package that prints two lines.
    if ! rpm -q mesa-va-drivers-freeworld.x86_64 >/dev/null 2>&1; then
        echo "mesa-va-drivers-freeworld is not installed for x86_64."
        return 1
    fi

    sudo usermod -aG render,video "$USER"

    echo "Log out and back in for render and video group access."
    echo "After the reboot, check hardware encode with:"
    echo "  vainfo --display drm --device /dev/dri/renderD128 | grep -E 'H264|HEVC|AV1' | grep EncSlice"
}
