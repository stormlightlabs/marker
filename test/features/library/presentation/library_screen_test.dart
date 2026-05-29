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
    expect(find.text('RECENT ANNOTATIONS'), findsOneWidget);
    expect(find.text('RECENTLY ANNOTATED'), findsOneWidget);
    final recentAnnotationsTop = tester.getTopLeft(find.text('RECENT ANNOTATIONS')).dy;
    final recentlyAnnotatedTop = tester.getTopLeft(find.text('RECENTLY ANNOTATED')).dy;
    expect(recentAnnotationsTop, lessThan(recentlyAnnotatedTop));
    expect(find.text('Show All'), findsNothing);
    expect(find.text('Grouped by page'), findsNothing);
    expect(find.text('Saved Article'), findsOneWidget);
    expect(find.text('Recent Article'), findsWidgets);
    expect(find.text('important quote'), findsOneWidget);
    expect(find.text('highlighting'), findsNothing);

    await tester.tap(find.text('Recent Article').first);
    await pumpRouteTransition(tester);

    expect(find.text('Open source page'), findsOneWidget);
    await tester.tap(find.text('Open source page'));
    await pumpRouteTransition(tester);

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(platform.controller.loadedUri, Uri.parse('https://example.com/recent'));
  });

  testWidgets('caps library sections at five rows and shows all annotations link', (tester) async {
    await seedLibrary(database);
    await _seedAdditionalAnnotations(database, count: 5);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();

    expect(find.text('Show All'), findsOneWidget);
    expect(find.text('important quote'), findsNothing);
    expect(find.text('extra quote 5'), findsOneWidget);
    expect(find.text('extra quote 1'), findsOneWidget);

    await tester.ensureVisible(find.text('Show All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show All'));
    await pumpRouteTransition(tester);

    expect(find.text('Annotations'), findsOneWidget);
    expect(find.text('Recent Article'), findsOneWidget);
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

Future<void> _seedAdditionalAnnotations(AppDatabase database, {required int count}) async {
  final base = DateTime.utc(2026, 5, 13, 12);
  for (var index = 1; index <= count; index += 1) {
    final id = 'annotation-extra-$index';
    await database
        .into(database.annotations)
        .insert(
          AnnotationsCompanion.insert(
            id: id,
            pageId: 'recent-page',
            motivation: 'highlighting',
            createdAt: base.add(Duration(minutes: index)),
            modifiedAt: base.add(Duration(minutes: index)),
          ),
        );
    await database
        .into(database.annotationTargets)
        .insert(
          AnnotationTargetsCompanion.insert(
            id: 'target-extra-$index',
            annotationId: id,
            sourceUrl: 'https://example.com/recent',
            selectorJson: '{"selector":[{"type":"TextQuoteSelector","exact":"extra quote $index"}]}',
          ),
        );
  }
}
