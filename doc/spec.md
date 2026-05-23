# Spec: Flutter WebView Highlighter with W3C Annotations

## Goal

Build a mobile-first web reading and annotation app that lets users open webpages in an embedded WebView, highlight selected text, attach notes, and persist annotations locally using a W3C-inspired annotation model.

The app should feel native on iOS through Cupertino UI, while keeping the core architecture portable enough for Android support.

## Core Stack

| Layer | Choice |
| --- | --- |
| App framework | Flutter |
| UI style | Cupertino UI |
| State management | Riverpod |
| Routing | go_router |
| Local database | Drift / SQLite |
| Web rendering | Flutter WebView |
| Annotation bridge | Injected JavaScript |
| Annotation model | W3C Web Annotation-inspired schema |

## Product Scope

### Primary User Flow

1. User enters or opens a URL.
2. App loads the page in a WebView.
3. User selects text inside the webpage.
4. Injected JavaScript captures the selection.
5. Flutter receives selection metadata through a JS bridge.
6. User chooses an annotation action:
   - Highlight
   - Note
   - Underline
   - Remove annotation
7. Annotation is saved locally through Drift.
8. When the page is reopened, annotations are rehydrated and rendered back into the WebView.

## Architecture

```text
Flutter App
├── Cupertino UI
│   ├── Library / saved pages
│   ├── Browser screen
│   ├── Settings screen
│   ├── Browser history screen
│   ├── Annotation toolbar
│   ├── Note editor
│   └── Annotation sidebar widget
│
├── Riverpod State
│   ├── Current page controller
│   ├── Annotation repository provider
│   ├── Bookmark repository provider
│   ├── WebView bridge controller
│   ├── Reader session state
│   └── Sidebar open/filter state
│
├── Drift Database
│   ├── pages
│   ├── bookmarks
│   ├── annotations
│   ├── annotation_targets
│   └── annotation_bodies
│
└── WebView Runtime
    ├── Injected selection JS
    ├── DOM range serialization
    ├── Annotation rendering JS
    ├── EasyList ad blocking
    ├── Cosmetic filter injection
    └── JS ↔ Flutter message bridge
```

## Key Components

## 1. WebView Reader

The reader screen owns the embedded WebView and coordinates page lifecycle events.

Responsibilities:

- Load arbitrary webpages.
- Track current page URL and title.
- Track app-managed tabs, bookmarks, and per-tab back/forward history.
- Inject the highlighter JavaScript after page load.
- Listen for selection events from JavaScript.
- Send stored annotations back into the page for rendering.
- Handle navigation, reloads, and page identity.

The page identity should be based on canonical URL where possible, falling back to the loaded URL.

## 2. JavaScript Highlighter

Injected JavaScript is responsible for DOM-aware selection and rendering.

Responsibilities:

- Detect user text selection.
- Serialize selected DOM ranges.
- Generate stable selectors.
- Render highlights and underlines.
- Remove or update rendered annotations.
- Send selection payloads to Flutter.

The JavaScript layer should not own persistence. It should act as a page-local annotation runtime.

## 3. Annotation Targeting

Each annotation should support multiple targeting strategies because webpage DOMs change over time.

Use a layered selector strategy:

```json
{
  "selector": [
    {
      "type": "TextQuoteSelector",
      "exact": "selected text",
      "prefix": "text before selection",
      "suffix": "text after selection"
    },
    {
      "type": "TextPositionSelector",
      "start": 1024,
      "end": 1089
    },
    {
      "type": "CssSelector",
      "value": "article p:nth-of-type(3)"
    }
  ]
}
```

Priority order for rehydration:

1. `TextQuoteSelector`
2. `TextPositionSelector`
3. `CssSelector`

The app should prefer quote-based anchoring because it is more resilient than raw DOM paths.

## 4. W3C Annotation Model

Persist annotations using a W3C-inspired structure.

Example:

```json
{
  "id": "annotation_123",
  "type": "Annotation",
  "motivation": "highlighting",
  "body": {
    "type": "TextualBody",
    "value": "Important point about local-first annotation.",
    "format": "text/plain"
  },
  "target": {
    "source": "https://example.com/article",
    "selector": [
      {
        "type": "TextQuoteSelector",
        "exact": "local-first annotation",
        "prefix": "Important point about ",
        "suffix": "."
      }
    ]
  },
  "created": "2026-05-12T21:00:00Z",
  "modified": "2026-05-12T21:00:00Z"
}
```

Supported motivations:

| Motivation | Meaning |
| --- | --- |
| `highlighting` | Visual highlight |
| `commenting` | Note attached to text |
| `tagging` | User-applied label |
| `linking` | Reference to another resource |

### Annotation Creation Decisions

Toolbar actions map to persisted annotations as follows:

