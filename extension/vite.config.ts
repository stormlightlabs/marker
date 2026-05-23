import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crx } from '@crxjs/vite-plugin';
import UnoCSS from 'unocss/vite';
import { defineConfig, type PluginOption } from 'vite';
import solid from 'vite-plugin-solid';
import zip from 'vite-plugin-zip-pack';
import manifest from './manifest.config.ts';
import { name, version } from './package.json';

const extensionRoot = fileURLToPath(new URL('.', import.meta.url));

export default defineConfig({
  resolve: { alias: { '@': path.resolve(extensionRoot, 'src') } },
  plugins: [
    UnoCSS() as unknown as PluginOption,
    solid(),
    crx({ manifest }),
    zip({ outDir: 'release', outFileName: `crx-${name}-${version}.zip` }),
  ],
  build: {
    rollupOptions: {
      input: {
        sidepanel: path.resolve(extensionRoot, 'src/pages/sidepanel/index.html'),
        library: path.resolve(extensionRoot, 'src/pages/library/index.html'),
        options: path.resolve(extensionRoot, 'src/pages/options/index.html'),
      },
    },
  },
  server: { cors: { origin: [/chrome-extension:\/\//] } },
});
