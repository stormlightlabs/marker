import 'dart:convert';

import 'package:cosmik_poptart/network/cosmik/collection_link_removal.dart' as cosmik_removal;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/shared/utils/atproto_utils.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:poptart_core/poptart_core.dart';
import 'package:poptart_lex/com/atproto/repo/strong_ref.dart';
import 'package:uuid/uuid.dart';

final atprotoDeletionSyncServiceProvider = Provider<AtprotoDeletionSyncService>((ref) {
  return AtprotoDeletionSyncService(
    database: ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    repoClient: ref.watch(atprotoRepoClientProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

class AtprotoDeletionSyncService {
  AtprotoDeletionSyncService({
    required AppDatabase database,
    required AtprotoSyncRepository syncRepository,
    required AtprotoRepoClient repoClient,
    Uuid? uuid,
    DateTime Function()? now,
    AppLogger? logger,
  }) : _database = database,
       _syncRepository = syncRepository,
       _repoClient = repoClient,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? (() => DateTime.now().toUtc()),
       _logger = logger ?? AppLogger.console();

  final AppDatabase _database;
  final AtprotoSyncRepository _syncRepository;
  final AtprotoRepoClient _repoClient;
  final Uuid _uuid;
  final DateTime Function() _now;
  final AppLogger _logger;

  Future<void> softDeleteLocal({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
  }) async {
    final now = _now();
    await _database.transaction(() async {
      await markLocalRowDeleted(localTable: localTable, localId: localId, deletedAt: now);
      final selection = await _syncRepository.selectionForLocal(
        accountDid: accountDid,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
      if (selection?.deselectedAt != null || selection == null || !selection.deleteRemoteOnLocalDelete) {
        return;
      }
      final mirror = await _syncRepository.mirrorForLocal(
        accountDid: accountDid,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
      if (mirror == null) {
        return;
      }
      await _syncRepository.markMirrorDirty(id: mirror.id, dirtyAt: now);
      await _syncRepository.enqueueOutbox(
        accountDid: accountDid,
        operation: AtprotoSyncOperation.delete.value,
        localTable: localTable,
        localId: localId,
        collection: collection,
      );
    });
  }

  Future<void> pushLocalDeletes(String accountDid) async {
    final outbox = await _syncRepository.pendingOutbox(accountDid: accountDid);
    for (final item in outbox.where((item) => item.operation == AtprotoSyncOperation.delete.value)) {
      final mirror = await _syncRepository.mirrorForLocal(
        accountDid: accountDid,
        localTable: item.localTable,
        localId: item.localId,
        collection: item.collection,
      );
      if (mirror == null) {
        await _syncRepository.deleteOutbox(item.id);
        continue;
      }

      if (item.localTable == AtprotoSyncLocalTable.bookmarkCollectionLinks.value &&
          _repoDid(mirror.uri) != accountDid) {
        await _publishCollectionLinkRemoval(accountDid: accountDid, removedLink: mirror);
      } else {
        await _repoClient.deleteRecord(
          did: accountDid,
          collection: mirror.collection,
          rkey: mirror.rkey,
          swapRecord: mirror.cid,
        );
      }
      await _syncRepository.markMirrorDeleted(id: mirror.id, deletedAt: _now());
      await _syncRepository.deleteOutbox(item.id);
    }
  }

  Future<void> markLocalRowDeleted({required String localTable, required String localId, DateTime? deletedAt}) async {
    final timestamp = deletedAt ?? _now();
    switch (AtprotoSyncLocalTable.fromValue(localTable)) {
      case AtprotoSyncLocalTable.bookmarks:
        await (_database.update(_database.bookmarks)..where((row) => row.id.equals(localId))).write(
          BookmarksCompanion(deletedAt: Value(timestamp), updatedAt: Value(timestamp)),
        );
      case AtprotoSyncLocalTable.bookmarkFolders:
        await (_database.update(_database.bookmarkFolders)..where((row) => row.id.equals(localId))).write(
          BookmarkFoldersCompanion(deletedAt: Value(timestamp), updatedAt: Value(timestamp)),
        );
      case AtprotoSyncLocalTable.bookmarkCollectionLinks:
        await (_database.update(_database.bookmarkCollectionLinks)..where((row) => row.id.equals(localId))).write(
          BookmarkCollectionLinksCompanion(deletedAt: Value(timestamp), updatedAt: Value(timestamp)),
        );
      case AtprotoSyncLocalTable.annotations:
        await (_database.update(_database.annotations)..where((row) => row.id.equals(localId))).write(
          AnnotationsCompanion(deletedAt: Value(timestamp), modifiedAt: Value(timestamp)),
        );
      case AtprotoSyncLocalTable.annotationCollections:
        await (_database.update(_database.annotationCollections)..where((row) => row.id.equals(localId))).write(
          AnnotationCollectionsCompanion(deletedAt: Value(timestamp), updatedAt: Value(timestamp)),
        );
      case AtprotoSyncLocalTable.annotationCollectionItems:
        await (_database.update(_database.annotationCollectionItems)..where((row) => row.id.equals(localId))).write(
          AnnotationCollectionItemsCompanion(deletedAt: Value(timestamp), updatedAt: Value(timestamp)),
        );
    }
  }

  Future<void> _publishCollectionLinkRemoval({
    required String accountDid,
    required AtprotoRecordMirror removedLink,
  }) async {
    final collectionRef = _collectionRefForRemovedLink(removedLink);
    final record = cosmik_removal.CollectionLinkRemovalRecord(
      collection: collectionRef,
      removedLink: RepoStrongRef(uri: AtUri(removedLink.uri), cid: removedLink.cid ?? ''),
      removedAt: _now(),
    );
    final json = const cosmik_removal.CollectionLinkRemovalRecordConverter().toJson(record);
    final result = await _repoClient.createRecord(
      did: accountDid,
      collection: SembleSyncCollection.collectionLinkRemoval.value,
      rkey: _uuid.v4(),
      record: json,
    );
    await _syncRepository.upsertMirror(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.bookmarkCollectionLinks.value,
      localId: removedLink.localId,
      collection: SembleSyncCollection.collectionLinkRemoval.value,
      rkey: rkeyFromUri(result.uri),
      uri: result.uri,
      cid: result.cid,
      lastSyncedRecordJson: jsonEncode(json),
      lastSyncedAt: _now(),
    );
  }

  RepoStrongRef _collectionRefForRemovedLink(AtprotoRecordMirror removedLink) {
    final json = removedLink.lastSyncedRecordJson;
    if (json != null) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map<String, dynamic>) {
          final collection = decoded['collection'];
          if (collection is Map<String, dynamic>) {
            final uri = collection['uri']?.toString();
            if (uri != null && uri.isNotEmpty) {
              return RepoStrongRef(uri: AtUri(uri), cid: collection['cid']?.toString() ?? '');
            }
          }
        }
      } on FormatException catch (error, stackTrace) {
        _logger.debug(
          'Could not parse collection link mirror JSON while preparing ATProto deletion sync.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return RepoStrongRef(
      uri: AtUri('at://${removedLink.accountDid}/${SembleSyncCollection.collection.value}/${removedLink.rkey}'),
      cid: '',
    );
  }

  String? _repoDid(String uri) => Uri.tryParse(uri)?.host;
}
