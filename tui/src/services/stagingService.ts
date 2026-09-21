import type { PluginActionType, PluginMetadata } from "../types";

export interface StagingResult {
  nextStaged: Map<string, PluginActionType>;
  autoStagedDeps: string[];
  warning?: string;
}

/**
 * Stage an action for a plugin and resolve any dependencies.
 */
export function stagePluginAction(
  currentStaged: Map<string, PluginActionType>,
  plugin: PluginMetadata,
  action: PluginActionType,
  allPlugins: PluginMetadata[]
): StagingResult {
  const next = new Map(currentStaged);
  const autoStagedDeps: string[] = [];

  if (action === "none") {
    next.delete(plugin.id);
    return { nextStaged: next, autoStagedDeps };
  }

  if (action === "remove" && !plugin.supportsRemove) {
    return {
      nextStaged: next,
      autoStagedDeps,
      warning: `Plugin '${plugin.id}' does not support automated removal.`,
    };
  }

  next.set(plugin.id, action);

  // If staging for install or update, inspect requirements
  if (action === "install" || action === "update") {
    for (const reqId of plugin.requires) {
      const depPlugin = allPlugins.find((p) => p.id === reqId);
      if (!depPlugin) continue;

      // If dependency is not already installed and not currently staged, auto-stage for install
      const currentDepAction = next.get(reqId);
      if (!depPlugin.isInstalled && (!currentDepAction || currentDepAction === "none")) {
        next.set(reqId, "install");
        autoStagedDeps.push(reqId);
      }
    }
  }

  return { nextStaged: next, autoStagedDeps };
}

/**
 * Toggle default action for a plugin.
 * If installed: toggles between 'update' (or 'none') and 'none'.
 * If uninstalled: toggles between 'install' and 'none'.
 */
export function togglePluginAction(
  currentStaged: Map<string, PluginActionType>,
  plugin: PluginMetadata,
  allPlugins: PluginMetadata[]
): StagingResult {
  const current = currentStaged.get(plugin.id);
  if (current && current !== "none") {
    return stagePluginAction(currentStaged, plugin, "none", allPlugins);
  }

  const targetAction: PluginActionType = plugin.isInstalled ? "update" : "install";
  return stagePluginAction(currentStaged, plugin, targetAction, allPlugins);
}

/**
 * Stage all uninstalled, non-opt-in plugins for install.
 */
export function stageAllDefaultMissing(
  currentStaged: Map<string, PluginActionType>,
  allPlugins: PluginMetadata[]
): Map<string, PluginActionType> {
  const next = new Map(currentStaged);
  for (const p of allPlugins) {
    if (!p.isInstalled && !p.disabled) {
      next.set(p.id, "install");
    }
  }
  return next;
}

/**
 * Stage all plugins that are not installed (including opt-in).
 */
export function stageAllMissing(allPlugins: PluginMetadata[]): Map<string, PluginActionType> {
  const next = new Map<string, PluginActionType>();
  for (const p of allPlugins) {
    if (!p.isInstalled) {
      next.set(p.id, "install");
    }
  }
  return next;
}

/**
 * Clear all staged actions.
 */
export function clearAllStaged(): Map<string, PluginActionType> {
  return new Map<string, PluginActionType>();
}
