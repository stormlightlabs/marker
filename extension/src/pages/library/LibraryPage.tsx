import { createMemo, createSignal, For, onMount, Show, type Accessor, type Setter } from 'solid-js';
import { Brand } from '@/components/Brand';
import { Icon, IconLabel } from '@/components/Icon';
import type { AnnotationWithParts } from '@/db/annotation-repository';
import type { BookmarkFolderRecord, BookmarkRecord, PageRecord } from '@/db/schema';
import type { LibraryState } from '@/shared/messages';
import { MarkerMessageType } from '@/shared/messages';
import '@/styles/index.css';
const maxRenderedResults = 80;

type LibraryFilter = 'all' | 'bookmarks' | 'annotations' | 'pages';
type SelectedItem =
  | { type: 'page'; id: string }
  | { type: 'bookmark'; id: string }
  | { type: 'annotation'; id: string };

type SearchResult =
  | { type: 'bookmark'; bookmark: BookmarkRecord; text: string }
  | { type: 'annotation'; annotation: AnnotationWithParts; text: string }
  | { type: 'page'; page: PageRecord; text: string };

function annotationQuote(annotation: AnnotationWithParts): string {
  const plain = annotation.bodies.find((body) => body.format === 'text/plain')?.value;
  const quote = annotation.targets[0]?.selector.find((selector) => selector.type === 'TextQuoteSelector');
  return plain ?? quote?.exact ?? '';
}

function annotationNote(annotation: AnnotationWithParts): string {
  return annotation.bodies.find((body) => body.format === 'text/markdown')?.value ?? '';
}

function annotationKind(annotation: AnnotationWithParts): string {
  if (annotationNote(annotation).trim().length > 0) return 'note';
  return annotation.annotation.motivation === 'linking' ? 'underline' : 'highlight';
}

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

function LibraryContent(props: {
  state: Accessor<LibraryState>;
  folderPath: (folderId: string | undefined) => string;
  filter: Accessor<LibraryFilter>;
  setFilter: Setter<LibraryFilter>;
  results: Accessor<SearchResult[]>;
  visibleResults: Accessor<SearchResult[]>;
  setSelected: Setter<SelectedItem | undefined>;
  selectedItemForResult: (result: SearchResult) => SelectedItem;
  selectedPage: Accessor<PageRecord | undefined>;
  annotationsByPage: Accessor<Map<string, AnnotationWithParts[]>>;
}) {
  return (
    <div class="app-content-scroll library-content">
      <section class="library-stats" aria-label="Library statistics">
        <article class="card library-stat">
          <strong>{props.state().bookmarks.length}</strong>
          <span class="muted">bookmarks</span>
        </article>
        <article class="card library-stat">
          <strong>{props.state().annotations.length}</strong>
          <span class="muted">annotations</span>
        </article>
        <article class="card library-stat">
          <strong>{props.state().folders.length}</strong>
          <span class="muted">folders</span>
        </article>
      </section>

      <section class="library-grid" aria-label="Library sections">
        <aside class="library-panel card">
          <h2 class="card__title">Folders</h2>
          <div class="library-list">
            <For each={props.state().folders} fallback={<p class="muted">No folders yet.</p>}>
              {(folder) => (
                <article class="card">
                  <strong>{folder.title}</strong>
                  <p class="muted">{props.folderPath(folder.parentId)}</p>
                </article>
              )}
            </For>
          </div>
        </aside>

        <section class="library-panel card">
          <h2 class="card__title">Results</h2>
          <div class="library-tabs" aria-label="Result filters">
            <For each={['all', 'bookmarks', 'annotations', 'pages'] as LibraryFilter[]}>
              {(nextFilter) => (
                <button
                  class={props.filter() === nextFilter ? 'button button--primary' : 'button'}
                  type="button"
                  onClick={() => props.setFilter(nextFilter)}>
                  {nextFilter}
                </button>
              )}
            </For>
          </div>
          <Show when={props.results().length > maxRenderedResults}>
            <p class="muted">
              Showing first {maxRenderedResults} of {props.results().length} results. Refine search to narrow the list.
            </p>
          </Show>
          <div class="library-list">
            <For each={props.visibleResults()} fallback={<p class="muted">No matching library items.</p>}>
              {(result) => (
                <article
                  class="card quote-card"
                  role="button"
                  tabIndex={0}
                  onClick={() => props.setSelected(props.selectedItemForResult(result))}>
                  <p class="eyebrow">{result.type}</p>
                  <Show when={result.type === 'bookmark'}>
                    <strong>
                      {(result as Extract<SearchResult, { type: 'bookmark' }>).bookmark.title ??
                        (result as Extract<SearchResult, { type: 'bookmark' }>).bookmark.url}
                    </strong>
                  </Show>
                  <Show when={result.type === 'annotation'}>
                    <blockquote>
                      {annotationQuote((result as Extract<SearchResult, { type: 'annotation' }>).annotation)}
                    </blockquote>
                  </Show>
                  <Show when={result.type === 'page'}>
                    <strong>
                      {(result as Extract<SearchResult, { type: 'page' }>).page.title ??
                        (result as Extract<SearchResult, { type: 'page' }>).page.url}
                    </strong>
                  </Show>
                  <p class="card__body muted">{result.text}</p>
                </article>
              )}
            </For>
          </div>
        </section>

        <aside class="library-panel card">
          <h2 class="card__title">Page detail</h2>
          <Show when={props.selectedPage()} fallback={<p class="card__body">Select a result to inspect its page.</p>}>
            {(page) => (
              <>
                <p class="eyebrow">Page</p>
                <strong>{page().title ?? page().url}</strong>
                <p class="card__body muted">{page().canonicalUrl ?? page().url}</p>
                <p class="card__body">
                  Bookmark state:{' '}
                  {props
                    .state()
                    .bookmarks.some((bookmark) => bookmark.pageId === page().id || bookmark.url === page().url)
                    ? 'saved'
                    : 'not saved'}
                </p>
                <div class="library-list">
                  <For
                    each={props.annotationsByPage().get(page().id) ?? []}
                    fallback={<p class="muted">No annotations on this page.</p>}>
                    {(annotation) => (
                      <article class="card quote-card">
                        <p class="eyebrow">{annotationKind(annotation)}</p>
                        <blockquote>{annotationQuote(annotation)}</blockquote>
                        <Show when={annotationNote(annotation)}>
                          <p class="card__body">{annotationNote(annotation)}</p>
                        </Show>
                      </article>
                    )}
                  </For>
                </div>
              </>
            )}
          </Show>
        </aside>
      </section>
    </div>
  );
}

