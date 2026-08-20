```
 ██╗  ██╗ █████╗ ████████╗██████╗ ██╗ ██████╗██╗  ██╗
 ██║  ██║██╔══██╗╚══██╔══╝██╔══██╗██║██╔════╝██║ ██╔╝
 ███████║███████║   ██║   ██████╔╝██║██║     █████╔╝
 ██╔══██║██╔══██║   ██║   ██╔══██╗██║██║     ██╔═██╗
 ██║  ██║██║  ██║   ██║   ██║  ██║██║╚██████╗██║  ██╗
 ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝
```

# Hatrick

Hatrick is an opinionated setup for a vanilla Fedora. Run it after a fresh install and pick, from
a menu, which parts of a C# developer's stack you want.

Every tool is a **plugin**: one file under `plugins/`, written in plain Fedora shell. Hatrick is a
single script that finds them, asks which ones you want, and runs them.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/Chuhukon/Hatrick/main/install.sh | bash
```

That downloads Hatrick to `~/.local/share/hatrick`, links it as `~/.local/bin/hatrick` and opens
the menu. Run the same line again later to upgrade in place. Or clone it yourself:

```bash
git clone https://github.com/Chuhukon/Hatrick.git && cd Hatrick
./hatrick.sh
```

Run it **as your normal user, not with sudo**. Plugins call `sudo` themselves for the system-wide
parts when needed.

The hatrick command:

```
hatrick [install]   pick plugins from a menu, then install them
hatrick list        show every plugin and exit
hatrick help

HATRICK_FORCE=1     reinstall even when a plugin reports itself installed
NO_COLOR=1          plain output
```

The menu is one numbered list. Everything which is not installed on your machine is ticked by default. 
ENTER alone installs exactly what is missing. Type numbers and ranges to toggle:

```
Development
   2) [ ] docker                 Docker Engine, CLI and compose             (installed)
  10) [x] virtualbox             Oracle VirtualBox

Theme
  14) [x] miami-sunset            Miami Sunset desktop (fonts, wallpaper, dark GNOME)

 numbers/ranges toggle (3 5-7) · a=all · n=none · ENTER=install · q=quit
 > 2 10
```

## Writing a plugin

Create `plugins/<group>/<name>.sh`. One variable and one function is a complete plugin:

```bash
PLUGIN_DESC="Hello world plugin"
plugin_install() { sudo dnf install -y ...; }
```

It appears in the menu on the next run. The name comes from the filename, the group from the
directory. There is nothing to register.

The full contract, all of it is optional except `PLUGIN_DESC` and `plugin_install`:

```bash
PLUGIN_DESC="Docker Engine, CLI and compose"   # required - the menu text
PLUGIN_REQUIRES="golang docker"                # optional - other plugin names

# Optional. True means "already installed", so the plugin starts unticked in the
# menu and re-runs skip it. Do NOT use sudo: it also runs during
# `hatrick list`.
plugin_detect() { rpm -q docker-ce >/dev/null 2>&1; }

# Required. Runs with `set -e`, so the first failing command stops this plugin -
# and only this plugin. The rest of the run continues.
plugin_install() {
    sudo dnf config-manager addrepo --overwrite \
        --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "Log out and back in for docker group access."
}
```

### Notes on writing the plugin:

- **It is just shell.** Use `dnf`, `curl`, `rpm`, `systemctl`, `usermod`, `flatpak`; whatever you
  would type yourself. There is nothing to learn beyond the two names above, unless you are writing
  a theme.
- **Files a plugin ships with** go in `plugins/<group>/<name>/`; the plugin's own path without the
  `.sh`. Inside the plugin that directory is `$PLUGIN_ASSETS`. Discovery globs `plugins/*/*.sh`, so
  a directory next to a plugin is never mistaken for one.
- **`sudo` where root is needed, and nowhere else.** `gsettings`, `flatpak --user`, `go install` and
  anything touching `$HOME` must run without it, or they land on root.
- **`$HATRICK_TMP`** is a scratch directory that is deleted when the run ends; handy for
  download-and-extract plugins. Use `mktemp -d` instead if you prefer.
- **Plain simple `echo`** anything the user should know afterwards.
- Pin versions with an ordinary variable at the top of the file (`VERSION="2.304"`), so bumping is
  a one-line edit.

**Order** is the order files are found: `plugins/<NN-group>/<NN-name>.sh`. 
`PLUGIN_REQUIRES` does not sort anything; it only ticks a dependency you left out of the menu.

Each plugin is read and run in its own subshell, so variables and functions cannot leak between
plugins. Everything in `lib/` is sourced first, by Hatrick itself, so those helpers *are* available
everywhere. That is f.e. what themes are built on.

## Writing a theme

A theme is how the desktop looks: fonts, wallpaper, dark or light, and whatever else you always
change on a fresh install. It is an ordinary plugin that only **declares** what it wants, next to a
folder holding the files it ships, for example;

```
plugins/50-theme/miami-sunset.sh                 the declarations
plugins/50-theme/miami-sunset/background.jpg     the wallpaper
```

Copy `miami-sunset.sh`, change the values, drop your own image in a folder beside it. `lib/theme.sh`
does the applying, so a new theme is one file and one image, togehter with a new *kind* of setting is one
new variable there, which every existing theme then ignores until it sets it.

```bash
PLUGIN_DESC="Miami Sunset desktop (fonts, wallpaper, dark GNOME)"

THEME_NAME="miami-sunset"           # the asset folder next to this file

THEME_FONTS="inter jetbrains-mono"       # installed by the theme, from lib/fonts.sh

THEME_FONT_INTERFACE="Inter 11"          # org.gnome.desktop.interface font-name
THEME_FONT_DOCUMENT="JetBrains Mono 12"  #                            document-font-name
THEME_FONT_MONOSPACE="JetBrains Mono 12" #                            monospace-font-name

THEME_BACKGROUND="background.jpg"        # a file in the asset folder
THEME_BACKGROUND_STYLE="zoom"            # picture-options

THEME_COLOR_SCHEME="prefer-dark"         # the dark/light switch
THEME_GTK_THEME="Adwaita-dark"           # for GTK3 apps, which ignore color-scheme
THEME_ICON_THEME=""                      # optional

THEME_EXTENSIONS_OFF=( "launch-new-instance@gnome-shell-extensions.gcampax.github.com" )
THEME_EXTENSIONS_ON=()

# Anything without a variable of its own yet. One "schema key value" per entry.
THEME_GSETTINGS=(
    "org.gnome.shell.extensions.dash-to-dock click-action focus-or-previews"
)

plugin_detect()  { theme_detect; }
plugin_install() { theme_apply; }
```

One theme file works on a bare GNOME and on a fully kitted one:

1. Installs each font in `THEME_FONTS`. Remember to add the font in `lib/fonts.sh` so any theme can use it.
2. Copies the wallpaper to `~/.local/share/backgrounds/hatrick/` and points the desktop *and* lock
   screen at it. 
3. Sets the three GNOME font keys.
4. Sets `color-scheme`, `gtk-theme`, `icon-theme`.
5. Enables and disables the GNOME Shell extensions listed.
6. Applies every line of `THEME_GSETTINGS`.

Only fonts use `sudo`. Wallpapers and `gsettings` belong to your account.
