import { readdirSync, statSync, existsSync } from "fs";
import { join, resolve, basename, dirname } from "path";
import { spawn } from "child_process";
import type { PluginMetadata } from "../types";

/**
 * Locate Hatrick root directory.
 */
export function findHatrickRoot(): string {
  if (process.env.HATRICK_ROOT && existsSync(process.env.HATRICK_ROOT)) {
    return resolve(process.env.HATRICK_ROOT);
  }

  // Check current working directory
  const cwd = process.cwd();
  if (existsSync(join(cwd, "plugins")) && existsSync(join(cwd, "lib"))) {
    return cwd;
  }

  // Check parent of tui directory
  const parent = resolve(cwd, "..");
  if (existsSync(join(parent, "plugins")) && existsSync(join(parent, "lib"))) {
    return parent;
  }

  // Check relative to executable or module location
  if (typeof import.meta.dir === "string") {
    const fromMeta = resolve(import.meta.dir, "../../");
    if (existsSync(join(fromMeta, "plugins")) && existsSync(join(fromMeta, "lib"))) {
      return fromMeta;
    }
  }

  const fromExec = resolve(process.execPath, "../../");
  if (existsSync(join(fromExec, "plugins")) && existsSync(join(fromExec, "lib"))) {
    return fromExec;
  }

  return cwd;
}

/**
 * Format category directory name to display title.
 * e.g. "00-system" -> "System", "20-webapps" -> "Webapps", "theme" -> "Theme"
 */
export function formatCategory(dirName: string): string {
  let cleaned = dirName.replace(/^[0-9]+-/, "");
  if (!cleaned) cleaned = dirName;
  return cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
}

/**
 * Format plugin file name to plugin id.
 * e.g. "00-ssh-key.sh" -> "ssh-key", "docker.sh" -> "docker"
 */
export function formatPluginId(fileName: string): string {
  let base = basename(fileName, ".sh");
  base = base.replace(/^[0-9]+-/, "");
  return base;
}

/**
 * Discover all plugin files sorted in execution order.
 */
export function discoverPluginFiles(hatrickRoot: string): { filePath: string; categoryRaw: string; category: string; id: string }[] {
  const pluginsDir = join(hatrickRoot, "plugins");
  if (!existsSync(pluginsDir)) return [];

  const results: { filePath: string; categoryRaw: string; category: string; id: string }[] = [];
  const categoryDirs = readdirSync(pluginsDir).sort();

  for (const catDir of categoryDirs) {
    const catPath = join(pluginsDir, catDir);
    if (!statSync(catPath).isDirectory()) continue;

    const files = readdirSync(catPath).sort();
    for (const f of files) {
      if (f.endsWith(".sh")) {
        const filePath = join(catPath, f);
        results.push({
          filePath,
          categoryRaw: catDir,
          category: formatCategory(catDir),
          id: formatPluginId(f),
        });
      }
    }
  }

  return results;
}

/**
 * Probe a single plugin using a bash subshell to extract metadata and detect status.
 */
export function probePlugin(
  pluginInfo: { filePath: string; categoryRaw: string; category: string; id: string },
  hatrickRoot: string
): Promise<PluginMetadata> {
  return new Promise((resolveResult) => {
    const { filePath, categoryRaw, category, id } = pluginInfo;
    const assetsPath = filePath.endsWith(".sh") ? filePath.slice(0, -3) : filePath;

    // Bash probe script to evaluate metadata and detect hooks
    const script = `
ROOT="${hatrickRoot}"
for _lib in "$ROOT"/lib/*.sh; do
  [ -f "$_lib" ] && . "$_lib"
done
unset _lib

PLUGIN_ASSETS="${assetsPath}"
# shellcheck source=/dev/null
. "${filePath}" >/dev/null 2>&1

has_detect=0
has_update=0
has_remove=0
is_installed=0

if declare -F plugin_detect >/dev/null; then
  has_detect=1
  if plugin_detect >/dev/null 2>&1; then
    is_installed=1
  fi
fi

if declare -F plugin_update >/dev/null; then
  has_update=1
fi

if declare -F plugin_remove >/dev/null; then
  has_remove=1
fi

p_off=0
case "\${PLUGIN_DISABLED:-}" in
  1|[Tt][Rr][Uu][Ee]) p_off=1 ;;
  *) p_off=0 ;;
esac

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s" \
  "\${PLUGIN_DESC:-}" \
  "\${PLUGIN_REQUIRES:-}" \
  "$p_off" \
  "$is_installed" \
  "$has_detect" \
  "$has_update" \
  "$has_remove"
`;

    const proc = spawn("bash", ["-c", script], {
      env: { ...process.env, HATRICK_ROOT: hatrickRoot },
    });

    let stdout = "";
    proc.stdout.on("data", (d) => {
      stdout += d.toString();
    });

    proc.on("close", () => {
      const parts = stdout.split("\t");
      const desc = parts[0] || id;
      const reqStr = parts[1] || "";
      const off = parts[2] === "1";
      const isInst = parts[3] === "1";
      const hasDet = parts[4] === "1";
      const hasUpd = parts[5] === "1";
      const hasRem = parts[6] === "1";

      const requires = reqStr
        .split(/\s+/)
        .map((r) => r.trim())
        .filter(Boolean);

      resolveResult({
        id,
        name: id,
        category,
        categoryRaw,
        filePath,
        description: desc,
        requires,
        disabled: off,
        isInstalled: isInst,
        supportsDetect: hasDet,
        supportsUpdate: hasUpd,
        supportsRemove: hasRem,
      });
    });

    proc.on("error", () => {
      resolveResult({
        id,
        name: id,
        category,
        categoryRaw,
        filePath,
        description: id,
        requires: [],
        disabled: false,
        isInstalled: false,
        supportsDetect: false,
        supportsUpdate: false,
        supportsRemove: false,
      });
    });
  });
}

/**
 * Load and probe all plugins in the Hatrick repository.
 */
export async function loadAllPlugins(hatrickRoot?: string): Promise<PluginMetadata[]> {
  const root = hatrickRoot || findHatrickRoot();
  const files = discoverPluginFiles(root);
  const plugins = await Promise.all(files.map((f) => probePlugin(f, root)));
  return plugins;
}
