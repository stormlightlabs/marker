import 'dart:convert';

import 'package:cosmik_poptart/network/cosmik/card.dart' as cosmik_card;
import 'package:cosmik_poptart/network/cosmik/collection/main.dart' as cosmik_collection;
import 'package:cosmik_poptart/network/cosmik/collection_link/main.dart' as cosmik_link;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/domain/atproto_repo_models.dart';
import 'package:uuid/uuid.dart';

const sembleCardCollection = 'network.cosmik.card';
const sembleCollectionCollection = 'network.cosmik.collection';
const sembleCollectionLinkCollection = 'network.cosmik.collectionLink';

const _bookmarksTable = 'bookmarks';
const _bookmarkFoldersTable = 'bookmark_folders';
const _bookmarkCollectionLinksTable = 'bookmark_collection_links';

final sembleBookmarkPullServiceProvider = Provider<SembleBookmarkPullService>((ref) {
  final database = ref.watch(databaseProvider);
  return SembleBookmarkPullService(
    database: database,
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    repoClient: ref.watch(atprotoRepoClientProvider),
  );
});

class SembleBookmarkPullResult {
  const SembleBookmarkPullResult({
    this.cardsImported = 0,
    this.collectionsImported = 0,
    this.linksImported = 0,
    this.duplicates = 0,
    this.conflicts = 0,
    this.malformed = 0,
  });

  final int cardsImported;
  final int collectionsImported;
  final int linksImported;
  final int duplicates;
  final int conflicts;
  final int malformed;

  SembleBookmarkPullResult operator +(SembleBookmarkPullResult other) => SembleBookmarkPullResult(
    cardsImported: cardsImported + other.cardsImported,
    collectionsImported: collectionsImported + other.collectionsImported,
    linksImported: linksImported + other.linksImported,
    duplicates: duplicates + other.duplicates,
    conflicts: conflicts + other.conflicts,
    malformed: malformed + other.malformed,
  );
}

