import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../../../helpers/harness.dart';

void main() {
  late FakeWebViewPlatform platform;
  late AppDatabase database;

  setUp(() {
    platform = FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
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
    expect(platform.controller.injectedScripts.first, contains('__markerReaderInstalled'));
    expect(platform.controller.injectedScripts.last, contains('renderAnnotations([])'));

    final pages = await database.select(database.pages).get();
    expect(pages, hasLength(1));
    expect(pages.single.url, 'https://news.ycombinator.com');
    expect(pages.single.canonicalUrl, 'https://news.ycombinator.com/news');
    expect(pages.single.title, 'Example Domain');
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
}
