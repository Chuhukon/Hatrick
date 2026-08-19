PLUGIN_DESC="Docker Engine, CLI and compose"

plugin_detect() { rpm -q docker-ce >/dev/null 2>&1; }

plugin_install() {
    # Fedora's own docker packages conflict with docker-ce.
    sudo dnf remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate \
        docker-selinux docker-engine-selinux docker-engine 2>/dev/null || true

    sudo dnf config-manager addrepo --overwrite \
        --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"

    echo "Log out and back in for docker group access."
}
