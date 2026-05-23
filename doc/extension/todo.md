# Marker Chrome Extension Todo

This todo implements `doc/extension/spec.md`. Chrome is the first browser target. Keep tests close to selector, storage, metadata, and message behavior.

## Milestone 1: replace scaffold and set Chrome side panel baseline

Deliverables:

- Remove scaffold demo UI and unused assets.
- Replace popup-first manifest with Chrome side panel behavior.
- Add background service worker shell.
- Add side panel page shell.
- Add library page shell.
- Add options page shell.
- Add shared message types.
- Add `typecheck` and `test` scripts for the extension.
- Add Vitest configuration.

Acceptance:

- `pnpm --filter marker-extension typecheck` passes.
- `pnpm --filter marker-extension test` passes.
- `pnpm build:extension` emits a Chrome MV3 extension with `side_panel.default_path`.
- Extension action opens or focuses the side panel.

## Milestone 2: vanilla CSS system

Deliverables:

- `src/styles/index.css`.
- Reset, base, utilities.
- Tokens for colors, type, spacing, radii, shadows.
- Component CSS folder.
- Side panel imports shared CSS.
- Library imports shared CSS.
- Options imports shared CSS.
- Shadow DOM toolbar stylesheet path documented and wired.

Acceptance:

- Shared app UI uses semantic component classes.
- No Tailwind-style utility sprawl.
- Content-script UI styles are isolated from host pages.

## Milestone 3: permissions and injection

Deliverables:

- Permission helper module.
- Background handlers for checking current-tab host permission.
- Enable-site action from side panel.
- Programmatic content script injection after permission grant.
- Disabled states for unsupported pages and denied permissions.
- Tests for permission helpers and message handlers.

Acceptance:

- Install prompt does not request broad host permissions.
- Current-origin permission is requested only when the user enables Marker for a site or starts annotating.
- Denied permission leaves side panel usable for library/options.
- Content script is injected after grant.

## Milestone 4: Dexie schema and repositories

Deliverables:

- Dexie schema.
- Page repository.
- Bookmark folder repository.
- Bookmark repository.
- Annotation repository.
- Export/import repository.
- Repository tests with fake IndexedDB.

Acceptance:

- Pages store loaded URL and canonical URL.
- Bookmarks support folders, nested folders, tags, ordering, soft delete, and Chrome bookmark IDs.
- Annotations support targets and bodies compatible with the mobile annotation model.
- JSON export/import round trips pages, bookmarks, folders, annotations, targets, bodies, and metadata.

## Milestone 5: page metadata and page identity

Deliverables:

- `page-meta.ts`.
- Canonical URL parsing.
- Standard meta parsing.
- Open Graph parsing.
- Twitter fallback parsing.
- Favicon lookup.
- Defensive JSON-LD parsing.
- URL/canonical identity helpers.

Acceptance:

- Tests cover canonical links, OG, Twitter, invalid JSON-LD, JSON-LD arrays, `@graph`, relative images, favicon fallback, hash/query behavior, and canonical collisions.
- `page:visited` persists searchable page metadata.

## Milestone 6: Chrome bookmark integration

Deliverables:

- On-demand `bookmarks` permission flow.
- Save to Marker only / Chrome only / both.
- Setting for always ask / Marker only / Chrome only / both.
- Chrome bookmark creation helper.
- Chrome bookmark import helper.
- Storage of `chromeBookmarkId` on linked Marker bookmarks.
- Tests for save choices, denied permission fallback, and import mapping.

Acceptance:

- User can save current page to Marker, Chrome, or both.
- User can skip future save-choice dialogs with a setting.
- User can import Chrome bookmarks into Marker folders.
- Deleting a Marker bookmark does not delete Chrome unless explicitly requested.
- Deleting Chrome externally does not delete Marker records in MVP.

## Milestone 7: selection capture

Status: Complete.

Deliverables:

- Quote selector capture.
- Text position selector capture.
- CSS selector fallback.
- Hidden text filtering.
- Whitespace-safe offset handling.
- Selection clear behavior.

Acceptance:

- Tests cover duplicate quotes, prefix/suffix scoring, whitespace, hidden text, nested inline elements, cross-element ranges, empty selections, and invalid selections.
- Leading/trailing whitespace does not corrupt offsets.

## Milestone 8: annotation rendering

Status: Complete.

Deliverables:

- Quote-first range resolution.
- Position fallback.
- CSS fallback.
- Highlight rendering.
- Underline rendering.
- Render cleanup/removal.
- Scroll-to-annotation.
- Short retry or MutationObserver for delayed content.

Acceptance:

- Tests cover multi-node ranges, repeated render calls, deletion cleanup, hidden nodes, nested annotations, delayed content, and scroll-to-annotation.
- Saved annotations reappear after reload on enabled sites.

## Milestone 9: annotation toolbar and Markdown note UI

Status: Complete.

Deliverables:

- Shadow DOM toolbar.
- Highlight action.
- Underline action.
- Markdown note dialog.
- Live preview.
- Sanitized Markdown rendering.
- Save/cancel/dismiss behavior.
- Toolbar-to-background create messages.

Acceptance:

- User can create highlight, underline, and Markdown note annotations from a selection.
- Markdown preview updates while editing.
- Preview is sanitized.
- Toolbar does not inherit page CSS or affect page layout.

## Milestone 10: side panel

Deliverables:

- Current tab summary.
- Site enable state.
- Segmented control for Page / Bookmarks / Annotations.
- Current page bookmark state and save controls.
- Current page annotation list.
- Jump/edit/delete controls.
- Highlight visibility toggle.
- Links to Library and Options.

Acceptance:

- Side panel works against the active tab.
- Side panel updates after annotation create/edit/delete.
- Side panel can jump to an annotation in the active tab.
- Bookmark save behavior follows the user setting.

## Milestone 11: full library page

Deliverables:

- Global search.
- Bookmarks section.
- Folder tree.
- Bookmark list and detail.
- Annotation section.
- Annotation filters for highlights, underlines, notes, page/domain.
- Annotation detail.
- Page detail combining bookmark metadata and annotations.
- JSON import/export entry points.
- Chrome bookmark import entry point.

Acceptance:

- Search covers bookmark title, URL, description, tags, folder path, page title, annotation quote, and note text.
- Bookmarks and annotations are separate first-class sections.
- Page detail shows bookmark state and annotations together.
- JSON import/export round trips with mobile-compatible shape.

## Milestone 12: options page

Deliverables:

- Bookmark save behavior setting.
- Permission status panel.
- Site permission management entry points.
- Chrome bookmark integration controls.
- JSON import/export settings.
- Annotation display settings.

Acceptance:

- User can switch default bookmark save behavior.
- User can see whether Chrome bookmarks permission is granted.
- User can start import/export from settings.

## Milestone 13: packaging and QA

Deliverables:

- Chrome production zip.
- Icons.
- Privacy policy copy.
- Permission rationale copy.
- Manual QA checklist.
- Store submission notes.

Acceptance:

- `pnpm --filter marker-extension typecheck` passes.
- `pnpm --filter marker-extension test` passes.
- `pnpm build:extension` passes.
- Manual Chrome smoke test passes.

## Later milestones

- Firefox sidebar build.
- Continuous Chrome bookmark sync.
- Bidirectional conflict resolution.
- Bulk editing.
- Advanced drag/drop polish.
- Store listing screenshots.
