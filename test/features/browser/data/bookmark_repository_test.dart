import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/browser/data/bookmark_repository.dart';

void main() {
  late AppDatabase database;
  late BookmarkRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = BookmarkRepository(database, now: () => DateTime.utc(2026, 5, 13, 12));
  });

  tearDown(() async {
    await database.close();
  });

  test('adds and lists bookmarks from drift', () async {
    final bookmarks = await repository.addBookmark(
      url: Uri.parse('https://news.ycombinator.com'),
      title: 'Hacker News',
    );

    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.url, Uri.parse('https://news.ycombinator.com'));
    expect(bookmarks.single.title, 'Hacker News');
    expect(bookmarks.single.createdAt.isAtSameMomentAs(DateTime.utc(2026, 5, 13, 12)), isTrue);

    final rows = await database.select(database.bookmarks).get();
    expect(rows.single.url, 'https://news.ycombinator.com');
  });

  test('does not duplicate bookmark URLs', () async {
    await repository.addBookmark(url: Uri.parse('https://news.ycombinator.com'), title: 'First');
    final bookmarks = await repository.addBookmark(url: Uri.parse('https://news.ycombinator.com'), title: 'Second');

    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.title, 'Second');
  });

  test('enqueues bookmark changes for connected ATProto accounts', () async {
    final syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 13, 12));
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    repository = BookmarkRepository(database, syncRepository: syncRepository, now: () => DateTime.utc(2026, 5, 13, 12));

    await repository.addBookmark(url: Uri.parse('https://news.ycombinator.com'), title: 'Hacker News');

    final outbox = await syncRepository.pendingOutbox(accountDid: 'did:plc:alice');
    expect(outbox.single.localTable, SembleSyncLocalTable.bookmarks.value);
    expect(outbox.single.collection, SembleSyncCollection.card.value);
    expect(outbox.single.operation, 'create');
  });

  test('removes bookmarks by URL', () async {
    final url = Uri.parse('https://news.ycombinator.com');
    await repository.addBookmark(url: url, title: 'Hacker News');

    final bookmarks = await repository.removeBookmark(url);

    expect(bookmarks, isEmpty);
    expect(await database.select(database.bookmarks).get(), isEmpty);
  });
}
