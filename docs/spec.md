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
│   └── AnnotationSidebarWidget (overlay, slides in from trailing edge)
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
