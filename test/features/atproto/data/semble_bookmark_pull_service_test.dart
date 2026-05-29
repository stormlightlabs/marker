import 'dart:convert';
import 'dart:io';

import 'package:cosmik_poptart/network/cosmik/card.dart' as card;
import 'package:cosmik_poptart/network/cosmik/collection.dart' as collection;
import 'package:cosmik_poptart/network/cosmik/collection_link.dart' as link;
import 'package:cosmik_poptart/network/cosmik/collection_link_removal.dart' as removal;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/logging/log_files.dart';
import 'package:marker/features/atproto/data/atproto_deletion_sync_service.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/domain/atproto_repo_models.dart';
import 'package:poptart_core/poptart_core.dart';
import 'package:poptart_lex/com/atproto/repo/strong_ref.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late FakeAtprotoRepoClient repoClient;
  late SembleBookmarkPullService service;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 26, 12));
    repoClient = FakeAtprotoRepoClient();
    service = SembleBookmarkPullService(
      database: database,
      syncRepository: syncRepository,
      repoClient: repoClient,
      now: () => DateTime.utc(2026, 5, 26, 12),
    );
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
  });

  tearDown(() async {
    await database.close();
  });

  test('pulls cards collections and collection links into local bookmarks', () async {
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://example.com/article', title: 'Example Article'),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.collection.value,
      rkey: 'collection-1',
      cid: 'cid-collection-1',
      value: _collectionJson(name: 'Research'),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.collectionLink.value,
      rkey: 'link-1',
      cid: 'cid-link-1',
      value: _linkJson(
        collectionUri: 'at://did:plc:alice/${SembleSyncCollection.collection.value}/collection-1',
        collectionCid: 'cid-collection-1',
        cardUri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
        cardCid: 'cid-card-1',
      ),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.cardsImported, 1);
    expect(result.collectionsImported, 1);
    expect(result.linksImported, 1);
    expect(result.malformed, 0);

    final bookmark = (await database.select(database.bookmarks).get()).single;
    final folder = (await database.select(database.bookmarkFolders).get()).single;
    final localLink = (await database.select(database.bookmarkCollectionLinks).get()).single;
    expect(bookmark.url, 'https://example.com/article');
    expect(bookmark.title, 'Example Article');
    expect(bookmark.description, 'Imported description');
    expect(folder.title, 'Research');
    expect(folder.parentId, isNull);
    expect(localLink.bookmarkId, bookmark.id);
    expect(localLink.folderId, folder.id);

    expect(
      await syncRepository.mirrorForUri(
        accountDid: 'did:plc:alice',
        uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
      ),
      isNotNull,
    );
    expect(
      (await syncRepository.syncState(
        accountDid: 'did:plc:alice',
        collection: SembleSyncCollection.card.value,
      ))?.lastError,
      isNull,
    );
  });

  test('deduplicates cards by normalized URL without an existing mirror', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com/article',
            title: const Value('Local title'),
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://example.com/article#section', title: 'Remote title'),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.duplicates, 1);
    expect(await database.select(database.bookmarks).get(), hasLength(1));
  });

  test('deduplicates links by collection plus card URI', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com',
            title: const Value('Local title'),
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkFolders)
        .insert(
          BookmarkFoldersCompanion.insert(
            id: 'local-folder',
            title: 'Research',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkCollectionLinks)
        .insert(
          BookmarkCollectionLinksCompanion.insert(
            id: 'local-link',
            bookmarkId: 'local-bookmark',
            folderId: 'local-folder',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );

    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://EXAMPLE.com/', title: 'Remote title'),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.collection.value,
      rkey: 'collection-1',
      cid: 'cid-collection-1',
      value: _collectionJson(name: 'research'),
    );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: 'bookmarks',
      localId: 'local-bookmark',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
    );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: 'bookmark_folders',
      localId: 'local-folder',
      collection: SembleSyncCollection.collection.value,
      rkey: 'collection-1',
      uri: 'at://did:plc:alice/${SembleSyncCollection.collection.value}/collection-1',
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.collectionLink.value,
      rkey: 'link-1',
      cid: 'cid-link-1',
      value: _linkJson(
        collectionUri: 'at://did:plc:alice/${SembleSyncCollection.collection.value}/collection-1',
        collectionCid: 'cid-collection-1',
        cardUri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
        cardCid: 'cid-card-1',
      ),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.duplicates, 1);
    expect(await database.select(database.bookmarks).get(), hasLength(1));
    expect(await database.select(database.bookmarkFolders).get(), hasLength(1));
    expect(await database.select(database.bookmarkCollectionLinks).get(), hasLength(1));
  });

  test('skips dirty mirrored local rows as conflicts', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com/article',
            title: const Value('Local dirty title'),
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 11),
          ),
        );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: 'bookmarks',
      localId: 'local-bookmark',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
      dirtyAt: DateTime.utc(2026, 5, 26, 11),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://example.com/article', title: 'Remote title'),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.conflicts, 1);
    expect((await database.select(database.bookmarks).get()).single.title, 'Local dirty title');
  });

  test('consumes collection link removal records as soft-deleted links and mirror tombstones', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkFolders)
        .insert(
          BookmarkFoldersCompanion.insert(
            id: 'local-folder',
            title: 'Research',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkCollectionLinks)
        .insert(
          BookmarkCollectionLinksCompanion.insert(
            id: 'local-link',
            bookmarkId: 'local-bookmark',
            folderId: 'local-folder',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      localId: 'local-link',
      collection: SembleSyncCollection.collectionLink.value,
      rkey: 'link-1',
      uri: 'at://did:plc:bob/${SembleSyncCollection.collectionLink.value}/link-1',
      cid: 'cid-link-1',
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.collectionLinkRemoval.value,
      rkey: 'removal-1',
      cid: 'cid-removal-1',
      value: _removalJson(
        collectionUri: 'at://did:plc:alice/${SembleSyncCollection.collection.value}/collection-1',
        collectionCid: 'cid-collection-1',
        removedLinkUri: 'at://did:plc:bob/${SembleSyncCollection.collectionLink.value}/link-1',
        removedLinkCid: 'cid-link-1',
      ),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.deleted, 1);
    expect((await database.select(database.bookmarkCollectionLinks).get()).single.deletedAt, isNotNull);
    expect(
      (await syncRepository.mirrorForUri(
        accountDid: 'did:plc:alice',
        uri: 'at://did:plc:bob/${SembleSyncCollection.collectionLink.value}/link-1',
      ))?.deletedAt,
      isNotNull,
    );
  });

  test('marks mirrored local rows deleted when getRecord confirms a missing remote record', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com/missing',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'local-bookmark',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-missing',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-missing',
      cid: 'cid-card-missing',
      lastSyncedAt: DateTime.utc(2026, 5, 26, 10),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.deleted, 1);
    expect((await database.select(database.bookmarks).get()).single.deletedAt, isNotNull);
    expect(
      (await syncRepository.mirrorForUri(
        accountDid: 'did:plc:alice',
        uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-missing',
      ))?.deletedAt,
      isNotNull,
    );
  });

  test('pushes local soft deletes through deleteRecord and keeps mirror tombstones', () async {
    final deletionService = AtprotoDeletionSyncService(
      database: database,
      syncRepository: syncRepository,
      repoClient: repoClient,
      now: () => DateTime.utc(2026, 5, 26, 13),
    );
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com/delete-me',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'local-bookmark',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
      cid: 'cid-card-1',
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.card.value,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://example.com/delete-me', title: 'Delete me'),
    );

    await deletionService.softDeleteLocal(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'local-bookmark',
      collection: SembleSyncCollection.card.value,
    );
    await deletionService.pushLocalDeletes('did:plc:alice');

    expect(repoClient.records['at://did:plc:alice/${SembleSyncCollection.card.value}/card-1'], isNull);
    expect((await database.select(database.bookmarks).get()).single.deletedAt, isNotNull);
    final mirror = await syncRepository.mirrorForUri(
      accountDid: 'did:plc:alice',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
    );
    expect(mirror?.deletedAt, isNotNull);
    expect(mirror?.dirtyAt, isNull);
    expect(await syncRepository.pendingOutbox(accountDid: 'did:plc:alice'), isEmpty);
  });

  test('publishes collectionLinkRemoval when deleting a link owned by another repo', () async {
    final deletionService = AtprotoDeletionSyncService(
      database: database,
      syncRepository: syncRepository,
      repoClient: repoClient,
      now: () => DateTime.utc(2026, 5, 26, 13),
    );
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com/shared',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkFolders)
        .insert(
          BookmarkFoldersCompanion.insert(
            id: 'local-folder',
            title: 'Research',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await database
        .into(database.bookmarkCollectionLinks)
        .insert(
          BookmarkCollectionLinksCompanion.insert(
            id: 'local-link',
            bookmarkId: 'local-bookmark',
            folderId: 'local-folder',
            createdAt: DateTime.utc(2026, 5, 26, 10),
            updatedAt: DateTime.utc(2026, 5, 26, 10),
          ),
        );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      localId: 'local-link',
      collection: SembleSyncCollection.collectionLink.value,
      rkey: 'link-1',
      uri: 'at://did:plc:bob/${SembleSyncCollection.collectionLink.value}/link-1',
      cid: 'cid-link-1',
      lastSyncedRecordJson: jsonForTest(
        _linkJson(
          collectionUri: 'at://did:plc:alice/${SembleSyncCollection.collection.value}/collection-1',
          collectionCid: 'cid-collection-1',
          cardUri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/card-1',
          cardCid: 'cid-card-1',
        ),
      ),
    );

    await deletionService.softDeleteLocal(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      localId: 'local-link',
      collection: SembleSyncCollection.collectionLink.value,
    );
    await deletionService.pushLocalDeletes('did:plc:alice');

    expect(
      repoClient.records.values.any(
        (record) => record.uri.startsWith('at://did:plc:alice/${SembleSyncCollection.collectionLinkRemoval.value}/'),
      ),
      isTrue,
    );
    expect(
      (await syncRepository.mirrorForUri(
        accountDid: 'did:plc:alice',
        uri: 'at://did:plc:bob/${SembleSyncCollection.collectionLink.value}/link-1',
      ))?.deletedAt,
      isNotNull,
    );
  });

  test('counts and logs malformed records and links with missing refs', () async {
    final logDirectory = await Directory.systemTemp.createTemp('marker_semble_malformed_logs_');
    addTearDown(() async {
      if (await logDirectory.exists()) await logDirectory.delete(recursive: true);
    });
    final logger = await AppLogger.initialize(directory: logDirectory);
    addTearDown(logger.close);
    service = SembleBookmarkPullService(
      database: database,
      syncRepository: syncRepository,
      repoClient: repoClient,
      logger: logger,
      now: () => DateTime.utc(2026, 5, 26, 12),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.card.value,
      rkey: 'bad-card',
      cid: 'cid-bad-card',
      value: {
        '\$type': 'network.cosmik.card',
        'type': 'URL',
        'content': {'\$type': 'unknown'},
      },
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: SembleSyncCollection.collectionLink.value,
      rkey: 'bad-link',
      cid: 'cid-bad-link',
      value: _linkJson(
        collectionUri: 'at://did:plc:alice/${SembleSyncCollection.collection.value}/missing',
        collectionCid: 'cid-missing',
        cardUri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/missing',
        cardCid: 'cid-missing',
      ),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.malformed, 2);
    final logText = await File('${logDirectory.path}/$activeLogFileName').readAsString();
    expect(logText, contains('Semble card record is missing a valid URL'));
    expect(logText, contains('Semble collection link references records that are not mirrored locally'));
    expect(await database.select(database.bookmarks).get(), isEmpty);
    expect(await database.select(database.bookmarkCollectionLinks).get(), isEmpty);
  });
}

