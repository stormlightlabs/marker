import { Brand } from '@/components/Brand';
import '@/styles/index.css';

function OptionsHeader() {
  return (
    <header class="app-header">
      <Brand label="Marker Options" />
      <p class="eyebrow">Options</p>
      <h1 class="app-header__title" id="options-title">
        Extension settings
      </h1>
      <p class="app-header__description">
        Configure bookmark save behavior, permissions, imports, exports, annotation display, and themes.
      </p>
    </header>
  );
}

function BookmarkSettingsCard() {
  return (
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
  );
}

function PermissionSettingsCard() {
  return (
    <section class="card" aria-labelledby="permission-heading">
      <p class="eyebrow">Permissions</p>
      <h2 class="card__title" id="permission-heading">
        Chrome integration
      </h2>
      <p class="card__body">Request bookmark and site permissions only when they are needed.</p>
    </section>
  );
}

function ThemeSwatch() {
  return (
    <aside class="card theme-swatch" aria-labelledby="theme-heading">
      <p class="eyebrow">Themes</p>
      <h2 class="card__title" id="theme-heading">
        Minimal + Retro
      </h2>
      <p class="card__body">Minimal supports light and dark. Retro uses Righteous, Oswald, and Libre Baskerville.</p>
      <div class="theme-swatch__row" aria-hidden="true">
        <span class="theme-swatch__chip theme-minimal-light"></span>
        <span class="theme-swatch__chip theme-minimal-dark"></span>
        <span class="theme-swatch__chip theme-retro"></span>
      </div>
    </aside>
  );
}

function OptionsPage() {
  return (
    <main class="app-shell app-shell--page theme-retro" aria-labelledby="options-title">
      <OptionsHeader />
      <section class="options-grid" aria-label="Options sections">
        <div class="options-list">
          <BookmarkSettingsCard />
          <PermissionSettingsCard />
        </div>
        <ThemeSwatch />
      </section>
    </main>
  );
}

export default OptionsPage;
