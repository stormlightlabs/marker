import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/settings/data/browser_history_repository.dart';

void main() {
  late AppDatabase database;
  late BrowserHistoryRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = BrowserHistoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('lists history newest first with fallback metadata', () async {
    final older = DateTime.utc(2026, 5, 13, 10);
    final newer = DateTime.utc(2026, 5, 13, 11);
    await database
        .into(database.browserHistoryEntries)
        .insert(
          BrowserHistoryEntriesCompanion.insert(
            id: 'older',
            url: 'https://example.com/old',
            title: const Value('Old Page'),
            visitedAt: older,
          ),
        );
    await database
        .into(database.browserHistoryEntries)
        .insert(
          BrowserHistoryEntriesCompanion.insert(
            id: 'newer',
            url: 'https://example.com/new',
            canonicalUrl: const Value('https://canonical.example/new'),
            visitedAt: newer,
          ),
        );

    final history = await repository.listHistory();

    expect(history.map((item) => item.id), ['newer', 'older']);
    expect(history.first.title, 'example.com');
    expect(history.first.subtitle, 'canonical.example');
    expect(history.last.title, 'Old Page');
  });

  test('clears browser history without deleting pages', () async {
    final now = DateTime.utc(2026, 5, 13, 12);
    await database
        .into(database.pages)
        .insert(PagesCompanion.insert(id: 'page', url: 'https://example.com', createdAt: now, lastVisitedAt: now));
    await database
        .into(database.browserHistoryEntries)
        .insert(BrowserHistoryEntriesCompanion.insert(id: 'history', url: 'https://example.com', visitedAt: now));

    await repository.clearHistory();

    expect(await database.select(database.browserHistoryEntries).get(), isEmpty);
    expect(await database.select(database.pages).get(), hasLength(1));
  });
}
