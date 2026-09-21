import React from "react";
import type { PluginActionType, PluginMetadata } from "../types";

interface ConfirmModalProps {
  stagedActions: Map<string, PluginActionType>;
  allPlugins: PluginMetadata[];
}

export function ConfirmModal({
  stagedActions,
  allPlugins,
}: ConfirmModalProps) {
  const installs: PluginMetadata[] = [];
  const updates: PluginMetadata[] = [];
  const removes: PluginMetadata[] = [];

  for (const [id, action] of stagedActions.entries()) {
    const p = allPlugins.find((plug) => plug.id === id);
    if (!p) continue;
    if (action === "install") installs.push(p);
    if (action === "update") updates.push(p);
    if (action === "remove") removes.push(p);
  }

  const totalActions = installs.length + updates.length + removes.length;

  return (
    <box
      flexDirection="column"
      width="100%"
      flexGrow={1}
      borderStyle="single"
      borderColor="green"
      title=" Review & Confirmation "
      paddingLeft={2}
      paddingRight={2}
      gap={1}
    >
      <box flexDirection="column">
        <text fg="white">
          <b>Ready to execute {totalActions} staged action(s):</b>
        </text>
        <text fg="gray">
          Please review the operations below before proceeding.
        </text>
      </box>

      {/* Preparation Step */}
      <box flexDirection="column">
        <text fg="cyan">
          <b>1. System Prerequisites</b>
        </text>
        <text fg="white">
          • DNF system packages upgrade & base tools (curl, git, fontconfig, etc.)
        </text>
        <text fg="white">
          • System fonts (Microsoft core fonts, JetBrains Mono, Inter)
        </text>
      </box>

      {/* Installs */}
      {installs.length > 0 && (
        <box flexDirection="column">
          <text fg="cyan">
            <b>2. Plugins to Install ({installs.length}):</b>
          </text>
          {installs.map((p) => (
            <box key={p.id} flexDirection="row" gap={1}>
              <text fg="cyan">✓</text>
              <text fg="white">
                <b>{p.id}</b>
              </text>
              <text fg="gray">- {p.description}</text>
            </box>
          ))}
        </box>
      )}

      {/* Updates */}
      {updates.length > 0 && (
        <box flexDirection="column">
          <text fg="yellow">
            <b>3. Plugins to Update ({updates.length}):</b>
          </text>
          {updates.map((p) => (
            <box key={p.id} flexDirection="row" gap={1}>
              <text fg="yellow">↑</text>
              <text fg="white">
                <b>{p.id}</b>
              </text>
              <text fg="gray">- {p.description}</text>
            </box>
          ))}
        </box>
      )}

      {/* Removes */}
      {removes.length > 0 && (
        <box flexDirection="column">
          <text fg="red">
            <b>4. Plugins to Remove ({removes.length}):</b>
          </text>
          {removes.map((p) => (
            <box key={p.id} flexDirection="row" gap={1}>
              <text fg="red">✗</text>
              <text fg="white">
                <b>{p.id}</b>
              </text>
              <text fg="gray">- {p.description}</text>
            </box>
          ))}
        </box>
      )}

      {/* Actions footer */}
      <box flexDirection="row" gap={2} marginTop={1}>
        <text fg="green">
          <b>[Enter] Proceed to Execution</b>
        </text>
        <text fg="yellow">[Esc / Backspace] Back to Catalog</text>
      </box>
    </box>
  );
}