function LibraryPage() {
  const [state, setState] = createSignal<LibraryState>({ pages: [], folders: [], bookmarks: [], annotations: [] });
  const [query, setQuery] = createSignal('');
  const [filter, setFilter] = createSignal<LibraryFilter>('all');
  const [selected, setSelected] = createSignal<SelectedItem>();
  const [status, setStatus] = createSignal<string>();

  const folderById = createMemo(() => new Map(state().folders.map((folder) => [folder.id, folder])));
  const pageById = createMemo(() => new Map(state().pages.map((page) => [page.id, page])));
  const annotationsByPage = createMemo(() => {
    const map = new Map<string, AnnotationWithParts[]>();
    for (const annotation of state().annotations) {
      const list = map.get(annotation.annotation.pageId) ?? [];
      list.push(annotation);
      map.set(annotation.annotation.pageId, list);
    }
    return map;
  });

  function folderPath(folderId: string | undefined): string {
    if (folderId == null) return 'Root';
    const parts: string[] = [];
    for (
      let folder: BookmarkFolderRecord | undefined = folderById().get(folderId);
      folder != null;
      folder = folder.parentId == null ? undefined : folderById().get(folder.parentId)
    ) {
      parts.unshift(folder.title);
    }
    return parts.join(' / ') || 'Root';
  }

  function searchableBookmark(bookmark: BookmarkRecord): string {
    return [bookmark.title, bookmark.url, bookmark.description, bookmark.tags.join(' '), folderPath(bookmark.folderId)]
      .filter(Boolean)
      .join(' ');
  }

  function searchableAnnotation(annotation: AnnotationWithParts): string {
    const page = pageById().get(annotation.annotation.pageId);
    return [annotationKind(annotation), annotationQuote(annotation), annotationNote(annotation), page?.title, page?.url]
      .filter(Boolean)
      .join(' ');
  }

  const results = createMemo<SearchResult[]>(() => {
    const normalizedQuery = query().trim().toLocaleLowerCase();
    const matches = (text: string) =>
      normalizedQuery.length === 0 || text.toLocaleLowerCase().includes(normalizedQuery);
    const output: SearchResult[] = [];

    if (filter() === 'all' || filter() === 'bookmarks') {
      for (const bookmark of state().bookmarks) {
        const text = searchableBookmark(bookmark);
        if (matches(text)) output.push({ type: 'bookmark', bookmark, text });
      }
    }

    if (filter() === 'all' || filter() === 'annotations') {
      for (const annotation of state().annotations) {
        const text = searchableAnnotation(annotation);
        if (matches(text)) output.push({ type: 'annotation', annotation, text });
      }
    }

    if (filter() === 'all' || filter() === 'pages') {
      for (const page of state().pages) {
        const text = [page.title, page.url, page.description, page.canonicalUrl, page.metadata?.siteName]
          .filter(Boolean)
          .join(' ');
        if (matches(text)) output.push({ type: 'page', page, text });
      }
    }

    return output;
  });

  const visibleResults = createMemo(() => results().slice(0, maxRenderedResults));

  const selectedPage = createMemo(() => {
    const item = selected();
    if (item?.type === 'page') return pageById().get(item.id);
    if (item?.type === 'bookmark')
      return pageById().get(state().bookmarks.find((bookmark) => bookmark.id === item.id)?.pageId ?? '');
    if (item?.type === 'annotation')
      return pageById().get(
        state().annotations.find((annotation) => annotation.annotation.id === item.id)?.annotation.pageId ?? '',
      );
    return state().pages[0];
  });

  async function refreshLibrary(): Promise<void> {
    setState(await chrome.runtime.sendMessage({ type: MarkerMessageType.GetLibraryState }));
  }

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
    if (!response.ok) {
      setStatus(response.reason);
      return;
    }
    setStatus('Imported Marker JSON.');
    await refreshLibrary();
  }

  function selectedItemForResult(result: SearchResult): SelectedItem {
    switch (result.type) {
      case 'bookmark': {
        return { type: 'bookmark', id: result.bookmark.id };
      }
      case 'annotation': {
        return { type: 'annotation', id: result.annotation.annotation.id };
      }
      case 'page': {
        return { type: 'page', id: result.page.id };
      }
    }
  }

  // TODO: this needs to be refactored to be browser/engine agnostic
  async function importChrome(): Promise<void> {
    if (!(await chrome.permissions.request({ permissions: ['bookmarks'] }))) {
      setStatus('Chrome bookmark permission was not granted.');
      return;
    }
    const response = await chrome.runtime.sendMessage({ type: MarkerMessageType.ImportChromeBookmarks });
    if ('reason' in response) {
      setStatus(response.reason);
      return;
    }
    setStatus(`Imported ${response.bookmarks.length} Chrome bookmarks.`);
    await refreshLibrary();
  }

  onMount(() => {
    void refreshLibrary().catch((error: unknown) => {
      console.debug('Marker could not load library state.', error);
      setStatus('Marker could not load the library.');
    });
  });

  return (
    <main class="app-shell app-shell--page" aria-labelledby="library-title">
      <header class="app-header">
        <Brand label="Marker Library" />
        <p class="eyebrow">Library</p>
        <h1 class="app-header__title" id="library-title">
          Bookmarks & Annotations
        </h1>
        <p class="app-header__description">Search bookmarks, folders, pages, highlights, underlines, and notes.</p>
        <div class="cluster">
          <input
            class="library-search"
            value={query()}
            onInput={(event) => setQuery(event.currentTarget.value)}
            placeholder="Search title, URL, folder, quote, or note"
            aria-label="Search library"
          />
          <button
            class="button button--primary"
            type="button"
            title="Import bookmarks"
            onClick={() => void importChrome()}>
            <Icon name="download" />
            <span aria-hidden="true">Import Bookmarks</span>
            <IconLabel label="Import bookmarks" />
          </button>
          <button class="button" type="button" title="Export JSON" onClick={() => void exportJson()}>
            <Icon name="file-down" />
            <span aria-hidden="true">Export JSON</span>
            <IconLabel label="Export JSON" />
          </button>
          <label class="button" for="library-import-json" title="Import JSON">
            <Icon name="file-up" />
            <span aria-hidden="true">Import JSON</span>
            <IconLabel label="Import JSON" />
          </label>
          <input
            id="library-import-json"
            class="visually-hidden"
            type="file"
            accept="application/json"
            onChange={(event) => {
              const file = event.currentTarget.files?.[0];
              if (file != null) void importJson(file);
            }}
          />
        </div>
        <Show when={status()}>
          <p class="card__body" role="status">
            {status()}
          </p>
        </Show>
      </header>

      <LibraryContent
        state={state}
        folderPath={folderPath}
        filter={filter}
        setFilter={setFilter}
        results={results}
        visibleResults={visibleResults}
        setSelected={setSelected}
        selectedItemForResult={selectedItemForResult}
        selectedPage={selectedPage}
        annotationsByPage={annotationsByPage}
      />
    </main>
  );
}

export default LibraryPage;
