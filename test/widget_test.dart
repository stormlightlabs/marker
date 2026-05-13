import 'package:drift/native.dart';
import 'package:code_forge/code_forge.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/app/marker_app.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';
import 'package:marker/src/features/browser/webview/browser_webview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  late _FakeWebViewPlatform platform;
  late AppDatabase database;

  setUp(() {
    platform = _FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('BrowserScreen loads the default URL and records the page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          browserWebViewBuilderProvider.overrideWithValue(
            (context, controller) => const Center(child: Text('Fake WebView')),
          ),
        ],
        child: const MarkerApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Library'), findsWidgets);
    expect(find.text('No Saved Pages'), findsOneWidget);
    await tester.tap(find.text('Browser'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(find.text('Browser'), findsOneWidget);
    expect(platform.controller.loadedUri, Uri.parse('https://news.ycombinator.com'));
    expect(platform.controller.injectedScripts.first, contains('__markerReaderInstalled'));
    expect(platform.controller.injectedScripts.last, contains('renderAnnotations([])'));

    final pages = await database.select(database.pages).get();
    expect(pages, hasLength(1));
    expect(pages.single.url, 'https://news.ycombinator.com');
    expect(pages.single.canonicalUrl, 'https://news.ycombinator.com/news');
    expect(pages.single.title, 'Example Domain');
  });

  testWidgets('BrowserScreen rehydrates saved annotations after page load', (tester) async {
    await _seedPageAnnotation(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          browserWebViewBuilderProvider.overrideWithValue(
            (context, controller) => const Center(child: Text('Fake WebView')),
          ),
        ],
        child: const MarkerApp(),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await tester.pump();
    await tester.pump();

    final renderScript = platform.controller.injectedScripts.last;
    expect(renderScript, contains('renderAnnotations'));
    expect(renderScript, contains('"id":"saved-annotation"'));
    expect(renderScript, contains('"exact":"selected text"'));
    expect(renderScript, contains('"style":"highlight"'));
    expect(renderScript, contains('"color":"#FFCC00"'));
  });

  testWidgets('BrowserScreen exposes bookmark and tab controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          browserWebViewBuilderProvider.overrideWithValue(
            (context, controller) => const Center(child: Text('Fake WebView')),
          ),
        ],
        child: const MarkerApp(),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Bookmarks 0'), findsOneWidget);
    expect(find.text('Tabs 1'), findsOneWidget);

    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Bookmarks 1'), findsOneWidget);

    await tester.tap(find.text('Tabs 1'));
    await tester.pumpAndSettle();

    expect(find.text('New Tab'), findsOneWidget);

    await tester.tap(find.text('New Tab'));
    await tester.pumpAndSettle();

    expect(find.text('Tabs 2'), findsOneWidget);
    expect(platform.controller.loadedUris, hasLength(2));
  });

  testWidgets('BrowserScreen shows annotation toolbar for captured selections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          browserWebViewBuilderProvider.overrideWithValue(
            (context, controller) => const Center(child: Text('Fake WebView')),
          ),
        ],
        child: const MarkerApp(),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await tester.pump();
    await tester.pump();

    platform.controller.sendSelectionMessage(
      '{"type":"selection-captured","payload":{"exact":"selected text","prefix":"before ","suffix":" after","sourceUrl":"https://news.ycombinator.com","pageTitle":"Hacker News","textPositionStart":7,"textPositionEnd":20,"cssSelector":"p:nth-of-type(1)"}}',
    );
    await tester.pump();

    expect(find.text('selected text'), findsOneWidget);
    expect(find.text('Highlight'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Underline'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.text('Highlight'));
    await tester.pumpAndSettle();

    expect(find.text('selected text'), findsNothing);
    expect(platform.controller.injectedScripts.last, contains('clearSelection'));
    expect(platform.controller.injectedScripts.any((script) => script.contains('"exact":"selected text"')), isTrue);

    final annotations = await database.select(database.annotations).get();
    final bodies = await database.select(database.annotationBodies).get();
    expect(annotations.single.motivation, 'highlighting');
    expect(bodies.single.type, 'StyleHint');
  });

  testWidgets('BrowserScreen opens note editor and saves markdown note annotations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          browserWebViewBuilderProvider.overrideWithValue(
            (context, controller) => const Center(child: Text('Fake WebView')),
          ),
        ],
        child: const MarkerApp(),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await tester.pump();
    await tester.pump();

    platform.controller.sendSelectionMessage(
      '{"type":"selection-captured","payload":{"exact":"note text","prefix":"before ","suffix":" after","sourceUrl":"https://news.ycombinator.com","pageTitle":"Hacker News","textPositionStart":7,"textPositionEnd":16,"cssSelector":"p:nth-of-type(1)"}}',
    );
    await tester.pump();

    await tester.tap(find.text('Note'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Add Note'), findsOneWidget);

    await tester.tap(find.byType(CodeForge));
    await tester.pump();
    tester.testTextInput.enterText('**Markdown** note');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final annotations = await database.select(database.annotations).get();
    final bodies = await database.select(database.annotationBodies).get();
    expect(annotations.single.motivation, 'commenting');
    expect(bodies.firstWhere((body) => body.type == 'TextualBody').format, 'text/markdown');
    expect(bodies.firstWhere((body) => body.type == 'TextualBody').value, '**Markdown** note');
  });

  testWidgets('LibraryScreen shows stored library sections', (tester) async {
    await _seedLibrary(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          browserWebViewBuilderProvider.overrideWithValue(
            (context, controller) => const Center(child: Text('Fake WebView')),
          ),
        ],
        child: const MarkerApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('LIBRARY'), findsNothing);
    expect(find.text('BOOKMARKS'), findsOneWidget);
    expect(find.text('RECENT PAGES'), findsOneWidget);
    expect(find.text('RECENT ANNOTATIONS'), findsOneWidget);
    expect(find.text('Saved Article'), findsOneWidget);
    expect(find.text('Recent Article'), findsOneWidget);
    expect(find.text('highlighting'), findsOneWidget);

    await tester.tap(find.text('Recent Article'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(platform.controller.loadedUri, Uri.parse('https://example.com/recent'));
  });
}

