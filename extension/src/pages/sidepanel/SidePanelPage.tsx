import { MarkerMessageType } from '@/shared/messages';
import './sidepanel.css';

function openExtensionPage(type: MarkerMessageType.OpenLibrary | MarkerMessageType.OpenOptions): void {
  void chrome.runtime.sendMessage({ type });
}

function SidePanelPage() {
  return (
    <main class="side-panel-shell" aria-labelledby="side-panel-title">
      <header class="side-panel-hero">
        <p class="eyebrow">Marker for Chrome</p>
        <h1 id="side-panel-title">Bookmarks and annotations for this page</h1>
        <p>
          The side panel will manage the active tab, site permissions, page bookmarks, and current-page annotations.
        </p>
      </header>

      <nav class="side-panel-tabs" aria-label="Marker sections">
        <button type="button" aria-current="page">
          Page
        </button>
        <button type="button">Bookmarks</button>
        <button type="button">Annotations</button>
      </nav>

      <section class="side-panel-card" aria-labelledby="current-page-heading">
        <h2 id="current-page-heading">Current page</h2>
        <p>Enable Marker for this site to capture highlights, notes, and bookmark metadata.</p>
        <button type="button">Enable site</button>
      </section>

      <section class="side-panel-card" aria-labelledby="quick-actions-heading">
        <h2 id="quick-actions-heading">Quick actions</h2>
        <div class="side-panel-actions">
          <button type="button" onClick={() => openExtensionPage(MarkerMessageType.OpenLibrary)}>
            Open Library
          </button>
          <button type="button" onClick={() => openExtensionPage(MarkerMessageType.OpenOptions)}>
            Open Options
          </button>
        </div>
      </section>
    </main>
  );
}

export default SidePanelPage;
