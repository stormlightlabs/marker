<!-- markdownlint-disable MD041 -->
![Marker banner](./assets/images/hero.png)

# Marker

A reading and annotation browser for iOS and Android. Open any webpage,
select text, and create highlights or notes. Annotations stay on device and
appear the next time you visit the page.

## What it does

- Select text, then choose: highlight, underline, or attach a note.
- Notes can be authored in Markdown
- Annotations are anchored with layered selectors (quote, position, CSS) modeled on the W3C Web Annotation spec.
- A sidebar panel lists all annotations on the current page, with quick
  actions to jump, edit, or delete.
- Bookmarks and browsing history are stored alongside annotations.

## Technology

| Concern           | Package / approach                 |
| ----------------- | ---------------------------------- |
| Framework         | Flutter (Cupertino UI)             |
| State             | Riverpod                           |
| Routing           | go_router                          |
| Database          | Drift / SQLite                     |
| Web rendering     | flutter_webview                    |
| Annotation bridge | Injected JavaScript                |
| Note editor       | code_forge + flutter_markdown_plus |

### Architecture

State flows in one direction:

```text
WebView JS event
  -> webViewBridgeProvider
  -> annotationRepositoryProvider (Drift)
  -> annotationsForPageProvider
  -> WebView render command
```

The JavaScript layer only handles DOM selection and rendering. It does not
own persistence and does not make routing decisions.

### Annotations

Each annotation stores a layered selector so anchoring degrades gracefully
when page DOM changes:

1. `TextQuoteSelector` - exact text with surrounding context (primary)
2. `TextPositionSelector` - character offsets (fallback)
3. `CssSelector` - element path (last resort)

The schema follows the W3C Web Annotation data model with four motivations:
`highlighting`, `commenting`, `tagging`, `linking`.

## Development

### Prerequisites

- Flutter SDK >= 3.11
- Dart SDK ^3.11.5
- Xcode (iOS builds)
- Android Studio (Android builds)

### Getting started

```sh
flutter pub get
dart run build_runner build
flutter run
```

### Regenerating native assets

After changing `assets/images/icon.png` or `assets/images/splash.png`, regenerate the native launcher icons and splash screens:

```sh
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Running tests

```sh
flutter analyze
flutter test --reporter=failures-only
```
