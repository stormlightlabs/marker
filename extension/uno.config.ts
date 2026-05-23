import { defineConfig, presetIcons } from 'unocss';

export default defineConfig({
  safelist: [
    'i-lucide-book-open',
    'i-lucide-bookmark',
    'i-lucide-bookmark-plus',
    'i-lucide-check',
    'i-lucide-chevron-right',
    'i-lucide-download',
    'i-lucide-eye',
    'i-lucide-eye-off',
    'i-lucide-file-down',
    'i-lucide-file-up',
    'i-lucide-highlighter',
    'i-lucide-library',
    'i-lucide-link',
    'i-lucide-palette',
    'i-lucide-pencil',
    'i-lucide-settings',
    'i-lucide-shield-check',
    'i-lucide-sticky-note',
    'i-lucide-trash-2',
    'i-lucide-underline',
    'i-lucide-upload',
    'i-lucide-x',
  ],
  presets: [
    presetIcons({
      collections: { lucide: () => import('@iconify-json/lucide/icons.json').then((module) => module.default) },
    }),
  ],
});
