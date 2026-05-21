import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/library/data/library_search_repository.dart';

void main() {
  late AppDatabase database;
  late LibrarySearchRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LibrarySearchRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and populates the fts table for library records', () async {
    await _seedSearchLibrary(database);

    await repository.rebuildIndex();

    final rows = await database.customSelect('SELECT document_type, title FROM library_search_fts').get();
    expect(rows.map((row) => row.read<String>('document_type')), containsAll(['page', 'annotation']));
    expect(rows.map((row) => row.read<String>('title')), contains('Neural Notes'));
  });

  test('searches pages and annotations without browsing history', () async {
    await _seedSearchLibrary(database);
    await database
        .into(database.browserHistoryEntries)
        .insert(
          BrowserHistoryEntriesCompanion.insert(
            id: 'history',
            url: 'https://history.example.com/private',
            title: const Value('Private History Only'),
            visitedAt: DateTime.utc(2026, 5, 13, 13),
          ),
        );

    final pageResults = await repository.search('neural');
    final annotationResults = await repository.search('vector recall');
    final historyResults = await repository.search('private');

    expect(pageResults.first.type, LibrarySearchResultType.page);
    expect(pageResults.first.id, 'page');
    expect(annotationResults.first.type, LibrarySearchResultType.annotation);
    expect(annotationResults.first.id, 'annotation');
    expect(historyResults, isEmpty);
  });

  test('uses fuzzy fallback for typo-tolerant annotation search and excludes deleted annotations', () async {
    await _seedSearchLibrary(database);
    await database
        .into(database.annotations)
        .insert(
          AnnotationsCompanion.insert(
            id: 'deleted',
            pageId: 'page',
            motivation: 'highlighting',
            createdAt: DateTime.utc(2026, 5, 13, 12),
            modifiedAt: DateTime.utc(2026, 5, 13, 12),
            deletedAt: Value(DateTime.utc(2026, 5, 13, 13)),
          ),
        );
    await database
        .into(database.annotationTargets)
        .insert(
          AnnotationTargetsCompanion.insert(
            id: 'deleted-target',
            annotationId: 'deleted',
            sourceUrl: 'https://example.com/neural',
            selectorJson: '{"selector":[{"type":"TextQuoteSelector","exact":"vanished phrase"}]}',
          ),
        );

    final typoResults = await repository.search('vectro recal');
    final deletedResults = await repository.search('vanished');

    expect(typoResults.map((result) => result.id), contains('annotation'));
    expect(deletedResults, isEmpty);
  });
}

Future<void> _seedSearchLibrary(AppDatabase database) async {
  final now = DateTime.utc(2026, 5, 13, 12);
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'page',
          url: 'https://example.com/neural',
          title: const Value('Neural Notes'),
          description: const Value('A saved article about embeddings and local search'),
          createdAt: now,
          lastVisitedAt: now,
        ),
      );
  await database
      .into(database.bookmarkFolders)
      .insert(BookmarkFoldersCompanion.insert(id: 'folder', title: 'Research', createdAt: now, updatedAt: now));
  await database
      .into(database.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          id: 'bookmark',
          folderId: const Value('folder'),
          url: 'https://example.com/neural',
          title: const Value('Neural Notes'),
          createdAt: now,
        ),
      );
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: 'annotation',
          pageId: 'page',
          motivation: 'commenting',
          createdAt: now,
          modifiedAt: now,
        ),
      );
  await database
      .into(database.annotationTargets)
      .insert(
        AnnotationTargetsCompanion.insert(
          id: 'target',
          annotationId: 'annotation',
          sourceUrl: 'https://example.com/neural',
          selectorJson: '{"selector":[{"type":"TextQuoteSelector","exact":"vector recall"}]}',
        ),
      );
  await database
      .into(database.annotationBodies)
      .insert(
        AnnotationBodiesCompanion.insert(
          id: 'note',
          annotationId: 'annotation',
          type: 'TextualBody',
          format: const Value('text/markdown'),
          value: 'semantic bookmark note',
        ),
      );
}
