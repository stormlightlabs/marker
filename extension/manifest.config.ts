import { defineManifest } from '@crxjs/vite-plugin';
import pkg from './package.json';

const sidePanelPath = 'src/pages/sidepanel/index.html';

export default defineManifest({
  manifest_version: 3,
  name: 'Marker',
  version: pkg.version,
  description: 'Local-first bookmarks, highlights, underlines, and notes for web pages.',
  icons: { 48: 'public/logo.png' },
  action: { default_icon: { 48: 'public/logo.png' }, default_title: 'Marker' },
  permissions: ['sidePanel', 'storage'],
  optional_permissions: ['bookmarks'],
  optional_host_permissions: ['http://*/*', 'https://*/*'],
  side_panel: { default_path: sidePanelPath },
  options_ui: { page: 'src/pages/options/index.html', open_in_tab: true },
  background: { service_worker: 'src/background/main.ts', type: 'module' },
});
