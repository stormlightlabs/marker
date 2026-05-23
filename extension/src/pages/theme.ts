import { createSignal, onMount } from 'solid-js';
import type { AppTheme } from '@/db/settings-repository';
import { MarkerMessageType } from '@/shared/messages';

export const themeLabels: Record<AppTheme, string> = {
  'minimal-light': 'Minimal light',
  'minimal-dark': 'Minimal dark',
  retro: 'Retro',
};

export function themeClass(theme: AppTheme): string {
  return theme === 'retro' ? 'theme-retro' : `theme-${theme}`;
}

export function createAppTheme() {
  const [theme, setTheme] = createSignal<AppTheme>('minimal-light');

  async function loadTheme(): Promise<void> {
    const response: { theme: AppTheme } = await chrome.runtime.sendMessage({ type: MarkerMessageType.GetAppTheme });
    setTheme(response.theme);
  }

  async function saveTheme(nextTheme: AppTheme): Promise<void> {
    setTheme(nextTheme);
    await chrome.runtime.sendMessage({ type: MarkerMessageType.SetAppTheme, theme: nextTheme });
  }

  onMount(() => {
    void loadTheme().catch((error: unknown) => {
      console.debug('Marker could not load theme setting.', error);
    });
  });

  return { theme, saveTheme };
}
