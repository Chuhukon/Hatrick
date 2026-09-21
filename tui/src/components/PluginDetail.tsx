import React from "react";
import type { PluginActionType, PluginMetadata } from "../types";

interface PluginDetailProps {
  plugin: PluginMetadata | null;
  stagedAction?: PluginActionType;
  allPlugins: PluginMetadata[];
}

export function PluginDetail({
  plugin,
  stagedAction = "none",
  allPlugins,
}: PluginDetailProps) {
  if (!plugin) {
    return (
      <box
        flexDirection="column"
        width={40}
        borderStyle="single"
        borderColor="gray"
        title=" Plugin Details "
        paddingLeft={1}
        paddingRight={1}
      >
        <text fg="gray">Select a plugin to view details</text>
      </box>
    );
  }

  return (
    <box
      flexDirection="column"
      width={42}
      borderStyle="single"
      borderColor="yellow"
      title=" Plugin Details "
      paddingLeft={1}
      paddingRight={1}
      gap={1}
    >
      <box flexDirection="column">
        <box flexDirection="row" gap={1}>
          <text fg="white">
            <b>{plugin.id}</b>
          </text>
          <text fg="gray">({plugin.category})</text>
        </box>
        <text fg="cyan">{plugin.description}</text>
      </box>

      <box flexDirection="column">
        <text fg="gray">
          <b>Status:</b>
        </text>
        <box flexDirection="row" gap={1}>
          {plugin.isInstalled ? (
            <text fg="green">
              <b>[✓] Installed on system</b>
            </text>
          ) : (
            <text fg="yellow">[ ] Not installed</text>
          )}
          {plugin.disabled && <text fg="magenta">(opt-in)</text>}
        </box>
      </box>

      <box flexDirection="column">
        <text fg="gray">
          <b>Staged Action:</b>
        </text>
        <box flexDirection="row" gap={1}>
          {stagedAction === "install" && (
            <text fg="cyan">
              <b>▶ INSTALL</b>
            </text>
          )}
          {stagedAction === "update" && (
            <text fg="yellow">
              <b>▶ UPDATE</b>
            </text>
          )}
          {stagedAction === "remove" && (
            <text fg="red">
              <b>▶ REMOVE</b>
            </text>
          )}
          {stagedAction === "none" && <text fg="gray">None</text>}
        </box>
      </box>

      <box flexDirection="column">
        <text fg="gray">
          <b>Action Capabilities:</b>
        </text>
        <box flexDirection="column">
          <box flexDirection="row" gap={1}>
            <text fg="white">• Install:</text>
            <text fg="green">Ready</text>
          </box>
          <box flexDirection="row" gap={1}>
            <text fg="white">• Update:</text>
            <text fg={plugin.supportsUpdate ? "green" : "cyan"}>
              {plugin.supportsUpdate ? "Custom hook" : "Install fallback"}
            </text>
          </box>
          <box flexDirection="row" gap={1}>
            <text fg="white">• Remove:</text>
            <text fg={plugin.supportsRemove ? "green" : "gray"}>
              {plugin.supportsRemove ? "Supported" : "Not supported"}
            </text>
          </box>
        </box>
      </box>

      {plugin.requires.length > 0 && (
        <box flexDirection="column">
          <text fg="gray">
            <b>Requirements:</b>
          </text>
          {plugin.requires.map((req) => {
            const reqP = allPlugins.find((p) => p.id === req);
            const isReqInst = reqP?.isInstalled;
            return (
              <box key={req} flexDirection="row" gap={1}>
                <text fg="white">↳ {req}</text>
                <text fg={isReqInst ? "green" : "yellow"}>
                  {isReqInst ? "(installed)" : "(missing, will stage)"}
                </text>
              </box>
            );
          })}
        </box>
      )}

      <box flexDirection="column">
        <text fg="gray">
          <b>Keyboard Controls:</b>
        </text>
        <text fg="gray">[Space / i] Toggle Install</text>
        <text fg="gray">[u] Stage Update</text>
        <text fg={plugin.supportsRemove ? "gray" : "gray"}>
          [r] Stage Remove {plugin.supportsRemove ? "" : "(disabled)"}
        </text>
        <text fg="gray">[c] Clear Staged Action</text>
      </box>
    </box>
  );
}
