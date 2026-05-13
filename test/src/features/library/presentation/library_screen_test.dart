import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/database/app_database.dart';

import '../../../../helpers/harness.dart';

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
}
