PLUGIN_DESC="ClamAV antivirus with the ClamUI desktop front end"

# ClamAV comes from Fedora; ClamUI (https://clamui.com) ships no RPM and points
# RPM distributions at its Flatpak. ClamUI drives the clamscan/freshclam that
# live on the host, so both halves are installed here.

plugin_detect() {
    rpm -q clamav >/dev/null 2>&1 &&
        flatpak info io.github.linx_systems.ClamUI >/dev/null 2>&1
}

plugin_install() {
    sudo dnf install -y clamav clamav-freshclam

    # Fetch the signatures once by hand, before the updater owns the lock, so
    # the first scan has a database to work with.
    sudo freshclam
    sudo systemctl enable --now clamav-freshclam

    # A vanilla Fedora has flatpak but no flathub remote, so add it first.
    flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y flathub io.github.linx_systems.ClamUI

    echo "Signatures update in the background via clamav-freshclam."
    echo "ClamUI asks for your password the first time it changes host ClamAV settings."
}