void _putRemote(
  FakeAtprotoRepoClient client, {
  required String did,
  required String collection,
  required String rkey,
  required String cid,
  required Map<String, dynamic> value,
}) => client.records['at://$did/$collection/$rkey'] = AtprotoRepoRecord(
  uri: 'at://$did/$collection/$rkey',
  cid: cid,
  value: value,
);

Map<String, dynamic> _cardJson({required String url, required String title}) => card.CardRecord(
  type: const card.CardType.knownValue(data: card.KnownCardType.uRL),
  url: url,
  content: card.UCardContent.urlContent(
    data: card.UrlContent(
      url: url,
      metadata: card.UrlMetadata(title: title, description: 'Imported description'),
    ),
  ),
  createdAt: DateTime.utc(2026, 5, 26, 9),
).toJson();

Map<String, dynamic> _collectionJson({required String name}) => collection.CollectionRecord(
  name: name,
  description: 'Imported collection',
  accessType: const collection.CollectionAccessType.knownValue(data: collection.KnownCollectionAccessType.cLOSED),
  createdAt: DateTime.utc(2026, 5, 26, 8),
  updatedAt: DateTime.utc(2026, 5, 26, 9),
).toJson();

String jsonForTest(Map<String, dynamic> value) => jsonEncode(value);

Map<String, dynamic> _linkJson({
  required String collectionUri,
  required String collectionCid,
  required String cardUri,
  required String cardCid,
}) => link.CollectionLinkRecord(
  collection: RepoStrongRef(uri: AtUri(collectionUri), cid: collectionCid),
  card: RepoStrongRef(uri: AtUri(cardUri), cid: cardCid),
  addedBy: 'did:plc:alice',
  addedAt: DateTime.utc(2026, 5, 26, 10),
  createdAt: DateTime.utc(2026, 5, 26, 10),
).toJson();

Map<String, dynamic> _removalJson({
  required String collectionUri,
  required String collectionCid,
  required String removedLinkUri,
  required String removedLinkCid,
}) => removal.CollectionLinkRemovalRecord(
  collection: RepoStrongRef(uri: AtUri(collectionUri), cid: collectionCid),
  removedLink: RepoStrongRef(uri: AtUri(removedLinkUri), cid: removedLinkCid),
  removedAt: DateTime.utc(2026, 5, 26, 11),
).toJson();
