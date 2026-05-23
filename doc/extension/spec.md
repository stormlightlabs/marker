# Marker Chrome Extension Spec

## Goal

Build a Chrome extension for local-first web bookmarks and annotations. The extension should bring the mobile app's core reading model to normal browser tabs: users can bookmark pages, organize them in Marker folders, select text on pages, create highlights/underlines/Markdown notes, and manage the resulting library from a Chrome side panel and full library page.

The extension is Chrome-first. Firefox support can be added later, but the MVP targets Chrome MV3 and the Chrome side panel API.

## Product decisions

- Bookmarks and annotations are both first-class features.
- Marker-owned Dexie data is canonical.
- Marker bookmark folders are canonical for Marker organization.
- Chrome bookmarks are an explicit integration, not the source of truth.
- The MVP includes Chrome bookmark save/import, but not continuous bidirectional sync.
- The MVP includes side panel, full library page, and options page.
- The library uses unified search with separate Bookmarks and Annotations sections.
- Annotation import/export must remain compatible with the mobile app's W3C-inspired JSON shape.
- Styling uses vanilla CSS with explicit reset, tokens, base, utilities, and component files.

## MVP scope

The MVP includes:

- Chrome side panel.
- Full library page.
- Options page.
- Highlight annotations.
- Underline annotations.
- Markdown note annotations with sanitized preview.
- Annotation rendering on revisit after a site is enabled.
- Marker-owned bookmark folders.
- Save bookmark to Marker, Chrome, or both.
- A user setting to skip the bookmark save-choice dialog.
- Basic Chrome bookmark import into Marker.
- Unified search across bookmarks and annotations.
- JSON import/export compatible with the mobile app data model.

The MVP does not include continuous Chrome bookmark sync, automatic destructive reconciliation, or Firefox packaging.

## Stack

| Layer               | Choice               |
| ------------------- | -------------------- |
| Extension framework | CRXJS + Vite         |
| UI                  | SolidJS + TypeScript |
| Browser target      | Chrome MV3           |
| Side panel          | `chrome.sidePanel`   |
| Persistence         | Dexie / IndexedDB    |
| Tests               | Vitest               |
| DOM tests           | happy-dom or jsdom   |
| Dexie tests         | fake-indexeddb       |
| CSS                 | Vanilla CSS          |

## Extension architecture

```text
extension/
  src/
    background/
      main.ts
      messages.ts
      permissions.ts
      chrome-bookmarks.ts
    content/
      main.tsx
      reader/
        capture.ts
        selectors.ts
        render.ts
        page-meta.ts
      ui/
        AnnotationToolbar.tsx
        MarkdownNoteDialog.tsx
        shadow-root.ts
    db/
      schema.ts
      annotation-repository.ts
      bookmark-repository.ts
      page-repository.ts
      export-repository.ts
    pages/
      sidepanel/
        index.html
        main.tsx
        SidePanelPage.tsx
      library/
        index.html
        main.tsx
        LibraryPage.tsx
      options/
        index.html
        main.tsx
        OptionsPage.tsx
    shared/
      annotation-model.ts
      bookmark-model.ts
      browser-api.ts
      markdown.ts
      messages.ts
      permissions.ts
      urls.ts
    styles/
      index.css
      reset.css
      base.css
      utilities.css
      tokens/
        colors.css
        type.css
        spacing.css
        radii.css
        shadows.css
      components/
    tests/
```

### Responsibilities

| Area                      | Owns                                                                               |
| ------------------------- | ---------------------------------------------------------------------------------- |
| Content script            | selection capture, selector creation, DOM rendering, Shadow DOM annotation toolbar |
| Background service worker | permissions, tab/content messaging, Chrome bookmark calls, coordination            |
| Dexie repositories        | local persistence and query behavior                                               |
| Side panel                | current tab/page management                                                        |
| Library page              | full bookmark and annotation management                                            |
| Options page              | settings, permission status, import/export settings                                |

## Manifest and permissions

Install-time permissions should be small:

- `sidePanel`
- `storage`

On-demand permissions:

- Current-origin host permission for annotation capture/rendering.
- `bookmarks` when the user chooses Chrome save/import.

The extension should not request broad host permissions at install.

Current scaffold items to replace:

- Remove `default_popup` unless a minimal fallback is intentionally kept.
- Replace static broad `content_scripts` with programmatic injection after site permission grant for production.
- Remove `contentSettings` unless a concrete feature needs it.
- Replace scaffold Solid demo UI with Marker side panel/library/options pages.

## Bookmark behavior

Marker bookmarks live in Dexie and use Marker-owned folders. Chrome bookmarks are optional linked external records.

