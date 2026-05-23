import { createSignal, onMount } from 'solid-js';
import { appThemes, type AppTheme, type BookmarkSaveBehavior } from '@/db/settings-repository';
import { MarkerMessageType } from '@/shared/messages';
import '@/styles/index.css';
import { Brand } from '@/components/Brand';
import { createAppTheme, themeClass, themeLabels } from '@/pages/theme';

const behaviorLabels: Record<BookmarkSaveBehavior, string> = {
  'always-ask': 'Always ask',
  'marker-only': 'Marker only',
  'chrome-only': 'Chrome only',
  both: 'Both',
};

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

function BehaviorButton(props: {
  activeBehavior: BookmarkSaveBehavior;
  behavior: BookmarkSaveBehavior;
  onSelect: () => void;
}) {
  return (
    <button
      class={props.activeBehavior === props.behavior ? 'button button--primary' : 'button'}
      type="button"
      onClick={props.onSelect}>
      {behaviorLabels[props.behavior]}
    </button>
  );
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
      .catch((error: unknown) => {
        console.debug('Marker could not load bookmark save behavior.', error);
      });
  });

  return (
    <section class="card" aria-labelledby="bookmark-default-heading">
      <p class="eyebrow">Bookmarking</p>
      <h2 class="card__title" id="bookmark-default-heading">
        Bookmark save behavior
      </h2>
      <p class="card__body">Skip the save dialog by choosing a default destination.</p>
      <div class="cluster card__body">
        <BehaviorButton
          activeBehavior={behavior()}
          behavior="always-ask"
          onSelect={() => void saveBehavior('always-ask')}
        />
        <BehaviorButton
          activeBehavior={behavior()}
          behavior="marker-only"
          onSelect={() => void saveBehavior('marker-only')}
        />
        <BehaviorButton
          activeBehavior={behavior()}
          behavior="chrome-only"
          onSelect={() => void saveBehavior('chrome-only')}
        />
        <BehaviorButton activeBehavior={behavior()} behavior="both" onSelect={() => void saveBehavior('both')} />
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

function ThemeButton(props: { activeTheme: AppTheme; theme: AppTheme; onSelect: () => void }) {
  return (
    <button class={props.activeTheme === props.theme ? 'button button--primary' : 'button'} type="button" onClick={props.onSelect}>
      {themeLabels[props.theme]}
    </button>
  );
}

function ThemeSettingsCard(props: { activeTheme: AppTheme; onSelect: (theme: AppTheme) => void }) {
  return (
    <aside class="card theme-swatch" aria-labelledby="theme-heading">
      <p class="eyebrow">Themes</p>
      <h2 class="card__title" id="theme-heading">
        App theme
      </h2>
      <p class="card__body">Choose one theme for Options, Library, and the side panel.</p>
      <div class="cluster card__body">
        {appThemes.map((theme) => (
          <ThemeButton activeTheme={props.activeTheme} theme={theme} onSelect={() => props.onSelect(theme)} />
        ))}
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
        </div>
        <ThemeSettingsCard activeTheme={appTheme.theme()} onSelect={(theme) => void appTheme.saveTheme(theme)} />
      </section>
    </main>
  );
}
