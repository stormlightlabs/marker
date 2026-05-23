import { createSignal, For, onMount, Show } from 'solid-js';
import { appThemes, type AnnotationDisplayMode, type AppTheme, type BookmarkSaveBehavior } from '@/db/settings-repository';
import { MarkerMessageType } from '@/shared/messages';
import type { ActiveTabSummary } from '@/shared/permissions';
import '@/styles/index.css';
import { Brand } from '@/components/Brand';
import { createAppTheme, themeClass, themeLabels } from '@/pages/theme';

const behaviorLabels: Record<BookmarkSaveBehavior, string> = {
  'always-ask': 'Always ask',
  'marker-only': 'Marker only',
  'chrome-only': 'Chrome only',
  both: 'Both',
};

type PermissionStatus = { hasChromeBookmarkPermission: boolean; activeTab: ActiveTabSummary };

function downloadJson(data: unknown, filename: string): void {
  const url = URL.createObjectURL(new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }));
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

async function readJsonFile(file: File): Promise<unknown> {
  return JSON.parse(await file.text()) as unknown;
}

function OptionsHeader() {
  return (
    <header class="app-header">
      <Brand label="Marker Options" />
      <p class="eyebrow">Options</p>
      <h1 class="app-header__title" id="options-title">Extension settings</h1>
      <p class="app-header__description">Configure bookmark saves, permissions, imports, exports, annotation display, and themes.</p>
    </header>
  );
}

function BehaviorButton(props: { activeBehavior: BookmarkSaveBehavior; behavior: BookmarkSaveBehavior; onSelect: () => void }) {
  return <button class={props.activeBehavior === props.behavior ? 'button button--primary' : 'button'} type="button" onClick={props.onSelect}>{behaviorLabels[props.behavior]}</button>;
}

function BookmarkSettingsCard() {
  const [behavior, setBehavior] = createSignal<BookmarkSaveBehavior>('always-ask');

  async function saveBehavior(nextBehavior: BookmarkSaveBehavior): Promise<void> {
    setBehavior(nextBehavior);
    await chrome.runtime.sendMessage({ type: MarkerMessageType.SetBookmarkSaveBehavior, behavior: nextBehavior });
  }

  onMount(() => {
    void chrome.runtime
      .sendMessage({ type: MarkerMessageType.GetBookmarkSaveBehavior })
      .then((response: { behavior: BookmarkSaveBehavior }) => setBehavior(response.behavior))
      .catch((error: unknown) => console.debug('Marker could not load bookmark save behavior.', error));
  });

  return (
    <section class="card" aria-labelledby="bookmark-default-heading">
      <p class="eyebrow">Bookmarking</p>
      <h2 class="card__title" id="bookmark-default-heading">Bookmark save behavior</h2>
      <p class="card__body">Choose the default destination used by the side panel save button.</p>
      <div class="cluster card__body">
        <For each={Object.keys(behaviorLabels) as BookmarkSaveBehavior[]}>
          {(nextBehavior) => <BehaviorButton activeBehavior={behavior()} behavior={nextBehavior} onSelect={() => void saveBehavior(nextBehavior)} />}
        </For>
      </div>
    </section>
  );
}

function PermissionSettingsCard() {
  const [permissionStatus, setPermissionStatus] = createSignal<PermissionStatus>();
  const [status, setStatus] = createSignal<string>();

  async function refresh(): Promise<void> {
    setPermissionStatus(await chrome.runtime.sendMessage({ type: MarkerMessageType.GetPermissionStatus }));
  }

  async function requestChromeBookmarks(): Promise<void> {
    const granted = await chrome.permissions.request({ permissions: ['bookmarks'] });
    setStatus(granted ? 'Chrome bookmark permission granted.' : 'Chrome bookmark permission denied.');
    await refresh();
  }

  async function requestSitePermission(): Promise<void> {
    const activeTab = permissionStatus()?.activeTab;
    if (activeTab?.originPattern == null) {
      setStatus('No supported active tab is available.');
      return;
    }
    const granted = await chrome.permissions.request({ permissions: ['scripting'], origins: [activeTab.originPattern] });
    setStatus(granted ? 'Site permission granted.' : 'Site permission denied.');
    await refresh();
  }

  onMount(() => void refresh().catch((error: unknown) => console.debug('Marker could not load permission status.', error)));

  return (
    <section class="card" aria-labelledby="permission-heading">
      <p class="eyebrow">Permissions</p>
      <h2 class="card__title" id="permission-heading">Permission status</h2>
      <p class="card__body">Chrome bookmarks: {permissionStatus()?.hasChromeBookmarkPermission ? 'granted' : 'not granted'}</p>
      <p class="card__body">Current site: {permissionStatus()?.activeTab.status ?? 'checking'}</p>
      <div class="cluster card__body">
        <button class="button" type="button" onClick={() => void requestChromeBookmarks()}>Enable Chrome bookmarks</button>
        <button class="button" type="button" onClick={() => void requestSitePermission()}>Enable active site</button>
      </div>
      <Show when={status()}><p class="card__body" role="status">{status()}</p></Show>
    </section>
  );
}

