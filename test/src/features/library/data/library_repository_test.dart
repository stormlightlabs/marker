import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/features/library/data/library_repository.dart';

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
    expect(snapshot.bookmarkedPages.single.annotationCount, 1);

    expect(snapshot.recentPages, hasLength(1));
    expect(snapshot.recentPages.single.title, 'Recent Article');
    expect(snapshot.recentPages.single.annotationCount, 1);

    expect(snapshot.recentAnnotations, hasLength(2));
    expect(snapshot.recentAnnotations.first.pageTitle, 'Recent Article');
    expect(snapshot.recentAnnotations.first.excerpt, 'quote from selector');
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

    expect(snapshot.recentPages.single.annotationCount, 0);
    expect(snapshot.recentAnnotations, isEmpty);
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
          createdAt: recentAt,
          lastVisitedAt: recentAt,
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
