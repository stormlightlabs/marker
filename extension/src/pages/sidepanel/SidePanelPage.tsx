import { createSignal, onMount, Show } from 'solid-js';
import { MarkerMessageType, type MarkerMessageResponse } from '@/shared/messages';
import type { ActiveTabSummary } from '@/shared/permissions';
import '@/styles/index.css';

function openExtensionPage(type: MarkerMessageType.OpenLibrary | MarkerMessageType.OpenOptions): void {
  void chrome.runtime.sendMessage({ type });
}

async function fetchActiveTabSummary(): Promise<ActiveTabSummary> {
  return chrome.runtime.sendMessage({ type: MarkerMessageType.GetActiveTabSummary });
}

async function requestSitePermissions(summary: ActiveTabSummary): Promise<boolean> {
  if (summary.originPattern == null) {
    return false;
  }

  return chrome.permissions.request({ permissions: ['scripting'], origins: [summary.originPattern] });
}

async function injectContentRuntime(
  tabId: number,
): Promise<MarkerMessageResponse<{ type: MarkerMessageType.EnableSite; tabId: number }>> {
  return chrome.runtime.sendMessage({ type: MarkerMessageType.EnableSite, tabId });
}

function permissionStatus(summary: ActiveTabSummary | undefined): string {
  if (summary == null) {
    return 'Checking this tab…';
  }

  if (summary.status === 'enabled') {
    return 'Marker is enabled for this site.';
  }

  if (summary.status === 'needs-permission') {
    return `Enable Marker for ${summary.origin ?? 'this site'} to capture highlights and notes.`;
  }

  return summary.reason ?? 'Marker cannot annotate this page.';
}

function SidePanelPage() {
  const [summary, setSummary] = createSignal<ActiveTabSummary>();
  const [isEnabling, setIsEnabling] = createSignal(false);
  const [error, setError] = createSignal<string>();

  async function refreshSummary(): Promise<void> {
    setSummary(await fetchActiveTabSummary());
  }

  async function enableSite(): Promise<void> {
    const activeSummary = summary();
    if (activeSummary?.tabId == null) {
      setError('Marker cannot find an active tab to enable.');
      return;
    }

    setIsEnabling(true);
    setError(undefined);

    try {
      const granted = await requestSitePermissions(activeSummary);
      if (!granted) {
        setError('Site permission was not granted.');
        return;
      }

      const response = await injectContentRuntime(activeSummary.tabId);
      if (!response.ok) {
        setError(response.reason);
        return;
      }

      await refreshSummary();
    } catch (caughtError) {
      console.debug('Marker could not enable this site from the side panel.', caughtError);
      setError('Marker could not enable this site.');
    } finally {
      setIsEnabling(false);
    }
  }

  onMount(() => {
    void refreshSummary().catch((caughtError: unknown) => {
      console.debug('Marker could not load the active tab summary.', caughtError);
      setError('Marker could not read the active tab.');
    });
  });

  return (
    <main class="app-shell side-panel-shell theme-minimal-dark" aria-labelledby="side-panel-title">
      <header class="app-header card card--accent">
        <div class="brand-lockup" aria-label="Marker for Chrome">
          <span class="brand-mark" aria-hidden="true">
            M
          </span>
          <span class="wordmark">Marker</span>
        </div>
        <p class="eyebrow">Chrome side panel</p>
        <h1 class="app-header__title" id="side-panel-title">
          Bookmarks and annotations for this page
        </h1>
        <p class="app-header__description">
          The side panel will manage the active tab, site permissions, page bookmarks, and current-page annotations.
        </p>
      </header>

      <nav class="side-panel-tabs" aria-label="Marker sections">
        <button class="button button--primary" type="button" aria-current="page">
          Page
        </button>
        <button class="button" type="button">
          Bookmarks
        </button>
        <button class="button" type="button">
          Notes
        </button>
      </nav>

      <section class="card" aria-labelledby="current-page-heading">
        <h2 class="card__title" id="current-page-heading">
          Current page
        </h2>
        <p class="card__body">{permissionStatus(summary())}</p>
        <Show when={summary()?.title || summary()?.url}>
          <p class="card__body muted">{summary()?.title ?? summary()?.url}</p>
        </Show>
        <Show when={error()}>
          <p class="card__body" role="alert">
            {error()}
          </p>
        </Show>
        <div class="side-panel-actions card__body">
          <button
            class="button button--primary"
            type="button"
            disabled={summary()?.status !== 'needs-permission' || isEnabling()}
            onClick={() => void enableSite()}>
            <Show
              when={isEnabling()}
              fallback={
                <Show when={summary()?.status === 'enabled'} fallback="Enable site">
                  Site enabled
                </Show>
              }>
              Enabling…
            </Show>
          </button>
          <button class="button" type="button" disabled={summary()?.status === 'unsupported'}>
            Save bookmark
          </button>
        </div>
      </section>

      <section class="side-panel-preview-list" aria-label="Current page annotations">
        <article class="card quote-card">
          <p class="eyebrow">Highlight · 2 min ago</p>
          <blockquote>Local-first tools win when the capture surface is already where attention lives.</blockquote>
        </article>
        <article class="card quote-card">
          <p class="eyebrow">Note · Product</p>
          <blockquote>Same selectors as mobile, different shell.</blockquote>
        </article>
      </section>

      <section class="card" aria-labelledby="quick-actions-heading">
        <h2 class="card__title" id="quick-actions-heading">
          Quick actions
        </h2>
        <div class="side-panel-actions card__body">
          <button class="button" type="button" onClick={() => openExtensionPage(MarkerMessageType.OpenLibrary)}>
            Open Library
          </button>
          <button class="button" type="button" onClick={() => openExtensionPage(MarkerMessageType.OpenOptions)}>
            Open Options
          </button>
        </div>
      </section>
    </main>
  );
}

export default SidePanelPage;