function ImportExportSettingsCard() {
  const [status, setStatus] = createSignal<string>();

  async function exportJson(): Promise<void> {
    const data = await chrome.runtime.sendMessage({ type: MarkerMessageType.ExportJson });
    downloadJson(data, `marker-export-${new Date().toISOString().slice(0, 10)}.json`);
    setStatus('Exported Marker JSON.');
  }

  async function importJson(file: File): Promise<void> {
    const response: { ok: true } | { ok: false; reason: string } = await chrome.runtime.sendMessage({
      type: MarkerMessageType.ImportJson,
      data: await readJsonFile(file),
    });
    setStatus(response.ok ? 'Imported Marker JSON.' : response.reason);
  }

  async function importChrome(): Promise<void> {
    if (!(await chrome.permissions.request({ permissions: ['bookmarks'] }))) {
      setStatus('Chrome bookmark permission was not granted.');
      return;
    }
    const response = await chrome.runtime.sendMessage({ type: MarkerMessageType.ImportChromeBookmarks });
    setStatus('reason' in response ? response.reason : `Imported ${response.bookmarks.length} Chrome bookmarks.`);
  }

  return (
    <section class="card" aria-labelledby="import-export-heading">
      <p class="eyebrow">Data</p>
      <h2 class="card__title" id="import-export-heading">Import / export</h2>
      <p class="card__body">Export a mobile-compatible Marker JSON file or import one back into this extension.</p>
      <div class="cluster card__body">
        <button class="button button--primary" type="button" onClick={() => void exportJson()}>Export JSON</button>
        <label class="button" for="options-import-json">Import JSON</label>
        <input id="options-import-json" class="visually-hidden" type="file" accept="application/json" onChange={(event) => {
          const file = event.currentTarget.files?.[0];
          if (file != null) void importJson(file);
        }} />
        <button class="button" type="button" onClick={() => void importChrome()}>Import Chrome bookmarks</button>
      </div>
      <Show when={status()}><p class="card__body" role="status">{status()}</p></Show>
    </section>
  );
}

function AnnotationDisplaySettingsCard() {
  const [mode, setMode] = createSignal<AnnotationDisplayMode>('visible');

  async function saveMode(nextMode: AnnotationDisplayMode): Promise<void> {
    setMode(nextMode);
    await chrome.runtime.sendMessage({ type: MarkerMessageType.SetAnnotationDisplayMode, mode: nextMode });
  }

  onMount(() => {
    void chrome.runtime
      .sendMessage({ type: MarkerMessageType.GetAnnotationDisplayMode })
      .then((response: { mode: AnnotationDisplayMode }) => setMode(response.mode))
      .catch((error: unknown) => console.debug('Marker could not load annotation display settings.', error));
  });

  return (
    <section class="card" aria-labelledby="annotation-display-heading">
      <p class="eyebrow">Annotations</p>
      <h2 class="card__title" id="annotation-display-heading">Display settings</h2>
      <p class="card__body">Choose whether page highlights should be visible by default.</p>
      <div class="cluster card__body">
        <button class={mode() === 'visible' ? 'button button--primary' : 'button'} type="button" onClick={() => void saveMode('visible')}>Visible</button>
        <button class={mode() === 'hidden' ? 'button button--primary' : 'button'} type="button" onClick={() => void saveMode('hidden')}>Hidden</button>
      </div>
    </section>
  );
}

function ThemeButton(props: { activeTheme: AppTheme; theme: AppTheme; onSelect: () => void }) {
  return <button class={props.activeTheme === props.theme ? 'button button--primary' : 'button'} type="button" onClick={props.onSelect}>{themeLabels[props.theme]}</button>;
}

function ThemeSettingsCard(props: { activeTheme: AppTheme; onSelect: (theme: AppTheme) => void }) {
  return (
    <aside class="card theme-swatch" aria-labelledby="theme-heading">
      <p class="eyebrow">Themes</p>
      <h2 class="card__title" id="theme-heading">App theme</h2>
      <p class="card__body">Choose one theme for Options, Library, and the side panel.</p>
      <div class="cluster card__body">
        <For each={appThemes}>{(theme) => <ThemeButton activeTheme={props.activeTheme} theme={theme} onSelect={() => props.onSelect(theme)} />}</For>
      </div>
      <div class="theme-swatch__row" aria-hidden="true">
        <span class="theme-swatch__chip theme-minimal-light"></span>
        <span class="theme-swatch__chip theme-minimal-dark"></span>
        <span class="theme-swatch__chip theme-retro"></span>
      </div>
    </aside>
  );
}

export default function OptionsPage() {
  const appTheme = createAppTheme();

  return (
    <main class={`app-shell app-shell--page ${themeClass(appTheme.theme())}`} aria-labelledby="options-title">
      <OptionsHeader />
      <section class="options-grid" aria-label="Options sections">
        <div class="options-list">
          <BookmarkSettingsCard />
          <PermissionSettingsCard />
          <ImportExportSettingsCard />
          <AnnotationDisplaySettingsCard />
        </div>
        <ThemeSettingsCard activeTheme={appTheme.theme()} onSelect={(theme) => void appTheme.saveTheme(theme)} />
      </section>
    </main>
  );
}
