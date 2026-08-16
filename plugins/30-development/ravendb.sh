PLUGIN_DESC="RavenDB development container (localhost:8080)"
PLUGIN_REQUIRES="docker"

# Uses 'sudo docker' throughout: you were only just added to the docker group,
# and that does not apply until you log in again.

plugin_detect() {
    # No sudo here - detection also runs during 'hatrick list', which must never
    # ask for a password. A false negative is harmless, plugin_install re-checks.
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx ravendb
}

plugin_install() {
    mkdir -p "$HOME/ravendb/data"

    if sudo docker ps -a --format '{{.Names}}' | grep -qx ravendb; then
        echo "Container 'ravendb' already exists, starting it."
        sudo docker start ravendb
    else
        sudo docker run -d \
            --name ravendb \
            --restart unless-stopped \
            -p 8080:8080 \
            -p 38888:38888 \
            -v "$HOME/ravendb/data:/opt/RavenDB/Server/RavenData" \
            -e RAVEN_Setup_Mode=None \
            -e RAVEN_License_Eula_Accepted=true \
            -e RAVEN_Security_UnsecuredAccessAllowed=PrivateNetwork \
            ravendb/ravendb:latest
    fi

    echo "RavenDB studio: http://localhost:8080 (data in $HOME/ravendb/data)"
}
