# shellcheck shell=bash
# Hatrick plugin — a local RavenDB container for development.
#
# Runs through 'as_root docker' on purpose: the user was only just added to the
# docker group and that does not apply until they log in again.

PLUGIN_NAME="ravendb"
PLUGIN_DESC="RavenDB development container (localhost:8080)"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on
PLUGIN_REQUIRES="docker"

PLUGIN_VERSION="latest"

RAVENDB_IMAGE="ravendb/ravendb:${PLUGIN_VERSION}"
RAVENDB_CONTAINER="ravendb"
RAVENDB_PORT="8080"

# Deliberately unprivileged: detection also runs during 'hatrick list', which
# must never prompt for a sudo password. A false negative here is harmless,
# _ravendb_exists re-checks with privileges before creating anything.
plugin_detect() {
    have docker || return 1
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$RAVENDB_CONTAINER"
}

_ravendb_exists() {
    as_root docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$RAVENDB_CONTAINER"
}

plugin_install() {
    local data="${HATRICK_HOME}/ravendb/data"
    as_user mkdir -p "$data"

    if _ravendb_exists; then
        log_info "Container '${RAVENDB_CONTAINER}' already exists, leaving it alone."
        as_root docker start "$RAVENDB_CONTAINER" >/dev/null 2>&1 || true
    else
        as_root docker run -d \
            --name "$RAVENDB_CONTAINER" \
            --restart unless-stopped \
            -p "${RAVENDB_PORT}:8080" \
            -p 38888:38888 \
            -v "${data}:/opt/RavenDB/Server/RavenData" \
            -e RAVEN_Setup_Mode=None \
            -e RAVEN_License_Eula_Accepted=true \
            -e RAVEN_Security_UnsecuredAccessAllowed=PrivateNetwork \
            "$RAVENDB_IMAGE"
    fi

    plugin_note "RavenDB studio: http://localhost:${RAVENDB_PORT} (data in ${data})"
}