class SembleBookmarkPullService {
  SembleBookmarkPullService({
    required AppDatabase database,
    required AtprotoSyncRepository syncRepository,
    required AtprotoRepoClient repoClient,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _database = database,
       _syncRepository = syncRepository,
       _repoClient = repoClient,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final AtprotoSyncRepository _syncRepository;
  final AtprotoRepoClient _repoClient;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<SembleBookmarkPullResult> pull(String accountDid) async {
    var result = const SembleBookmarkPullResult();
    result += await _pullCollection(accountDid, sembleCardCollection, _importCard);
    result += await _pullCollection(accountDid, sembleCollectionCollection, _importCollection);
    result += await _pullCollection(accountDid, sembleCollectionLinkCollection, _importCollectionLink);
    return result;
  }

  Future<SembleBookmarkPullResult> _pullCollection(
    String accountDid,
    String collection,
    Future<SembleBookmarkPullResult> Function(String accountDid, AtprotoRepoRecord record) importRecord,
  ) async {
    var result = const SembleBookmarkPullResult();
    String? cursor;
    do {
      final page = await _repoClient.listRecords(did: accountDid, collection: collection, cursor: cursor, limit: 100);
      for (final record in page.records) {
        result += await importRecord(accountDid, record);
      }
      cursor = page.cursor;
    } while (cursor != null);

    await _syncRepository.saveCursor(
      accountDid: accountDid,
      collection: collection,
      cursor: null,
      lastSuccessfulSyncAt: _now(),
    );
    return result;
  }

  Future<SembleBookmarkPullResult> _importCard(String accountDid, AtprotoRepoRecord remote) async {
    try {
      final record = const cosmik_card.CardRecordConverter().fromJson(remote.value);
      final content = record.content.urlContent;
      final url = content?.url ?? record.url;
      if (url == null || Uri.tryParse(url) == null) {
        return const SembleBookmarkPullResult(malformed: 1);
      }

      final json = _canonicalJson(remote.value);
      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) {
        return const SembleBookmarkPullResult(conflicts: 1);
      }

      final existing = mirror == null ? await _bookmarkByNormalizedUrl(url) : await _bookmarkById(mirror.localId);
      final createdAt = record.createdAt ?? _now();
      final title = _emptyToNull(content?.metadata?.title);
      final description = _emptyToNull(content?.metadata?.description);
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
          localTable: _bookmarksTable,
          localId: localId,
          collection: sembleCardCollection,
          rkey: _rkeyFromUri(remote.uri),
          uri: remote.uri,
          cid: remote.cid,
          lastSyncedRecordJson: json,
          lastSyncedHash: _stableHash(json),
          lastSyncedAt: _now(),
        );
      }
      return SembleBookmarkPullResult(cardsImported: duplicates == 0 ? 1 : 0, duplicates: duplicates);
    } catch (_) {
      return const SembleBookmarkPullResult(malformed: 1);
    }
  }

  Future<SembleBookmarkPullResult> _importCollection(String accountDid, AtprotoRepoRecord remote) async {
    try {
      final record = const cosmik_collection.CollectionRecordConverter().fromJson(remote.value);
      final title = _emptyToNull(record.name) ?? 'Untitled Collection';
      final json = _canonicalJson(remote.value);
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
                description: Value(_emptyToNull(record.description)),
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
          localTable: _bookmarkFoldersTable,
          localId: localId,
          collection: sembleCollectionCollection,
          rkey: _rkeyFromUri(remote.uri),
          uri: remote.uri,
          cid: remote.cid,
          lastSyncedRecordJson: json,
          lastSyncedHash: _stableHash(json),
          lastSyncedAt: _now(),
        );
      }
      return SembleBookmarkPullResult(collectionsImported: duplicates == 0 ? 1 : 0, duplicates: duplicates);
    } catch (_) {
      return const SembleBookmarkPullResult(malformed: 1);
    }
  }

  Future<SembleBookmarkPullResult> _importCollectionLink(String accountDid, AtprotoRepoRecord remote) async {
    try {
      final record = const cosmik_link.CollectionLinkRecordConverter().fromJson(remote.value);
      final collectionMirror = await _syncRepository.mirrorForUri(
        accountDid: accountDid,
        uri: record.collection.uri.toString(),
      );
      final cardMirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: record.card.uri.toString());
      if (collectionMirror == null || cardMirror == null) {
        return const SembleBookmarkPullResult(malformed: 1);
      }
      if (collectionMirror.localTable != _bookmarkFoldersTable || cardMirror.localTable != _bookmarksTable) {
        return const SembleBookmarkPullResult(malformed: 1);
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
        duplicates = mirror == null ? 1 : 0;
        await (_database.update(_database.bookmarkCollectionLinks)..where((link) => link.id.equals(existing.id))).write(
          BookmarkCollectionLinksCompanion(
            updatedAt: Value(_newer(existing.updatedAt, record.createdAt ?? existing.updatedAt)),
            deletedAt: const Value(null),
          ),
        );
      }

      final json = _canonicalJson(remote.value);
      if (duplicates == 0 || mirror != null) {
        await _syncRepository.upsertMirror(
          accountDid: accountDid,
          localTable: _bookmarkCollectionLinksTable,
          localId: localId,
          collection: sembleCollectionLinkCollection,
          rkey: _rkeyFromUri(remote.uri),
          uri: remote.uri,
          cid: remote.cid,
          lastSyncedRecordJson: json,
          lastSyncedHash: _stableHash(json),
          lastSyncedAt: _now(),
        );
      }
      return SembleBookmarkPullResult(linksImported: duplicates == 0 ? 1 : 0, duplicates: duplicates);
    } catch (_) {
      return const SembleBookmarkPullResult(malformed: 1);
    }
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

  String _rkeyFromUri(String uri) {
    final parsed = Uri.tryParse(uri);
    final segments = parsed?.pathSegments;
    if (segments != null && segments.isNotEmpty) return segments.last;
    final slash = uri.lastIndexOf('/');
    if (slash >= 0 && slash < uri.length - 1) return uri.substring(slash + 1);
    return uri;
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

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _preferNonEmpty(String? current, String? remote) => _emptyToNull(current) ?? _emptyToNull(remote);

  DateTime _newer(DateTime current, DateTime remote) => remote.isAfter(current) ? remote : current;

  String _canonicalJson(Object? value) => jsonEncode(_sortJson(value));

  Object? _sortJson(Object? value) {
    if (value is Map) {
      return {for (final key in value.keys.map((key) => key.toString()).toList()..sort()) key: _sortJson(value[key])};
    }
    if (value is Iterable) return value.map(_sortJson).toList(growable: false);
    return value;
  }

  String _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash.toRadixString(16);
  }
}
