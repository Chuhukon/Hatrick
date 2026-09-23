PLUGIN_DESC="PowerShell (cross-platform shell)"

plugin_detect() { rpm -q powershell >/dev/null 2>&1; }

plugin_install() {
    # PowerShell ships from the Microsoft feed rather than Fedora's own.
    rpm -q packages-microsoft-prod >/dev/null 2>&1 ||
        sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm

    sudo dnf install -y powershell
    echo "Run 'pwsh' to start PowerShell."
}
