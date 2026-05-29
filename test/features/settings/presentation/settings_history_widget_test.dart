import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/settings/application/log_share_controller.dart';
import 'package:marker/features/settings/data/app_log_repository.dart';
import 'package:marker/features/settings/data/settings_repository.dart';
import 'package:marker/features/settings/presentation/logs_screen.dart';
import 'package:rough_notation/rough_notation.dart';

import '../../../helpers/harness.dart';

void main() {
  late AppDatabase database;
  late String clipboardText;

  setUp(() {
    FakeWebViewPlatform();
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
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
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

  testWidgets('shows AT Proto explainer link in sync settings', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('Sync'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.at_circle), findsOneWidget);
    expect(find.text('What is AT Proto?'), findsOneWidget);
    expect(find.text('ATProto Sync'), findsOneWidget);
  });

  testWidgets('toggles ad blocking from settings', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('Ad Blocker'), findsOneWidget);
    expect(await SettingsRepository(database).isAdBlockEnabled(), isTrue);

    await tester.tap(find.byType(CupertinoSwitch).first);
    await tester.pumpAndSettle();

    expect(await SettingsRepository(database).isAdBlockEnabled(), isFalse);
  });

  testWidgets('about screen uses rough notation while fun is enabled', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database, funEnabled: true));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);
    await tester.tap(find.text('About'));
    await pumpRouteTransition(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Marker'), findsOneWidget);
    expect(find.byType(RoughUnderlineAnnotation), findsWidgets);
  });

  testWidgets('toggles fun and opens about screen', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database, funEnabled: null));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('Fun'), findsOneWidget);
    expect(await SettingsRepository(database).isFunEnabled(), isTrue);

    await tester.tap(find.byType(CupertinoSwitch).at(1));
    await tester.pumpAndSettle();

    expect(await SettingsRepository(database).isFunEnabled(), isFalse);

    await tester.tap(find.text('About'));
    await pumpRouteTransition(tester);

    expect(find.text('Marker'), findsOneWidget);
    expect(find.text('Owais'), findsOneWidget);
    expect(find.textContaining('Stormlight Labs makes high quality'), findsOneWidget);
  });

  testWidgets('clears logs from the logs screen', (tester) async {
    final now = DateTime(2026, 5, 16, 12);
    var entries = [
      AppLogEntry(time: now, level: AppLogLevel.info, message: 'temporary diagnostic', sourceFile: 'marker.log'),
    ];
    var cleared = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLogEntriesProvider.overrideWith((ref) async => entries),
          appLogRepositoryProvider.overrideWithValue(
            _ClearingAppLogRepository(() {
              cleared = true;
              entries = const [];
            }),
          ),
        ],
        child: const CupertinoApp(home: LogsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('temporary diagnostic'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Clear Logs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(cleared, isTrue);
    expect(find.text('Logs cleared'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No matching logs'), findsOneWidget);
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

    await tester.tap(find.byIcon(CupertinoIcons.doc_on_doc).last);
    await tester.pumpAndSettle();

    expect(clipboardText, contains('WARN [marker.log] ignored malformed bridge message'));
    expect(find.text('Copied log entry'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download'));
    await tester.pump();

    expect(shared, isTrue);
  });
}

class _ClearingAppLogRepository extends AppLogRepository {
  _ClearingAppLogRepository(this._onClear) : super(directoryLoader: _unusedDirectoryLoader);

  final VoidCallback _onClear;

  @override
  Future<void> clearLogs() async {
    _onClear();
  }
}

Future<Directory> _unusedDirectoryLoader() async => Directory.systemTemp;
