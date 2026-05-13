# Todo And Milestones

## Milestone 1: WebView Reader

- Load URLs.
- Track current page URL and title.
- Inject basic JavaScript after page load.

Status: implemented.

## Milestone 2: Browser Shell

- Add `go_router` routing.
- Support browser tabs.
- Support bookmarks.
- Support app-managed back/forward history per tab.
- Persist bookmarks in Drift.

Status: implemented.

## Milestone 3: Library

- Add `LibraryScreen`.
- Show bookmarks as a separate section.
- Show saved or recently visited pages separately from bookmarks.
- Show recent annotations.
- Let users open a bookmark or saved page in the browser.
- Back the Library sections with Drift queries.

Status: implemented.

## Milestone 4: Selection Capture

- Detect selected text in WebView.
- Send selected text and basic context to Flutter.
- Show Cupertino annotation toolbar.

Status: implemented.

## Milestone 5: Local Annotation Persistence

- Save annotations in Drift.
- Save annotation targets.
- Save annotation bodies.
- List annotations for a page.

Status: implemented.

## Milestone 6: Highlight Rendering

- Reinject saved annotations into the page.
- Render highlights from stored selectors.
- Support deletion and rerendering.

Status: implemented.

## Milestone 7: Notes And Details

- Attach textual notes to highlights.
- Add annotation detail screen.
- Support editing annotation bodies.
- Support deleting annotations from annotation detail actions.

Status: not started.

## Milestone 8: Annotation Sidebar

- Implement `AnnotationSidebarWidget` as a native Flutter overlay in `BrowserScreen`.
- Add collapsed toggle tab with annotation count badge.
- Add scrollable annotation card list filtered by type.
- Add tap-to-jump by sending a scroll command to the WebView through the JS bridge.
- Add quick actions per card: edit, jump, delete.
- Animate open/close from trailing edge over 300 ms.

Status: not started.

## Milestone 9: Settings And Browser History

- Add `SettingsScreen`.
- Add `BrowserHistoryScreen` accessible from Settings.
- Persist browser history or page visits in Drift with enough metadata for a history list.
- Show browser history as a screen separate from Library.
- Add a clear-history action.
- Decide whether browser history should reuse `pages.lastVisitedAt` or move to a dedicated visit-events table.

Status: not started.
