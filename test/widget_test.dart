import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';
import 'package:marker/src/features/browser/presentation/browser_screen.dart';
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
        child: const CupertinoApp(home: BrowserScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(find.text('Browser'), findsOneWidget);
    expect(platform.controller.loadedUri, Uri.parse('https://news.ycombinator.com'));
    expect(platform.controller.injectedScripts.single, contains('__markerReaderInstalled'));

    final pages = await database.select(database.pages).get();
    expect(pages, hasLength(1));
    expect(pages.single.url, 'https://news.ycombinator.com');
    expect(pages.single.canonicalUrl, 'https://news.ycombinator.com/news');
    expect(pages.single.title, 'Example Domain');
  });
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
  final injectedScripts = <String>[];
  _FakePlatformNavigationDelegate? navigationDelegate;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {
    navigationDelegate = handler as _FakePlatformNavigationDelegate;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedUri = params.uri;
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
