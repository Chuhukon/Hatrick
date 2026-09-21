import React from "react";

interface HeaderProps {
  totalCount: number;
  installedCount: number;
  stagedCount: number;
  activeCategory: string;
}

export function Header({
  totalCount,
  installedCount,
  stagedCount,
  activeCategory,
}: HeaderProps) {
  const missingCount = totalCount - installedCount;

  return (
    <box
      flexDirection="row"
      width="100%"
      borderStyle="single"
      borderColor="cyan"
      paddingLeft={1}
      paddingRight={1}
    >
      <box flexDirection="column" flexGrow={1}>
        <box flexDirection="row" gap={1}>
          <text fg="cyan">
            <b>⚡ HATRICK</b>
          </text>
          <text fg="gray">|</text>
          <text fg="white">Opinionated Fedora Setup</text>
          <text fg="gray">({activeCategory})</text>
        </box>
      </box>

      <box flexDirection="row" gap={2}>
        <box flexDirection="row" gap={1}>
          <text fg="gray">Total:</text>
          <text fg="white">
            <b>{totalCount}</b>
          </text>
        </box>
        <box flexDirection="row" gap={1}>
          <text fg="gray">Installed:</text>
          <text fg="green">
            <b>{installedCount}</b>
          </text>
        </box>
        <box flexDirection="row" gap={1}>
          <text fg="gray">Missing:</text>
          <text fg="yellow">
            <b>{missingCount}</b>
          </text>
        </box>
        <box flexDirection="row" gap={1}>
          <text fg="gray">Staged:</text>
          <text fg={stagedCount > 0 ? "cyan" : "gray"}>
            <b>{stagedCount}</b>
          </text>
        </box>
      </box>
    </box>
  );
}
