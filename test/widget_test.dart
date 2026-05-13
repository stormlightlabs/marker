import 'package:drift/native.dart';
import 'package:code_forge/code_forge.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/app/marker_app.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';
import 'package:marker/src/features/browser/application/native_share_controller.dart';
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
    await _pumpRouteTransition(tester);

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(find.text('Browser'), findsWidgets);
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
    await _pumpRouteTransition(tester);

    final renderScript = platform.controller.injectedScripts.last;
    expect(renderScript, contains('renderAnnotations'));
    expect(renderScript, contains('"id":"saved-annotation"'));
    expect(renderScript, contains('"exact":"selected text"'));
    expect(renderScript, contains('"style":"highlight"'));
    expect(renderScript, contains('"color":"#FFCC00"'));
  });

  testWidgets('BrowserScreen annotation sidebar filters, jumps, edits, and deletes', (tester) async {
    await _seedSidebarAnnotations(database);

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
    await _pumpRouteTransition(tester);
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    expect(find.text('Annotations'), findsOneWidget);
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Underlines'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('note quote'), findsOneWidget);
    expect(find.textContaining('highlight quote'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Jump').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(platform.controller.injectedScripts.last, contains('scrollToAnnotation("note-annotation")'));

    await tester.tap(find.bySemanticsLabel('Edit').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Edit Note'), findsOneWidget);
    await tester.tap(find.byType(CodeForge));
    await tester.pump();
    tester.testTextInput.enterText('Updated sidebar note');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final editedBody = (await database.select(database.annotationBodies).get()).firstWhere(
      (body) => body.annotationId == 'note-annotation' && body.type == 'TextualBody',
    );
    expect(editedBody.value, 'Updated sidebar note');

    await tester.tap(find.bySemanticsLabel('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final deleted = await (database.select(
      database.annotations,
    )..where((annotation) => annotation.id.equals('note-annotation'))).getSingle();
    expect(deleted.deletedAt, isNotNull);
    expect(
      platform.controller.injectedScripts.any(
        (script) => script.contains('deleteRenderedAnnotation("note-annotation")'),
      ),
      isTrue,
    );
  });

  testWidgets('BrowserScreen handles link long-press menus', (tester) async {
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
    await _pumpRouteTransition(tester);

    platform.controller.sendLinkContextMessage(
      '{"type":"link-long-pressed","payload":{"href":"https://example.com/linked","text":"Linked Article","pageUrl":"https://news.ycombinator.com","pageTitle":"Hacker News"}}',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Linked Article'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Open in New Tab'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);
    expect(find.text('Add Bookmark'), findsOneWidget);

    await tester.tap(find.text('Open in New Tab'));
    await tester.pumpAndSettle();

    expect(platform.controller.loadedUri, Uri.parse('https://example.com/linked'));
    expect(find.text('Tabs 2'), findsOneWidget);
  });

  testWidgets('BrowserScreen browser menu exposes page, tab, and annotation actions', (tester) async {
    await _seedPageAnnotation(database);
    Uri? sharedUrl;
    String? sharedTitle;
    Rect? sharedOrigin;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          nativeUrlShareProvider.overrideWithValue(({required title, required url, sharePositionOrigin}) async {
            sharedUrl = url;
            sharedTitle = title;
            sharedOrigin = sharePositionOrigin;
          }),
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
    await _pumpRouteTransition(tester);

    await tester.tap(find.text('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Browser Menu'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Copy URL'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('New Tab'), findsOneWidget);
    expect(find.text('Show Tabs'), findsOneWidget);
    expect(find.text('Open Annotations'), findsOneWidget);
    expect(find.text('Hide Highlights'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(sharedUrl, Uri.parse('https://news.ycombinator.com'));
    expect(sharedTitle, 'Example Domain');
    expect(sharedOrigin, isNotNull);

    await tester.tap(find.text('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Hide Highlights'));
    await tester.pumpAndSettle();
    expect(platform.controller.injectedScripts.last, contains('renderAnnotations([])'));

    await tester.tap(find.text('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Show Highlights'), findsOneWidget);
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
    await _pumpRouteTransition(tester);

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
    await _pumpRouteTransition(tester);

    platform.controller.sendSelectionMessage(
      '{"type":"selection-captured","payload":{"exact":"selected text","prefix":"before ","suffix":" after","sourceUrl":"https://news.ycombinator.com","pageTitle":"Hacker News","textPositionStart":7,"textPositionEnd":20,"cssSelector":"p:nth-of-type(1)"}}',
    );
    await tester.pump();

    expect(find.text('selected text'), findsOneWidget);
    expect(find.text('Highlight'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Underline'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.widgetWithText(CupertinoButton, 'Highlight'));
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
    await _pumpRouteTransition(tester);

    platform.controller.sendSelectionMessage(
      '{"type":"selection-captured","payload":{"exact":"note text","prefix":"before ","suffix":" after","sourceUrl":"https://news.ycombinator.com","pageTitle":"Hacker News","textPositionStart":7,"textPositionEnd":16,"cssSelector":"p:nth-of-type(1)"}}',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(CupertinoButton, 'Note'));
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

  testWidgets('Annotation detail supports editing and deleting notes', (tester) async {
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
    await tester.tap(find.text('highlighting'));
    await tester.pumpAndSettle();

    expect(find.text('Annotation'), findsOneWidget);
    expect(find.text('"important quote"'), findsOneWidget);
    expect(find.text('No note attached. Tap Edit to add one.'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Add Note'), findsOneWidget);

    await tester.tap(find.byType(CodeForge));
    await tester.pump();
    tester.testTextInput.enterText('Updated note');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Updated note'), findsOneWidget);
    final editedBodies = await database.select(database.annotationBodies).get();
    expect(editedBodies.where((body) => body.type == 'TextualBody').single.value, 'Updated note');

    await tester.tap(find.text('Delete annotation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsWidgets);
    final deleted = await (database.select(
      database.annotations,
    )..where((annotation) => annotation.id.equals('annotation'))).getSingle();
    expect(deleted.deletedAt, isNotNull);
  });
}

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
  await tester.pump();
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

Future<void> _seedSidebarAnnotations(AppDatabase database) async {
  final now = DateTime.utc(2026, 5, 13, 12);
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'sidebar-page',
          url: 'https://news.ycombinator.com',
          canonicalUrl: const Value('https://news.ycombinator.com/news'),
          title: const Value('Hacker News'),
          createdAt: now,
          lastVisitedAt: now,
        ),
      );

  await _insertSeedAnnotation(
    database,
    id: 'highlight-annotation',
    pageId: 'sidebar-page',
    sourceUrl: 'https://news.ycombinator.com',
    exact: 'highlight quote',
    style: 'highlight',
    color: '#FFCC00',
    createdAt: now,
  );
  await _insertSeedAnnotation(
    database,
    id: 'note-annotation',
    pageId: 'sidebar-page',
    sourceUrl: 'https://news.ycombinator.com',
    exact: 'note quote',
    style: 'highlight',
    color: '#34C759',
    note: 'Original sidebar note',
    createdAt: now.add(const Duration(minutes: 1)),
    motivation: 'commenting',
  );
  await _insertSeedAnnotation(
    database,
    id: 'underline-annotation',
    pageId: 'sidebar-page',
    sourceUrl: 'https://news.ycombinator.com',
    exact: 'underline quote',
    style: 'underline',
    color: '#64D2FF',
    createdAt: now.add(const Duration(minutes: 2)),
  );
}

Future<void> _insertSeedAnnotation(
  AppDatabase database, {
  required String id,
  required String pageId,
  required String sourceUrl,
  required String exact,
  required String style,
  required String color,
  required DateTime createdAt,
  String motivation = 'highlighting',
  String? note,
}) async {
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: id,
          pageId: pageId,
          motivation: motivation,
          createdAt: createdAt,
          modifiedAt: createdAt,
        ),
      );
  await database
      .into(database.annotationTargets)
      .insert(
        AnnotationTargetsCompanion.insert(
          id: '$id-target',
          annotationId: id,
          sourceUrl: sourceUrl,
          selectorJson:
              '[{"type":"TextQuoteSelector","exact":"$exact","prefix":"","suffix":""},{"type":"TextPositionSelector","start":0,"end":${exact.length}}]',
        ),
      );
  await database
      .into(database.annotationBodies)
      .insert(
        AnnotationBodiesCompanion.insert(
          id: '$id-style',
          annotationId: id,
          type: 'StyleHint',
          format: const Value('application/json'),
          value: '{"style":"$style","color":"$color"}',
        ),
      );
  if (note != null) {
    await database
        .into(database.annotationBodies)
        .insert(
          AnnotationBodiesCompanion.insert(
            id: '$id-note',
            annotationId: id,
            type: 'TextualBody',
            format: const Value('text/markdown'),
            value: note,
          ),
        );
  }
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

  void sendLinkContextMessage(String message) {
    javaScriptChannels['MarkerLinkContext']?.onMessageReceived(JavaScriptMessage(message: message));
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
