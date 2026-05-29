import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/semble_bookmark_push_service.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late FakeAtprotoRepoClient repoClient;
  late SembleBookmarkPushService service;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 27, 12));
    repoClient = FakeAtprotoRepoClient();
    service = SembleBookmarkPushService(
      database: database,
      syncRepository: syncRepository,
      repoClient: repoClient,
      now: () => DateTime.utc(2026, 5, 27, 12),
    );
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
  });

  tearDown(() async {
    await database.close();
  });

  test('maps bookmarks folders and memberships to Semble records and stores mirrors', () async {
    await _seedBookmarkFolderAndLink(database);
    await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
      localId: 'folder-1',
      collection: SembleSyncCollection.collection.value,
    );
    await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      localId: 'link-1',
      collection: SembleSyncCollection.collectionLink.value,
    );

    final result = await service.pushPending('did:plc:alice');

    expect(result.pushed, 3);
    expect(await syncRepository.pendingOutbox(accountDid: 'did:plc:alice'), isEmpty);
    final bookmarkMirror = await syncRepository.mirrorForLocal(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    final folderMirror = await syncRepository.mirrorForLocal(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
      localId: 'folder-1',
      collection: SembleSyncCollection.collection.value,
    );
    final linkMirror = await syncRepository.mirrorForLocal(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      localId: 'link-1',
      collection: SembleSyncCollection.collectionLink.value,
    );
    expect(bookmarkMirror?.uri, 'at://did:plc:alice/${SembleSyncCollection.card.value}/bookmark-1');
    expect(folderMirror?.cid, isNotNull);
    expect(linkMirror?.lastSyncedHash, isNotNull);

    final card = repoClient.records[bookmarkMirror!.uri]!.value;
    expect(card['url'], 'https://example.com/article');
    expect((card['content'] as Map<String, dynamic>)['url'], 'https://example.com/article');
    expect(((card['content'] as Map<String, dynamic>)['metadata'] as Map<String, dynamic>)['title'], 'Example');

    final collection = repoClient.records[folderMirror!.uri]!.value;
    expect(collection['name'], 'Research');
    expect(collection['accessType'], 'CLOSED');

    final link = repoClient.records[linkMirror!.uri]!.value;
    expect((link['collection'] as Map<String, dynamic>)['uri'], folderMirror.uri);
    expect((link['card'] as Map<String, dynamic>)['uri'], bookmarkMirror.uri);
    expect(link['addedBy'], 'did:plc:alice');
  });

  test('updates existing mirrors with putRecord and clears dirty state', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'bookmark-1',
            url: 'https://example.com/article',
            title: const Value('Updated'),
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 27, 11),
          ),
        );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
      rkey: 'bookmark-1',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/bookmark-1',
      cid: 'old-cid',
      dirtyAt: DateTime.utc(2026, 5, 27, 11),
    );
    await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.update.value,
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );

    await service.pushPending('did:plc:alice');

    expect(repoClient.calls.single, isA<Record>());
    final mirror = await syncRepository.mirrorForLocal(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    expect(mirror?.cid, isNot('old-cid'));
    expect(mirror?.dirtyAt, isNull);
    expect(mirror?.lastSyncedRecordJson, contains('Updated'));
  });

  test('defers retries during backoff and records useful errors', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'missing-bookmark',
            url: 'https://example.com/missing-mirror',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkFolders)
        .insert(
          BookmarkFoldersCompanion.insert(
            id: 'missing-folder',
            title: 'Missing mirror',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkCollectionLinks)
        .insert(
          BookmarkCollectionLinksCompanion.insert(
            id: 'link-1',
            bookmarkId: 'missing-bookmark',
            folderId: 'missing-folder',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    final outbox = await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      localId: 'link-1',
      collection: SembleSyncCollection.collectionLink.value,
    );

    final failed = await service.pushPending('did:plc:alice');
    expect(failed.failed, 1);
    final attempted = (await syncRepository.pendingOutbox(accountDid: 'did:plc:alice')).single;
    expect(attempted.id, outbox.id);
    expect(attempted.attemptCount, 1);
    expect(attempted.lastError, contains('Sync the bookmark folder before its folder link'));

    final deferred = await service.pushPending('did:plc:alice');
    expect(deferred.deferred, 1);
    expect((await syncRepository.pendingOutbox(accountDid: 'did:plc:alice')).single.attemptCount, 1);
  });

  test('is idempotent when retrying after a write already produced a mirror', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'bookmark-1',
            url: 'https://example.com/article',
            title: const Value('Example'),
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    await service.pushPending('did:plc:alice');
    await syncRepository.markMirrorDirty(
      id: (await syncRepository.mirrorForLocal(
        accountDid: 'did:plc:alice',
        localTable: AtprotoSyncLocalTable.bookmarks.value,
        localId: 'bookmark-1',
        collection: SembleSyncCollection.card.value,
      ))!.id,
      dirtyAt: DateTime.utc(2026, 5, 27, 11),
    );
    await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    repoClient.calls.clear();

    await service.pushPending('did:plc:alice');

    expect(repoClient.calls, isEmpty);
    expect(await syncRepository.pendingOutbox(accountDid: 'did:plc:alice'), isEmpty);
    final mirror = await syncRepository.mirrorForLocal(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    expect(mirror?.dirtyAt, isNull);
  });
}

Future<void> _seedBookmarkFolderAndLink(AppDatabase database) async {
  await database
      .into(database.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          id: 'bookmark-1',
          url: 'https://example.com/article',
          title: const Value('Example'),
          description: const Value('Description'),
          createdAt: DateTime.utc(2026, 5, 26, 10),
          updatedAt: DateTime.utc(2026, 5, 26, 11),
        ),
      );
  await database
      .into(database.bookmarkFolders)
      .insert(
        BookmarkFoldersCompanion.insert(
          id: 'folder-1',
          title: 'Research',
          description: const Value('Papers'),
          accessType: const Value('CLOSED'),
          createdAt: DateTime.utc(2026, 5, 26, 9),
          updatedAt: DateTime.utc(2026, 5, 26, 11),
        ),
      );
  await database
      .into(database.bookmarkCollectionLinks)
      .insert(
        BookmarkCollectionLinksCompanion.insert(
          id: 'link-1',
          bookmarkId: 'bookmark-1',
          folderId: 'folder-1',
          createdAt: DateTime.utc(2026, 5, 26, 12),
          updatedAt: DateTime.utc(2026, 5, 26, 12),
        ),
      );
}
