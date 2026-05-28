import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marker/app/marker_app.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/features/browser/ad_block/ad_block_providers.dart';
import 'package:marker/features/browser/ad_block/ad_block_rules.dart';
import 'package:marker/features/browser/application/native_share_controller.dart';
import 'package:marker/features/browser/data/favicon_cache.dart';
import 'package:marker/features/browser/webview/browser_webview.dart';
import 'package:marker/features/browser/webview/reader_webview_bridge.dart';

FakeWebViewPlatform? _activeFakeWebViewPlatform;

Widget markerTestApp({
  required AppDatabase database,
  NativeUrlShare? nativeUrlShare,
  FaviconCache? faviconCache,
  CompiledAdBlockRules? compiledAdBlockRules,
  List<dynamic> additionalOverrides = const [],
}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final fakeWebViewController = _activeFakeWebViewPlatform?.controller ?? FakeBrowserWebViewController();
  final effectiveAdBlockRules =
      compiledAdBlockRules ??
      const CompiledAdBlockRules(
        networkRules: [],
        cosmeticRules: [],
        stats: AdBlockParseStats(
          totalLines: 0,
          commentLines: 0,
          networkRules: 0,
          cosmeticRules: 0,
          exceptionRules: 0,
          unsupportedRules: 0,
          invalidRules: 0,
        ),
      );
  final overrides = [
    databaseProvider.overrideWithValue(database),
    compiledAdBlockRulesProvider.overrideWith((ref) => effectiveAdBlockRules),
    readerWebViewBridgeProvider.overrideWithValue(testReaderBridge()),
    faviconCacheProvider.overrideWithValue(faviconCache ?? FaviconCache(fetcher: (_) async => null)),
    browserWebViewControllerFactoryProvider.overrideWithValue(() => fakeWebViewController),
    browserWebViewBuilderProvider.overrideWithValue((context, controller) => const Center(child: Text('Fake WebView'))),
    if (nativeUrlShare != null) nativeUrlShareProvider.overrideWithValue(nativeUrlShare),
    ...additionalOverrides,
  ];

  return ProviderScope(overrides: overrides.cast(), child: const MarkerApp());
}

Future<void> pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await tester.pump();
}

ReaderWebViewBridge testReaderBridge() => ReaderWebViewBridge(assetBundle: _StringAssetBundle());

Future<void> seedLibrary(AppDatabase database) async {
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
          updatedAt: savedAt,
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

Future<void> seedPageAnnotation(AppDatabase database) async {
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

Future<void> seedSidebarAnnotations(AppDatabase database) async {
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

  await insertSeedAnnotation(
    database,
    id: 'highlight-annotation',
    pageId: 'sidebar-page',
    sourceUrl: 'https://news.ycombinator.com',
    exact: 'highlight quote',
    style: 'highlight',
    color: '#FFCC00',
    createdAt: now,
  );
  await insertSeedAnnotation(
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
  await insertSeedAnnotation(
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

Future<void> insertSeedAnnotation(
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

class FakeWebViewPlatform {
  FakeWebViewPlatform() {
    _activeFakeWebViewPlatform = this;
  }

  late final FakeBrowserWebViewController controller = FakeBrowserWebViewController();
  bool get throwOnCanonicalUrlRead => controller.throwOnCanonicalUrlRead;
  set throwOnCanonicalUrlRead(bool value) => controller.throwOnCanonicalUrlRead = value;
  Object get canonicalUrlResult => controller.canonicalUrlResult;
  set canonicalUrlResult(Object value) => controller.canonicalUrlResult = value;
  Object get faviconUrlResult => controller.faviconUrlResult;
  set faviconUrlResult(Object value) => controller.faviconUrlResult = value;
  Object get metaDescriptionResult => controller.metaDescriptionResult;
  set metaDescriptionResult(Object value) => controller.metaDescriptionResult = value;
  Object get renderAnnotationsResult => controller.renderAnnotationsResult;
  set renderAnnotationsResult(Object value) => controller.renderAnnotationsResult = value;
}

class FakeBrowserWebViewController implements BrowserWebViewController {
  Uri? loadedUri;
  final loadedUris = <Uri>[];
  final injectedScripts = <String>[];
  final javaScriptChannels = <String, BrowserJavaScriptMessageHandler>{};
  BrowserNavigationDelegate? navigationDelegate;
  bool throwOnCanonicalUrlRead = false;
  Object canonicalUrlResult = '"https://news.ycombinator.com/news"';
  Object faviconUrlResult = '"https://news.ycombinator.com/favicon.ico"';
  Object metaDescriptionResult = '"Front page links and discussions"';
  Object renderAnnotationsResult = 1;
  CompiledAdBlockRules? adBlockRules;
  int reloadCount = 0;
  int stopLoadingCount = 0;

  @override
  Future<void> setJavaScriptModeUnrestricted() async {}

  @override
  Future<void> setNavigationDelegate(BrowserNavigationDelegate delegate) async {
    navigationDelegate = delegate;
  }

  @override
  Future<void> addJavaScriptChannel(String name, {required BrowserJavaScriptMessageHandler onMessageReceived}) async {
    javaScriptChannels[name] = onMessageReceived;
  }

  @override
  Future<void> loadRequest(Uri uri) async {
    loadedUri = uri;
    loadedUris.add(uri);
    navigationDelegate?.onProgress(40);
    navigationDelegate?.onProgress(100);
    await navigationDelegate?.onPageFinished(uri.toString());
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    injectedScripts.add(javaScript);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String javaScript) async {
    injectedScripts.add(javaScript);
    if (javaScript.contains('renderAnnotations(')) {
      return renderAnnotationsResult;
    }
    if (javaScript.contains('link[rel="canonical"')) {
      if (throwOnCanonicalUrlRead) {
        throw PlatformException(code: 'javaScript-error', message: 'canonical lookup failed');
      }
      return canonicalUrlResult;
    }
    if (javaScript.contains('link[rel~="icon"')) {
      return faviconUrlResult;
    }
    if (javaScript.contains('meta[name="description"')) {
      return metaDescriptionResult;
    }
    return canonicalUrlResult;
  }

  @override
  Future<String?> getTitle() async => 'Example Domain';

  @override
  Future<String?> currentUrl() async => loadedUri?.toString();

  @override
  Future<void> reload() async {
    reloadCount += 1;
    final uri = loadedUri;
    if (uri != null) {
      await loadRequest(uri);
    }
  }

  @override
  Future<void> stopLoading() async {
    stopLoadingCount += 1;
  }

  @override
  Future<void> setAdBlockRules(CompiledAdBlockRules? rules) async {
    adBlockRules = rules;
  }

  void sendSelectionMessage(String message) {
    javaScriptChannels['MarkerSelection']?.call(message);
  }

  void sendLinkContextMessage(String message) {
    javaScriptChannels['MarkerLinkContext']?.call(message);
  }
}

class _StringAssetBundle extends CachingAssetBundle {
  static const String _readerScript = '''
(function () {
  window.__markerReaderInstalled = true;
})();
''';

  @override
  Future<ByteData> load(String key) {
    if (key != ReaderWebViewBridge.bootstrapScriptAsset) {
      return Future<ByteData>.error(FlutterError('Missing test asset: $key'));
    }
    final bytes = Uint8List.fromList(utf8.encode(_readerScript));
    return SynchronousFuture<ByteData>(ByteData.view(bytes.buffer));
  }
}
