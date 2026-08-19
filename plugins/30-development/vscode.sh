PLUGIN_DESC="Visual Studio Code"

plugin_detect() { rpm -q code >/dev/null 2>&1; }

plugin_install() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    # Microsoft publishes no .repo file for the VS Code feed, so write one.
    sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    sudo dnf install -y code
}
