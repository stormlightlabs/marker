import '@/styles/index.css';

function OptionsPage() {
  return (
    <main class="app-shell app-shell--page theme-retro" aria-labelledby="options-title">
      <header class="app-header">
        <div class="brand-lockup" aria-label="Marker Options">
          <span class="brand-mark" aria-hidden="true">
            M
          </span>
          <span class="wordmark wordmark--large">Marker</span>
        </div>
        <p class="eyebrow">Options</p>
        <h1 class="app-header__title" id="options-title">
          Extension settings
        </h1>
        <p class="app-header__description">
          Configure bookmark save behavior, permissions, imports, exports, annotation display, and themes.
        </p>
      </header>

      <section class="options-grid" aria-label="Options sections">
        <div class="options-list">
          <section class="card" aria-labelledby="bookmark-default-heading">
            <p class="eyebrow">Bookmarking</p>
            <h2 class="card__title" id="bookmark-default-heading">
              Bookmark save behavior
            </h2>
            <p class="card__body">Always ask, Marker only, Chrome only, or save to both.</p>
            <div class="cluster card__body">
              <button class="button button--primary" type="button">
                Always ask
              </button>
              <button class="button" type="button">
                Marker only
              </button>
              <button class="button" type="button">
                Both
              </button>
            </div>
          </section>

          <section class="card" aria-labelledby="permission-heading">
            <p class="eyebrow">Permissions</p>
            <h2 class="card__title" id="permission-heading">
              Chrome integration
            </h2>
            <p class="card__body">Request bookmark and site permissions only when they are needed.</p>
          </section>
        </div>

        <aside class="card theme-swatch" aria-labelledby="theme-heading">
          <p class="eyebrow">Themes</p>
          <h2 class="card__title" id="theme-heading">
            Minimal + Retro
          </h2>
          <p class="card__body">
            Minimal supports light and dark. Retro uses Righteous, Oswald, and Libre Baskerville.
          </p>
          <div class="theme-swatch__row" aria-hidden="true">
            <span class="theme-swatch__chip theme-minimal-light"></span>
            <span class="theme-swatch__chip theme-minimal-dark"></span>
            <span class="theme-swatch__chip theme-retro"></span>
          </div>
        </aside>
      </section>
    </main>
  );
}

export default OptionsPage;
