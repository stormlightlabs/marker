import './options.css';

function OptionsPage() {
  return (
    <main class="options-shell" aria-labelledby="options-title">
      <header class="options-header">
        <p class="eyebrow">Marker Options</p>
        <h1 id="options-title">Extension settings</h1>
        <p>Configure bookmark save behavior, permissions, imports, exports, and annotation display.</p>
      </header>

      <section class="options-card" aria-labelledby="bookmark-default-heading">
        <h2 id="bookmark-default-heading">Bookmark save behavior</h2>
        <p>The MVP will support always ask, Marker only, Chrome only, and both.</p>
      </section>
    </main>
  );
}

export default OptionsPage;
