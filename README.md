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
a checklist, which parts of a C# developer's stack you want.

Every tool is a **plugin**: one self-contained file under `plugins/`. Hatrick discovers them at
startup, asks you which ones to install, works out the order, and runs them. Adding a tool means
dropping in a file — you never edit the installer.

## Quick start

```bash
git clone <this repo> && cd Hatrick
./hatrick
```

Run it **as your normal user, not with sudo**. Hatrick calls `sudo` itself for the system-wide
steps and deliberately keeps the user-scoped ones — group membership, GNOME settings, Flatpaks,
`$HOME` — under your own account. Running the whole thing as root is what puts *root* in the
`docker` group and writes your fonts and containers into `/root`.

```
hatrick [install]     Pick plugins from a checklist, then install them
hatrick list          Show every discovered plugin and exit (changes nothing)
hatrick help
hatrick version
```

| Variable | Effect |
| --- | --- |
| `HATRICK_FORCE=1` | Reinstall plugins even when they are detected as already present |
| `HATRICK_DEBUG=1` | Log every package/repo command as it runs |
| `NO_COLOR=1` | Plain output |

Each run is logged to `~/.local/state/hatrick/hatrick-<timestamp>.log`.

## What you can install

| Group | Plugins |
| --- | --- |
| Base *(always)* | system update, base dependencies |
| Browser | Vivaldi (set as default) |
| Fonts | JetBrains Mono, Mona Sans, GNOME font settings |
| Development | Docker + compose, lazydocker, .NET SDK 8, .NET SDK 10, Go, Sublime Text/Merge, VS Code, JetBrains Toolbox, VirtualBox *(off by default)*, RavenDB container |
| Tooling | Obsidian, GNOME Tweaks + extensions |

## How a run works

1. **Discover** — every `plugins/<group>/<name>.sh` is read in a subshell to collect its metadata.
2. **Select** — one whiptail checklist per group, defaults pre-ticked, anything already installed
   marked as such. Cancel at any point and nothing has changed.
3. **Resolve** — if something you ticked depends on something you did not, Hatrick offers to add
   it. Decline and the dependent plugin is dropped instead of failing halfway through.
4. **Confirm** — a final summary of exactly what will be installed.
5. **Run** — dependencies first, each plugin in its own subshell. A plugin that fails is reported
   and the rest of the run continues.
6. **Summarise** — installed / skipped / failed, plus any notes plugins left for you.

## Writing a plugin

Create `plugins/<group>/<name>.sh`. Set the metadata, define `plugin_install`, done — it appears
in the checklist on the next run.

```bash
# plugins/30-development/docker.sh
PLUGIN_NAME="docker"                # unique id, used for dependencies
PLUGIN_DESC="Docker Engine, CLI, containerd and compose"
PLUGIN_GROUP="Development"          # checklist this appears under
PLUGIN_DEFAULT=on                   # on | off — initial checkbox state
PLUGIN_REQUIRES=""                  # space-separated PLUGIN_NAMEs
PLUGIN_VERSION=""                   # pinned version, when you download a fixed artifact
PLUGIN_MANDATORY=no                 # yes = always runs, never offered

# Optional. True means "already installed", so the plugin is skipped on a re-run.
# Must not need root: it also runs during `hatrick list`.
plugin_detect() { pkg_installed docker-ce; }

# Required. Runs with `set -e`, so the first failing command stops this plugin only.
plugin_install() {
    add_repofile https://download.docker.com/linux/fedora/docker-ce.repo
    pkg_install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    enable_service docker
    add_user_to_group docker
}

# Optional. Runs after every selected plugin has been installed.
plugin_postinstall() { :; }
```

Group directories are numerically prefixed (`00-base`, `10-browser`, …) and so are files within a
group where order matters. That prefix is only about presentation order; real ordering comes from
`PLUGIN_REQUIRES`, which is topologically sorted before anything runs. Unknown dependencies and
dependency cycles are reported as errors before the first package is installed.

Metadata is read, and plugins are executed, in subshells, so variables and functions from one
plugin can never leak into another. Hatrick's own state uses an `HP_` prefix — the whole `PLUGIN_*`
namespace is yours.

### Helpers available to plugins

Use these instead of calling `dnf`, `rpm`, `curl`, `usermod` or `systemctl` directly; they handle
privilege escalation, the user-vs-root distinction, and logging.

| Helper | Purpose |
| --- | --- |
| `as_root <cmd>` / `as_user <cmd>` | Run with root privileges / as the invoking user |
| `pkg_install`, `pkg_remove`, `pkg_installed`, `pkg_update` | Package operations |
| `add_repofile <url>`, `write_repofile <name> <content>`, `add_repo_rpm <url>`, `import_rpm_key <url>` | Repositories and keys |
| `fetch <url> <dest>` | Download into `$HATRICK_TMP`, cleaned up automatically |
| `install_fonts_from_zip <url> <dir> <glob>...` | Install fonts and refresh the cache |
| `add_user_to_group <group>`, `enable_service <unit>` | System integration |
| `flatpak_install <app-id>`, `ensure_flathub` | Flatpak, in the user's scope |
| `gsettings_set <schema> <key> <value>`, `is_gnome` | GNOME settings, applied to your session |
| `have <cmd>`, `plugin_note <text>` | Command check; queue a message for the final summary |
| `log_info`, `log_ok`, `log_warn`, `log_error` | Output that also lands in the run log |

Useful variables: `$HATRICK_USER`, `$HATRICK_HOME` (the invoking user, never root) and
`$HATRICK_TMP` (scratch space removed when the run ends).

## Layout

```
hatrick              CLI entrypoint
lib/log.sh           output and the run log
lib/system.sh        the helpers plugins are written against
lib/plugin.sh        discovery, metadata, dependency sort, execution
lib/ui.sh            whiptail checklists
plugins/<group>/     one file per tool
```

`whiptail` comes from the `newt` package, which is not on a stock Fedora Workstation; Hatrick
installs it before showing the first menu.
