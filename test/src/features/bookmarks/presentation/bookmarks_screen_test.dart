import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';
import 'package:marker/src/features/bookmarks/presentation/bookmarks_screen.dart';

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

  testWidgets('opens bookmark manager from main nav and renders folders and bookmarks', (tester) async {
    await _seedBookmarkManager(database);

    await tester.pumpWidget(markerTestApp(database: database));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Bookmarks'));
    await pumpRouteTransition(tester);

    expect(find.text('Bookmarks'), findsWidgets);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Browser'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);
    expect(find.text('Example Article'), findsOneWidget);

    await tester.tap(find.text('Example Article'));
    await pumpRouteTransition(tester);

    expect(find.text('Fake WebView'), findsOneWidget);
    expect(platform.controller.loadedUri, Uri.parse('https://example.com/article'));
  });

  testWidgets('shows bookmark detail and edit route for folders', (tester) async {
    await _seedBookmarkManager(database);

    await tester.pumpWidget(markerTestApp(database: database));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Bookmarks'));
    await pumpRouteTransition(tester);
    await tester.tap(find.text('Programming'));
    await pumpRouteTransition(tester);

    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const CupertinoApp(home: BookmarkEditScreen(id: 'folder')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Edit Bookmark'), findsOneWidget);
  });
}

Future<void> _seedBookmarkManager(AppDatabase database) async {
  final now = DateTime.utc(2026, 5, 13, 12);
  await database
      .into(database.bookmarkFolders)
      .insert(BookmarkFoldersCompanion.insert(id: 'folder', title: 'Programming', createdAt: now, updatedAt: now));
  await database
      .into(database.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          id: 'bookmark',
          url: 'https://example.com/article',
          title: const Value('Example Article'),
          createdAt: now,
        ),
      );
}
