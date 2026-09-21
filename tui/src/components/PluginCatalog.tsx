import React from "react";
import type { PluginActionType, PluginMetadata } from "../types";

interface PluginCatalogProps {
  categories: string[];
  activeCategoryIndex: number;
  plugins: PluginMetadata[];
  selectedIndex: number;
  stagedActions: Map<string, PluginActionType>;
  activePane: "categories" | "plugins";
  maxVisibleItems?: number;
}

export function PluginCatalog({
  categories,
  activeCategoryIndex,
  plugins,
  selectedIndex,
  stagedActions,
  activePane,
  maxVisibleItems = 16,
}: PluginCatalogProps) {
  // Windowing for plugins list
  const halfVisible = Math.floor(maxVisibleItems / 2);
  let startIndex = Math.max(0, selectedIndex - halfVisible);
  let endIndex = Math.min(plugins.length, startIndex + maxVisibleItems);
  if (endIndex - startIndex < maxVisibleItems && startIndex > 0) {
    startIndex = Math.max(0, endIndex - maxVisibleItems);
  }

  const visiblePlugins = plugins.slice(startIndex, endIndex);

  return (
    <box flexDirection="row" flexGrow={1} width="100%">
      {/* Categories Sidebar */}
      <box
        flexDirection="column"
        width={22}
        borderStyle="single"
        borderColor={activePane === "categories" ? "cyan" : "gray"}
        title=" Categories "
        paddingLeft={1}
        paddingRight={1}
      >
        {categories.map((cat, idx) => {
          const isCatSelected = idx === activeCategoryIndex;
          return (
            <box key={cat} flexDirection="row" gap={1}>
              <text fg={isCatSelected ? "cyan" : "gray"}>
                {isCatSelected ? "▶" : " "}
              </text>
              <text fg={isCatSelected ? "white" : "gray"}>
                {isCatSelected ? <b>{cat}</b> : cat}
              </text>
            </box>
          );
        })}
      </box>

      {/* Main Plugin List */}
      <box
        flexDirection="column"
        flexGrow={1}
        borderStyle="single"
        borderColor={activePane === "plugins" ? "cyan" : "gray"}
        title={` Plugins (${plugins.length}) `}
        paddingLeft={1}
        paddingRight={1}
      >
        {visiblePlugins.length === 0 ? (
          <text fg="gray">No plugins found in this category.</text>
        ) : (
          visiblePlugins.map((plugin, vIdx) => {
            const actualIndex = startIndex + vIdx;
            const isSelected = actualIndex === selectedIndex;
            const action = stagedActions.get(plugin.id);

            return (
              <box key={plugin.id} flexDirection="row" gap={1}>
                <text fg={isSelected ? "cyan" : "gray"}>
                  {isSelected ? "▶" : " "}
                </text>

                {/* Installed Indicator */}
                <text fg={plugin.isInstalled ? "green" : "gray"}>
                  {plugin.isInstalled ? "[✓]" : "[ ]"}
                </text>

                {/* Plugin ID */}
                <box width={18}>
                  <text fg={isSelected ? "white" : "gray"}>
                    {isSelected ? <b>{plugin.id}</b> : plugin.id}
                  </text>
                </box>

                {/* Staged Action Badge */}
                <box width={10}>
                  {action === "install" && (
                    <text fg="cyan">
                      <b>[INSTALL]</b>
                    </text>
                  )}
                  {action === "update" && (
                    <text fg="yellow">
                      <b>[UPDATE]</b>
                    </text>
                  )}
                  {action === "remove" && (
                    <text fg="red">
                      <b>[REMOVE]</b>
                    </text>
                  )}
                  {!action && plugin.disabled && (
                    <text fg="magenta">(opt-in)</text>
                  )}
                </box>

                {/* Description */}
                <box flexGrow={1}>
                  <text fg={isSelected ? "white" : "gray"}>
                    {plugin.description}
                  </text>
                </box>
              </box>
            );
          })
        )}
      </box>
    </box>
  );
}
