import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/browser/ad_block/ad_block_rules.dart';
import 'package:marker/features/browser/data/favicon_cache.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

import '../../../helpers/harness.dart';

void main() {
  late FakeWebViewPlatform platform;
  late AppDatabase database;
  late String clipboardText;

  setUp(() {
    platform = FakeWebViewPlatform();
    database = AppDatabase(NativeDatabase.memory());
    clipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map<Object?, Object?>)['text']! as String;
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return {'text': clipboardText};
        }
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    await database.close();
  });

  testWidgets('loads the default URL and records the page', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database, faviconCache: _FakeFaviconCache()));

    await tester.pump();
    await tester.pump();

    expect(find.text('Library'), findsWidgets);
    expect(find.text('No Saved Pages'), findsOneWidget);
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(find.text('Browser'), findsWidgets);
    expect(platform.controller.loadedUri, Uri.parse('https://news.ycombinator.com'));
    expect(platform.controller.injectedScripts.first, contains('installChannel'));
    expect(platform.controller.injectedScripts[1], contains('__markerReaderInstalled'));
    expect(platform.controller.injectedScripts.last, contains('renderAnnotations([])'));

    final pages = await database.select(database.pages).get();
    expect(pages, hasLength(1));
    expect(pages.single.url, 'https://news.ycombinator.com');
    expect(pages.single.canonicalUrl, 'https://news.ycombinator.com/news');
    expect(pages.single.description, 'Front page links and discussions');
    expect(pages.single.faviconUrl, 'https://news.ycombinator.com/favicon.ico');
    expect(pages.single.faviconFilePath, '/cache/favicons/hacker-news.ico');
    expect(pages.single.title, 'Example Domain');
  });

  testWidgets('keeps address text until typing and resets unsent edits on blur', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    final field = find.byType(CupertinoTextField);
    String addressText() => tester.widget<CupertinoTextField>(field).controller!.text;
    expect(addressText(), 'https://news.ycombinator.com');

    await tester.tap(field);
    await tester.pump();
    expect(find.text('Paste and Go'), findsOneWidget);
    expect(find.text('Copy URL'), findsWidgets);
    expect(find.text('Example Domain'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Copy Current URL'));
    await tester.pump();
    expect((await Clipboard.getData('text/plain'))?.text, 'https://news.ycombinator.com');

    await tester.enterText(field, 'example.com');
    await tester.pump();
    expect(addressText(), 'example.com');
    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pump();
    expect(addressText(), isEmpty);

    await tester.enterText(field, 'example.com');
    await tester.pump();
    expect(addressText(), 'example.com');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(addressText(), 'https://news.ycombinator.com');
    expect(platform.controller.loadedUris, [Uri.parse('https://news.ycombinator.com')]);
  });

  testWidgets('reload button refreshes the current page', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    await tester.tap(find.byIcon(CupertinoIcons.refresh));
    await tester.pump();

    expect(platform.controller.reloadCount, 1);
  });

  testWidgets('loading address control stops loading instead of refreshing', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    platform.controller.navigationDelegate?.onProgress(40);
    await tester.pump();

    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.refresh), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pump();

    expect(platform.controller.stopLoadingCount, 1);
    expect(find.byIcon(CupertinoIcons.refresh), findsOneWidget);
  });

  testWidgets('renders fuzzy history matches with cached favicon and description', (tester) async {
    final now = DateTime.utc(2026, 5, 13, 12);
    final sharedUrls = <Uri>[];
    await database
        .into(database.pages)
        .insert(
          PagesCompanion.insert(
            id: 'page',
            url: 'https://example.com/article',
            title: const Value('Example Article'),
            description: const Value('A saved article about browser metadata'),
            faviconFilePath: const Value('/cache/favicons/example.ico'),
            createdAt: now,
            lastVisitedAt: now,
          ),
        );
    await database
        .into(database.browserHistoryEntries)
        .insert(
          BrowserHistoryEntriesCompanion.insert(
            id: 'history',
            url: 'https://example.com/article',
            title: const Value('Example Article'),
            description: const Value('A saved article about browser metadata'),
            visitedAt: now,
          ),
        );
    await tester.pumpWidget(
      markerTestApp(
        database: database,
        nativeUrlShare: ({required url, required title, sharePositionOrigin}) async {
          sharedUrls.add(url);
        },
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    final field = find.byType(CupertinoTextField);
    await tester.tap(field);
    await tester.enterText(field, 'metadata');
    await tester.pump();
    await tester.pump();

    final addressBarBottom = tester.getBottomLeft(field).dy;
    expect(tester.getTopLeft(find.text('Paste and Go')).dy, greaterThan(addressBarBottom));
    expect(find.byIcon(CupertinoIcons.arrow_right), findsOneWidget);
    expect(find.text('Go'), findsNothing);
    expect(find.text('Example Article'), findsOneWidget);
    expect(find.text('A saved article about browser metadata'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.globe), findsAtLeastNWidgets(1));

    await tester.tap(find.byIcon(CupertinoIcons.doc_on_doc).last);
    await tester.pump();
    expect((await Clipboard.getData('text/plain'))?.text, 'https://example.com/article');
    expect(sharedUrls, isEmpty);

    await tester.tap(find.byIcon(CupertinoIcons.share).last);
    await tester.pump();
    expect(sharedUrls, [Uri.parse('https://example.com/article')]);

    await tester.tap(find.text('Example Article'));
    await tester.pump();

    expect(platform.controller.loadedUri, Uri.parse('https://example.com/article'));
  });

  testWidgets('paste and go opens the clipboard URL from history overlay', (tester) async {
    await Clipboard.setData(const ClipboardData(text: 'https://paste.example/article'));
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    final field = find.byType(CupertinoTextField);
    await tester.tap(field);
    await tester.enterText(field, 'paste');
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Paste and Go'));
    await tester.pump();

    expect(platform.controller.loadedUri, Uri.parse('https://paste.example/article'));
  });

  testWidgets('shows page load progress at the bottom without a WebView spinner overlay', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    platform.controller.navigationDelegate?.onProgress(40);
    await tester.pump();

    final progressBar = find.byKey(const ValueKey('reader-progress-bar'));
    final bottomActionBar = find.byKey(const ValueKey('browser-bottom-action-bar'));

    expect(progressBar, findsOneWidget);
    expect(tester.getRect(progressBar).bottom, tester.getRect(bottomActionBar).top);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    expect(find.text('Loading'), findsNothing);
  });

  testWidgets('rehydrates saved annotations after page load', (tester) async {
    await seedPageAnnotation(database);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    final renderScript = platform.controller.injectedScripts.last;
    expect(renderScript, contains('renderAnnotations'));
    expect(renderScript, contains('"id":"saved-annotation"'));
    expect(renderScript, contains('"exact":"selected text"'));
    expect(renderScript, contains('"style":"highlight"'));
    expect(renderScript, contains('"color":"#FFCC00"'));
  });

  testWidgets('rehydrates saved annotations when canonical URL lookup fails', (tester) async {
    platform.throwOnCanonicalUrlRead = true;
    await seedPageAnnotation(database);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    expect(
      platform.controller.injectedScripts.any(
        (script) => script.contains('renderAnnotations') && script.contains('"id":"saved-annotation"'),
      ),
      isTrue,
    );
  });

  testWidgets('applies compiled ad-block rules when enabled', (tester) async {
    final rules = EasyListParser().parse('||ads.example.com^\nnews.ycombinator.com##.ad');

    await tester.pumpWidget(markerTestApp(database: database, compiledAdBlockRules: rules));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    expect(platform.controller.adBlockRules, same(rules));
    expect(
      platform.controller.injectedScripts.any((script) => script.contains('MarkerAdBlock') && script.contains('.ad')),
      isTrue,
    );
  });

  testWidgets('does not apply ad-block rules when disabled', (tester) async {
    final rules = EasyListParser().parse('||ads.example.com^\nnews.ycombinator.com##.ad');
    await SettingsRepository(database).setAdBlockEnabled(false);

    await tester.pumpWidget(markerTestApp(database: database, compiledAdBlockRules: rules));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    expect(platform.controller.adBlockRules, isNull);
    expect(platform.controller.injectedScripts.any((script) => script.contains('MarkerAdBlock')), isFalse);
  });
}

class _FakeFaviconCache extends FaviconCache {
  @override
  Future<String?> cacheFavicon(Uri? faviconUrl) async {
    return faviconUrl == null ? null : '/cache/favicons/hacker-news.ico';
  }
}