| Action | Motivation | Bodies |
| --- | --- | --- |
| Highlight | `highlighting` | `StyleHint`, `application/json`, e.g. `{"style":"highlight","color":"#FFCC00"}` |
| Note | `commenting` | `TextualBody`, `text/markdown`, plus a `StyleHint` for the attached highlight color |
| Underline | `highlighting` | `StyleHint`, `application/json`, e.g. `{"style":"underline","color":"#64D2FF"}` |
| Remove | none at selection-capture time | Clears the active selection; deletion is only valid after an existing annotation is identified |

The `annotation_targets.selectorJson` field stores the selector list for the selected range:

```json
[
  {
    "type": "TextQuoteSelector",
    "exact": "selected text",
    "prefix": "text before ",
    "suffix": " text after"
  },
  {
    "type": "TextPositionSelector",
    "start": 1024,
    "end": 1037
  },
  {
    "type": "CssSelector",
    "value": "article > p:nth-of-type(3)"
  }
]
```

Notes should be authored and persisted as Markdown (`TextualBody`, `text/markdown`). The chosen note editor stack is:

| Layer | Package | Role |
| --- | --- | --- |
| Markdown source editor | `code_forge` | Dark, multiline Markdown/code editing surface. Use `langMarkdown`, line wrapping, no gutter, no suggestions, no LSP. |
| Markdown preview/rendering | `flutter_markdown_plus` | Render note previews and future annotation detail bodies. |
| Syntax highlighting | `re_highlight` | Highlight Markdown editor text and code fences in rendered Markdown previews. |

`code_forge` depends on `dart:io`, so this stack targets the app's iOS/Android scope and is not expected to support Flutter web. Keep the persisted body canonical as Markdown even though editor and preview widgets may have their own internal highlighting models.

## 5. Drift Persistence Model

### `pages`

Stores known webpages.

| Field | Type |
| --- | --- |
| `id` | text / uuid |
| `url` | text |
| `canonicalUrl` | text nullable |
| `title` | text nullable |
| `createdAt` | datetime |
| `lastVisitedAt` | datetime |

### `bookmarks`

Stores pages saved by the user for the Library.

| Field | Type |
| --- | --- |
| `id` | text / uuid |
| `url` | text unique |
| `title` | text nullable |
| `createdAt` | datetime |

### `annotations`

Stores annotation-level metadata.

| Field | Type |
| --- | --- |
| `id` | text / uuid |
| `pageId` | text |
| `motivation` | text |
| `createdAt` | datetime |
| `modifiedAt` | datetime |
| `deletedAt` | datetime nullable |

### `annotation_targets`

Stores serialized W3C target data.

| Field | Type |
| --- | --- |
| `id` | text / uuid |
| `annotationId` | text |
| `sourceUrl` | text |
| `selectorJson` | text |

### `annotation_bodies`

Stores note/comment/tag body content.

| Field | Type |
| --- | --- |
| `id` | text / uuid |
| `annotationId` | text |
| `type` | text |
| `format` | text nullable |
| `value` | text |

## 6. Riverpod State Model

Use Riverpod to separate UI, persistence, and WebView concerns.

Suggested providers:

```text
databaseProvider
annotationRepositoryProvider
bookmarkRepositoryProvider
currentPageProvider
annotationsForPageProvider
webViewBridgeProvider
selectionStateProvider
readerControllerProvider
sidebarStateProvider
```

State should flow one way:

```text
WebView JS event
→ WebView bridge
→ Riverpod controller
→ Drift repository
→ Annotation state refresh
→ WebView render command
```

## 7. UI Structure

Use Cupertino-first screens:

```text
CupertinoApp
├── LibraryScreen
│   ├── Bookmarks
│   ├── Saved pages
│   └── Recent annotations
│
├── BrowserScreen
│   ├── URL/search bar
│   ├── Tabs
│   ├── Bookmarks action
│   ├── WebView
│   ├── Floating annotation toolbar
│   ├── Bottom sheet note editor
│   ├── AnnotationSidebarWidget (overlay, slides in from trailing edge)
│   ├── Link context action sheet
│   ├── Browser overflow menu
│   └── Edge swipe navigation wrapper
│
├── SettingsScreen
│   └── Browser history entry point
│
├── BrowserHistoryScreen
│   ├── Recent page visits
│   └── Clear history action
│
└── AnnotationDetailScreen
    ├── Quote preview
    ├── Note body
    ├── Source URL
    └── Created/modified metadata
```

The browser screen should keep the reading surface dominant. Annotation controls should appear contextually only after text selection.

## 8. Annotation Sidebar Widget

The sidebar is a native Flutter overlay widget that slides in from the trailing edge of the `BrowserScreen`. It is not implemented in JavaScript. It is a Flutter `Stack` child that sits above the `WebView`.

