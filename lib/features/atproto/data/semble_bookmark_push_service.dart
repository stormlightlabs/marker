import 'package:cosmik_poptart/network/cosmik/card.dart' as cosmik_card;
import 'package:cosmik_poptart/network/cosmik/collection.dart' as cosmik_collection;
import 'package:cosmik_poptart/network/cosmik/collection_link.dart' as cosmik_link;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/shared/utils/atproto_utils.dart';
import 'package:marker/core/shared/utils/json_utils.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:poptart_core/poptart_core.dart';
import 'package:poptart_lex/com/atproto/repo/strong_ref.dart';

final sembleBookmarkPushServiceProvider = Provider<SembleBookmarkPushService>((ref) {
  return SembleBookmarkPushService(
    database: ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    repoClient: ref.watch(atprotoRepoClientProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

class SembleBookmarkPushService {
  SembleBookmarkPushService({
    required AppDatabase database,
    required AtprotoSyncRepository syncRepository,
    required AtprotoRepoClient repoClient,
    AppLogger? logger,
    DateTime Function()? now,
  }) : _database = database,
       _syncRepository = syncRepository,
       _repoClient = repoClient,
       _logger = logger,
       _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final AtprotoSyncRepository _syncRepository;
  final AtprotoRepoClient _repoClient;
  final AppLogger? _logger;
  final DateTime Function() _now;

  Future<SembleBookmarkPushResult> pushPending(String accountDid, {int limit = 100}) async {
    final pending = await _syncRepository.pendingOutbox(accountDid: accountDid, limit: limit);
    var result = const SembleBookmarkPushResult();
    for (final item in pending.where(
      (item) =>
          _isSembleOutboxItem(item) &&
          (item.operation == AtprotoSyncOperation.create.value || item.operation == AtprotoSyncOperation.update.value),
    )) {
      if (!_isDue(item)) {
        result += const SembleBookmarkPushResult(deferred: 1);
        continue;
      }
      try {
        await _pushItem(item);
        await _syncRepository.deleteOutbox(item.id);
        result += SembleBookmarkPushResult(
          pushed: 1,
          created: item.operation == AtprotoSyncOperation.create.value ? 1 : 0,
          updated: item.operation == AtprotoSyncOperation.update.value ? 1 : 0,
        );
      } on Object catch (error, stackTrace) {
        _logger?.error(
          'Failed to push Semble bookmark outbox item. '
          'id=${item.id} localTable=${item.localTable} localId=${item.localId} collection=${item.collection}',
          error: error,
          stackTrace: stackTrace,
        );
        await _syncRepository.markOutboxAttempt(
          id: item.id,
          attemptCount: item.attemptCount + 1,
          lastError: _shortError(error),
        );
        result += const SembleBookmarkPushResult(failed: 1);
      }
    }
    return result;
  }

  bool _isDue(AtprotoSyncOutboxData item) {
    if (item.attemptCount <= 0) return true;
    final backoff = Duration(minutes: 1 << (item.attemptCount - 1).clamp(0, 5));
    return !item.updatedAt.add(backoff).isAfter(_now());
  }

  bool _isSembleOutboxItem(AtprotoSyncOutboxData item) {
    if (item.localTable == AtprotoSyncLocalTable.bookmarks.value &&
        item.collection == SembleSyncCollection.card.value) {
      return true;
    }
    if (item.localTable == AtprotoSyncLocalTable.bookmarkFolders.value &&
        item.collection == SembleSyncCollection.collection.value) {
      return true;
    }
    if (item.localTable == AtprotoSyncLocalTable.bookmarkCollectionLinks.value &&
        item.collection == SembleSyncCollection.collectionLink.value) {
      return true;
    }
    return false;
  }

  Future<void> _pushItem(AtprotoSyncOutboxData item) async {
    if (item.operation != AtprotoSyncOperation.delete.value) {
      final selection = await _syncRepository.selectionForLocal(
        accountDid: item.accountDid,
        localTable: item.localTable,
        localId: item.localId,
        collection: item.collection,
      );
      if (selection?.deselectedAt != null || selection == null) return;
    }
    final mirror = await _syncRepository.mirrorForLocal(
      accountDid: item.accountDid,
      localTable: item.localTable,
      localId: item.localId,
      collection: item.collection,
    );
    final rkey = mirror?.rkey ?? _rkeyForLocal(item.localTable, item.localId);
    final record = await _recordForItem(item);
    final json = canonicalJson(record);
    final hash = stableJenkinsOneAtATimeHash(json);
    if (mirror?.lastSyncedHash == hash && mirror?.deletedAt == null) {
      if (mirror?.dirtyAt != null) {
        await _syncRepository.upsertMirror(
          accountDid: item.accountDid,
          localTable: item.localTable,
          localId: item.localId,
          collection: item.collection,
          rkey: mirror!.rkey,
          uri: mirror.uri,
          cid: mirror.cid,
          lastSyncedRecordJson: mirror.lastSyncedRecordJson,
          lastSyncedHash: mirror.lastSyncedHash,
          lastSyncedAt: mirror.lastSyncedAt,
        );
      }
      return;
    }

    final write = await _repoClient.putRecord(
      did: item.accountDid,
      collection: item.collection,
      rkey: rkey,
      record: record,
      swapRecord: mirror?.cid,
    );
    await _syncRepository.upsertMirror(
      accountDid: item.accountDid,
      localTable: item.localTable,
      localId: item.localId,
      collection: item.collection,
      rkey: rkeyFromUri(write.uri),
      uri: write.uri,
      cid: write.cid,
      lastSyncedRecordJson: json,
      lastSyncedHash: hash,
      lastSyncedAt: _now(),
    );
  }

  Future<Map<String, dynamic>> _recordForItem(AtprotoSyncOutboxData item) async {
    if (item.localTable == AtprotoSyncLocalTable.bookmarks.value &&
        item.collection == SembleSyncCollection.card.value) {
      final bookmark = await (_database.select(
        _database.bookmarks,
      )..where((row) => row.id.equals(item.localId) & row.deletedAt.isNull())).getSingleOrNull();
      if (bookmark == null) throw StateError('Bookmark no longer exists locally.');
      return mapBookmarkToSembleCard(bookmark);
    }

    if (item.localTable == AtprotoSyncLocalTable.bookmarkFolders.value &&
        item.collection == SembleSyncCollection.collection.value) {
      final folder = await (_database.select(
        _database.bookmarkFolders,
      )..where((row) => row.id.equals(item.localId) & row.deletedAt.isNull())).getSingleOrNull();
      if (folder == null) throw StateError('Bookmark folder no longer exists locally.');
      return mapFolderToSembleCollection(folder);
    }

    if (item.localTable == AtprotoSyncLocalTable.bookmarkCollectionLinks.value &&
        item.collection == SembleSyncCollection.collectionLink.value) {
      final link = await (_database.select(
        _database.bookmarkCollectionLinks,
      )..where((row) => row.id.equals(item.localId) & row.deletedAt.isNull())).getSingleOrNull();
      if (link == null) throw StateError('Bookmark folder link no longer exists locally.');
      return _mapLinkToSembleCollectionLink(accountDid: item.accountDid, link: link);
    }

    throw StateError('Unsupported Semble bookmark push item: ${item.localTable} ${item.collection}.');
  }

  Map<String, dynamic> mapBookmarkToSembleCard(Bookmark bookmark) => const cosmik_card.CardRecordConverter().toJson(
    cosmik_card.CardRecord(
      type: const cosmik_card.CardType.knownValue(data: cosmik_card.KnownCardType.uRL),
      url: bookmark.url,
      content: cosmik_card.UCardContent.urlContent(
        data: cosmik_card.UrlContent(
          url: bookmark.url,
          metadata: cosmik_card.UrlMetadata(
            title: emptyToNull(bookmark.title),
            description: emptyToNull(bookmark.description),
            retrievedAt: bookmark.updatedAt,
          ),
        ),
      ),
      createdAt: bookmark.createdAt,
    ),
  );

  Map<String, dynamic> mapFolderToSembleCollection(BookmarkFolder folder) {
    final knownAccessType = cosmik_collection.KnownCollectionAccessType.valueOf(folder.accessType);
    return const cosmik_collection.CollectionRecordConverter().toJson(
      cosmik_collection.CollectionRecord(
        name: folder.title,
        description: emptyToNull(folder.description),
        accessType: knownAccessType == null
            ? cosmik_collection.CollectionAccessType.unknown(data: folder.accessType)
            : cosmik_collection.CollectionAccessType.knownValue(data: knownAccessType),
        createdAt: folder.createdAt,
        updatedAt: folder.updatedAt,
      ),
    );
  }

  Future<Map<String, dynamic>> _mapLinkToSembleCollectionLink({
    required String accountDid,
    required BookmarkCollectionLink link,
  }) async {
    final collectionMirror = await _syncRepository.mirrorForLocal(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
      localId: link.folderId,
      collection: SembleSyncCollection.collection.value,
    );
    final cardMirror = await _syncRepository.mirrorForLocal(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: link.bookmarkId,
      collection: SembleSyncCollection.card.value,
    );
    if (collectionMirror == null || collectionMirror.deletedAt != null || collectionMirror.cid == null) {
      throw StateError('Sync the bookmark folder before its folder link.');
    }
    if (cardMirror == null || cardMirror.deletedAt != null || cardMirror.cid == null) {
      throw StateError('Sync the bookmark before its folder link.');
    }
    return const cosmik_link.CollectionLinkRecordConverter().toJson(
      cosmik_link.CollectionLinkRecord(
        collection: RepoStrongRef(uri: AtUri(collectionMirror.uri), cid: collectionMirror.cid!),
        card: RepoStrongRef(uri: AtUri(cardMirror.uri), cid: cardMirror.cid!),
        addedBy: accountDid,
        addedAt: link.createdAt,
        createdAt: link.createdAt,
      ),
    );
  }

  String _rkeyForLocal(String localTable, String localId) {
    final safe = localId.replaceAll(RegExp(r'[^A-Za-z0-9._~-]'), '-');
    if (safe.isNotEmpty && safe.length <= 512 && !safe.startsWith('.')) return safe;
    return 'm-${stableJenkinsOneAtATimeHash('$localTable:$localId')}';
  }

  String _shortError(Object error) {
    final value = error.toString();
    return value.length <= 240 ? value : '${value.substring(0, 240)}…';
  }
}

class SembleBookmarkPushResult {
  const SembleBookmarkPushResult({
    this.pushed = 0,
    this.created = 0,
    this.updated = 0,
    this.failed = 0,
    this.deferred = 0,
  });

  final int pushed;
  final int created;
  final int updated;
  final int failed;
  final int deferred;

  SembleBookmarkPushResult operator +(SembleBookmarkPushResult other) => SembleBookmarkPushResult(
    pushed: pushed + other.pushed,
    created: created + other.created,
    updated: updated + other.updated,
    failed: failed + other.failed,
    deferred: deferred + other.deferred,
  );
}
