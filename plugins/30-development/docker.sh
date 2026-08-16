# shellcheck shell=bash
# Hatrick plugin — Docker Engine from Docker's own repository (not Fedora's
# podman-docker shim), plus compose and the current user's group membership.

PLUGIN_NAME="docker"
PLUGIN_DESC="Docker Engine, CLI, containerd and compose"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on

plugin_detect() {
    pkg_installed docker-ce
}

plugin_install() {
    # Fedora's own docker packages conflict with docker-ce.
    pkg_remove docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate \
        docker-selinux docker-engine-selinux docker-engine

    add_repofile https://download.docker.com/linux/fedora/docker-ce.repo
    pkg_install docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    enable_service docker
    add_user_to_group docker
}
