import 'package:cosmik_poptart/network/cosmik/card.dart' as cosmik_card;
import 'package:cosmik_poptart/network/cosmik/collection/main.dart' as cosmik_collection;
import 'package:cosmik_poptart/network/cosmik/collection_link/main.dart' as cosmik_link;
import 'package:cosmik_poptart/network/cosmik/collection_link_removal.dart' as cosmik_removal;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/shared/utils/atproto_utils.dart';
import 'package:marker/core/shared/utils/json_utils.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/atproto/data/atproto_deletion_sync_service.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/domain/atproto_repo_models.dart';
import 'package:uuid/uuid.dart';

export 'package:marker/features/atproto/data/atproto_sync_constants.dart';

final sembleBookmarkPullServiceProvider = Provider<SembleBookmarkPullService>((ref) {
  final database = ref.watch(databaseProvider);
  return SembleBookmarkPullService(
    database: database,
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    repoClient: ref.watch(atprotoRepoClientProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

class SembleBookmarkPullProgress {
  const SembleBookmarkPullProgress({
    required this.completedRequests,
    required this.totalRequests,
    required this.description,
  });

  final int completedRequests;
  final int totalRequests;
  final String description;

  double get fraction => totalRequests == 0 ? 0 : completedRequests / totalRequests;

  SembleBookmarkPullProgress offsetBy(int completedOffset) => SembleBookmarkPullProgress(
    completedRequests: completedRequests + completedOffset,
    totalRequests: totalRequests + completedOffset,
    description: description,
  );
}

typedef SembleBookmarkPullProgressListener = void Function(SembleBookmarkPullProgress progress);

class SembleBookmarkPullResult {
  const SembleBookmarkPullResult({
    this.cardsImported = 0,
    this.collectionsImported = 0,
    this.linksImported = 0,
    this.duplicates = 0,
    this.conflicts = 0,
    this.malformed = 0,
    this.deleted = 0,
  });

  final int cardsImported;
  final int collectionsImported;
  final int linksImported;
  final int duplicates;
  final int conflicts;
  final int malformed;
  final int deleted;

  SembleBookmarkPullResult operator +(SembleBookmarkPullResult other) => SembleBookmarkPullResult(
    cardsImported: cardsImported + other.cardsImported,
    collectionsImported: collectionsImported + other.collectionsImported,
    linksImported: linksImported + other.linksImported,
    duplicates: duplicates + other.duplicates,
    conflicts: conflicts + other.conflicts,
    malformed: malformed + other.malformed,
    deleted: deleted + other.deleted,
  );
}

class SembleBookmarkPullService {
  SembleBookmarkPullService({
    required AppDatabase database,
    required AtprotoSyncRepository syncRepository,
    required AtprotoRepoClient repoClient,
    AppLogger? logger,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _database = database,
       _syncRepository = syncRepository,
       _repoClient = repoClient,
       _logger = logger,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final AtprotoSyncRepository _syncRepository;
  final AtprotoRepoClient _repoClient;
  final AppLogger? _logger;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<SembleBookmarkPullResult> pull(
    String accountDid, {
    SembleBookmarkPullProgressListener? onProgress,
    bool importAsLocalOnly = false,
  }) async {
    var result = const SembleBookmarkPullResult();
    var completedRequests = 0;
    var totalRequests = 4;
    final seenUrisByCollection = <String, Set<String>>{};

    Future<SembleBookmarkPullResult> pullCollection(
      String collection,
      String description,
      Future<SembleBookmarkPullResult> Function(
        String accountDid,
        AtprotoRepoRecord record, {
        required bool importAsLocalOnly,
      })
      importRecord,
    ) async => _pullCollection(
      accountDid,
      collection,
      description,
      (accountDid, record) => importRecord(accountDid, record, importAsLocalOnly: importAsLocalOnly),
      onProgress: onProgress,
      completedRequests: () => completedRequests,
      totalRequests: () => totalRequests,
      onRequestCompleted: () => completedRequests += 1,
      onAdditionalRequestNeeded: () => totalRequests += 1,
      onRecordSeen: (uri) => (seenUrisByCollection[collection] ??= <String>{}).add(uri),
    );

    result += await pullCollection(SembleSyncCollection.card.value, 'Fetching cards', _importCard);
    result += await pullCollection(SembleSyncCollection.collection.value, 'Fetching collections', _importCollection);
    result += await pullCollection(
      SembleSyncCollection.collectionLink.value,
      'Fetching collection links',
      _importCollectionLink,
    );
    result += await pullCollection(
      SembleSyncCollection.collectionLinkRemoval.value,
      'Fetching collection link removals',
      _importCollectionLinkRemoval,
    );
    for (final collection in [
      SembleSyncCollection.card.value,
      SembleSyncCollection.collection.value,
      SembleSyncCollection.collectionLink.value,
    ]) {
      result += await _verifyMissingMirrors(
        accountDid,
        collection,
        seenUrisByCollection[collection] ?? const <String>{},
      );
    }
    onProgress?.call(
      SembleBookmarkPullProgress(
        completedRequests: completedRequests,
        totalRequests: totalRequests,
        description: 'Import complete',
      ),
    );
    return result;
  }

  Future<SembleBookmarkPullResult> _pullCollection(
    String accountDid,
    String collection,
    String description,
    Future<SembleBookmarkPullResult> Function(String accountDid, AtprotoRepoRecord record) importRecord, {
    SembleBookmarkPullProgressListener? onProgress,
    required int Function() completedRequests,
    required int Function() totalRequests,
    required void Function() onRequestCompleted,
    required void Function() onAdditionalRequestNeeded,
    required void Function(String uri) onRecordSeen,
  }) async {
    var result = const SembleBookmarkPullResult();
    String? cursor;
    do {
      onProgress?.call(
        SembleBookmarkPullProgress(
          completedRequests: completedRequests(),
          totalRequests: totalRequests(),
          description: cursor == null ? description : '$description (next page)',
        ),
      );
      final page = await _repoClient.listRecords(did: accountDid, collection: collection, cursor: cursor, limit: 100);
      onRequestCompleted();
      for (final record in page.records) {
        onRecordSeen(record.uri);
        result += await importRecord(accountDid, record);
      }
      cursor = page.cursor;
      if (cursor != null) {
        onAdditionalRequestNeeded();
      }
    } while (cursor != null);

    await _syncRepository.saveCursor(
      accountDid: accountDid,
      collection: collection,
      cursor: null,
      lastSuccessfulSyncAt: _now(),
    );
    return result;
  }

  Future<SembleBookmarkPullResult> _importCard(
    String accountDid,
    AtprotoRepoRecord remote, {
    required bool importAsLocalOnly,
  }) async {
    try {
      final record = const cosmik_card.CardRecordConverter().fromJson(remote.value);
      final content = record.content.urlContent;
      final url = content?.url ?? record.url;
      if (url == null || Uri.tryParse(url) == null) {
        return _malformed(remote, 'Semble card record is missing a valid URL.');
      }

      final json = canonicalJson(remote.value);
      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) {
        return const SembleBookmarkPullResult(conflicts: 1);
      }

      final existing = mirror == null ? await _bookmarkByNormalizedUrl(url) : await _bookmarkById(mirror.localId);
      final createdAt = record.createdAt ?? _now();
      final title = emptyToNull(content?.metadata?.title);
      final description = emptyToNull(content?.metadata?.description);
      late final String localId;
      var duplicates = 0;
      if (existing == null) {
        localId = _uuid.v4();
        await _database
            .into(_database.bookmarks)
            .insert(
              BookmarksCompanion.insert(
                id: localId,
                url: url,
                title: Value(title),
                description: Value(description),
                createdAt: createdAt,
                updatedAt: record.createdAt ?? _now(),
              ),
            );
      } else {
        localId = existing.id;
        duplicates = mirror == null ? 1 : 0;
        if (mirror?.dirtyAt != null) {
          return const SembleBookmarkPullResult(conflicts: 1);
        }
        await (_database.update(_database.bookmarks)..where((bookmark) => bookmark.id.equals(existing.id))).write(
          BookmarksCompanion(
            title: Value(_preferNonEmpty(existing.title, title)),
            description: Value(_preferNonEmpty(existing.description, description)),
            url: Value(existing.url),
            updatedAt: Value(_newer(existing.updatedAt, record.createdAt ?? existing.updatedAt)),
          ),
        );
      }

      if (duplicates == 0 || mirror != null) {
        await _syncRepository.upsertMirror(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarks.value,
          localId: localId,
          collection: SembleSyncCollection.card.value,
          rkey: rkeyFromUri(remote.uri),
          uri: remote.uri,
          cid: remote.cid,
          lastSyncedRecordJson: json,
          lastSyncedHash: stableJenkinsOneAtATimeHash(json),
          lastSyncedAt: _now(),
        );
        if (!importAsLocalOnly) {
          await _syncRepository.selectForSync(
            accountDid: accountDid,
            localTable: AtprotoSyncLocalTable.bookmarks.value,
            localId: localId,
            collection: SembleSyncCollection.card.value,
            enqueueCurrent: false,
          );
        }
      }
      return SembleBookmarkPullResult(cardsImported: duplicates == 0 ? 1 : 0, duplicates: duplicates);
    } on Object catch (error, stackTrace) {
      return _malformed(remote, 'Ignoring malformed Semble card record.', error: error, stackTrace: stackTrace);
    }
  }

  Future<SembleBookmarkPullResult> _importCollection(
    String accountDid,
    AtprotoRepoRecord remote, {
    required bool importAsLocalOnly,
  }) async {
    try {
      final record = const cosmik_collection.CollectionRecordConverter().fromJson(remote.value);
      final title = emptyToNull(record.name) ?? 'Untitled Collection';
      final json = canonicalJson(remote.value);
      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) {
        return const SembleBookmarkPullResult(conflicts: 1);
      }

      final existing = mirror == null ? await _folderByNormalizedTitle(title) : await _folderById(mirror.localId);
      late final String localId;
      var duplicates = 0;
      if (existing == null) {
        localId = _uuid.v4();
        await _database
            .into(_database.bookmarkFolders)
            .insert(
              BookmarkFoldersCompanion.insert(
                id: localId,
                parentId: const Value(null),
                title: title,
                description: Value(emptyToNull(record.description)),
                accessType: Value((record.toJson()['accessType'] as String?) ?? 'CLOSED'),
                sortOrder: Value(await _nextRootFolderSortOrder()),
                createdAt: record.createdAt ?? _now(),
                updatedAt: record.updatedAt ?? record.createdAt ?? _now(),
              ),
            );
      } else {
        localId = existing.id;
        duplicates = mirror == null ? 1 : 0;
        await (_database.update(_database.bookmarkFolders)..where((folder) => folder.id.equals(existing.id))).write(
          BookmarkFoldersCompanion(
            parentId: const Value(null),
            title: Value(_preferNonEmpty(existing.title, title) ?? title),
            description: Value(_preferNonEmpty(existing.description, record.description)),
            accessType: Value((record.toJson()['accessType'] as String?) ?? existing.accessType),
            updatedAt: Value(_newer(existing.updatedAt, record.updatedAt ?? existing.updatedAt)),
          ),
        );
      }

      if (duplicates == 0 || mirror != null) {
        await _syncRepository.upsertMirror(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
          localId: localId,
          collection: SembleSyncCollection.collection.value,
          rkey: rkeyFromUri(remote.uri),
          uri: remote.uri,
          cid: remote.cid,
          lastSyncedRecordJson: json,
          lastSyncedHash: stableJenkinsOneAtATimeHash(json),
          lastSyncedAt: _now(),
        );
        if (!importAsLocalOnly) {
          await _syncRepository.selectForSync(
            accountDid: accountDid,
            localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
            localId: localId,
            collection: SembleSyncCollection.collection.value,
            enqueueCurrent: false,
          );
        }
      }
      return SembleBookmarkPullResult(collectionsImported: duplicates == 0 ? 1 : 0, duplicates: duplicates);
    } on Object catch (error, stackTrace) {
      return _malformed(remote, 'Ignoring malformed Semble collection record.', error: error, stackTrace: stackTrace);
    }
  }

  Future<SembleBookmarkPullResult> _importCollectionLink(
    String accountDid,
    AtprotoRepoRecord remote, {
    required bool importAsLocalOnly,
  }) async {
    try {
      final record = const cosmik_link.CollectionLinkRecordConverter().fromJson(remote.value);
      final collectionMirror = await _syncRepository.mirrorForUri(
        accountDid: accountDid,
        uri: record.collection.uri.toString(),
      );
      final cardMirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: record.card.uri.toString());
      if (collectionMirror == null || cardMirror == null) {
        return _malformed(remote, 'Semble collection link references records that are not mirrored locally.');
      }
      if (collectionMirror.localTable != AtprotoSyncLocalTable.bookmarkFolders.value ||
          cardMirror.localTable != AtprotoSyncLocalTable.bookmarks.value) {
        return _malformed(remote, 'Semble collection link references incompatible mirrored record types.');
      }

      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) {
        return const SembleBookmarkPullResult(conflicts: 1);
      }

      final existing = await _linkByBookmarkAndFolder(
        bookmarkId: cardMirror.localId,
        folderId: collectionMirror.localId,
      );
      late final String localId;
      var duplicates = 0;
      if (existing == null) {
        localId = _uuid.v4();
        await _database
            .into(_database.bookmarkCollectionLinks)
            .insert(
              BookmarkCollectionLinksCompanion.insert(
                id: localId,
                bookmarkId: cardMirror.localId,
                folderId: collectionMirror.localId,
                sortOrder: Value(await _nextLinkSortOrder(collectionMirror.localId)),
                createdAt: record.addedAt,
                updatedAt: record.createdAt ?? record.addedAt,
              ),
            );
      } else {
        localId = existing.id;
        duplicates = mirror == null || mirror.localId != existing.id ? 1 : 0;
        await (_database.update(_database.bookmarkCollectionLinks)..where((link) => link.id.equals(existing.id))).write(
          BookmarkCollectionLinksCompanion(
            updatedAt: Value(_newer(existing.updatedAt, record.createdAt ?? existing.updatedAt)),
            deletedAt: const Value(null),
          ),
        );
      }

      final json = canonicalJson(remote.value);
      if (duplicates == 0 || mirror?.localId == localId) {
        await _syncRepository.upsertMirror(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
          localId: localId,
          collection: SembleSyncCollection.collectionLink.value,
          rkey: rkeyFromUri(remote.uri),
          uri: remote.uri,
          cid: remote.cid,
          lastSyncedRecordJson: json,
          lastSyncedHash: stableJenkinsOneAtATimeHash(json),
          lastSyncedAt: _now(),
        );
        if (!importAsLocalOnly) {
          await _syncRepository.selectForSync(
            accountDid: accountDid,
            localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
            localId: localId,
            collection: SembleSyncCollection.collectionLink.value,
            enqueueCurrent: false,
          );
        }
      }
      return SembleBookmarkPullResult(linksImported: duplicates == 0 ? 1 : 0, duplicates: duplicates);
    } on Object catch (error, stackTrace) {
      return _malformed(
        remote,
        'Ignoring malformed Semble collection link record.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<SembleBookmarkPullResult> _importCollectionLinkRemoval(
    String accountDid,
    AtprotoRepoRecord remote, {
    required bool importAsLocalOnly,
  }) async {
    try {
      final record = const cosmik_removal.CollectionLinkRemovalRecordConverter().fromJson(remote.value);
      final removedLinkMirror = await _syncRepository.mirrorForUri(
        accountDid: accountDid,
        uri: record.removedLink.uri.toString(),
      );
      if (removedLinkMirror == null ||
          removedLinkMirror.localTable != AtprotoSyncLocalTable.bookmarkCollectionLinks.value) {
        return _malformed(remote, 'Semble collection link removal references a link that is not mirrored locally.');
      }
      if (removedLinkMirror.dirtyAt != null) {
        return const SembleBookmarkPullResult(conflicts: 1);
      }

      final deletionSync = AtprotoDeletionSyncService(
        database: _database,
        syncRepository: _syncRepository,
        repoClient: _repoClient,
        now: _now,
      );
      await deletionSync.markLocalRowDeleted(
        localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
        localId: removedLinkMirror.localId,
        deletedAt: record.removedAt,
      );
      await _syncRepository.markMirrorDeleted(id: removedLinkMirror.id, deletedAt: record.removedAt);
      await _syncRepository.upsertMirror(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
        localId: removedLinkMirror.localId,
        collection: SembleSyncCollection.collectionLinkRemoval.value,
        rkey: rkeyFromUri(remote.uri),
        uri: remote.uri,
        cid: remote.cid,
        lastSyncedRecordJson: canonicalJson(remote.value),
        lastSyncedHash: stableJenkinsOneAtATimeHash(canonicalJson(remote.value)),
        lastSyncedAt: _now(),
      );
      return const SembleBookmarkPullResult(deleted: 1);
    } on Object catch (error, stackTrace) {
      return _malformed(
        remote,
        'Ignoring malformed Semble collection link removal record.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  SembleBookmarkPullResult _malformed(
    AtprotoRepoRecord remote,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger?.error('$message uri=${remote.uri} cid=${remote.cid ?? 'unknown'}', error: error, stackTrace: stackTrace);
    return const SembleBookmarkPullResult(malformed: 1);
  }

  Future<SembleBookmarkPullResult> _verifyMissingMirrors(
    String accountDid,
    String collection,
    Set<String> seenUris,
  ) async {
    var deleted = 0;
    final deletionSync = AtprotoDeletionSyncService(
      database: _database,
      syncRepository: _syncRepository,
      repoClient: _repoClient,
      now: _now,
    );
    final mirrors = await _syncRepository.activeMirrors(accountDid: accountDid, collection: collection);
    for (final mirror in mirrors) {
      if (mirror.dirtyAt != null || seenUris.contains(mirror.uri)) {
        continue;
      }
      final remote = await _repoClient.getRecord(did: accountDid, collection: mirror.collection, rkey: mirror.rkey);
      if (remote != null) {
        continue;
      }
      await deletionSync.markLocalRowDeleted(localTable: mirror.localTable, localId: mirror.localId, deletedAt: _now());
      await _syncRepository.markMirrorDeleted(id: mirror.id, deletedAt: _now());
      deleted += 1;
    }
    return SembleBookmarkPullResult(deleted: deleted);
  }

  Future<Bookmark?> _bookmarkById(String id) {
    return (_database.select(_database.bookmarks)..where((bookmark) => bookmark.id.equals(id))).getSingleOrNull();
  }

  Future<Bookmark?> _bookmarkByNormalizedUrl(String url) async {
    final normalized = _normalizeUrl(url);
    final rows = await (_database.select(_database.bookmarks)..where((bookmark) => bookmark.deletedAt.isNull())).get();
    for (final row in rows) {
      if (_normalizeUrl(row.url) == normalized) return row;
    }
    return null;
  }

  Future<BookmarkFolder?> _folderById(String id) {
    return (_database.select(_database.bookmarkFolders)..where((folder) => folder.id.equals(id))).getSingleOrNull();
  }

  Future<BookmarkFolder?> _folderByNormalizedTitle(String title) async {
    final normalized = title.trim().toLowerCase();
    final rows = await (_database.select(
      _database.bookmarkFolders,
    )..where((folder) => folder.deletedAt.isNull())).get();
    for (final row in rows) {
      if (row.title.trim().toLowerCase() == normalized) return row;
    }
    return null;
  }

  Future<BookmarkCollectionLink?> _linkByBookmarkAndFolder({required String bookmarkId, required String folderId}) {
    return (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((link) => link.bookmarkId.equals(bookmarkId) & link.folderId.equals(folderId))).getSingleOrNull();
  }

  Future<int> _nextRootFolderSortOrder() async {
    final folders = await (_database.select(
      _database.bookmarkFolders,
    )..where((folder) => folder.parentId.isNull() & folder.deletedAt.isNull())).get();
    return folders.fold<int>(-1, (max, folder) => folder.sortOrder > max ? folder.sortOrder : max) + 1;
  }

  Future<int> _nextLinkSortOrder(String folderId) async {
    final links = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((link) => link.folderId.equals(folderId) & link.deletedAt.isNull())).get();
    return links.fold<int>(-1, (max, link) => link.sortOrder > max ? link.sortOrder : max) + 1;
  }

  String _normalizeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url.trim();
    final normalized = uri.replace(scheme: uri.scheme.toLowerCase(), host: uri.host.toLowerCase(), fragment: '');
    var value = normalized.toString();
    if (value.endsWith('/') && normalized.path == '/') {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  String? _preferNonEmpty(String? current, String? remote) => emptyToNull(current) ?? emptyToNull(remote);

  DateTime _newer(DateTime current, DateTime remote) => remote.isAfter(current) ? remote : current;
}
