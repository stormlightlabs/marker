import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/features/settings/application/log_share_controller.dart';
import 'package:marker/src/features/settings/data/app_log_repository.dart';
import 'package:marker/src/features/settings/data/settings_repository.dart';

import '../../../../helpers/harness.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    FakeWebViewPlatform();
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

  testWidgets('toggles ad blocking from settings', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('Ad Blocker'), findsOneWidget);
    expect(await SettingsRepository(database).isAdBlockEnabled(), isTrue);

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();

    expect(await SettingsRepository(database).isAdBlockEnabled(), isFalse);
  });

  testWidgets('opens logs screen and filters logs', (tester) async {
    final now = DateTime(2026, 5, 16, 12);
    var shared = false;

    await tester.pumpWidget(
      markerTestApp(
        database: database,
        additionalOverrides: [
          appLogEntriesProvider.overrideWith((ref) async {
            return [
              AppLogEntry(time: now, level: AppLogLevel.info, message: 'loaded library', sourceFile: 'marker.log'),
              AppLogEntry(
                time: now,
                level: AppLogLevel.warning,
                message: 'ignored malformed bridge message',
                sourceFile: 'marker.log',
              ),
            ];
          }),
          nativeLogShareProvider.overrideWithValue(({Rect? sharePositionOrigin}) async {
            shared = true;
          }),
        ],
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('Advanced'), findsOneWidget);
    await tester.tap(find.text('Logs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();
    await tester.pump();

    expect(find.text('loaded library'), findsOneWidget);
    expect(find.text('ignored malformed bridge message'), findsOneWidget);

    await tester.tap(find.text('Warn').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('loaded library'), findsNothing);
    expect(find.text('ignored malformed bridge message'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pump();

    expect(shared, isTrue);
  });
}
