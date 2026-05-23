import './library.css';

function LibraryPage() {
  return (
    <main class="library-shell" aria-labelledby="library-title">
      <header class="library-header">
        <p class="eyebrow">Marker Library</p>
        <h1 id="library-title">Bookmarks and annotations</h1>
        <p>Search and manage Marker folders, bookmarks, pages, highlights, underlines, and notes.</p>
      </header>

      <section class="library-grid" aria-label="Library sections">
        <article>
          <h2>Bookmarks</h2>
          <p>Folder tree, Chrome import, bookmark details, and save destinations will live here.</p>
        </article>
        <article>
          <h2>Annotations</h2>
          <p>Filters, annotation details, Markdown notes, and page-linked highlights will live here.</p>
        </article>
      </section>
    </main>
  );
}

export default LibraryPage;
