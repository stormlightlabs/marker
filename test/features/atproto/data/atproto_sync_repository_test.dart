import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 26, 12));
  });

  tearDown(() async {
    await database.close();
  });

  test('stores accounts mirrors cursors and outbox records', () async {
    final account = await repository.upsertAccount(
      did: 'did:plc:alice',
      handle: 'alice.example',
      pdsEndpoint: 'https://pds.example',
      authMethod: 'oauth',
    );
    expect(account.did, 'did:plc:alice');
    expect(account.handle, 'alice.example');

    final mirror = await repository.createMirror(
      accountDid: account.did,
      localTable: 'bookmarks',
      localId: 'bookmark-1',
      collection: 'network.cosmik.card',
      rkey: 'card-1',
      uri: 'at://did:plc:alice/network.cosmik.card/card-1',
      cid: 'cid-1',
      lastSyncedRecordJson: '{"url":"https://example.com"}',
      lastSyncedHash: 'hash-1',
      lastSyncedAt: DateTime.utc(2026, 5, 26, 11),
    );

    expect(
      await repository.mirrorForLocal(
        accountDid: account.did,
        localTable: 'bookmarks',
        localId: 'bookmark-1',
        collection: 'network.cosmik.card',
      ),
      mirror,
    );
    expect(await repository.mirrorForUri(accountDid: account.did, uri: mirror.uri), mirror);

    await repository.markMirrorSynced(
      id: mirror.id,
      cid: 'cid-2',
      lastSyncedRecordJson: '{"url":"https://example.com/updated"}',
      lastSyncedHash: 'hash-2',
    );
    final syncedMirror = await repository.mirrorForUri(accountDid: account.did, uri: mirror.uri);
    expect(syncedMirror?.cid, 'cid-2');
    expect(syncedMirror?.dirtyAt, isNull);

    final state = await repository.saveCursor(
      accountDid: account.did,
      collection: 'network.cosmik.card',
      cursor: 'cursor-1',
      lastSuccessfulSyncAt: DateTime.utc(2026, 5, 26, 10),
    );
    expect(state.cursor, 'cursor-1');
    expect((await repository.syncState(accountDid: account.did, collection: 'network.cosmik.card'))?.id, state.id);

    final outbox = await repository.enqueueOutbox(
      accountDid: account.did,
      operation: 'update',
      localTable: 'bookmarks',
      localId: 'bookmark-1',
      collection: 'network.cosmik.card',
      payloadJson: '{"url":"https://example.com"}',
    );
    expect(await repository.pendingOutbox(accountDid: account.did), [outbox]);

    await repository.markOutboxAttempt(id: outbox.id, attemptCount: 1, lastError: 'rate limited');
    final attempted = (await repository.pendingOutbox(accountDid: account.did)).single;
    expect(attempted.attemptCount, 1);
    expect(attempted.lastError, 'rate limited');

    await repository.deleteOutbox(outbox.id);
    expect(await repository.pendingOutbox(accountDid: account.did), isEmpty);
  });

  test('enforces mirror uniqueness by local row and remote uri per account', () async {
    await repository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    await repository.upsertAccount(did: 'did:plc:bob', authMethod: 'oauth');
    await repository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: 'bookmarks',
      localId: 'bookmark-1',
      collection: 'network.cosmik.card',
      rkey: 'card-1',
      uri: 'at://did:plc:alice/network.cosmik.card/card-1',
    );

    await expectLater(
      repository.createMirror(
        accountDid: 'did:plc:alice',
        localTable: 'bookmarks',
        localId: 'bookmark-1',
        collection: 'network.cosmik.card',
        rkey: 'card-2',
        uri: 'at://did:plc:alice/network.cosmik.card/card-2',
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      repository.createMirror(
        accountDid: 'did:plc:alice',
        localTable: 'bookmarks',
        localId: 'bookmark-2',
        collection: 'network.cosmik.card',
        rkey: 'card-1',
        uri: 'at://did:plc:alice/network.cosmik.card/card-1',
      ),
      throwsA(isA<Exception>()),
    );

    final bobMirror = await repository.createMirror(
      accountDid: 'did:plc:bob',
      localTable: 'bookmarks',
      localId: 'bookmark-1',
      collection: 'network.cosmik.card',
      rkey: 'card-1',
      uri: 'at://did:plc:alice/network.cosmik.card/card-1',
    );
    expect(bobMirror.accountDid, 'did:plc:bob');
  });

  test('selects deselects lists watches and gates local change enqueue', () async {
    await repository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');

    await repository.enqueueLocalChangeForAllAccounts(
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    expect(await repository.pendingOutbox(accountDid: 'did:plc:alice'), isEmpty);

    final selected = await repository.selectForSync(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    expect(selected.deselectedAt, isNull);
    expect(await repository.activeSelections(accountDid: 'did:plc:alice'), hasLength(1));
    expect(await repository.watchActiveSelections(accountDid: 'did:plc:alice').first, hasLength(1));
    expect((await repository.pendingOutbox(accountDid: 'did:plc:alice')).single.operation, 'create');

    await repository.deselectForSync(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    expect(await repository.activeSelections(accountDid: 'did:plc:alice'), isEmpty);

    await repository.enqueueLocalChangeForAllAccounts(
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'bookmark-1',
      collection: SembleSyncCollection.card.value,
    );
    expect(await repository.pendingOutbox(accountDid: 'did:plc:alice'), hasLength(1));
  });

  test('enqueues outbox records in the same transaction as local writes', () async {
    await repository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    final now = DateTime.utc(2026, 5, 26, 12);

    await expectLater(
      repository.transaction<void>((sync) async {
        await database
            .into(database.bookmarks)
            .insert(
              BookmarksCompanion.insert(
                id: 'rolled-back-bookmark',
                url: 'https://rolled-back.example',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await sync.enqueueOutbox(
          accountDid: 'did:plc:alice',
          operation: 'create',
          localTable: 'bookmarks',
          localId: 'rolled-back-bookmark',
          collection: 'network.cosmik.card',
        );
        throw StateError('abort transaction');
      }),
      throwsStateError,
    );

    expect(await database.select(database.bookmarks).get(), isEmpty);
    expect(await repository.pendingOutbox(accountDid: 'did:plc:alice'), isEmpty);

    await repository.transaction<void>((sync) async {
      await database
          .into(database.bookmarks)
          .insert(
            BookmarksCompanion.insert(id: 'bookmark-1', url: 'https://example.com', createdAt: now, updatedAt: now),
          );
      await sync.enqueueOutbox(
        accountDid: 'did:plc:alice',
        operation: 'create',
        localTable: 'bookmarks',
        localId: 'bookmark-1',
        collection: 'network.cosmik.card',
      );
    });

    expect((await database.select(database.bookmarks).get()).single.id, 'bookmark-1');
    expect((await repository.pendingOutbox(accountDid: 'did:plc:alice')).single.localId, 'bookmark-1');
  });
}
