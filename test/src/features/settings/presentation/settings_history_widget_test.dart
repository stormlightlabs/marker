import 'package:drift/drift.dart' show Value;
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

  testWidgets('opens browser history and clears visits', (tester) async {
    final now = DateTime.utc(2026, 5, 13, 12);
    await database
        .into(database.browserHistoryEntries)
        .insert(
          BrowserHistoryEntriesCompanion.insert(
            id: 'history',
            url: 'https://example.com/history',
            title: const Value('History Page'),
            visitedAt: now,
          ),
        );

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('Browser History'), findsOneWidget);
    await tester.tap(find.text('Browser History'));
    await pumpRouteTransition(tester);

    expect(find.text('History Page'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();

    expect(find.text('No browser history'), findsOneWidget);
    expect(await database.select(database.browserHistoryEntries).get(), isEmpty);
  });
}