The sidebar gives users a persistent, scrollable view of all annotations on the current page without leaving the browser.

### Behavior

- A collapsed toggle tab is always visible on the trailing edge of the `WebView` when the current page has at least one annotation. It shows a count badge.
- Tapping the toggle slides the sidebar open, covering about 78% of screen width.
- The exposed leading strip acts as a scrim. Tapping it closes the sidebar.
- Tapping an annotation card in the sidebar scrolls the WebView to that annotation through a JS bridge command and highlights the card as focused.
- Each card has quick-action buttons: Edit, Jump, Delete.
- The sidebar can be filtered by annotation type: All, Highlights, Notes, Underlines.

### Implementation Notes

- The widget is a `ConsumerWidget` backed by `annotationsForPageProvider`.
- It does not inject or manipulate the DOM. Scroll-to-annotation is handled by sending a message through `webViewBridgeProvider` with the annotation selector.
- The toggle tab and sidebar are rendered inside a `Stack` in `BrowserScreen`, above the `WebView` but below modal sheets.
- Animation: `AnimatedPositioned` or `SlideTransition` on the trailing axis, 300 ms ease-in-out curve.

```text
BrowserScreen (Stack)
├── WebView (fills screen)
├── AnnotationSidebarWidget
│   ├── CollapsedToggleTab  (always visible when annotations exist)
│   └── SidebarPanel        (visible when open)
│       ├── Header (title + URL chip + close button)
│       ├── FilterPillRow
│       ├── AnnotationCardList (scrollable)
│       │   └── AnnotationCard
│       │       ├── Accent bar (color-coded by type)
│       │       ├── Quote text
│       │       ├── Note preview (if present)
│       │       ├── Type tag + timestamp
│       │       └── Quick actions (Edit · Jump · Delete)
│       └── NewAnnotationButton
└── FloatingAnnotationToolbar  (shown on text selection, above sidebar)
```

## 9. Link Long-Press Menus

The app should support native link actions when the user long-presses a link in the WebView. Link detection happens in injected JavaScript because Flutter cannot reliably inspect DOM hit targets from outside the WebView.

### Behavior

- Long-pressing a webpage link opens a Cupertino action sheet.
- The action sheet shows the link label or URL and offers link-specific actions.
- Long-pressing non-link text should keep normal text selection behavior.
- Ordinary taps on links should preserve normal page navigation.
- Link menus should not appear while an annotation selection toolbar is active.

### Link Payload

The JavaScript bridge sends a message to Flutter when a link long press is recognized:

```json
{
  "type": "link-long-pressed",
  "payload": {
    "href": "https://example.com/article",
    "text": "Read the article",
    "pageUrl": "https://current-page.example",
    "pageTitle": "Current Page"
  }
}
```

Required fields:

| Field | Meaning |
| --- | --- |
| `href` | Fully resolved link URL from the nearest ancestor anchor. |
| `text` | Trimmed visible link text, nullable or empty when the link has no text. |
| `pageUrl` | Current WebView URL when the gesture occurred. |
| `pageTitle` | Current document title, nullable. |

### Actions

Initial actions:

- Open in Current Tab.
- Open in New Tab.
- Copy Link.
- Add Bookmark.
- Cancel.

The JavaScript layer should only detect and report the link gesture. Flutter owns the action sheet, tab operations, bookmark writes, clipboard interaction, and navigation state changes.

### Implementation Notes

- Extend the injected bridge with a link gesture detector that observes `contextmenu` plus touch/mouse long-press events.
- Resolve anchors with `event.target.closest('a[href]')`.
- Use a press duration threshold so ordinary taps do not open the menu.
- Cancel the pending long press on movement, scroll, selection changes, or touch end before the threshold.
- Add a dedicated Riverpod controller or state object for active link context if the action sheet needs testable state beyond the immediate bridge event.
- Use a second JavaScript channel or typed bridge event parsing so link events do not get mixed with selection capture logic.

## 10. Browser Kebab Menu

The browser should have a single overflow menu for page-level and browser-level actions as the browser chrome grows. This keeps the address bar compact and prevents the bottom toolbar from becoming a dumping ground for controls.

### Behavior

- A kebab or overflow button appears in the browser chrome.
- Tapping it opens a Cupertino action sheet or menu.
- The menu groups actions by purpose: page, tab, annotations, history/settings.
- Disabled actions should reflect current state, such as no back history or no annotations.
- The menu should be reachable with a stable semantic label for tests and accessibility.

### Initial Action Groups

Page actions:

- Reload.
- Copy URL.
- Share.
- Bookmark or Unbookmark.

Tab actions:

- New Tab.
- Show Tabs.
- Close Current Tab when more than one tab exists.

Annotation actions:

- Open Annotations when the page has annotations.
- Hide or Show Rendered Highlights.

History and settings actions:

