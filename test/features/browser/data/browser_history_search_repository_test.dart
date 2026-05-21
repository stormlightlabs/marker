import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/browser/data/browser_history_search_repository.dart';

void main() {
  late AppDatabase database;
  late BrowserHistorySearchRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = BrowserHistorySearchRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('finds fuzzy matches across title url and meta description with cached favicon metadata', () async {
    final now = DateTime.utc(2026, 5, 13, 12);
    await database
        .into(database.pages)
        .insert(
          PagesCompanion.insert(
            id: 'page',
            url: 'https://example.com/browser-metadata',
            title: const Value('Browser Storage'),
            description: const Value('How cached metadata helps address search'),
            faviconUrl: const Value('https://example.com/favicon.ico'),
            faviconFilePath: const Value('/cache/favicons/example.ico'),
            createdAt: now,
            lastVisitedAt: now,
          ),
        );
    await database
        .into(database.browserHistoryEntries)
        .insert(
          BrowserHistoryEntriesCompanion.insert(
            id: 'history',
            url: 'https://example.com/browser-metadata',
            title: const Value('Browser Storage'),
            description: const Value('How cached metadata helps address search'),
            visitedAt: now,
          ),
        );

    final results = await repository.search('metadta');

    expect(results, hasLength(1));
    expect(results.single.title, 'Browser Storage');
    expect(results.single.description, 'How cached metadata helps address search');
    expect(results.single.faviconFilePath, '/cache/favicons/example.ico');
    expect(results.single.faviconUrl, Uri.parse('https://example.com/favicon.ico'));
  });

  test('does not suggest pages after history is cleared', () async {
    final now = DateTime.utc(2026, 5, 13, 12);
    await database
        .into(database.pages)
        .insert(
          PagesCompanion.insert(
            id: 'page',
            url: 'https://example.com/saved',
            title: const Value('Saved Page'),
            createdAt: now,
            lastVisitedAt: now,
          ),
        );

    final results = await repository.search('saved');

    expect(results, isEmpty);
  });
}
