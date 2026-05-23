import { defineManifest } from '@crxjs/vite-plugin';
import pkg from './package.json';

const sidePanelPath = 'src/pages/sidepanel/index.html';
const extensionIcons = {
  16: 'public/logo-16.png',
  32: 'public/logo-32.png',
  48: 'public/logo-48.png',
  128: 'public/logo-128.png',
};

export default defineManifest({
  manifest_version: 3,
  name: 'Marker',
  version: pkg.version,
  description: 'Bookmark and annotate the web.',
  icons: extensionIcons,
  action: { default_icon: extensionIcons, default_title: 'Marker' },
  permissions: ['activeTab', 'sidePanel', 'storage', 'tabs'],
  optional_permissions: ['bookmarks', 'scripting'],
  optional_host_permissions: ['http://*/*', 'https://*/*'],
  content_scripts: [{ matches: ['http://*/*', 'https://*/*'], js: ['src/content/main.ts'], run_at: 'document_idle' }],
  side_panel: { default_path: sidePanelPath },
  options_ui: { page: 'src/pages/options/index.html', open_in_tab: true },
  background: { service_worker: 'src/background/main.ts', type: 'module' },
});
