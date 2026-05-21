import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/browser/ad_block/ad_block_rules.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

import '../../../helpers/harness.dart';

void main() {
  late FakeWebViewPlatform platform;
  late AppDatabase database;

  setUp(() {
    platform = FakeWebViewPlatform();
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('loads the default URL and records the page', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

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
    expect(pages.single.title, 'Example Domain');
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
    final tabBar = find.byType(MarkerTabBar);

    expect(progressBar, findsOneWidget);
    expect(tester.getRect(progressBar).bottom, tester.getRect(tabBar).top);
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
