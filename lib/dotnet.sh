# lib/dotnet.sh - .NET helpers shared by the dotnet-* plugins.
#
# Guarded like lib/gnome.sh: nothing in here is fatal and everything returns 0,
# so a plugin running under `set -e` is never cut short by a missing SDK.

DOTNET_DEVCERT_ANCHOR="/etc/pki/ca-trust/source/anchors/aspnetcore-dev-cert.pem"
DOTNET_DEVCERT_PROFILE="/etc/profile.d/aspnetcore-dev-cert.sh"

# dotnet_trust_dev_cert
#
# `dotnet dev-certs https --trust` on Linux only trusts the certificate for
# .NET itself. Clients like Go's crypto/tls read the system trust instead, so
# https://localhost:<port> fails there with "certificate signed by unknown
# authority".
#
# Copying the cert into Fedora's ca-trust anchors alone is not enough: the dev
# cert is not a CA, so update-ca-trust leaves it out of tls-ca-bundle.pem. Go
# does accept a non-CA cert it finds in SSL_CERT_DIR, so the anchors directory
# is added to SSL_CERT_DIR for every login shell via /etc/profile.d.
#
# Idempotent: the anchor and the profile file are only rewritten, and
# update-ca-trust only run, when their content actually changed.
dotnet_trust_dev_cert() {
    command -v dotnet >/dev/null 2>&1 || { echo "  dotnet not found, skipping dev cert"; return 0; }

    # Create the cert for this user if there is none yet (no-op otherwise).
    dotnet dev-certs https >/dev/null 2>&1 || true
    # Best effort: also trust it for .NET's own clients (.NET 9+ supports this on Linux).
    dotnet dev-certs https --trust >/dev/null 2>&1 || true

    local tmp
    tmp="$(mktemp -d)" || return 0
    if ! dotnet dev-certs https --export-path "$tmp/dev.pem" --format Pem --no-password >/dev/null 2>&1; then
        echo "  could not export the ASP.NET Core dev certificate"
        rm -rf "$tmp"; return 0
    fi

    if sudo cmp -s "$tmp/dev.pem" "$DOTNET_DEVCERT_ANCHOR" 2>/dev/null; then
        echo "  ASP.NET Core dev certificate already in ca-trust anchors"
    else
        sudo install -m 0644 "$tmp/dev.pem" "$DOTNET_DEVCERT_ANCHOR" &&
            sudo update-ca-trust extract &&
            echo "  ASP.NET Core dev certificate copied to ca-trust anchors"
    fi

    printf '# Written by hatrick: lets Go (and other SSL_CERT_DIR readers) trust the ASP.NET Core dev cert.\nexport SSL_CERT_DIR="/etc/pki/tls/certs:%s"\n' \
        "$(dirname "$DOTNET_DEVCERT_ANCHOR")" > "$tmp/profile.sh"
    if cmp -s "$tmp/profile.sh" "$DOTNET_DEVCERT_PROFILE" 2>/dev/null; then
        echo "  SSL_CERT_DIR already set in $DOTNET_DEVCERT_PROFILE"
    else
        sudo install -m 0644 "$tmp/profile.sh" "$DOTNET_DEVCERT_PROFILE" &&
            echo "  SSL_CERT_DIR set in $DOTNET_DEVCERT_PROFILE (new login shells; now: . $DOTNET_DEVCERT_PROFILE)"
    fi
    rm -rf "$tmp"
    return 0
}
