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

Status: implemented.

## Milestone 8: Annotation Sidebar

- Implement `AnnotationSidebarWidget` as a native Flutter overlay in `BrowserScreen`.
- Add collapsed toggle tab with annotation count badge.
- Add scrollable annotation card list filtered by type.
- Add tap-to-jump by sending a scroll command to the WebView through the JS bridge.
- Add quick actions per card: edit, jump, delete.
- Animate open/close from trailing edge over 300 ms.

Status: implemented.

## Milestone 9: Settings And Browser History

- Add `SettingsScreen`.
- Add `BrowserHistoryScreen` accessible from Settings.
- Persist browser history or page visits in Drift with enough metadata for a history list.
- Show browser history as a screen separate from Library.
- Add a clear-history action.
- Decide whether browser history should reuse `pages.lastVisitedAt` or move to a dedicated visit-events table.

Status: not started.

## Milestone 10: Link Long-Press Menus

- Detect long-press or context-menu gestures on webpage links in injected JavaScript.
- Send link metadata to Flutter through the WebView bridge, including `href`, visible text, and current page URL.
- Show a Cupertino action sheet for link actions.
- Support opening the link in the current tab.
- Support opening the link in a new browser tab.
- Support copying the link URL.
- Support bookmarking the link URL.
- Avoid triggering link menus for ordinary text selection or non-link long presses.

Status: not started.

## Milestone 11: Browser Kebab Menu

- Add a browser overflow or kebab menu entry point to the browser chrome.
- Show a Cupertino action sheet or menu with page and browser actions.
- Include page actions such as reload, copy URL, share, and bookmark or unbookmark.
- Include tab actions such as new tab and tab overview.
- Include annotation actions such as open annotations and hide or show rendered highlights.
- Include history/settings entry points once those screens exist.
- Keep the action list grouped and testable as the menu grows.

Status: not started.

## Milestone 12: Edge Swipe Navigation

- Add reusable edge-swipe navigation around the WebView reading surface.
- Support left-edge swipe back when the active tab can go back.
- Support right-edge swipe forward when the active tab can go forward.
- Use distance and velocity thresholds to avoid accidental navigation.
- Avoid hijacking normal webpage vertical or horizontal scrolling.
- Show a subtle drag affordance while swiping.
- Respect current browser history state and disable unavailable directions.

Status: not started.