- Open History once `BrowserHistoryScreen` exists.
- Open Settings once `SettingsScreen` exists.

### Implementation Notes

- Keep menu construction in a dedicated widget or helper once it grows beyond a few actions.
- Actions should delegate to `ReaderController`, repositories, or WebView bridge methods rather than directly mutating UI state in the menu widget.
- Use the same bookmark repository and tab methods as existing browser controls.
- Keep destructive actions behind confirmation when they delete user data or close meaningful state.
- Tests should cover menu visibility, state-dependent labels, and one representative action from each group.

## 11. Branding Typography

Use **Righteous** for the Marker app wordmark and explicit logo text in the mobile app. Bundle it as a Flutter font asset before applying it in production UI.

Suggested usage:

- App wordmark/logo lockups.
- Splash or launch-adjacent branded screens.
- Empty states where the Marker brand is the subject.

Do not replace Cupertino/system text for ordinary controls, settings, browser chrome, annotation cards, or reading surfaces. Righteous should identify the product, not become the app's default UI font.

## 12. Toggleable Ad Blocking

Marker includes a local EasyList-based blocker for the embedded browser. The blocker is enabled by default and can be turned off from Settings when a page breaks.

### Behavior

- Settings shows an Ad Blocker switch.
- New installs and migrated installs default to enabled when no stored setting exists.
- Toggling the switch persists the setting in Drift and reloads the active WebView with the new rules.
- The v1 bundled list is `assets/filters/easylist.txt`.
- EasyPrivacy is a planned follow-up, not part of the v1 bundle.

### Filtering Model

The app parses EasyList syntax into two rule groups:

| Rule type | Runtime behavior |
| --- | --- |
| Network filters | Compile to WebView content blockers and Android request interception where available. |
| Cosmetic filters | Inject a page-local runtime that hides matching CSS selectors and watches later DOM changes. |

Supported v1 syntax:

- Comments and metadata.
- `@@` exceptions.
- `||host^`, `|` anchors, `^` separators, `*` wildcards, plain substring rules, and regex rules.
- `$domain` / `$from`, first-party / third-party, common resource types, and `$important`.
- `##`, domain-scoped `##`, and `#@#` cosmetic exceptions.

Unsupported uBlock/EasyList features are ignored and counted for diagnostics: scriptlets, HTML filters, response-header filters, redirects, CSP, removeparam, replace, urlskip, and procedural cosmetic selectors that cannot be safely applied inside the mobile WebView.

### Persistence

Settings use a Drift-backed key/value table:

| Field | Type |
| --- | --- |
| `key` | text primary key |
| `value` | text |
| `updatedAt` | datetime |

The `ad_block_enabled` key stores `true` or `false`.

## 13. Edge Swipe Navigation

The browser should support edge-swipe back and forward gestures around the WebView reading surface while avoiding conflict with normal webpage scrolling and text selection.

### Behavior

- A left-edge horizontal swipe navigates back when the active tab can go back.
- A right-edge horizontal swipe navigates forward when the active tab can go forward.
- Swipes should require a minimum drag distance or velocity before triggering navigation.
- Vertical scrolls, ordinary horizontal webpage gestures, and text selection should not trigger browser navigation.
- A subtle chevron or progress affordance should appear while the edge gesture is active.
- The gesture should be disabled in unavailable directions based on current tab history.

### Implementation Notes

- Implement this as a reusable Flutter widget, e.g. `EdgeSwipeNavigator`, around the WebView/sidebar stack.
- Restrict gesture start zones to narrow leading/trailing edge bands.
- Use `ReaderSessionState.canGoBack` and `canGoForward` to decide whether a gesture can begin.
- Trigger existing `_goBack` and `_goForward` callbacks instead of duplicating history logic.
- Avoid placing gesture detectors above modal sheets, action sheets, or the annotation sidebar panel.
- Tests should cover threshold behavior, disabled directions, and successful back/forward callback invocation.

## v2

The first version should not include:

- Full browser replacement features
- Account system
- PDF annotation
- Offline webpage archival
- Cloud sync
  - Social/public annotations
  - Cross-device conflict resolution

These can be added later once local annotation capture and rehydration are reliable.

## Design Principles

- **Local-first:** annotations should work without an account or backend.
- **Resilient anchoring:** store more than one selector type.
- **Thin JavaScript layer:** JS manipulates the DOM but does not own app logic.
- **Native-feeling UI:** prefer Cupertino controls, sheets, and transitions.
- **Portable domain model:** keep annotation entities independent from Flutter widgets and WebView implementation details.

## Definition of Done

The first usable version is complete when:

- A user can open a webpage.
- Select text inside the WebView.
- Create a highlight.
- Optionally attach a note.
- Close and reopen the page.
- See the annotation restored in the correct location.
- View and edit saved annotations from a native Flutter interface.
