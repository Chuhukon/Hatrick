PLUGIN_DESC="Miami Sunset desktop (fonts, wallpaper, dark GNOME)"

# A theme declares; lib/theme.sh does the work. Assets - here, the wallpaper -
# live in plugins/50-theme/miami-sunset/, reachable as $PLUGIN_ASSETS. See
# "Writing a theme" in README.md.

THEME_NAME="miami-sunset"

# Installed by the theme, from lib/fonts.sh.
THEME_FONTS="inter jetbrains-mono"

THEME_FONT_INTERFACE="Inter 11"
THEME_FONT_DOCUMENT="JetBrains Mono 12"
THEME_FONT_MONOSPACE="JetBrains Mono 12"

THEME_BACKGROUND="background.jpg"
THEME_BACKGROUND_STYLE="zoom"

THEME_COLOR_SCHEME="prefer-dark"
THEME_GTK_THEME="Adwaita-dark"

# launch-new-instance is what makes a click on a dash icon open a *second*
# window instead of raising the one already open. background-logo draws the
# Fedora logo over the wallpaper.
THEME_EXTENSIONS_OFF=(
    "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
    "background-logo@fedorahosted.org"
)

# Anything else this theme wants, one "schema key value" per line.
THEME_GSETTINGS=(
    # Font rendering. Full hinting snaps stems to the pixel grid; rgba is
    # subpixel antialiasing, which is what an LCD wants and what GNOME leaves
    # on grayscale by default.
    "org.gnome.desktop.interface font-hinting full"
    "org.gnome.desktop.interface font-antialiasing rgba"

    # Dash to Dock, when it is installed: click an icon, get the window you
    # already have. Previews only once that window is the focused one.
    "org.gnome.shell.extensions.dash-to-dock click-action focus-or-previews"
)

plugin_detect()  { theme_detect; }
plugin_install() { theme_apply; }
