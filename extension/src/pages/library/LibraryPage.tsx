import { Brand } from '@/components/Brand';
import '@/styles/index.css';

function LibraryHeader() {
  return (
    <header class="app-header">
      <Brand label="Marker Library" />
      <p class="eyebrow">Library</p>
      <h1 class="app-header__title" id="library-title">
        Bookmarks / Annotations
      </h1>
      <p class="app-header__description">
        Search and manage Marker folders, bookmarks, pages, highlights, underlines, and notes.
      </p>
      <div class="cluster">
        <input class="library-search" value="folder:research annotation:note" aria-label="Search library" />
        <button class="button button--primary" type="button">
          Import Chrome
        </button>
        <button class="button" type="button">
          Export JSON
        </button>
      </div>
    </header>
  );
}

function LibraryStats() {
  return (
    <section class="library-stats" aria-label="Library statistics">
      <article class="card library-stat">
        <strong>128</strong>
        <span class="muted">bookmarks</span>
      </article>
      <article class="card library-stat">
        <strong>412</strong>
        <span class="muted">annotations</span>
      </article>
      <article class="card library-stat">
        <strong>23</strong>
        <span class="muted">folders</span>
      </article>
    </section>
  );
}

function FolderCard(props: { title: string; count: string }) {
  return (
    <article class="card">
      <strong>{props.title}</strong>
      <p class="muted">{props.count}</p>
    </article>
  );
}

function FoldersPanel() {
  return (
    <aside class="library-panel card">
      <h2 class="card__title">Folders</h2>
      <div class="library-list">
        <FolderCard title="Inbox" count="9 items" />
        <FolderCard title="Long reads" count="31 items" />
        <FolderCard title="Interface research" count="22 items" />
      </div>
    </aside>
  );
}

function ResultsPanel() {
  return (
    <section class="library-panel card">
      <h2 class="card__title">Results</h2>
      <div class="library-tabs" aria-label="Result filters">
        <button class="button button--primary" type="button">
          All
        </button>
        <button class="button" type="button">
          Bookmarks
        </button>
        <button class="button" type="button">
          Annotations
        </button>
      </div>
      <div class="library-list">
        <article class="card">
          <p class="eyebrow">Bookmark</p>
          <strong>The browser as notebook</strong>
          <p class="card__body">A saved page with four annotations and Chrome bookmark linkage.</p>
        </article>
        <article class="card quote-card">
          <p class="eyebrow">Annotation</p>
          <blockquote>The best bookmark is often the sentence that explains why you saved the page.</blockquote>
        </article>
      </div>
    </section>
  );
}

function PageDetailPanel() {
  return (
    <aside class="library-panel card">
      <h2 class="card__title">Page detail</h2>
      <p class="card__body">Joined bookmark metadata, annotation count, Markdown notes, and export status.</p>
      <article class="card quote-card">
        <p class="eyebrow">Saved quote</p>
        <blockquote>The active tab is context, not just a URL.</blockquote>
      </article>
    </aside>
  );
}

function LibraryPage() {
  return (
    <main class="app-shell app-shell--page theme-minimal-light" aria-labelledby="library-title">
      <LibraryHeader />
      <LibraryStats />
      <section class="library-grid" aria-label="Library sections">
        <FoldersPanel />
        <ResultsPanel />
        <PageDetailPanel />
      </section>
    </main>
  );
}

export default LibraryPage;
