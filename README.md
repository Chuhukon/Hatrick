```
            #####      #####
       #########      ######                                                   #####                          ##
    ####  ######      ######                          ####                    #######                    ######
  ####   ######      ######                         ######                     #####                     ######
 ####    ######     #######                         ######                                              ######
#####   ######      ######        #####  ######   ##########  ######   ###   #######        #######     ######      ####
 ####   ##################     ###############     ######     #############  ######       #####  ###    ######   ####
    #   ##################   ######     ######    ######     #######   #### #######     ######   ###   ######  ###
       ######      ######   ######     #######    ######     ######         ######     ######     #    #############
       ######     #######   ######     ######     ######    #######         ######    ######          ################
      ######      ######   ######     #######    ######     ######         ######    #######          ######    ######
      ######      ######   ######     ######     ######    #######         ######    ######          ######     ######
     ######      ######    ######    #######    ######     ######         ######     ######        ########    ######
     ######      ######    ####### #########  ######### #########         ##################     ##########    #######
     ######     #######     ######### #########  ###############           #########  ############  ######      ########
```

# Hatrick

Hatrick is an opinionated setup for a vanilla Fedora. Run it after a fresh install and pick, from
a menu, which parts of a C# developer's stack you want.

Every tool is a **plugin**: one file under `plugins/`, written in plain Fedora shell. Hatrick is a
single script that finds them, asks which ones you want, and runs them.

## Quick start

```bash
git clone <this repo> && cd Hatrick
./hatrick
```

Run it **as your normal user, not with sudo**. Plugins call `sudo` themselves for the system-wide
parts, which is what keeps `$USER`, `$HOME`, `gsettings` and `flatpak` pointing at your account.
Running the whole thing as root is what puts *root* in the `docker` group and writes your fonts and
containers into `/root`.

```
hatrick [install]   pick plugins from a menu, then install them
hatrick list        show every plugin and exit
hatrick help

HATRICK_FORCE=1     reinstall even when a plugin reports itself installed
NO_COLOR=1          plain output
```

The menu is one numbered list. Type numbers and ranges to toggle, then press ENTER:

```
Fonts
   2) [x] jetbrains-mono         JetBrains Mono font
   3) [x] mona-sans              Mona Sans font (static + variable)
   4) [x] gnome-font-settings    Use Mona Sans / JetBrains Mono in GNOME

Development
   5) [x] docker                 Docker Engine, CLI and compose             (installed)
  13) [ ] virtualbox             Oracle VirtualBox

 numbers/ranges toggle (3 5-7) · a=all · n=none · ENTER=install · q=quit
 > 5 13
```

Anything you tick that needs something you did not is added for you, with a line saying why
(`+ docker (required by ravendb)`). Each run is logged to `~/.local/state/hatrick/`.

## What you can install

| Group | Plugins |
| --- | --- |
| Browser | Vivaldi (set as default) |
| Fonts | JetBrains Mono, Mona Sans, GNOME font settings |
| Development | Docker + compose, lazydocker, .NET SDK 8, .NET SDK 10, Go, Sublime Text/Merge, VS Code, JetBrains Toolbox, VirtualBox *(off by default)*, RavenDB container |
| Tooling | Obsidian, GNOME Tweaks + extensions |

Before any of them, Hatrick runs `dnf update` and installs `curl wget git unzip tar fontconfig
flatpak dnf-plugins-core`, which several plugins assume are there.

## Writing a plugin

Create `plugins/<group>/<name>.sh`. One variable and one function is a complete plugin:

```bash
PLUGIN_DESC="htop process viewer"

plugin_install() { sudo dnf install -y htop; }
```

It appears in the menu on the next run. The name comes from the filename, the group from the
directory — there is nothing to register.

The full contract, all of it optional except `PLUGIN_DESC` and `plugin_install`:

```bash
PLUGIN_DESC="Docker Engine, CLI and compose"   # required - the menu text
PLUGIN_DEFAULT=off                             # optional - defaults to on
PLUGIN_REQUIRES="golang docker"                # optional - other plugin names

# Optional. True means "already installed", so re-runs skip it. Must not need
# sudo: it also runs during `hatrick list`.
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

Notes on writing the body:

- **It is just shell.** Use `dnf`, `curl`, `rpm`, `systemctl`, `usermod`, `flatpak` — whatever you
  would type yourself. There is no Hatrick API to learn.
- **`sudo` where root is needed, and nowhere else.** `gsettings`, `flatpak --user`, `go install` and
  anything touching `$HOME` must run without it, or they land on root.
- **`$HATRICK_TMP`** is a scratch directory that is deleted when the run ends — handy for
  download-and-extract plugins. Use `mktemp -d` instead if you prefer.
- **`echo`** anything the user should know afterwards.
- Pin versions with an ordinary variable at the top of the file (`VERSION="2.304"`), so bumping is
  a one-line edit.

**Order** is the order files are found: `plugins/<NN-group>/<NN-name>.sh`. Rename to reorder — that
is what the `10-`/`20-` prefixes are for, and they are stripped from the displayed name.
`PLUGIN_REQUIRES` does not sort anything; it only ticks a dependency you left out of the menu.

Each plugin is read and run in its own subshell, so variables and functions cannot leak between
plugins.

## Layout

```
hatrick              the whole program
plugins/<group>/     one file per tool
```
