import 'package:cosmik_poptart/network/cosmik/card.dart' as card;
import 'package:cosmik_poptart/network/cosmik/collection.dart' as collection;
import 'package:cosmik_poptart/network/cosmik/collection_link.dart' as link;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
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
      collection: sembleCardCollection,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://example.com/article', title: 'Example Article'),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: sembleCollectionCollection,
      rkey: 'collection-1',
      cid: 'cid-collection-1',
      value: _collectionJson(name: 'Research'),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: sembleCollectionLinkCollection,
      rkey: 'link-1',
      cid: 'cid-link-1',
      value: _linkJson(
        collectionUri: 'at://did:plc:alice/$sembleCollectionCollection/collection-1',
        collectionCid: 'cid-collection-1',
        cardUri: 'at://did:plc:alice/$sembleCardCollection/card-1',
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
        uri: 'at://did:plc:alice/$sembleCardCollection/card-1',
      ),
      isNotNull,
    );
    expect(
      (await syncRepository.syncState(accountDid: 'did:plc:alice', collection: sembleCardCollection))?.lastError,
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
      collection: sembleCardCollection,
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
      collection: sembleCardCollection,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://EXAMPLE.com/', title: 'Remote title'),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: sembleCollectionCollection,
      rkey: 'collection-1',
      cid: 'cid-collection-1',
      value: _collectionJson(name: 'research'),
    );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: 'bookmarks',
      localId: 'local-bookmark',
      collection: sembleCardCollection,
      rkey: 'card-1',
      uri: 'at://did:plc:alice/$sembleCardCollection/card-1',
    );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: 'bookmark_folders',
      localId: 'local-folder',
      collection: sembleCollectionCollection,
      rkey: 'collection-1',
      uri: 'at://did:plc:alice/$sembleCollectionCollection/collection-1',
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: sembleCollectionLinkCollection,
      rkey: 'link-1',
      cid: 'cid-link-1',
      value: _linkJson(
        collectionUri: 'at://did:plc:alice/$sembleCollectionCollection/collection-1',
        collectionCid: 'cid-collection-1',
        cardUri: 'at://did:plc:alice/$sembleCardCollection/card-1',
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
      collection: sembleCardCollection,
      rkey: 'card-1',
      uri: 'at://did:plc:alice/$sembleCardCollection/card-1',
      dirtyAt: DateTime.utc(2026, 5, 26, 11),
    );
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: sembleCardCollection,
      rkey: 'card-1',
      cid: 'cid-card-1',
      value: _cardJson(url: 'https://example.com/article', title: 'Remote title'),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.conflicts, 1);
    expect((await database.select(database.bookmarks).get()).single.title, 'Local dirty title');
  });

  test('counts malformed records and links with missing refs', () async {
    _putRemote(
      repoClient,
      did: 'did:plc:alice',
      collection: sembleCardCollection,
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
      collection: sembleCollectionLinkCollection,
      rkey: 'bad-link',
      cid: 'cid-bad-link',
      value: _linkJson(
        collectionUri: 'at://did:plc:alice/$sembleCollectionCollection/missing',
        collectionCid: 'cid-missing',
        cardUri: 'at://did:plc:alice/$sembleCardCollection/missing',
        cardCid: 'cid-missing',
      ),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.malformed, 2);
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