Future<void> _seedLibrary(AppDatabase database) async {
  final savedAt = DateTime.utc(2026, 5, 13, 10);
  final recentAt = DateTime.utc(2026, 5, 13, 11);
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'saved-page',
          url: 'https://example.com/saved',
          title: const Value('Saved Article'),
          createdAt: savedAt,
          lastVisitedAt: savedAt,
        ),
      );
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'recent-page',
          url: 'https://example.com/recent',
          title: const Value('Recent Article'),
          createdAt: recentAt,
          lastVisitedAt: recentAt,
        ),
      );
  await database
      .into(database.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          id: 'bookmark',
          url: 'https://example.com/saved',
          title: const Value('Saved Article'),
          createdAt: savedAt,
        ),
      );
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: 'annotation',
          pageId: 'recent-page',
          motivation: 'highlighting',
          createdAt: recentAt,
          modifiedAt: recentAt,
        ),
      );
  await database
      .into(database.annotationTargets)
      .insert(
        AnnotationTargetsCompanion.insert(
          id: 'target',
          annotationId: 'annotation',
          sourceUrl: 'https://example.com/recent',
          selectorJson: '{"selector":[{"type":"TextQuoteSelector","exact":"important quote"}]}',
        ),
      );
}

Future<void> _seedPageAnnotation(AppDatabase database) async {
  final now = DateTime.utc(2026, 5, 13, 12);
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'news-page',
          url: 'https://news.ycombinator.com',
          canonicalUrl: const Value('https://news.ycombinator.com/news'),
          title: const Value('Hacker News'),
          createdAt: now,
          lastVisitedAt: now,
        ),
      );
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: 'saved-annotation',
          pageId: 'news-page',
          motivation: 'highlighting',
          createdAt: now,
          modifiedAt: now,
        ),
      );
  await database
      .into(database.annotationTargets)
      .insert(
        AnnotationTargetsCompanion.insert(
          id: 'saved-target',
          annotationId: 'saved-annotation',
          sourceUrl: 'https://news.ycombinator.com',
          selectorJson:
              '[{"type":"TextQuoteSelector","exact":"selected text","prefix":"before ","suffix":" after"},{"type":"TextPositionSelector","start":7,"end":20}]',
        ),
      );
  await database
      .into(database.annotationBodies)
      .insert(
        AnnotationBodiesCompanion.insert(
          id: 'saved-body',
          annotationId: 'saved-annotation',
          type: 'StyleHint',
          format: const Value('application/json'),
          value: '{"style":"highlight","color":"#FFCC00"}',
        ),
      );
}

class _FakeWebViewPlatform extends WebViewPlatform {
  late final _FakePlatformWebViewController controller;

  @override
  PlatformWebViewController createPlatformWebViewController(PlatformWebViewControllerCreationParams params) {
    controller = _FakePlatformWebViewController(params);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(PlatformNavigationDelegateCreationParams params) {
    return _FakePlatformNavigationDelegate(params);
  }
}

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params) : super.implementation();

  Uri? loadedUri;
  final loadedUris = <Uri>[];
  final injectedScripts = <String>[];
  _FakePlatformNavigationDelegate? navigationDelegate;
  final javaScriptChannels = <String, JavaScriptChannelParams>{};

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {
    navigationDelegate = handler as _FakePlatformNavigationDelegate;
  }

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams javaScriptChannelParams) async {
    javaScriptChannels[javaScriptChannelParams.name] = javaScriptChannelParams;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedUri = params.uri;
    loadedUris.add(params.uri);
    navigationDelegate?.onProgress?.call(40);
    navigationDelegate?.onProgress?.call(100);
    navigationDelegate?.onPageFinished?.call(params.uri.toString());
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    injectedScripts.add(javaScript);
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    return '"https://news.ycombinator.com/news"';
  }

  @override
  Future<String?> getTitle() async => 'Example Domain';

  @override
  Future<String?> currentUrl() async => loadedUri?.toString();

  void sendSelectionMessage(String message) {
    javaScriptChannels['MarkerSelection']?.onMessageReceived(JavaScriptMessage(message: message));
  }
}

class _FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(super.params) : super.implementation();

  ProgressCallback? onProgress;
  PageEventCallback? onPageFinished;
  WebResourceErrorCallback? onWebResourceError;

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    this.onProgress = onProgress;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    this.onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async {
    this.onWebResourceError = onWebResourceError;
  }
}
