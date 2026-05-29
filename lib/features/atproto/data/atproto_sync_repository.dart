import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:uuid/uuid.dart';

final atprotoSyncRepositoryProvider = Provider<AtprotoSyncRepository>((ref) {
  return AtprotoSyncRepository(ref.watch(databaseProvider));
});

const String atprotoAutoSelectPageAnnotationsSettingPrefix = 'atproto.auto_select_page_annotations.';

enum AtprotoLocalSyncStatus { localOnly, syncPending, synced, needsAttention }

class AtprotoSyncRepository {
  AtprotoSyncRepository(this._database, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<T> transaction<T>(Future<T> Function(AtprotoSyncRepository repository) action) {
    return _database.transaction(() => action(this));
  }

  Future<List<AtprotoAccount>> accounts() =>
      (_database.select(_database.atprotoAccounts)..orderBy([(account) => OrderingTerm.desc(account.updatedAt)])).get();

  Future<AtprotoAccount?> accountByDid(String did) {
    return (_database.select(_database.atprotoAccounts)..where((account) => account.did.equals(did))).getSingleOrNull();
  }

  Future<void> deleteAccount(String did) async {
    await (_database.delete(_database.atprotoAccounts)..where((account) => account.did.equals(did))).go();
  }

  Future<AtprotoAccount> upsertAccount({
    required String did,
    required String authMethod,
    String? handle,
    String? pdsEndpoint,
  }) async {
    final existing = await (_database.select(
      _database.atprotoAccounts,
    )..where((account) => account.did.equals(did))).getSingleOrNull();
    final now = _now();
    if (existing == null) {
      await _database
          .into(_database.atprotoAccounts)
          .insert(
            AtprotoAccountsCompanion.insert(
              did: did,
              authMethod: authMethod,
              handle: Value(handle),
              pdsEndpoint: Value(pdsEndpoint),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(_database.atprotoAccounts)..where((account) => account.did.equals(did))).write(
        AtprotoAccountsCompanion(
          authMethod: Value(authMethod),
          handle: Value(handle),
          pdsEndpoint: Value(pdsEndpoint),
          updatedAt: Value(now),
        ),
      );
    }
    return (_database.select(_database.atprotoAccounts)..where((account) => account.did.equals(did))).getSingle();
  }

  Future<AtprotoRecordMirror> upsertMirror({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
    required String rkey,
    required String uri,
    String? cid,
    String? lastSyncedRecordJson,
    String? lastSyncedHash,
    DateTime? lastSyncedAt,
    DateTime? dirtyAt,
    DateTime? deletedAt,
  }) async {
    final byUri = await mirrorForUri(accountDid: accountDid, uri: uri);
    final existing =
        byUri ??
        await mirrorForLocal(accountDid: accountDid, localTable: localTable, localId: localId, collection: collection);
    if (existing == null) {
      return createMirror(
        accountDid: accountDid,
        localTable: localTable,
        localId: localId,
        collection: collection,
        rkey: rkey,
        uri: uri,
        cid: cid,
        lastSyncedRecordJson: lastSyncedRecordJson,
        lastSyncedHash: lastSyncedHash,
        lastSyncedAt: lastSyncedAt,
        dirtyAt: dirtyAt,
        deletedAt: deletedAt,
      );
    }

    await (_database.update(_database.atprotoRecordMirrors)..where((mirror) => mirror.id.equals(existing.id))).write(
      AtprotoRecordMirrorsCompanion(
        localTable: Value(localTable),
        localId: Value(localId),
        collection: Value(collection),
        rkey: Value(rkey),
        uri: Value(uri),
        cid: Value(cid),
        lastSyncedRecordJson: Value(lastSyncedRecordJson),
        lastSyncedHash: Value(lastSyncedHash),
        lastSyncedAt: Value(lastSyncedAt),
        dirtyAt: Value(dirtyAt),
        deletedAt: Value(deletedAt),
      ),
    );
    return (_database.select(
      _database.atprotoRecordMirrors,
    )..where((mirror) => mirror.id.equals(existing.id))).getSingle();
  }

  Future<AtprotoRecordMirror> createMirror({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
    required String rkey,
    required String uri,
    String? cid,
    String? lastSyncedRecordJson,
    String? lastSyncedHash,
    DateTime? lastSyncedAt,
    DateTime? dirtyAt,
    DateTime? deletedAt,
  }) async {
    final id = _uuid.v4();
    await _database
        .into(_database.atprotoRecordMirrors)
        .insert(
          AtprotoRecordMirrorsCompanion.insert(
            id: id,
            accountDid: accountDid,
            localTable: localTable,
            localId: localId,
            collection: collection,
            rkey: rkey,
            uri: uri,
            cid: Value(cid),
            lastSyncedRecordJson: Value(lastSyncedRecordJson),
            lastSyncedHash: Value(lastSyncedHash),
            lastSyncedAt: Value(lastSyncedAt),
            dirtyAt: Value(dirtyAt),
            deletedAt: Value(deletedAt),
          ),
        );
    return (_database.select(_database.atprotoRecordMirrors)..where((mirror) => mirror.id.equals(id))).getSingle();
  }

  Future<AtprotoRecordMirror?> mirrorForLocal({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
  }) async {
    final rows =
        await (_database.select(_database.atprotoRecordMirrors)
              ..where(
                (mirror) =>
                    mirror.accountDid.equals(accountDid) &
                    mirror.localTable.equals(localTable) &
                    mirror.localId.equals(localId) &
                    mirror.collection.equals(collection),
              )
              ..orderBy([(mirror) => OrderingTerm.desc(mirror.lastSyncedAt), (mirror) => OrderingTerm.desc(mirror.id)]))
            .get();
    return rows.firstOrNull;
  }

  Future<AtprotoRecordMirror?> mirrorForUri({required String accountDid, required String uri}) async {
    final rows =
        await (_database.select(_database.atprotoRecordMirrors)
              ..where((mirror) => mirror.accountDid.equals(accountDid) & mirror.uri.equals(uri))
              ..orderBy([(mirror) => OrderingTerm.desc(mirror.lastSyncedAt), (mirror) => OrderingTerm.desc(mirror.id)]))
            .get();
    return rows.firstOrNull;
  }

  Future<List<AtprotoRecordMirror>> activeMirrors({required String accountDid, required String collection}) {
    return (_database.select(_database.atprotoRecordMirrors)..where(
          (mirror) =>
              mirror.accountDid.equals(accountDid) & mirror.collection.equals(collection) & mirror.deletedAt.isNull(),
        ))
        .get();
  }

  Future<void> markMirrorDirty({required String id, DateTime? dirtyAt}) async {
    await (_database.update(
      _database.atprotoRecordMirrors,
    )..where((mirror) => mirror.id.equals(id))).write(AtprotoRecordMirrorsCompanion(dirtyAt: Value(dirtyAt ?? _now())));
  }

  Future<void> markMirrorDeleted({required String id, DateTime? deletedAt}) async {
    await (_database.update(_database.atprotoRecordMirrors)..where((mirror) => mirror.id.equals(id))).write(
      AtprotoRecordMirrorsCompanion(deletedAt: Value(deletedAt ?? _now()), dirtyAt: const Value(null)),
    );
  }

  Future<void> markMirrorSynced({
    required String id,
    required String cid,
    required String lastSyncedRecordJson,
    required String lastSyncedHash,
    DateTime? lastSyncedAt,
  }) async {
    await (_database.update(_database.atprotoRecordMirrors)..where((mirror) => mirror.id.equals(id))).write(
      AtprotoRecordMirrorsCompanion(
        cid: Value(cid),
        lastSyncedRecordJson: Value(lastSyncedRecordJson),
        lastSyncedHash: Value(lastSyncedHash),
        lastSyncedAt: Value(lastSyncedAt ?? _now()),
        dirtyAt: const Value(null),
        deletedAt: const Value(null),
      ),
    );
  }

  Future<AtprotoSyncStateData?> syncState({required String accountDid, required String collection}) async {
    final rows =
        await (_database.select(_database.atprotoSyncState)
              ..where((state) => state.accountDid.equals(accountDid) & state.collection.equals(collection))
              ..orderBy([
                (state) => OrderingTerm.desc(state.lastSuccessfulSyncAt),
                (state) => OrderingTerm.desc(state.id),
              ]))
            .get();
    return rows.firstOrNull;
  }

  Future<int> syncedRecordCount({required String accountDid, required String collection}) async {
    final count = _database.atprotoRecordMirrors.id.count();
    final query = _database.selectOnly(_database.atprotoRecordMirrors)
      ..addColumns([count])
      ..where(
        _database.atprotoRecordMirrors.accountDid.equals(accountDid) &
            _database.atprotoRecordMirrors.collection.equals(collection) &
            _database.atprotoRecordMirrors.lastSyncedAt.isNotNull() &
            _database.atprotoRecordMirrors.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<Map<String, int>> syncedRecordCountsForAccount(String accountDid) async {
    final rows =
        await (_database.select(_database.atprotoRecordMirrors)..where(
              (mirror) =>
                  mirror.accountDid.equals(accountDid) & mirror.lastSyncedAt.isNotNull() & mirror.deletedAt.isNull(),
            ))
            .get();
    return _countsByCollection(rows);
  }

  Future<Map<String, int>> deletedRecordCountsForAccount(String accountDid) async {
    final rows = await (_database.select(
      _database.atprotoRecordMirrors,
    )..where((mirror) => mirror.accountDid.equals(accountDid) & mirror.deletedAt.isNotNull())).get();
    return _countsByCollection(rows);
  }

  Future<DateTime?> latestMirrorSyncAtForAccount(String accountDid) async {
    final rows =
        await (_database.select(_database.atprotoRecordMirrors)
              ..where((mirror) => mirror.accountDid.equals(accountDid) & mirror.lastSyncedAt.isNotNull())
              ..orderBy([(mirror) => OrderingTerm.desc(mirror.lastSyncedAt)])
              ..limit(1))
            .get();
    return rows.firstOrNull?.lastSyncedAt;
  }

  Map<String, int> _countsByCollection(List<AtprotoRecordMirror> rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      counts[row.collection] = (counts[row.collection] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<AtprotoSyncStateData>> syncStatesForAccount(String accountDid) {
    return (_database.select(_database.atprotoSyncState)
          ..where((state) => state.accountDid.equals(accountDid))
          ..orderBy([(state) => OrderingTerm.asc(state.collection)]))
        .get();
  }

  Future<AtprotoSyncStateData> saveCursor({
    required String accountDid,
    required String collection,
    String? cursor,
    DateTime? lastSuccessfulSyncAt,
    String? lastError,
  }) async {
    final existing = await syncState(accountDid: accountDid, collection: collection);
    if (existing == null) {
      final id = _uuid.v4();
      await _database
          .into(_database.atprotoSyncState)
          .insert(
            AtprotoSyncStateCompanion.insert(
              id: id,
              accountDid: accountDid,
              collection: collection,
              cursor: Value(cursor),
              lastSuccessfulSyncAt: Value(lastSuccessfulSyncAt),
              lastError: Value(lastError),
            ),
          );
      return (_database.select(_database.atprotoSyncState)..where((state) => state.id.equals(id))).getSingle();
    }

    await (_database.update(_database.atprotoSyncState)..where((state) => state.id.equals(existing.id))).write(
      AtprotoSyncStateCompanion(
        cursor: Value(cursor),
        lastSuccessfulSyncAt: Value(lastSuccessfulSyncAt),
        lastError: Value(lastError),
      ),
    );
    return (_database.select(_database.atprotoSyncState)..where((state) => state.id.equals(existing.id))).getSingle();
  }

  Future<AtprotoSyncSelection?> selectionForLocal({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
  }) {
    return (_database.select(_database.atprotoSyncSelections)..where(
          (selection) =>
              selection.accountDid.equals(accountDid) &
              selection.localTable.equals(localTable) &
              selection.localId.equals(localId) &
              selection.collection.equals(collection),
        ))
        .getSingleOrNull();
  }

  Future<Map<String, AtprotoLocalSyncStatus>> localSyncStatuses({
    required String accountDid,
    required String localTable,
    required String collection,
    required Iterable<String> localIds,
  }) async {
    final ids = localIds.toSet();
    if (ids.isEmpty) return const <String, AtprotoLocalSyncStatus>{};

    final selections = await activeSelections(accountDid: accountDid, localTable: localTable, collection: collection);
    final selectedIds = selections.map((selection) => selection.localId).where(ids.contains).toSet();
    final mirrors =
        await (_database.select(_database.atprotoRecordMirrors)..where(
              (mirror) =>
                  mirror.accountDid.equals(accountDid) &
                  mirror.localTable.equals(localTable) &
                  mirror.collection.equals(collection) &
                  mirror.localId.isIn(ids),
            ))
            .get();
    final pending = await pendingOutbox(accountDid: accountDid, limit: 1000);
    final pendingById = <String, AtprotoSyncOutboxData>{};
    for (final item in pending.where(
      (item) => item.localTable == localTable && item.collection == collection && ids.contains(item.localId),
    )) {
      pendingById[item.localId] = item;
    }
    final syncedIds = mirrors
        .where((mirror) => mirror.lastSyncedAt != null && mirror.deletedAt == null)
        .map((mirror) => mirror.localId)
        .toSet();

    return {
      for (final id in ids)
        id: (() {
          final pendingItem = pendingById[id];
          if (pendingItem?.lastError?.trim().isNotEmpty == true) return AtprotoLocalSyncStatus.needsAttention;
          if (syncedIds.contains(id)) return AtprotoLocalSyncStatus.synced;
          if (!selectedIds.contains(id)) return AtprotoLocalSyncStatus.localOnly;
          if (pendingItem != null) return AtprotoLocalSyncStatus.syncPending;
          return AtprotoLocalSyncStatus.syncPending;
        })(),
    };
  }

  Future<List<AtprotoSyncSelection>> activeSelections({String? accountDid, String? localTable, String? collection}) {
    final query = _database.select(_database.atprotoSyncSelections)
      ..where((selection) => selection.deselectedAt.isNull())
      ..orderBy([(selection) => OrderingTerm.asc(selection.selectedAt)]);
    if (accountDid != null) {
      query.where((selection) => selection.accountDid.equals(accountDid));
    }
    if (localTable != null) {
      query.where((selection) => selection.localTable.equals(localTable));
    }
    if (collection != null) {
      query.where((selection) => selection.collection.equals(collection));
    }
    return query.get();
  }

  Stream<List<AtprotoSyncSelection>> watchActiveSelections({
    required String accountDid,
    String? localTable,
    String? collection,
  }) {
    final query = _database.select(_database.atprotoSyncSelections)
      ..where((selection) => selection.accountDid.equals(accountDid) & selection.deselectedAt.isNull())
      ..orderBy([(selection) => OrderingTerm.asc(selection.selectedAt)]);
    if (localTable != null) {
      query.where((selection) => selection.localTable.equals(localTable));
    }
    if (collection != null) {
      query.where((selection) => selection.collection.equals(collection));
    }
    return query.watch();
  }

  Future<AtprotoSyncSelection> selectForSync({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
    bool deleteRemoteOnLocalDelete = true,
    bool enqueueCurrent = true,
  }) async {
    final now = _now();
    final existing = await selectionForLocal(
      accountDid: accountDid,
      localTable: localTable,
      localId: localId,
      collection: collection,
    );
    if (existing == null) {
      final id = _uuid.v4();
      await _database
          .into(_database.atprotoSyncSelections)
          .insert(
            AtprotoSyncSelectionsCompanion.insert(
              id: id,
              accountDid: accountDid,
              localTable: localTable,
              localId: localId,
              collection: collection,
              selectedAt: now,
              deleteRemoteOnLocalDelete: Value(deleteRemoteOnLocalDelete),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(
        _database.atprotoSyncSelections,
      )..where((selection) => selection.id.equals(existing.id))).write(
        AtprotoSyncSelectionsCompanion(
          selectedAt: Value(existing.deselectedAt == null ? existing.selectedAt : now),
          deselectedAt: const Value(null),
          deleteRemoteOnLocalDelete: Value(deleteRemoteOnLocalDelete),
          updatedAt: Value(now),
        ),
      );
    }
    final selection = await selectionForLocal(
      accountDid: accountDid,
      localTable: localTable,
      localId: localId,
      collection: collection,
    );
    if (selection == null) {
      throw StateError('Failed to select $localTable/$localId for ATProto sync.');
    }
    if (enqueueCurrent) {
      final mirror = await mirrorForLocal(
        accountDid: accountDid,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
      if (mirror != null) {
        await markMirrorDirty(id: mirror.id, dirtyAt: now);
      }
      await enqueueOutbox(
        accountDid: accountDid,
        operation: mirror == null ? AtprotoSyncOperation.create.value : AtprotoSyncOperation.update.value,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
    }
    return selection;
  }

  Future<void> deselectForSync({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
    bool deleteRemote = false,
  }) async {
    final selection = await selectionForLocal(
      accountDid: accountDid,
      localTable: localTable,
      localId: localId,
      collection: collection,
    );
    if (selection == null) return;
    final now = _now();
    await (_database.update(_database.atprotoSyncSelections)..where((row) => row.id.equals(selection.id))).write(
      AtprotoSyncSelectionsCompanion(deselectedAt: Value(now), updatedAt: Value(now)),
    );
    if (deleteRemote) {
      final mirror = await mirrorForLocal(
        accountDid: accountDid,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
      if (mirror != null && mirror.deletedAt == null) {
        await enqueueOutbox(
          accountDid: accountDid,
          operation: AtprotoSyncOperation.delete.value,
          localTable: localTable,
          localId: localId,
          collection: collection,
        );
      }
    }
  }

  Future<void> selectAllForSync({
    required String accountDid,
    required String localTable,
    required String collection,
    required Iterable<String> localIds,
    bool deleteRemoteOnLocalDelete = true,
  }) async {
    for (final localId in localIds) {
      await selectForSync(
        accountDid: accountDid,
        localTable: localTable,
        localId: localId,
        collection: collection,
        deleteRemoteOnLocalDelete: deleteRemoteOnLocalDelete,
      );
    }
  }

  Future<void> selectBookmarkForSync(String accountDid, String bookmarkId) async {
    final links = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((row) => row.bookmarkId.equals(bookmarkId) & row.deletedAt.isNull())).get();
    await transaction((sync) async {
      await sync.selectForSync(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.bookmarks.value,
        localId: bookmarkId,
        collection: SembleSyncCollection.card.value,
      );
      for (final link in links) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
          localId: link.folderId,
          collection: SembleSyncCollection.collection.value,
        );
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
          localId: link.id,
          collection: SembleSyncCollection.collectionLink.value,
        );
      }
    });
  }

  Future<void> selectBookmarkFolderForSync(String accountDid, String folderId) async {
    final folders = await (_database.select(_database.bookmarkFolders)..where((row) => row.deletedAt.isNull())).get();
    final links = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((row) => row.deletedAt.isNull())).get();
    final folderIds = <String>{folderId};
    var foundChild = true;
    while (foundChild) {
      foundChild = false;
      for (final folder in folders) {
        if (folder.parentId != null && folderIds.contains(folder.parentId) && folderIds.add(folder.id)) {
          foundChild = true;
        }
      }
    }
    final bookmarkIds = links.where((link) => folderIds.contains(link.folderId)).map((link) => link.bookmarkId).toSet();
    await transaction((sync) async {
      for (final id in folderIds) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
          localId: id,
          collection: SembleSyncCollection.collection.value,
        );
      }
      for (final bookmarkId in bookmarkIds) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarks.value,
          localId: bookmarkId,
          collection: SembleSyncCollection.card.value,
        );
      }
      for (final link in links.where((link) => folderIds.contains(link.folderId))) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
          localId: link.id,
          collection: SembleSyncCollection.collectionLink.value,
        );
      }
    });
  }

  Future<void> deselectBookmarkForSync(String accountDid, String bookmarkId, {bool deleteRemote = false}) async {
    final links = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((row) => row.bookmarkId.equals(bookmarkId) & row.deletedAt.isNull())).get();
    await transaction((sync) async {
      await sync.deselectForSync(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.bookmarks.value,
        localId: bookmarkId,
        collection: SembleSyncCollection.card.value,
        deleteRemote: deleteRemote,
      );
      for (final link in links) {
        await sync.deselectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
          localId: link.id,
          collection: SembleSyncCollection.collectionLink.value,
          deleteRemote: deleteRemote,
        );
      }
    });
  }

  Future<void> deselectBookmarkFolderForSync(String accountDid, String folderId, {bool deleteRemote = false}) {
    return deselectForSync(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
      localId: folderId,
      collection: SembleSyncCollection.collection.value,
      deleteRemote: deleteRemote,
    );
  }

  Future<void> selectAllBookmarksForSync(String accountDid) async {
    final folders = await (_database.select(_database.bookmarkFolders)..where((row) => row.deletedAt.isNull())).get();
    final bookmarks = await (_database.select(_database.bookmarks)..where((row) => row.deletedAt.isNull())).get();
    final links = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((row) => row.deletedAt.isNull())).get();
    await transaction((sync) async {
      for (final folder in folders) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
          localId: folder.id,
          collection: SembleSyncCollection.collection.value,
        );
      }
      for (final bookmark in bookmarks) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarks.value,
          localId: bookmark.id,
          collection: SembleSyncCollection.card.value,
        );
      }
      for (final link in links) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
          localId: link.id,
          collection: SembleSyncCollection.collectionLink.value,
        );
      }
    });
  }

  Future<void> selectAnnotationsForPageForSync(String accountDid, String pageId) async {
    final annotations = await (_database.select(
      _database.annotations,
    )..where((row) => row.pageId.equals(pageId) & row.deletedAt.isNull())).get();
    await transaction((sync) async {
      for (final annotation in annotations) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.annotations.value,
          localId: annotation.id,
          collection: MarginSyncCollection.note.value,
        );
      }
      await sync._setAutoSelectEnabled('$atprotoAutoSelectPageAnnotationsSettingPrefix$accountDid.$pageId', true);
    });
  }

  Future<void> deselectAnnotationsForPageForSync(String accountDid, String pageId, {bool deleteRemote = false}) async {
    final annotations = await (_database.select(
      _database.annotations,
    )..where((row) => row.pageId.equals(pageId) & row.deletedAt.isNull())).get();
    await transaction((sync) async {
      for (final annotation in annotations) {
        await sync.deselectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.annotations.value,
          localId: annotation.id,
          collection: MarginSyncCollection.note.value,
          deleteRemote: deleteRemote,
        );
      }
      await sync._setAutoSelectEnabled('$atprotoAutoSelectPageAnnotationsSettingPrefix$accountDid.$pageId', false);
    });
  }

  Future<List<String>> accountsWithAutoSelectForAnnotationPage(String pageId) async {
    const prefix = atprotoAutoSelectPageAnnotationsSettingPrefix;
    final rows = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.like('$prefix%.$pageId') & setting.value.equals('true'))).get();
    return rows
        .map((row) => row.key.substring(prefix.length, row.key.length - '.$pageId'.length))
        .where((accountDid) => accountDid.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> selectAnnotationForPageAutoSyncAccounts({required String pageId, required String annotationId}) async {
    final accountDids = await accountsWithAutoSelectForAnnotationPage(pageId);
    for (final accountDid in accountDids) {
      await selectForSync(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.annotations.value,
        localId: annotationId,
        collection: MarginSyncCollection.note.value,
      );
    }
  }

  Future<void> selectAllAnnotationsForSync(String accountDid) async {
    final annotations = await (_database.select(_database.annotations)..where((row) => row.deletedAt.isNull())).get();
    final collections = await (_database.select(
      _database.annotationCollections,
    )..where((row) => row.deletedAt.isNull())).get();
    final items = await (_database.select(
      _database.annotationCollectionItems,
    )..where((row) => row.deletedAt.isNull())).get();
    await transaction((sync) async {
      for (final annotation in annotations) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.annotations.value,
          localId: annotation.id,
          collection: MarginSyncCollection.note.value,
        );
      }
      for (final collection in collections) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.annotationCollections.value,
          localId: collection.id,
          collection: MarginSyncCollection.collection.value,
        );
      }
      for (final item in items) {
        await sync.selectForSync(
          accountDid: accountDid,
          localTable: AtprotoSyncLocalTable.annotationCollectionItems.value,
          localId: item.id,
          collection: MarginSyncCollection.collectionItem.value,
        );
      }
    });
  }

  Future<bool> autoSelectBookmarksEnabled(String accountDid) =>
      _autoSelectEnabled('$atprotoAutoSelectBookmarksSettingPrefix$accountDid');

  Future<bool> autoSelectAnnotationsEnabled(String accountDid) =>
      _autoSelectEnabled('$atprotoAutoSelectAnnotationsSettingPrefix$accountDid');

  Future<void> setAutoSelectBookmarksEnabled(String accountDid, bool enabled) =>
      _setAutoSelectEnabled('$atprotoAutoSelectBookmarksSettingPrefix$accountDid', enabled);

  Future<void> setAutoSelectAnnotationsEnabled(String accountDid, bool enabled) =>
      _setAutoSelectEnabled('$atprotoAutoSelectAnnotationsSettingPrefix$accountDid', enabled);

  Future<bool> _autoSelectEnabled(String key) async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.equals(key))).getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> _setAutoSelectEnabled(String key, bool enabled) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: enabled ? 'true' : 'false', updatedAt: _now()),
        );
  }

  Future<Map<String, int>> selectionDiagnosticsForAccount(String accountDid) async {
    final selected = await activeSelections(accountDid: accountDid);
    final counts = <String, int>{};
    for (final row in selected) {
      counts['selected:${row.collection}'] = (counts['selected:${row.collection}'] ?? 0) + 1;
    }
    counts['unselected:${SembleSyncCollection.card.value}'] = await _unselectedCount(
      accountDid: accountDid,
      tableName: AtprotoSyncLocalTable.bookmarks.value,
      collection: SembleSyncCollection.card.value,
      localIds: (await (_database.select(
        _database.bookmarks,
      )..where((row) => row.deletedAt.isNull())).get()).map((row) => row.id),
    );
    counts['unselected:${MarginSyncCollection.note.value}'] = await _unselectedCount(
      accountDid: accountDid,
      tableName: AtprotoSyncLocalTable.annotations.value,
      collection: MarginSyncCollection.note.value,
      localIds: (await (_database.select(
        _database.annotations,
      )..where((row) => row.deletedAt.isNull())).get()).map((row) => row.id),
    );
    counts['dependencyBlocked:${SembleSyncCollection.collectionLink.value}'] = await _dependencyBlockedBookmarkLinks(
      accountDid,
    );
    counts['dependencyBlocked:${MarginSyncCollection.collectionItem.value}'] = await _dependencyBlockedCollectionItems(
      accountDid,
    );
    return counts;
  }

  Future<int> _unselectedCount({
    required String accountDid,
    required String tableName,
    required String collection,
    required Iterable<String> localIds,
  }) async {
    var count = 0;
    for (final localId in localIds) {
      final selection = await selectionForLocal(
        accountDid: accountDid,
        localTable: tableName,
        localId: localId,
        collection: collection,
      );
      if (selection?.deselectedAt == null) {
        if (selection == null) count += 1;
      }
    }
    return count;
  }

  Future<int> _dependencyBlockedBookmarkLinks(String accountDid) async {
    final links = await activeSelections(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      collection: SembleSyncCollection.collectionLink.value,
    );
    var blocked = 0;
    for (final selection in links) {
      final link = await (_database.select(
        _database.bookmarkCollectionLinks,
      )..where((row) => row.id.equals(selection.localId))).getSingleOrNull();
      if (link == null) continue;
      final bookmarkMirror = await mirrorForLocal(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.bookmarks.value,
        localId: link.bookmarkId,
        collection: SembleSyncCollection.card.value,
      );
      final folderMirror = await mirrorForLocal(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
        localId: link.folderId,
        collection: SembleSyncCollection.collection.value,
      );
      if (bookmarkMirror?.deletedAt != null ||
          bookmarkMirror == null ||
          folderMirror?.deletedAt != null ||
          folderMirror == null) {
        blocked += 1;
      }
    }
    return blocked;
  }

  Future<int> _dependencyBlockedCollectionItems(String accountDid) async {
    final items = await activeSelections(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.annotationCollectionItems.value,
      collection: MarginSyncCollection.collectionItem.value,
    );
    var blocked = 0;
    for (final selection in items) {
      final item = await (_database.select(
        _database.annotationCollectionItems,
      )..where((row) => row.id.equals(selection.localId))).getSingleOrNull();
      if (item == null) continue;
      final annotationMirror = await mirrorForLocal(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.annotations.value,
        localId: item.annotationId,
        collection: MarginSyncCollection.note.value,
      );
      final collectionMirror = await mirrorForLocal(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.annotationCollections.value,
        localId: item.collectionId,
        collection: MarginSyncCollection.collection.value,
      );
      if (annotationMirror?.deletedAt != null ||
          annotationMirror == null ||
          collectionMirror?.deletedAt != null ||
          collectionMirror == null) {
        blocked += 1;
      }
    }
    return blocked;
  }

  Future<void> enqueueLocalChangeForAllAccounts({
    required String localTable,
    required String localId,
    required String collection,
    DateTime? dirtyAt,
  }) async {
    final connectedAccounts = await accounts();
    final now = dirtyAt ?? _now();
    for (final account in connectedAccounts) {
      var selection = await selectionForLocal(
        accountDid: account.did,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
      if (selection == null && await _shouldAutoSelect(account.did, localTable)) {
        selection = await selectForSync(
          accountDid: account.did,
          localTable: localTable,
          localId: localId,
          collection: collection,
          enqueueCurrent: false,
        );
      }
      if (selection?.deselectedAt != null || selection == null) {
        continue;
      }
      final mirror = await mirrorForLocal(
        accountDid: account.did,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
      if (mirror != null) {
        await markMirrorDirty(id: mirror.id, dirtyAt: now);
      }
      await enqueueOutbox(
        accountDid: account.did,
        operation: mirror == null ? AtprotoSyncOperation.create.value : AtprotoSyncOperation.update.value,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
    }
  }

  Future<bool> _shouldAutoSelect(String accountDid, String localTable) async {
    final table = AtprotoSyncLocalTable.fromValue(localTable);
    return switch (table) {
      AtprotoSyncLocalTable.bookmarks ||
      AtprotoSyncLocalTable.bookmarkFolders ||
      AtprotoSyncLocalTable.bookmarkCollectionLinks => autoSelectBookmarksEnabled(accountDid),
      AtprotoSyncLocalTable.annotations ||
      AtprotoSyncLocalTable.annotationCollections ||
      AtprotoSyncLocalTable.annotationCollectionItems => autoSelectAnnotationsEnabled(accountDid),
    };
  }

  Future<AtprotoSyncOutboxData> enqueueOutbox({
    required String accountDid,
    required String operation,
    required String localTable,
    required String localId,
    required String collection,
    String? payloadJson,
  }) async {
    final now = _now();
    final id = _uuid.v4();
    await _database
        .into(_database.atprotoSyncOutbox)
        .insert(
          AtprotoSyncOutboxCompanion.insert(
            id: id,
            accountDid: accountDid,
            operation: operation,
            localTable: localTable,
            localId: localId,
            collection: collection,
            payloadJson: Value(payloadJson),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_database.select(_database.atprotoSyncOutbox)..where((outbox) => outbox.id.equals(id))).getSingle();
  }

  Future<List<AtprotoSyncOutboxData>> pendingOutbox({String? accountDid, int limit = 100}) {
    final query = _database.select(_database.atprotoSyncOutbox)
      ..orderBy([(outbox) => OrderingTerm.asc(outbox.createdAt)])
      ..limit(limit);
    if (accountDid != null) {
      query.where((outbox) => outbox.accountDid.equals(accountDid));
    }
    return query.get();
  }

  Future<void> markOutboxAttempt({required String id, required int attemptCount, String? lastError}) async {
    await (_database.update(_database.atprotoSyncOutbox)..where((outbox) => outbox.id.equals(id))).write(
      AtprotoSyncOutboxCompanion(
        attemptCount: Value(attemptCount),
        lastError: Value(lastError),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<void> deleteOutbox(String id) async {
    await (_database.delete(_database.atprotoSyncOutbox)..where((outbox) => outbox.id.equals(id))).go();
  }
}
