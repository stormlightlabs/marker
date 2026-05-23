import { createMemo, createSignal, For, onCleanup, onMount, Show } from 'solid-js';
import { type BookmarkSaveDestination } from '@/background/bookmark-save-service';
import type { AnnotationWithParts } from '@/db/annotation-repository';
import type { BookmarkSaveBehavior } from '@/db/settings-repository';
import {
  MarkerMessageType,
  type CurrentPageState,
  type MarkerMessageResponse,
  type ScrollToAnnotationMessage,
} from '@/shared/messages';
import type { ActiveTabSummary } from '@/shared/permissions';
import '@/styles/index.css';
import { Brand } from '@/components/Brand';
import { IconButton } from '@/components/IconButton';
type SidePanelSection = 'page' | 'bookmarks' | 'annotations';

function openExtensionPage(type: MarkerMessageType.OpenLibrary | MarkerMessageType.OpenOptions): void {
  void chrome.runtime.sendMessage({ type });
}

async function fetchCurrentPageState(): Promise<CurrentPageState> {
  return chrome.runtime.sendMessage({ type: MarkerMessageType.GetCurrentPageState });
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

async function requestBookmarkPermission(): Promise<boolean> {
  return chrome.permissions.request({ permissions: ['bookmarks'] });
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

function annotationLabel(annotation: AnnotationWithParts): string {
  const note = annotation.bodies.find((body) => body.format === 'text/markdown')?.value;
  if (note != null && note.trim().length > 0) return 'Note';
  if (annotation.annotation.motivation === 'linking') return 'Underline';
  return 'Highlight';
}

function annotationQuote(annotation: AnnotationWithParts): string {
  const plain = annotation.bodies.find((body) => body.format === 'text/plain')?.value;
  const quote = annotation.targets[0]?.selector.find((selector) => selector.type === 'TextQuoteSelector');
  return plain ?? quote?.exact ?? 'Annotation target';
}

function annotationNote(annotation: AnnotationWithParts): string | undefined {
  return annotation.bodies.find((body) => body.format === 'text/markdown')?.value;
}

function SidePanelPage() {
  const [state, setState] = createSignal<CurrentPageState>();
  const [activeSection, setActiveSection] = createSignal<SidePanelSection>('page');
  const [isEnabling, setIsEnabling] = createSignal(false);
  const [error, setError] = createSignal<string>();
  const [saveStatus, setSaveStatus] = createSignal<string>();
  const [annotationsVisible, setAnnotationsVisible] = createSignal(true);
  const summary = createMemo(() => state()?.summary);
  const annotations = createMemo(() => state()?.annotations ?? []);
  const bookmarkBehavior = createMemo<BookmarkSaveBehavior>(() => state()?.bookmarkSaveBehavior ?? 'always-ask');
  const markerActionLabel = createMemo(() => (summary()?.status === 'enabled' ? 'Load Marker' : 'Enable site'));
  const markerActionVisibleLabel = createMemo(() => (isEnabling() ? 'Loading…' : markerActionLabel()));

  async function refreshState(): Promise<void> {
    const nextState = await fetchCurrentPageState();
    setState(nextState);
    setAnnotationsVisible(nextState.annotationDisplayMode === 'visible');
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
      if (activeSummary.status === 'needs-permission') {
        const granted = await requestSitePermissions(activeSummary);
        if (!granted) {
          setError('Site permission was not granted.');
          return;
        }
      }

      const response = await injectContentRuntime(activeSummary.tabId);
      if (!response.ok) {
        setError(response.reason);
        return;
      }

      await refreshState();
    } catch (caughtError) {
      console.debug('Marker could not enable this site from the side panel.', caughtError);
      setError('Marker could not enable this site.');
    } finally {
      setIsEnabling(false);
    }
  }

  async function saveBookmark(destination: BookmarkSaveDestination): Promise<void> {
    const activeSummary = summary();
    if (activeSummary?.url == null) {
      setSaveStatus('Marker cannot save this page.');
      return;
    }

    setSaveStatus(undefined);

    try {
      if ((destination === 'chrome' || destination === 'both') && !(await requestBookmarkPermission())) {
        setSaveStatus(
          destination === 'both'
            ? 'Saved to Marker only because Chrome permission was denied.'
            : 'Chrome permission was denied.',
        );
        if (destination === 'chrome') {
          return;
        }
      }

      const response = await chrome.runtime.sendMessage({
        type: MarkerMessageType.SaveBookmark,
        destination,
        title: activeSummary.title,
        url: activeSummary.url,
      });

      if (!response.ok) {
        setSaveStatus(response.reason);
        return;
      }

      setSaveStatus(response.chromeSkippedReason ?? 'Bookmark saved.');
      await refreshState();
    } catch (caughtError) {
      console.debug('Marker could not save a bookmark from the side panel.', caughtError);
      setSaveStatus('Marker could not save this bookmark.');
    }
  }

  function saveWithDefaultBehavior(): void {
    const behavior = bookmarkBehavior();

    switch (behavior) {
      case 'always-ask': {
        setActiveSection('bookmarks');
        setSaveStatus('Choose where to save this page.');
        return;
      }
      case 'marker-only': {
        void saveBookmark('marker');
        return;
      }
      case 'chrome-only': {
        void saveBookmark('chrome');
        return;
      }
      case 'both': {
        void saveBookmark('both');
        return;
      }
    }
  }

  async function sendToActiveTab(
    message:
      | ScrollToAnnotationMessage
      | { type: MarkerMessageType.RemoveRenderedAnnotation; annotationId: string }
      | { type: MarkerMessageType.SetAnnotationVisibility; visible: boolean },
  ): Promise<unknown> {
    const tabId = summary()?.tabId;
    if (tabId == null) return undefined;
    return chrome.tabs.sendMessage(tabId, message);
  }

  async function jumpToAnnotation(annotationId: string): Promise<void> {
    const response = (await sendToActiveTab({ type: MarkerMessageType.ScrollToAnnotation, annotationId })) as
      | { ok: true }
      | { ok: false; reason: string }
      | undefined;
    if (response != null && !response.ok) setError(response.reason);
  }

  async function editAnnotation(annotation: AnnotationWithParts): Promise<void> {
    const currentNote = annotationNote(annotation) ?? '';
    const nextNote = window.prompt('Edit Markdown note', currentNote);
    if (nextNote == null) return;
    const response: { ok: true } | { ok: false; reason: string } = await chrome.runtime.sendMessage({
      type: MarkerMessageType.UpdateAnnotationNote,
      annotationId: annotation.annotation.id,
      value: nextNote,
    });
    if (!response.ok) {
      setError(response.reason);
      return;
    }
    await refreshState();
  }

  async function deleteAnnotation(annotationId: string): Promise<void> {
    const response: { ok: true } | { ok: false; reason: string } = await chrome.runtime.sendMessage({
      type: MarkerMessageType.DeleteAnnotation,
      annotationId,
    });
    if (!response.ok) {
      setError(response.reason);
      return;
    }
    await sendToActiveTab({ type: MarkerMessageType.RemoveRenderedAnnotation, annotationId });
    await refreshState();
  }

  async function toggleAnnotationVisibility(): Promise<void> {
    const visible = !annotationsVisible();
    setAnnotationsVisible(visible);
    await sendToActiveTab({ type: MarkerMessageType.SetAnnotationVisibility, visible });
  }

  onMount(() => {
    void refreshState().catch((caughtError: unknown) => {
      console.debug('Marker could not load the active tab summary.', caughtError);
      setError('Marker could not read the active tab.');
    });

    const listener = (message: unknown) => {
      if (
        typeof message !== 'object' ||
        message == null ||
        (message as { type?: unknown }).type !== MarkerMessageType.SettingsChanged
      ) {
        return;
      }
      const changed = message as { key?: unknown; value?: unknown };
      if (changed.key === 'bookmark-save-behavior' || changed.key === 'annotation-display-mode') {
        void refreshState().catch((error: unknown) => {
          console.debug('Marker could not refresh side panel settings.', error);
        });
      }
    };
    const refreshFromTabChange = () => {
      void refreshState().catch((error: unknown) => {
        console.debug('Marker could not refresh side panel after tab change.', error);
      });
    };
    chrome.runtime.onMessage.addListener(listener);
    chrome.tabs.onActivated.addListener(refreshFromTabChange);
    chrome.tabs.onUpdated.addListener(refreshFromTabChange);
    onCleanup(() => {
      chrome.runtime.onMessage.removeListener(listener);
      chrome.tabs.onActivated.removeListener(refreshFromTabChange);
      chrome.tabs.onUpdated.removeListener(refreshFromTabChange);
    });
  });

  return (
    <main class="app-shell side-panel-shell" aria-labelledby="side-panel-title">
      <header class="app-header card card--accent">
        <Brand label="Marker for Chrome" />
        <p class="eyebrow">Chrome side panel</p>

        <nav class="side-panel-tabs" aria-label="Marker sections">
          <For each={['page', 'bookmarks', 'annotations'] as SidePanelSection[]}>
            {(section) => (
              <button
                class={activeSection() === section ? 'button button--primary' : 'button'}
                type="button"
                aria-current={activeSection() === section ? 'page' : undefined}
                onClick={() => setActiveSection(section)}>
                <Show
                  when={section === 'page'}
                  fallback={
                    <Show when={section === 'bookmarks'} fallback="Annotations">
                      Bookmarks
                    </Show>
                  }>
                  Page
                </Show>
              </button>
            )}
          </For>
        </nav>
      </header>

      <Show when={activeSection() === 'page'}>
        <section class="card" aria-labelledby="current-page-heading">
          <h2 class="card__title" id="current-page-heading">
            Current page
          </h2>
          <p class="card__body">{permissionStatus(summary())}</p>
          <Show when={summary()?.title || summary()?.url}>
            <p class="card__body muted">{summary()?.title ?? summary()?.url}</p>
          </Show>
          <p class="card__body muted">
            {state()?.bookmark != null ? 'Saved to Marker.' : 'Not saved to Marker yet.'} {annotations().length}{' '}
            annotations.
          </p>
          <Show when={error()}>
            <p class="card__body" role="alert">
              {error()}
            </p>
          </Show>
          <Show when={saveStatus()}>
            <p class="card__body" role="status">
              {saveStatus()}
            </p>
          </Show>
          <div class="side-panel-actions card__body">
            <IconButton
              class="button button--primary"
              type="button"
              icon="shield-check"
              label={markerActionLabel()}
              visibleLabel={markerActionVisibleLabel()}
              disabled={summary()?.status === 'unsupported' || summary() == null || isEnabling()}
              onClick={() => void enableSite()}
            />
            <IconButton
              class="button"
              type="button"
              icon="bookmark-plus"
              label="Save page"
              disabled={summary()?.url == null}
              onClick={saveWithDefaultBehavior}
            />
            <IconButton
              class="button"
              type="button"
              icon={annotationsVisible() ? 'eye-off' : 'eye'}
              label={annotationsVisible() ? 'Hide highlights' : 'Show highlights'}
              onClick={() => void toggleAnnotationVisibility()}
            />
          </div>
        </section>
      </Show>

      <Show when={activeSection() === 'bookmarks'}>
        <section class="card" aria-labelledby="bookmark-heading">
          <h2 class="card__title" id="bookmark-heading">
            Page bookmark
          </h2>
          <p class="card__body">
            Default behavior: {bookmarkBehavior().replace('-', ' ')}.{' '}
            {state()?.bookmark != null ? 'This page is saved in Marker.' : 'Choose a destination to save this page.'}
          </p>
          <div class="side-panel-actions card__body">
            <IconButton
              class="button"
              type="button"
              icon="bookmark"
              label="Save to Marker"
              visibleLabel="Save Marker"
              disabled={summary()?.url == null}
              onClick={() => void saveBookmark('marker')}
            />
            <IconButton
              class="button"
              type="button"
              icon="bookmark-plus"
              label="Save to Chrome"
              visibleLabel="Save Chrome"
              disabled={summary()?.url == null}
              onClick={() => void saveBookmark('chrome')}
            />
            <IconButton
              class="button button--primary"
              type="button"
              icon="check"
              label="Save to both"
              visibleLabel="Save both"
              disabled={summary()?.url == null}
              onClick={() => void saveBookmark('both')}
            />
          </div>
        </section>
      </Show>

      <Show when={activeSection() === 'annotations'}>
        <section class="side-panel-preview-list" aria-label="Current page annotations">
          <Show
            when={annotations().length > 0}
            fallback={
              <article class="card">
                <p class="card__body">No annotations saved for this page yet.</p>
              </article>
            }>
            <For each={annotations()}>
              {(annotation) => (
                <article class="card quote-card">
                  <p class="eyebrow">
                    {annotationLabel(annotation)} · {new Date(annotation.annotation.createdAt).toLocaleDateString()}
                  </p>
                  <blockquote>{annotationQuote(annotation)}</blockquote>
                  <Show when={annotationNote(annotation)}>
                    <p class="card__body">{annotationNote(annotation)}</p>
                  </Show>
                  <div class="side-panel-actions card__body">
                    <IconButton
                      class="button"
                      type="button"
                      icon="chevron-right"
                      label="Jump to annotation"
                      visibleLabel="Jump"
                      onClick={() => void jumpToAnnotation(annotation.annotation.id)}
                    />
                    <IconButton
                      class="button"
                      type="button"
                      icon="pencil"
                      label="Edit annotation"
                      visibleLabel="Edit"
                      onClick={() => void editAnnotation(annotation)}
                    />
                    <IconButton
                      class="button"
                      type="button"
                      icon="trash-2"
                      label="Delete annotation"
                      visibleLabel="Delete"
                      onClick={() => void deleteAnnotation(annotation.annotation.id)}
                    />
                  </div>
                </article>
              )}
            </For>
          </Show>
        </section>
      </Show>

      <section class="card" aria-labelledby="quick-actions-heading">
        <h2 class="card__title" id="quick-actions-heading">
          Quick actions
        </h2>
        <div class="side-panel-actions card__body">
          <IconButton
            class="button"
            type="button"
            icon="library"
            label="Open Library"
            onClick={() => openExtensionPage(MarkerMessageType.OpenLibrary)}
          />
          <IconButton
            class="button"
            type="button"
            icon="settings"
            label="Open Options"
            onClick={() => openExtensionPage(MarkerMessageType.OpenOptions)}
          />
        </div>
      </section>
    </main>
  );
}

export default SidePanelPage;
