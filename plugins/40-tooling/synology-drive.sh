PLUGIN_DESC="Synology Drive (sync files with your Synology NAS)"

# https://copr.fedorainfracloud.org/coprs/emixampp/synology-drive/

plugin_detect() { rpm -q synology-drive >/dev/null 2>&1; }

plugin_install() {
    sudo dnf copr enable -y emixampp/synology-drive
    sudo dnf install -y --refresh synology-drive
}
