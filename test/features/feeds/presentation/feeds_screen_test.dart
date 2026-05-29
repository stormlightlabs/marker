import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';

import '../../../helpers/harness.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => await database.close());

  testWidgets('feeds route is available from the bottom bar', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Feeds'));
    await pumpRouteTransition(tester);
    expect(find.text('Feeds'), findsWidgets);
    expect(find.text('Feeds are coming soon'), findsOneWidget);
    expect(find.text('Browser'), findsOneWidget);
    expect(find.text('Bookmarks'), findsNothing);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