Bookmark save choices:

- Save to Marker only.
- Save to Chrome only.
- Save to both.

Options page setting:

- Always ask.
- Always Marker only.
- Always Chrome only.
- Always both.

When saving to both, create/update the Marker bookmark and create a Chrome bookmark. Store the Chrome bookmark ID on the Marker record. Deleting a Marker bookmark must not delete the Chrome bookmark unless the user explicitly chooses that action. Deleting a Chrome bookmark outside Marker must not delete the Marker bookmark in MVP.

Chrome import should copy Chrome bookmarks into Marker folders selected by the user. Imported records may store `chromeBookmarkId` for future linking.

### Bookmark record sketch

```ts
export type BookmarkFolderRecord = {
  id: string;
  parentId?: string;
  title: string;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

export type BookmarkRecord = {
  id: string;
  folderId?: string;
  pageId?: string;
  chromeBookmarkId?: string;
  url: string;
  title?: string;
  description?: string;
  tags: string[];
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
};
```

## Annotation behavior

The content script handles selection and rendering. Persistence stays in Dexie through repository calls coordinated by background/page UI.

Supported actions:

- Highlight.
- Underline.
- Markdown note.
- Edit note.
- Delete annotation.
- Jump to annotation.
- Toggle rendered annotations for the active tab.

Selectors degrade in this order:

1. `TextQuoteSelector`
2. `TextPositionSelector`
3. `CssSelector`

The renderer should skip hidden text, script/style/template content, and text nodes already inside Marker annotation wrappers.

Annotation export/import must preserve mobile-compatible concepts:

- `Annotation`
- `TextualBody`
- `StyleHint`
- `TextQuoteSelector`
- `TextPositionSelector`
- `CssSelector`
- page metadata
- created/modified/deleted timestamps

## Page identity and metadata

Page identity should prefer canonical URL when available and fall back to the loaded URL. Store both. The repository must handle canonical collisions defensively by merging only when URLs are clearly equivalent or when the user/import flow explicitly chooses a merge.

Metadata extraction order:

1. `link[rel="canonical"]`
2. standard meta tags such as description, author, article dates
3. Open Graph tags
4. Twitter card tags
5. favicon link tags, with `/favicon.ico` fallback
6. JSON-LD scripts

JSON-LD parsing must handle invalid JSON, arrays, `@graph`, and unrelated entities without throwing.

## UI information architecture

### Side panel

The side panel is the day-to-day current-tab surface. It should include a segmented control or tabs for current-page work, bookmarks, and annotations.

Required content:

- Current tab summary.
- Enable Marker for site.
- Bookmark state and save controls.
- Current page annotations.
- Quick create/edit/delete/jump actions.
- Links to Library and Options.

### Library page

The library page is the full management surface.

Required content:

- Global search.
- Bookmarks section with folder tree, bookmark list, and bookmark detail.
- Annotations section with filters and annotation detail.
- Page detail joining bookmark metadata and annotations.
- Import/export entry points.

### Options page

Required content:

- Default bookmark save behavior.
- Permission status.
- Chrome bookmark import settings.
- JSON import/export settings.
- Annotation display settings.

## CSS architecture

Use vanilla CSS. Avoid utility-first markup. Prefer semantic HTML and component CSS.

Main app styles:

```text
extension/src/styles/
  index.css
  reset.css
  base.css
  utilities.css
  tokens/
    colors.css
    type.css
    spacing.css
    radii.css
    shadows.css
  components/
```

`index.css` should only compose the CSS system with imports. Components get one unique root class and their own file. Parent layouts own spacing. Use CSS variables for repeated color, type, spacing, radius, and shadow decisions.

Content-script UI should mount in Shadow DOM with a separate bundled stylesheet so host page CSS does not leak into Marker UI and Marker CSS does not affect the page.

## Testing requirements

Use tests for all logic that can lose, hide, or corrupt user data.

Required test areas:

- Permission helpers.
- Page metadata extraction.
- URL/canonical identity helpers.
- Dexie repositories with fake IndexedDB.
- Bookmark folder CRUD, move, reorder, delete tree, tags, Chrome ID links.
- Chrome bookmark import mapping.
- Annotation create/update/delete/import/export.
- Selection capture with duplicate quotes, whitespace, hidden text, nested elements, cross-node ranges.
- Annotation rendering, repeated render calls, cleanup, delayed content, scroll-to-annotation.
- Markdown preview sanitization.
- Message handlers between side panel, background, and content script.

Run before handoff when extension code changes:

```sh
pnpm --filter marker-extension typecheck
pnpm --filter marker-extension test
pnpm build:extension
```
