import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
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

  testWidgets('handles link long-press menus', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

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

  testWidgets('browser menu exposes page, tab, history, settings, and annotation actions', (tester) async {
    await seedPageAnnotation(database);
    Uri? sharedUrl;
    String? sharedTitle;
    Rect? sharedOrigin;

    await tester.pumpWidget(
      markerTestApp(
        database: database,
        nativeUrlShare: ({required title, required url, sharePositionOrigin}) async {
          sharedUrl = url;
          sharedTitle = title;
          sharedOrigin = sharePositionOrigin;
        },
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    expect(find.text('Menu'), findsNothing);
    expect(find.bySemanticsLabel('Browser Menu'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Browser Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Browser Menu'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Copy URL'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('New Tab'), findsOneWidget);
    expect(find.text('Show Tabs'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Open Annotations'), findsOneWidget);
    expect(find.text('Hide Highlights'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(sharedUrl, Uri.parse('https://news.ycombinator.com'));
    expect(sharedTitle, 'Example Domain');
    expect(sharedOrigin, isNotNull);

    await tester.tap(find.bySemanticsLabel('Browser Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(CupertinoActionSheet), const Offset(0, -180));
    await tester.pump();
    await tester.tap(find.text('Hide Highlights'));
    await tester.pumpAndSettle();
    expect(platform.controller.injectedScripts.last, contains('renderAnnotations([])'));

    await tester.tap(find.bySemanticsLabel('Browser Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Show Highlights'), findsOneWidget);
  });

  testWidgets('exposes bookmark and tab controls', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

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
}
