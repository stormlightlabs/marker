import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/browser/data/favicon_cache.dart';
import 'package:marker/features/library/data/library_repository.dart';

void main() {
  late AppDatabase database;
  late LibraryRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LibraryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('loads bookmarks, recent pages, and recent annotations from drift', () async {
    await _seedLibrary(database);

    final snapshot = await repository.loadSnapshot();

    expect(snapshot.bookmarkedPages, hasLength(1));
    expect(snapshot.bookmarkedPages.single.title, 'Saved Article');
    expect(snapshot.bookmarkedPages.single.bookmarkFolderPath, 'Research / Reading');
    expect(snapshot.bookmarkedPages.single.annotationCount, 1);

    expect(snapshot.recentPages, hasLength(2));
    expect(snapshot.recentPages.first.title, 'Recent Article');
    expect(snapshot.recentPages.first.annotationCount, 1);
    expect(snapshot.recentPages.first.faviconUrl, Uri.parse('https://example.com/favicon.ico'));
    expect(snapshot.recentPages.first.faviconFilePath, '/cache/favicons/example.ico');
    expect(snapshot.recentPages.first.annotationPreview, 'quote from selector');
    expect(snapshot.recentPages.last.title, 'Saved Article');
    expect(snapshot.recentPages.last.bookmarkFolderPath, 'Research / Reading');

    expect(snapshot.recentAnnotations, hasLength(2));
    expect(snapshot.recentAnnotations.first.pageTitle, 'Recent Article');
    expect(snapshot.recentAnnotations.first.excerpt, 'quote from selector');

    final groups = await repository.loadAnnotationGroups();
    expect(groups, hasLength(2));
    expect(groups.first.title, 'Recent Article');
    expect(groups.first.annotations.single.excerpt, 'quote from selector');
    expect(groups.last.title, 'Saved Article');
    expect(groups.last.bookmarkFolderPath, 'Research / Reading');
  });

  test('ignores deleted annotations in counts and recent annotations', () async {
    final now = DateTime.utc(2026, 5, 13, 12);
    await database
        .into(database.pages)
        .insert(
          PagesCompanion.insert(
            id: 'page',
            url: 'https://example.com/page',
            title: const Value('Example Page'),
            createdAt: now,
            lastVisitedAt: now,
          ),
        );
    await database
        .into(database.annotations)
        .insert(
          AnnotationsCompanion.insert(
            id: 'deleted',
            pageId: 'page',
            motivation: 'highlighting',
            createdAt: now,
            modifiedAt: now,
            deletedAt: Value(now),
          ),
        );

    final snapshot = await repository.loadSnapshot();

    expect(snapshot.recentPages, isEmpty);
    expect(snapshot.recentAnnotations, isEmpty);
  });

  test('recaches favicon files when the stored cache path is missing', () async {
    final directory = await Directory.systemTemp.createTemp('marker_library_favicon_test_');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    await _seedLibrary(database);
    repository = LibraryRepository(
      database,
      faviconCache: FaviconCache(
        cacheDirectory: () async => directory,
        fetcher: (url) async => FaviconFetchResult(bytes: Uint8List.fromList([7, 8, 9]), contentType: 'image/x-icon'),
      ),
    );

    final snapshot = await repository.loadSnapshot();
    final page = await (database.select(database.pages)..where((row) => row.id.equals('recent-page'))).getSingle();

    expect(snapshot.recentPages.first.faviconFilePath, isNot('/cache/favicons/example.ico'));
    expect(snapshot.recentPages.first.faviconFilePath, page.faviconFilePath);
    expect(await File(page.faviconFilePath!).readAsBytes(), [7, 8, 9]);
  });
}

Future<void> _seedLibrary(AppDatabase database) async {
  final savedAt = DateTime.utc(2026, 5, 13, 10);
  final recentAt = DateTime.utc(2026, 5, 13, 11);
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'saved-page',
          url: 'https://example.com/saved',
          title: const Value('Saved Article'),
          createdAt: savedAt,
          lastVisitedAt: savedAt,
        ),
      );
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'recent-page',
          url: 'https://example.com/recent',
          title: const Value('Recent Article'),
          faviconUrl: const Value('https://example.com/favicon.ico'),
          faviconFilePath: const Value('/cache/favicons/example.ico'),
          createdAt: recentAt,
          lastVisitedAt: recentAt,
        ),
      );
  await database
      .into(database.bookmarkFolders)
      .insert(
        BookmarkFoldersCompanion.insert(
          id: 'research-folder',
          title: 'Research',
          createdAt: savedAt,
          updatedAt: savedAt,
        ),
      );
  await database
      .into(database.bookmarkFolders)
      .insert(
        BookmarkFoldersCompanion.insert(
          id: 'reading-folder',
          parentId: const Value('research-folder'),
          title: 'Reading',
          createdAt: savedAt,
          updatedAt: savedAt,
        ),
      );
  await database
      .into(database.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          id: 'bookmark',
          url: 'https://example.com/saved',
          title: const Value('Saved Article'),
          createdAt: savedAt,
          updatedAt: savedAt,
        ),
      );
  await database
      .into(database.bookmarkCollectionLinks)
      .insert(
        BookmarkCollectionLinksCompanion.insert(
          id: 'bookmark-reading-folder',
          bookmarkId: 'bookmark',
          folderId: 'reading-folder',
          sortOrder: const Value(0),
          createdAt: savedAt,
          updatedAt: savedAt,
        ),
      );
  await database
      .into(database.bookmarkCollectionLinks)
      .insert(
        BookmarkCollectionLinksCompanion.insert(
          id: 'bookmark-research-folder',
          bookmarkId: 'bookmark',
          folderId: 'research-folder',
          sortOrder: const Value(1),
          createdAt: savedAt.add(const Duration(minutes: 1)),
          updatedAt: savedAt.add(const Duration(minutes: 1)),
        ),
      );
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: 'saved-annotation',
          pageId: 'saved-page',
          motivation: 'highlighting',
          createdAt: savedAt,
          modifiedAt: savedAt,
        ),
      );
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: 'recent-annotation',
          pageId: 'recent-page',
          motivation: 'highlighting',
          createdAt: recentAt,
          modifiedAt: recentAt,
        ),
      );
  await database
      .into(database.annotationTargets)
      .insert(
        AnnotationTargetsCompanion.insert(
          id: 'recent-target',
          annotationId: 'recent-annotation',
          sourceUrl: 'https://example.com/recent',
          selectorJson: '{"selector":[{"type":"TextQuoteSelector","exact":"quote from selector"}]}',
        ),
      );
}
