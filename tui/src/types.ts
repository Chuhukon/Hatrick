export type PluginActionType = 'install' | 'update' | 'remove' | 'none';

export interface PluginMetadata {
  id: string;              // e.g. "docker"
  name: string;            // display name
  category: string;        // formatted group name, e.g. "Development"
  categoryRaw: string;     // raw directory, e.g. "30-development"
  filePath: string;        // absolute path to script
  description: string;     // PLUGIN_DESC
  requires: string[];      // PLUGIN_REQUIRES
  disabled: boolean;       // PLUGIN_DISABLED (opt-in)
  isInstalled: boolean;    // result of plugin_detect
  supportsDetect: boolean; // whether plugin_detect function is declared
  supportsUpdate: boolean; // whether plugin_update function is declared
  supportsRemove: boolean; // whether plugin_remove function is declared
}

export interface StagedAction {
  plugin: PluginMetadata;
  action: PluginActionType;
}

export interface ExecutionStep {
  id: string;
  title: string;
  status: 'pending' | 'running' | 'success' | 'failed';
  error?: string;
}
