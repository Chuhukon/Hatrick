# AGENTS.MD

Hatrick is one script (`hatrick`) plus one file per tool in `plugins/`. That is the whole design.

## Keep it stupid simple

This is the rule everything else bends to. Do not over-engineer.

- **No new files in `lib/`.** `lib/` exists for things *every* plugin needs — today that is fonts and
  the theme engine. A helper, wrapper, abstraction or "framework" for one or two plugins does not go
  there; it goes in the plugin, inline. If you think you need a new `lib/*.sh`, ask first.
- **No new layers.** No config files, no plugin manifests, no registries, no state machines, no
  indirection to "make it extensible". Discovery is a glob and the contract is two names
  (`PLUGIN_DESC`, `plugin_install`). Leave it that way.
- **Plain Fedora shell.** `dnf`, `curl`, `rpm`, `systemctl`, `flatpak` — what you would type yourself.
  Repeating three obvious lines in two plugins is better than one clever shared function.
- **The boring option wins.** Prefer the version that a person can read top to bottom and understand
  without jumping between files.

## Scope

Do what was asked, and nothing next to it. No drive-by refactors, no renaming, no "while I was here".
Adding a tool means adding one file under `plugins/<group>/<name>.sh`.

## The rules that are not style

- `sudo` only where root is genuinely needed. `gsettings`, `flatpak --user`, `go install` and
  anything touching `$HOME` must run without it.
- `plugin_detect` must work without sudo — it also runs during `hatrick list`.
- A plugin's own files live in `plugins/<group>/<name>/`, reachable as `$PLUGIN_ASSETS`.
- Pin versions in a variable at the top of the plugin file.
- After changing a shell file, run `bash -n` on it.
- Do not implement duplicate installs, in that case ask where it needs to be part of.

`README.md` is the contract for plugins and themes. If a change makes the README wrong, fix the
README in the same change. Keep language and style of the README short and sweet. Do not add
information that is already in the README or change style of sentences already in the README. A list of plugins is not meant to be part of the README.
