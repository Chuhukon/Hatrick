# lib/fonts.sh - the fonts, how they are drawn, and how big they end up.
#
# Sourced by hatrick before any plugin, so font_install/font_installed are
# available inside every plugin_install and plugin_detect. font_setup is the
# part hatrick runs itself on every install, whichever plugins were picked.
#
# Adding a font is one arm in each case statement. Nothing else needs to know.

JETBRAINS_MONO_VERSION="2.304"   # bump this line to move to a newer release
INTER_VERSION="4.1"              # bump this line to move to a newer release
MSTTCORE_VERSION="2.6-1"         # bump this line to move to a newer release

# font_installed <key> - true when fontconfig already knows the family.
# Must never need sudo: it runs during `hatrick list` too.
font_installed() {
    case "$1" in
        jetbrains-mono) fc-list | grep -qi "JetBrains Mono" ;;
        inter)          fc-list : family | grep -qix "inter" ;;
        ms-core)        fc-list : family | grep -qix "arial" ;;
        *)              return 1 ;;
    esac
}

# font_install <key> - download and install one font, system-wide. Idempotent:
# a font that fontconfig already has is left alone.
font_install() {
    local key="$1"

    if font_installed "$key"; then
        echo "  font ${key} already installed"
        return 0
    fi

    echo "  installing font ${key}"
    case "$key" in
        jetbrains-mono)
            curl -fsSL -o "$HATRICK_TMP/jetbrains-mono.zip" \
                "https://github.com/JetBrains/JetBrainsMono/releases/download/v${JETBRAINS_MONO_VERSION}/JetBrainsMono-${JETBRAINS_MONO_VERSION}.zip"
            unzip -qo "$HATRICK_TMP/jetbrains-mono.zip" -d "$HATRICK_TMP/jetbrains-mono"

            sudo mkdir -p /usr/share/fonts/jetbrains-mono
            sudo cp "$HATRICK_TMP"/jetbrains-mono/fonts/ttf/*.ttf /usr/share/fonts/jetbrains-mono/
            sudo fc-cache -f /usr/share/fonts/jetbrains-mono
            ;;
        inter)
            curl -fsSL -o "$HATRICK_TMP/inter.zip" \
                "https://github.com/rsms/inter/releases/download/v${INTER_VERSION}/Inter-${INTER_VERSION}.zip"
            unzip -qo "$HATRICK_TMP/inter.zip" -d "$HATRICK_TMP/inter"

            sudo mkdir -p /usr/share/fonts/inter
            sudo cp "$HATRICK_TMP"/inter/Inter.ttc /usr/share/fonts/inter/
            sudo cp "$HATRICK_TMP"/inter/InterVariable*.ttf /usr/share/fonts/inter/
            sudo fc-cache -f /usr/share/fonts/inter
            ;;
        ms-core)
            # Arial, Times New Roman, Verdana, Georgia and the rest. Microsoft
            # licenses these for redistribution only as the original installers,
            # so no repository carries the fonts themselves; this RPM fetches
            # them and unpacks them with cabextract, and dnf pulls in cabextract
            # and the font utilities it needs. Nobody signs it, hence
            # --nogpgcheck. Its %post runs fc-cache for us.
            sudo dnf install -y --nogpgcheck \
                "https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-${MSTTCORE_VERSION}.noarch.rpm"
            ;;
        *)
            echo "unknown font '${key}'" >&2
            return 1
            ;;
    esac
}

# ---------------------------------------------------------------------------
# How they are drawn
# ---------------------------------------------------------------------------

# _font_gsettings <key> <value> - set one org.gnome.desktop.interface key, or
# name the one this GNOME does not have. Always returns 0.
_font_gsettings() {
    if gsettings set org.gnome.desktop.interface "$1" "$2" 2>/dev/null; then
        echo "  ${1} = ${2}"
    else
        echo "  skip ${1}: not in this GNOME"
    fi
    return 0
}

# font_rendering - the rendering settings, said twice on purpose. GNOME's keys
# only reach GTK; Chromium, Vivaldi, the Electron apps and the JetBrains IDEs
# read fontconfig instead, so both have to say the same thing or one desktop
# draws the same sentence two different ways.
#
# Slight hinting fits stems to the Y axis only. That is what Fedora itself
# defaults to and what the GNOME schema calls recommended; full hinting pulls
# variable fonts like Inter out of shape. Antialiasing stays grayscale because
# subpixel assumes a fixed RGB stripe, which a rotated panel does not have and
# Wayland scaling does not preserve.
font_rendering() {
    local conf="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d/99-hatrick-rendering.conf"

    mkdir -p "${conf%/*}"
    cat > "$conf" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<!-- Written by Hatrick. Delete this file to go back to the Fedora defaults. -->
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="rgba" mode="assign"><const>none</const></edit>

    <!-- Unused while rgba is none, and right the moment someone turns it on. -->
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>

    <!-- Several Microsoft fonts carry low resolution bitmaps for small sizes,
         which is what makes Calibri and Times New Roman look blocky. Ignore
         them and scale the outlines instead. -->
    <edit name="embeddedbitmap" mode="assign"><bool>false</bool></edit>
  </match>
</fontconfig>
EOF
    echo "  rendering -> ${conf}"

    # The GNOME half. No session bus means no gsettings, which is the normal
    # state over SSH or from a TTY, so say nothing there and carry on.
    command -v gsettings >/dev/null 2>&1 || return 0
    [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || [ -S "${XDG_RUNTIME_DIR:-}/bus" ] || return 0

    # font-rendering arrived in GNOME 48 and, left at its default of
    # 'automatic', makes the toolkit ignore the other two keys entirely.
    _font_gsettings font-rendering    manual
    _font_gsettings font-hinting      slight
    _font_gsettings font-antialiasing grayscale
    return 0
}

# ---------------------------------------------------------------------------
# How big they end up
# ---------------------------------------------------------------------------

# font_scaling - keep text readable on a big, dense screen.
#
# GNOME draws at a logical 96 DPI, and Mutter only doubles that by itself past
# 192 DPI. Everything in between - a 25" 1440p at 118 DPI, a 32" 4K at 138 -
# is left at scale 1 and comes out about a quarter too small.
# text-scaling-factor is the one knob that covers that gap, so measure what is
# actually plugged in rather than hard-coding the author's own desk.
font_scaling() {
    command -v gsettings >/dev/null 2>&1 || return 0
    [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || [ -S "${XDG_RUNTIME_DIR:-}/bus" ] || return 0

    # A factor you set yourself is yours. Only the untouched default is ours.
    if [ "$(gsettings get org.gnome.desktop.interface text-scaling-factor 2>/dev/null)" != "1.0" ]; then
        echo "  text scaling left alone: it is not at the default any more"
        return 0
    fi

    local out mode cm dpi best=0 factor
    for out in /sys/class/drm/card*-*; do
        [ "$(cat "$out/status" 2>/dev/null)" = "connected" ] || continue

        mode="$(head -1 "$out/modes" 2>/dev/null)"
        # sysfs reports edid as a zero-length file that still reads 128 bytes or
        # more, so read it rather than test it: a [ -s ] guard here would skip
        # every display. Bytes 21 and 22 are the screen size in whole cm.
        cm="$(od -An -tu1 -j21 -N2 "$out/edid" 2>/dev/null | awk '{print $1, $2}')"
        [ -n "$mode" ] && [ -n "$cm" ] || continue

        dpi="$(awk -v m="$mode" -v c="$cm" 'BEGIN {
            split(m, r, "x"); split(c, s, " ")
            if (r[1] < 1 || s[1] < 1 || s[2] < 1) exit
            printf "%.0f", sqrt(r[1]^2 + r[2]^2) / (sqrt(s[1]^2 + s[2]^2) / 2.54)
        }')"
        [ -n "$dpi" ] || continue

        # 192 is Mutter's own HiDPI cut-off: past it GNOME is already applying
        # an integer scale, and scaling the text too would correct it twice.
        [ "$dpi" -ge 192 ] && continue
        if [ "$dpi" -gt "$best" ]; then best="$dpi"; fi
    done

    if [ "$best" -eq 0 ]; then
        echo "  text scaling stays at 1.0: no display to measure"
        return 0
    fi

    if   [ "$best" -ge 140 ]; then factor="1.5"
    elif [ "$best" -ge 110 ]; then factor="1.25"
    else
        echo "  text scaling stays at 1.0 (densest unscaled display: ${best} dpi)"
        return 0
    fi

    if gsettings set org.gnome.desktop.interface text-scaling-factor "$factor" 2>/dev/null; then
        echo "  text-scaling-factor = ${factor} (densest unscaled display: ${best} dpi)"
    else
        echo "  ! text-scaling-factor could not be set"
    fi
    return 0
}

# ---------------------------------------------------------------------------

# font_setup - what every machine gets, whichever plugins were picked. hatrick
# calls it once, after the base packages. Never fatal: a font that would not
# download must not cost you the rest of the run.
font_setup() {
    font_install ms-core || echo "  ! the Microsoft fonts did not install"
    font_rendering
    font_scaling
    return 0
}
