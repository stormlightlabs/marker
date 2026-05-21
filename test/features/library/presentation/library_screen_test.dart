import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';

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

  testWidgets('shows stored library sections', (tester) async {
    await seedLibrary(database);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();

    expect(find.text('LIBRARY'), findsNothing);
    expect(find.text('BOOKMARKS'), findsOneWidget);
    expect(find.text('RECENTLY ANNOTATED'), findsOneWidget);
    expect(find.text('RECENT ANNOTATIONS'), findsOneWidget);
    expect(find.text('All Annotations'), findsOneWidget);
    expect(find.text('Browse every highlight and note'), findsOneWidget);
    expect(find.text('Grouped by page'), findsNothing);
    expect(find.text('Saved Article'), findsOneWidget);
    expect(find.text('Recent Article'), findsWidgets);
    expect(find.text('important quote'), findsOneWidget);
    expect(find.text('highlighting'), findsNothing);

    await tester.tap(find.text('All Annotations'));
    await pumpRouteTransition(tester);

    expect(find.text('RECENT ARTICLE'), findsNothing);
    expect(find.text('All Annotations'), findsNothing);
    expect(find.text('Grouped by page'), findsNothing);

    await tester.tap(find.text('Library'));
    await pumpRouteTransition(tester);

    expect(find.text('All Annotations'), findsOneWidget);

    await tester.tap(find.text('All Annotations'));
    await pumpRouteTransition(tester);

    await tester.tap(find.text('Recent Article').first);
    await tester.pump();
    await tester.pump();

    expect(find.text('Open source page'), findsOneWidget);
    await tester.tap(find.text('Open source page'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(platform.controller.loadedUri, Uri.parse('https://example.com/recent'));
  });

  testWidgets('searches library and opens recent annotated page detail', (tester) async {
    await seedLibrary(database);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(CupertinoSearchTextField), 'important');
    await tester.pump();
    await tester.pump();

    expect(find.text('SEARCH RESULTS'), findsOneWidget);
    expect(find.text('important quote'), findsWidgets);

    await tester.tap(find.text('Recent Article').first);
    await tester.pump();
    await tester.pump();

    expect(find.text('Open source page'), findsOneWidget);
    expect(find.text('important quote'), findsWidgets);
  });

  testWidgets('page detail filters and bulk deletes annotations', (tester) async {
    await seedLibrary(database);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Recent Article').first);
    await pumpRouteTransition(tester);

    await tester.tap(find.widgetWithText(CupertinoButton, 'Edit').last, warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('important quote').first);
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    final annotation = await (database.select(
      database.annotations,
    )..where((row) => row.id.equals('annotation'))).getSingle();
    expect(annotation.deletedAt, isNotNull);
  });
}
