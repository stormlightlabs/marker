import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/features/bookmarks/presentation/bookmarks_screen.dart';

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

  testWidgets('opens folder child list and info detail from folder rows', (tester) async {
    await _seedBookmarkManager(database);

    await tester.pumpWidget(markerTestApp(database: database));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Bookmarks'));
    await pumpRouteTransition(tester);
    await tester.tap(find.text('Programming'));
    await pumpRouteTransition(tester);
    expect(find.text('Child Bookmark'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.info_circle));
    await pumpRouteTransition(tester);
    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);
  });

  testWidgets('long pressing bookmarks opens detail', (tester) async {
    await _seedBookmarkManager(database);

    await tester.pumpWidget(markerTestApp(database: database));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Bookmarks'));
    await pumpRouteTransition(tester);
    await tester.longPress(find.text('Example Article'));
    await pumpRouteTransition(tester);
    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('https://example.com/article'), findsOneWidget);
  });

  testWidgets('edit mode selects and deletes bookmarks', (tester) async {
    await _seedBookmarkManager(database);

    await tester.pumpWidget(markerTestApp(database: database));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Bookmarks'));
    await pumpRouteTransition(tester);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.text('Example Article'));
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.tap(find.text('Delete').last);
    await tester.pump();
    await tester.pump();
    expect(find.text('Example Article'), findsNothing);
  });

  testWidgets('reorders bookmarks using adjusted destination index', (tester) async {
    await _seedBookmarkManager(database);

    await tester.pumpWidget(markerTestApp(database: database));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Bookmarks'));
    await pumpRouteTransition(tester);

    final list = tester.widget<ReorderableList>(find.byType(ReorderableList));
    list.onReorderItem!(0, 1);
    await tester.pump();
    await tester.pump();

    final rootBookmarks = await database.select(database.bookmarks).get();
    final rootFolders = await database.select(database.bookmarkFolders).get();
    final bookmark = rootBookmarks.singleWhere((row) => row.id == 'bookmark');
    final folder = rootFolders.singleWhere((row) => row.id == 'folder');
    expect(bookmark.sortOrder, lessThan(folder.sortOrder));
  });

  testWidgets('shows bookmark edit screen', (tester) async {
    await _seedBookmarkManager(database);

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
          updatedAt: now,
        ),
      );
  await database
      .into(database.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          id: 'child-bookmark',
          url: 'https://example.com/child',
          title: const Value('Child Bookmark'),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await database
      .into(database.bookmarkCollectionLinks)
      .insert(
        BookmarkCollectionLinksCompanion.insert(
          id: 'child-bookmark-folder',
          bookmarkId: 'child-bookmark',
          folderId: 'folder',
          createdAt: now,
          updatedAt: now,
        ),
      );
}
