import React from "react";
import { createCliRenderer } from "@opentui/core";
import { createRoot } from "@opentui/react";
import { App } from "./App";

async function main() {
  const renderer = await createCliRenderer();
  const root = createRoot(renderer);

  root.render(
    <App
      onExit={() => {
        renderer.destroy();
        process.exit(0);
      }}
    />
  );
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
