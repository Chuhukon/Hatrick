import React, { useEffect, useState } from "react";
import { useKeyboard, useAppContext } from "@opentui/react";
import type { PluginActionType, PluginMetadata } from "./types";
import { loadAllPlugins } from "./services/pluginLoader";
import {
  stagePluginAction,
  togglePluginAction,
  stageAllDefaultMissing,
  clearAllStaged,
} from "./services/stagingService";
import { Header } from "./components/Header";
import { PluginCatalog } from "./components/PluginCatalog";
import { PluginDetail } from "./components/PluginDetail";
import { ConfirmModal } from "./components/ConfirmModal";
import { ExecutionView } from "./components/ExecutionView";

export type ViewMode = "browse" | "confirm" | "executing" | "finished";

interface AppProps {
  onExit?: () => void;
  initialView?: ViewMode;
}

export function App({ onExit, initialView = "browse" }: AppProps) {
  const { renderer } = useAppContext();
  const [plugins, setPlugins] = useState<PluginMetadata[]>([]);
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState<ViewMode>(initialView);

  const [activeCategoryIndex, setActiveCategoryIndex] = useState(0);
  const [selectedPluginIndex, setSelectedPluginIndex] = useState(0);
  const [activePane, setActivePane] = useState<"categories" | "plugins">("plugins");
  const [stagedActions, setStagedActions] = useState<Map<string, PluginActionType>>(
    new Map()
  );
  const [notification, setNotification] = useState<string | null>(null);

  // Load plugins on mount
  useEffect(() => {
    loadAllPlugins()
      .then((loaded) => {
        setPlugins(loaded);
        // Stage missing plugins by default (matching hatrick classic behavior)
        const initialStaged = stageAllDefaultMissing(new Map(), loaded);
        setStagedActions(initialStaged);
        setLoading(false);
      })
      .catch((err) => {
        setNotification(`Error loading plugins: ${String(err)}`);
        setLoading(false);
      });
  }, []);

  // Compute categories
  const categories = ["All", ...Array.from(new Set(plugins.map((p) => p.category)))];
  const activeCategory = categories[activeCategoryIndex] || "All";

  // Filter plugins by active category
  const filteredPlugins =
    activeCategory === "All"
      ? plugins
      : plugins.filter((p) => p.category === activeCategory);

  const currentPlugin = filteredPlugins[selectedPluginIndex] || null;

  // Notification auto-clear timer
  useEffect(() => {
    if (!notification) return;
    const timer = setTimeout(() => setNotification(null), 4000);
    return () => clearTimeout(timer);
  }, [notification]);

  // Keyboard controls
  useKeyboard((event) => {
    // Global quit
    if ((event.ctrl && event.name === "c") || (view === "browse" && event.name === "q")) {
      if (onExit) onExit();
      else if (renderer) renderer.destroy();
      else process.exit(0);
      return;
    }

    if (view === "browse") {
      // Tab or Left/Right pane switching
      if (event.name === "tab" || event.name === "left" || event.name === "right") {
        setActivePane((prev) => (prev === "categories" ? "plugins" : "categories"));
        return;
      }

      // Up / Down navigation
      if (event.name === "up") {
        if (activePane === "categories") {
          setActiveCategoryIndex((prev) => (prev > 0 ? prev - 1 : categories.length - 1));
          setSelectedPluginIndex(0);
        } else {
          setSelectedPluginIndex((prev) => (prev > 0 ? prev - 1 : filteredPlugins.length - 1));
        }
        return;
      }

      if (event.name === "down") {
        if (activePane === "categories") {
          setActiveCategoryIndex((prev) => (prev < categories.length - 1 ? prev + 1 : 0));
          setSelectedPluginIndex(0);
        } else {
          setSelectedPluginIndex((prev) => (prev < filteredPlugins.length - 1 ? prev + 1 : 0));
        }
        return;
      }

      // Action staging
      if (currentPlugin) {
        if (event.name === "space" || event.name === "i") {
          const res = togglePluginAction(stagedActions, currentPlugin, plugins);
          setStagedActions(res.nextStaged);
          if (res.autoStagedDeps.length > 0) {
            setNotification(`Auto-staged requirement(s): ${res.autoStagedDeps.join(", ")}`);
          }
          return;
        }

        if (event.name === "u") {
          const res = stagePluginAction(stagedActions, currentPlugin, "update", plugins);
          setStagedActions(res.nextStaged);
          if (res.autoStagedDeps.length > 0) {
            setNotification(`Auto-staged requirement(s): ${res.autoStagedDeps.join(", ")}`);
          }
          return;
        }

        if (event.name === "r") {
          const res = stagePluginAction(stagedActions, currentPlugin, "remove", plugins);
          if (res.warning) {
            setNotification(res.warning);
          } else {
            setStagedActions(res.nextStaged);
          }
          return;
        }

        if (event.name === "c") {
          const res = stagePluginAction(stagedActions, currentPlugin, "none", plugins);
          setStagedActions(res.nextStaged);
          return;
        }
      }

      // Batch shortcuts
      if (event.name === "a") {
        const next = stageAllDefaultMissing(stagedActions, plugins);
        setStagedActions(next);
        setNotification("Staged all default missing plugins for installation");
        return;
      }

      if (event.name === "n") {
        setStagedActions(clearAllStaged());
        setNotification("Cleared all staged actions");
        return;
      }

      // Proceed to confirm
      if (event.name === "return") {
        if (stagedActions.size > 0) {
          setView("confirm");
        } else {
          setNotification("No actions staged. Select plugins with [Space] or [i] first.");
        }
        return;
      }
    } else if (view === "confirm") {
      if (event.name === "return") {
        setView("executing");
        return;
      }

      if (event.name === "escape" || event.name === "backspace" || event.name === "q") {
        setView("browse");
        return;
      }
    }
  });

  const installedCount = plugins.filter((p) => p.isInstalled).length;

  if (loading) {
    return (
      <box flexDirection="column" padding={2}>
        <text fg="cyan">
          <b>Scanning plugins and evaluating system state...</b>
        </text>
      </box>
    );
  }

  return (
    <box flexDirection="column" width="100%" height="100%">
      {/* Top Header */}
      <Header
        totalCount={plugins.length}
        installedCount={installedCount}
        stagedCount={stagedActions.size}
        activeCategory={activeCategory}
      />

      {/* Main Content Area */}
      {view === "browse" && (
        <box flexDirection="row" flexGrow={1} width="100%">
          <PluginCatalog
            categories={categories}
            activeCategoryIndex={activeCategoryIndex}
            plugins={filteredPlugins}
            selectedIndex={selectedPluginIndex}
            stagedActions={stagedActions}
            activePane={activePane}
          />

          <PluginDetail
            plugin={currentPlugin}
            stagedAction={currentPlugin ? stagedActions.get(currentPlugin.id) : undefined}
            allPlugins={plugins}
          />
        </box>
      )}

      {view === "confirm" && (
        <ConfirmModal stagedActions={stagedActions} allPlugins={plugins} />
      )}

      {view === "executing" && (
        <ExecutionView
          stagedActions={stagedActions}
          allPlugins={plugins}
          onFinish={() => {
            if (onExit) onExit();
            else if (renderer) renderer.destroy();
            else process.exit(0);
          }}
        />
      )}

      {/* Bottom Notification or Controls Bar */}
      <box
        flexDirection="row"
        width="100%"
        borderStyle="single"
        borderColor="gray"
        paddingLeft={1}
        paddingRight={1}
      >
        {notification ? (
          <text fg="yellow">
            <b>ℹ {notification}</b>
          </text>
        ) : (
          <box flexDirection="row" gap={2}>
            <text fg="gray">[↑/↓] Navigate</text>
            <text fg="gray">[Tab] Switch Pane</text>
            <text fg="cyan">[Space/i] Install</text>
            <text fg="yellow">[u] Update</text>
            <text fg="red">[r] Remove</text>
            <text fg="white">[a] All / [n] None</text>
            <text fg="green">
              <b>[Enter] Review ({stagedActions.size})</b>
            </text>
            <text fg="gray">[q] Quit</text>
          </box>
        )}
      </box>
    </box>
  );
}
