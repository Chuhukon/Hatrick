PLUGIN_DESC="GNOME Commander (twin-panel file manager)"

# https://gitlab.gnome.org/GNOME/gnome-commander/-/releases - the 2.x line is the
# GTK4 rewrite and ships as a source tarball only, so this builds it. Fedora's
# own package is still on the old 1.18 line. Bump this line for a newer release.
VERSION="2.0.3"

# Upstream installs into /usr/local, and the metainfo file it puts there is the
# only place the installed version is written down.
plugin_detect() {
    grep -q "version=\"${VERSION}\"" \
        /usr/local/share/metainfo/org.gnome.gnome-commander.metainfo.xml 2>/dev/null
}

plugin_install() {
    # meson, rust and gcc build it; the rest are the libraries meson.build looks
    # for. exiv2, libgsf, taglib and poppler are optional to the build, but they
    # are what reads the metadata out of images, documents and music.
    sudo dnf install -y meson ninja-build gcc gcc-c++ rust cargo gettext-devel \
                        glib2-devel gobject-introspection-devel gtk4-devel \
                        vte291-gtk4-devel gdk-pixbuf2-devel \
                        exiv2-devel libgsf-devel taglib-devel poppler-glib-devel \
                        yelp-tools desktop-file-utils

    # The GitLab release points at the GNOME download server for the tarball;
    # the directory there is the major.minor part of the version.
    curl -fsSL -o "$HATRICK_TMP/gnome-commander.tar.xz" \
        "https://download.gnome.org/sources/gnome-commander/${VERSION%.*}/gnome-commander-${VERSION}.tar.xz"
    tar -xf "$HATRICK_TMP/gnome-commander.tar.xz" -C "$HATRICK_TMP"
    cd "$HATRICK_TMP/gnome-commander-${VERSION}"

    # The build fetches its crates from crates.io, so it needs the network and a
    # few minutes. --no-rebuild keeps the install step from running cargo again
    # as root, which would leave root-owned files behind in $HATRICK_TMP.
    meson setup builddir --prefix=/usr/local --buildtype=release
    meson compile -C builddir
    sudo meson install -C builddir --no-rebuild

    echo "GNOME Commander is installed in /usr/local; start it as gnome-commander."
}
