import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:margin_poptart/at/margin/note/body.dart' as margin_body;
import 'package:margin_poptart/at/margin/collection/main.dart' as margin_collection;
import 'package:margin_poptart/at/margin/collection_item/main.dart' as margin_collection_item;
import 'package:margin_poptart/at/margin/note/generator.dart' as margin_generator;
import 'package:margin_poptart/at/margin/note/main.dart' as margin_note;
import 'package:margin_poptart/at/margin/note/main_motivation.dart' as margin_motivation;
import 'package:margin_poptart/at/margin/note/selector.dart' as margin_selector;
import 'package:margin_poptart/at/margin/note/selector_type.dart' as margin_selector_type;
import 'package:margin_poptart/at/margin/note/target.dart' as margin_target;
import 'package:margin_poptart/at/margin/note/time_state.dart' as margin_time_state;
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/shared/utils/atproto_utils.dart';
import 'package:marker/core/shared/utils/json_utils.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/atproto/data/atproto_deletion_sync_service.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/domain/atproto_repo_models.dart';
import 'package:poptart_core/poptart_core.dart';
import 'package:uuid/uuid.dart';

const markerMarginGeneratorId = 'app.marker';
const markerMarginGeneratorName = 'Marker';
const markerMarginGeneratorHomepage = 'https://marker.stormlightlabs.org';
const markerMarginStyleField = 'markerStyle';
const markerMarginUnderlineStyle = 'underline';

final marginNoteSyncServiceProvider = Provider<MarginNoteSyncService>((ref) {
  return MarginNoteSyncService(
    database: ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    repoClient: ref.watch(atprotoRepoClientProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

class MarginNoteSyncResult {
  const MarginNoteSyncResult({
    this.imported = 0,
    this.updated = 0,
    this.pushed = 0,
    this.duplicates = 0,
    this.conflicts = 0,
    this.malformed = 0,
    this.failed = 0,
    this.deferred = 0,
    this.deleted = 0,
  });

  final int imported;
  final int updated;
  final int pushed;
  final int duplicates;
  final int conflicts;
  final int malformed;
  final int failed;
  final int deferred;
  final int deleted;

  MarginNoteSyncResult operator +(MarginNoteSyncResult other) => MarginNoteSyncResult(
    imported: imported + other.imported,
    updated: updated + other.updated,
    pushed: pushed + other.pushed,
    duplicates: duplicates + other.duplicates,
    conflicts: conflicts + other.conflicts,
    malformed: malformed + other.malformed,
    failed: failed + other.failed,
    deferred: deferred + other.deferred,
    deleted: deleted + other.deleted,
  );
}

class MarginNoteSyncService {
  MarginNoteSyncService({
    required AppDatabase database,
    required AtprotoSyncRepository syncRepository,
    required AtprotoRepoClient repoClient,
    Uuid? uuid,
    AppLogger? logger,
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

  Future<MarginNoteSyncResult> pull(String accountDid) async {
    var result = const MarginNoteSyncResult();
    final seenUrisByCollection = <MarginSyncCollection, Set<String>>{};
    result += await _pullCollection(
      accountDid,
      MarginSyncCollection.collection,
      _importCollection,
      onRecordSeen: (uri) => (seenUrisByCollection[MarginSyncCollection.collection] ??= <String>{}).add(uri),
    );
    result += await _pullCollection(
      accountDid,
      MarginSyncCollection.note,
      _importNote,
      onRecordSeen: (uri) => (seenUrisByCollection[MarginSyncCollection.note] ??= <String>{}).add(uri),
    );
    result += await _pullCollection(
      accountDid,
      MarginSyncCollection.collectionItem,
      _importCollectionItem,
      onRecordSeen: (uri) => (seenUrisByCollection[MarginSyncCollection.collectionItem] ??= <String>{}).add(uri),
    );
    for (final collection in MarginSyncCollection.values) {
      result += await _verifyMissingMirrors(
        accountDid,
        collection,
        seenUrisByCollection[collection] ?? const <String>{},
      );
    }
    return result;
  }

  Future<MarginNoteSyncResult> _pullCollection(
    String accountDid,
    MarginSyncCollection collection,
    Future<MarginNoteSyncResult> Function(String accountDid, AtprotoRepoRecord record) importRecord, {
    void Function(String uri)? onRecordSeen,
  }) async {
    var result = const MarginNoteSyncResult();
    String? cursor;
    do {
      final page = await _repoClient.listRecords(
        did: accountDid,
        collection: collection.value,
        cursor: cursor,
        limit: 100,
      );
      for (final record in page.records) {
        onRecordSeen?.call(record.uri);
        result += await importRecord(accountDid, record);
      }
      cursor = page.cursor;
    } while (cursor != null);

    await _syncRepository.saveCursor(
      accountDid: accountDid,
      collection: collection.value,
      cursor: null,
      lastSuccessfulSyncAt: _now(),
    );
    return result;
  }

  Future<MarginNoteSyncResult> pushPending(String accountDid, {int limit = 100}) async {
    final pending = await _syncRepository.pendingOutbox(accountDid: accountDid, limit: limit);
    var result = const MarginNoteSyncResult();
    for (final item in pending.where(
      (item) =>
          _isMarginOutboxItem(item) &&
          (item.operation == AtprotoSyncOperation.create.value || item.operation == AtprotoSyncOperation.update.value),
    )) {
      if (!_isDue(item)) {
        result += const MarginNoteSyncResult(deferred: 1);
        continue;
      }
      try {
        await _pushItem(item);
        await _syncRepository.deleteOutbox(item.id);
        result += const MarginNoteSyncResult(pushed: 1);
      } on Object catch (error, stackTrace) {
        _logger?.error(
          'Failed to push Margin outbox item. '
          'id=${item.id} localTable=${item.localTable} localId=${item.localId} collection=${item.collection}',
          error: error,
          stackTrace: stackTrace,
        );
        await _syncRepository.markOutboxAttempt(
          id: item.id,
          attemptCount: item.attemptCount + 1,
          lastError: _shortError(error),
        );
        result += const MarginNoteSyncResult(failed: 1);
      }
    }
    return result;
  }

  bool _isMarginOutboxItem(AtprotoSyncOutboxData item) {
    if (item.localTable == AtprotoSyncLocalTable.annotations.value &&
        item.collection == MarginSyncCollection.note.value) {
      return true;
    }
    if (item.localTable == AtprotoSyncLocalTable.annotationCollections.value &&
        item.collection == MarginSyncCollection.collection.value) {
      return true;
    }
    if (item.localTable == AtprotoSyncLocalTable.annotationCollectionItems.value &&
        item.collection == MarginSyncCollection.collectionItem.value) {
      return true;
    }
    return false;
  }

  Future<MarginNoteSyncResult> _importCollection(String accountDid, AtprotoRepoRecord remote) async {
    try {
      final record = const margin_collection.CollectionRecordConverter().fromJson(remote.value);
      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) return const MarginNoteSyncResult(conflicts: 1);
      final json = canonicalJson(remote.value);
      final hash = stableJenkinsOneAtATimeHash(json);
      if (mirror != null && mirror.lastSyncedHash == hash && mirror.deletedAt == null) {
        return const MarginNoteSyncResult(duplicates: 1);
      }
      final localId = mirror?.localId ?? _uuid.v4();
      final now = _now();
      await _database.transaction(() async {
        if (mirror == null) {
          await _database
              .into(_database.annotationCollections)
              .insert(
                AnnotationCollectionsCompanion.insert(
                  id: localId,
                  name: record.name,
                  description: Value(emptyToNull(record.description)),
                  icon: Value(emptyToNull(record.icon)),
                  createdAt: record.createdAt,
                  updatedAt: now,
                ),
              );
        } else {
          await (_database.update(_database.annotationCollections)..where((row) => row.id.equals(localId))).write(
            AnnotationCollectionsCompanion(
              name: Value(record.name),
              description: Value(emptyToNull(record.description)),
              icon: Value(emptyToNull(record.icon)),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          );
        }
      });
      await _syncRepository.upsertMirror(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.annotationCollections.value,
        localId: localId,
        collection: MarginSyncCollection.collection.value,
        rkey: rkeyFromUri(remote.uri),
        uri: remote.uri,
        cid: remote.cid,
        lastSyncedRecordJson: json,
        lastSyncedHash: hash,
        lastSyncedAt: _now(),
      );
      return MarginNoteSyncResult(imported: mirror == null ? 1 : 0, updated: mirror == null ? 0 : 1);
    } on Object catch (error, stackTrace) {
      return _malformed(remote, 'Ignoring malformed Margin collection record.', error: error, stackTrace: stackTrace);
    }
  }

  Future<MarginNoteSyncResult> _importCollectionItem(String accountDid, AtprotoRepoRecord remote) async {
    try {
      final record = const margin_collection_item.CollectionItemRecordConverter().fromJson(remote.value);
      final collectionMirror = await _syncRepository.mirrorForUri(
        accountDid: accountDid,
        uri: record.collection.toString(),
      );
      final annotationMirror = await _syncRepository.mirrorForUri(
        accountDid: accountDid,
        uri: record.annotation.toString(),
      );
      if (collectionMirror == null || annotationMirror == null) {
        return _malformed(remote, 'Margin collection item references records that are not mirrored locally.');
      }
      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) return const MarginNoteSyncResult(conflicts: 1);
      final json = canonicalJson(remote.value);
      final hash = stableJenkinsOneAtATimeHash(json);
      if (mirror != null && mirror.lastSyncedHash == hash && mirror.deletedAt == null) {
        return const MarginNoteSyncResult(duplicates: 1);
      }
      final localId = mirror?.localId ?? _uuid.v4();
      final now = _now();
      await _database.transaction(() async {
        if (mirror == null) {
          await _database
              .into(_database.annotationCollectionItems)
              .insert(
                AnnotationCollectionItemsCompanion.insert(
                  id: localId,
                  collectionId: collectionMirror.localId,
                  annotationId: annotationMirror.localId,
                  position: Value(record.position),
                  createdAt: record.createdAt,
                  updatedAt: now,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        } else {
          await (_database.update(_database.annotationCollectionItems)..where((row) => row.id.equals(localId))).write(
            AnnotationCollectionItemsCompanion(
              collectionId: Value(collectionMirror.localId),
              annotationId: Value(annotationMirror.localId),
              position: Value(record.position),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          );
        }
      });
      await _syncRepository.upsertMirror(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.annotationCollectionItems.value,
        localId: localId,
        collection: MarginSyncCollection.collectionItem.value,
        rkey: rkeyFromUri(remote.uri),
        uri: remote.uri,
        cid: remote.cid,
        lastSyncedRecordJson: json,
        lastSyncedHash: hash,
        lastSyncedAt: _now(),
      );
      return MarginNoteSyncResult(imported: mirror == null ? 1 : 0, updated: mirror == null ? 0 : 1);
    } on Object catch (error, stackTrace) {
      return _malformed(
        remote,
        'Ignoring malformed Margin collection item record.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<MarginNoteSyncResult> _importNote(String accountDid, AtprotoRepoRecord remote) async {
    try {
      final note = const margin_note.NoteRecordConverter().fromJson(remote.value);
      final source = emptyToNull(note.target.source);
      if (source == null) return _malformed(remote, 'Margin note record is missing a source URL.');
      final sourceUri = Uri.tryParse(source);
      if (sourceUri == null || !sourceUri.hasScheme) {
        return _malformed(remote, 'Margin note record has an invalid source URL.');
      }

      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) return const MarginNoteSyncResult(conflicts: 1);

      final json = canonicalJson(remote.value);
      final hash = stableJenkinsOneAtATimeHash(json);
      if (mirror != null && mirror.lastSyncedHash == hash && mirror.deletedAt == null) {
        return const MarginNoteSyncResult(duplicates: 1);
      }

      final page = await _upsertPage(source, note.target.title);
      final annotationId = mirror?.localId ?? _uuid.v4();
      final motivation = note.motivation.toJson();
      final createdAt = note.createdAt;
      final modifiedAt = note.modifiedAt ?? createdAt;
      final selectorJson = jsonEncode([if (note.target.selector != null) _selectorToLocalJson(note.target.selector!)]);
      final body = emptyToNull(note.body?.value);
      final bodyUri = emptyToNull(note.body?.uri);
      final color = emptyToNull(note.color);
      final markerStyle = _remoteMarkerStyle(remote.value);
      final tagNames = _normalizeTags(note.tags);

      await _database.transaction(() async {
        if (mirror == null) {
          await _database
              .into(_database.annotations)
              .insert(
                AnnotationsCompanion.insert(
                  id: annotationId,
                  pageId: page.id,
                  motivation: motivation,
                  marginMetadataJson: Value(_marginMetadataJson(remote.value)),
                  createdAt: createdAt,
                  modifiedAt: modifiedAt,
                ),
              );
        } else {
          await (_database.update(_database.annotations)..where((row) => row.id.equals(annotationId))).write(
            AnnotationsCompanion(
              pageId: Value(page.id),
              motivation: Value(motivation),
              marginMetadataJson: Value(_marginMetadataJson(remote.value)),
              modifiedAt: Value(modifiedAt),
              deletedAt: const Value(null),
            ),
          );
          await (_database.delete(
            _database.annotationTargets,
          )..where((row) => row.annotationId.equals(annotationId))).go();
          await (_database.delete(
            _database.annotationBodies,
          )..where((row) => row.annotationId.equals(annotationId))).go();
          await (_database.delete(
            _database.annotationTags,
          )..where((row) => row.annotationId.equals(annotationId))).go();
        }

        await _database
            .into(_database.annotationTargets)
            .insert(
              AnnotationTargetsCompanion.insert(
                id: _uuid.v4(),
                annotationId: annotationId,
                sourceUrl: source,
                sourceHash: Value(emptyToNull(note.target.sourceHash)),
                selectorJson: selectorJson,
                stateJson: Value(note.target.state == null ? null : jsonEncode(note.target.state!.toJson())),
              ),
            );
        if (body != null || bodyUri != null) {
          await _database
              .into(_database.annotationBodies)
              .insert(
                AnnotationBodiesCompanion.insert(
                  id: _uuid.v4(),
                  annotationId: annotationId,
                  type: 'TextualBody',
                  format: Value(emptyToNull(note.body?.format) ?? 'text/plain'),
                  value: body ?? '',
                  uri: Value(bodyUri),
                ),
              );
        }
        if (color != null) {
          await _database
              .into(_database.annotationBodies)
              .insert(
                AnnotationBodiesCompanion.insert(
                  id: _uuid.v4(),
                  annotationId: annotationId,
                  type: 'StyleHint',
                  format: const Value('application/json'),
                  value: jsonEncode({
                    'style': markerStyle == markerMarginUnderlineStyle
                        ? AnnotationVisualStyle.underline.name
                        : AnnotationVisualStyle.highlight.name,
                    'color': color,
                  }),
                ),
              );
        }
        for (final tagName in tagNames) {
          await _database
              .into(_database.annotationTags)
              .insert(
                AnnotationTagsCompanion.insert(
                  id: _uuid.v4(),
                  annotationId: annotationId,
                  name: tagName,
                  createdAt: _now(),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      });

      await _syncRepository.upsertMirror(
        accountDid: accountDid,
        localTable: AtprotoSyncLocalTable.annotations.value,
        localId: annotationId,
        collection: MarginSyncCollection.note.value,
        rkey: rkeyFromUri(remote.uri),
        uri: remote.uri,
        cid: remote.cid,
        lastSyncedRecordJson: json,
        lastSyncedHash: hash,
        lastSyncedAt: _now(),
      );
      return MarginNoteSyncResult(imported: mirror == null ? 1 : 0, updated: mirror == null ? 0 : 1);
    } on Object catch (error, stackTrace) {
      return _malformed(remote, 'Ignoring malformed Margin note record.', error: error, stackTrace: stackTrace);
    }
  }

  MarginNoteSyncResult _malformed(AtprotoRepoRecord remote, String message, {Object? error, StackTrace? stackTrace}) {
    _logger?.debug('$message uri=${remote.uri} cid=${remote.cid ?? 'unknown'}', error: error, stackTrace: stackTrace);
    return const MarginNoteSyncResult(malformed: 1);
  }

  Future<MarginNoteSyncResult> _verifyMissingMirrors(
    String accountDid,
    MarginSyncCollection collection,
    Set<String> seenUris,
  ) async {
    var deleted = 0;
    final deletionSync = AtprotoDeletionSyncService(
      database: _database,
      syncRepository: _syncRepository,
      repoClient: _repoClient,
      now: _now,
      logger: _logger,
    );
    final mirrors = await _syncRepository.activeMirrors(accountDid: accountDid, collection: collection.value);
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
    return MarginNoteSyncResult(deleted: deleted);
  }

  Future<void> _pushItem(AtprotoSyncOutboxData item) async {
    final mirror = await _syncRepository.mirrorForLocal(
      accountDid: item.accountDid,
      localTable: item.localTable,
      localId: item.localId,
      collection: item.collection,
    );
    final record = await _recordForItem(item);
    final json = canonicalJson(record);
    final hash = stableJenkinsOneAtATimeHash(json);
    if (mirror?.lastSyncedHash == hash && mirror?.deletedAt == null) return;

    final rkey = mirror?.rkey ?? _rkeyForLocal(item.localId);
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
    if (item.localTable == AtprotoSyncLocalTable.annotations.value &&
        item.collection == MarginSyncCollection.note.value) {
      return mapLocalAnnotationToMarginNote(item.localId);
    }
    if (item.localTable == AtprotoSyncLocalTable.annotationCollections.value &&
        item.collection == MarginSyncCollection.collection.value) {
      return mapLocalAnnotationCollectionToMargin(item.localId);
    }
    if (item.localTable == AtprotoSyncLocalTable.annotationCollectionItems.value &&
        item.collection == MarginSyncCollection.collectionItem.value) {
      return _mapLocalAnnotationCollectionItemToMargin(accountDid: item.accountDid, itemId: item.localId);
    }
    throw StateError('Unsupported Margin push item: ${item.localTable} ${item.collection}.');
  }

  Future<Map<String, dynamic>> mapLocalAnnotationCollectionToMargin(String collectionId) async {
    final collection = await (_database.select(
      _database.annotationCollections,
    )..where((row) => row.id.equals(collectionId) & row.deletedAt.isNull())).getSingleOrNull();
    if (collection == null) throw StateError('Annotation collection no longer exists locally.');
    return const margin_collection.CollectionRecordConverter().toJson(
      margin_collection.CollectionRecord(
        name: collection.name,
        description: emptyToNull(collection.description),
        icon: emptyToNull(collection.icon),
        createdAt: collection.createdAt,
      ),
    );
  }

  Future<Map<String, dynamic>> _mapLocalAnnotationCollectionItemToMargin({
    required String accountDid,
    required String itemId,
  }) async {
    final item = await (_database.select(
      _database.annotationCollectionItems,
    )..where((row) => row.id.equals(itemId) & row.deletedAt.isNull())).getSingleOrNull();
    if (item == null) throw StateError('Annotation collection item no longer exists locally.');
    final collectionMirror = await _syncRepository.mirrorForLocal(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.annotationCollections.value,
      localId: item.collectionId,
      collection: MarginSyncCollection.collection.value,
    );
    final annotationMirror = await _syncRepository.mirrorForLocal(
      accountDid: accountDid,
      localTable: AtprotoSyncLocalTable.annotations.value,
      localId: item.annotationId,
      collection: MarginSyncCollection.note.value,
    );
    if (collectionMirror == null || collectionMirror.deletedAt != null) {
      throw StateError('Sync the annotation collection before its collection item.');
    }
    if (annotationMirror == null || annotationMirror.deletedAt != null) {
      throw StateError('Sync the annotation before its collection item.');
    }
    return const margin_collection_item.CollectionItemRecordConverter().toJson(
      margin_collection_item.CollectionItemRecord(
        collection: AtUri(collectionMirror.uri),
        annotation: AtUri(annotationMirror.uri),
        position: item.position,
        createdAt: item.createdAt,
      ),
    );
  }

  Future<Map<String, dynamic>> mapLocalAnnotationToMarginNote(String annotationId) async {
    final annotation = await (_database.select(
      _database.annotations,
    )..where((row) => row.id.equals(annotationId) & row.deletedAt.isNull())).getSingleOrNull();
    if (annotation == null) throw StateError('Annotation no longer exists locally.');
    final page = await (_database.select(
      _database.pages,
    )..where((row) => row.id.equals(annotation.pageId))).getSingle();
    final target = await (_database.select(
      _database.annotationTargets,
    )..where((row) => row.annotationId.equals(annotation.id))).getSingleOrNull();
    if (target == null) throw StateError('Annotation target no longer exists locally.');
    final bodies = await (_database.select(
      _database.annotationBodies,
    )..where((row) => row.annotationId.equals(annotation.id))).get();
    final tags = await (_database.select(
      _database.annotationTags,
    )..where((row) => row.annotationId.equals(annotation.id))).get();
    final local = PageAnnotation(annotation: annotation, target: target, bodies: bodies, logger: _logger);
    final noteBody = local.note;
    final textBody = _marginBody(bodies, noteBody);
    final tagNames = _normalizeTags(tags.map((tag) => tag.name));

    final record = const margin_note.NoteRecordConverter().toJson(
      margin_note.NoteRecord(
        motivation: _noteMotivation(annotation.motivation),
        color: emptyToNull(local.colorHex),
        body: textBody,
        target: margin_target.Target(
          source: target.sourceUrl,
          sourceHash: emptyToNull(target.sourceHash),
          title: emptyToNull(page.title),
          selector: _chooseRemoteSelector(local.selectors),
          state: _targetState(target.stateJson),
        ),
        tags: tagNames.isEmpty ? _metadataList(annotation.marginMetadataJson, 'tags') : tagNames,
        generator: const margin_generator.Generator(
          id: markerMarginGeneratorId,
          name: markerMarginGeneratorName,
          homepage: markerMarginGeneratorHomepage,
        ),
        rights: _metadataString(annotation.marginMetadataJson, 'rights'),
        createdAt: annotation.createdAt,
        modifiedAt: annotation.modifiedAt,
      ),
    );
    _applyMarginMetadata(record, annotation.marginMetadataJson);
    if (!record.containsKey('facets') && noteBody != null) {
      final facets = _markdownLinkFacets(noteBody);
      if (facets.isNotEmpty) record['facets'] = facets;
    }
    if (local.visualStyle == AnnotationVisualStyle.underline) {
      record[markerMarginStyleField] = markerMarginUnderlineStyle;
    }
    return record;
  }

  Future<Page> _upsertPage(String url, String? title) async {
    final existing = await (_database.select(_database.pages)..where((row) => row.url.equals(url))).getSingleOrNull();
    if (existing != null) {
      if (emptyToNull(title) != null) {
        await (_database.update(
          _database.pages,
        )..where((row) => row.id.equals(existing.id))).write(PagesCompanion(title: Value(title)));
      }
      return (_database.select(_database.pages)..where((row) => row.id.equals(existing.id))).getSingle();
    }
    final now = _now();
    final id = _uuid.v4();
    await _database
        .into(_database.pages)
        .insert(
          PagesCompanion.insert(id: id, url: url, title: Value(emptyToNull(title)), createdAt: now, lastVisitedAt: now),
        );
    return (_database.select(_database.pages)..where((row) => row.id.equals(id))).getSingle();
  }

  margin_selector.Selector? _chooseRemoteSelector(List<Map<String, Object?>> selectors) {
    for (final selector in selectors) {
      if (selector['type'] == 'TextQuoteSelector' || selector['type'] == 'TextPositionSelector') {
        return _localSelectorToRemote(selector);
      }
    }
    for (final selector in selectors) {
      final mapped = _localSelectorToRemote(selector);
      if (mapped != null) return mapped;
    }
    return null;
  }

  margin_selector.Selector? _localSelectorToRemote(Map<String, Object?> selector) {
    final type = margin_selector_type.SelectorType.valueOf(emptyToNull(selector['type']?.toString()));
    if (type == null) return null;
    return margin_selector.Selector(
      type: type,
      exact: emptyToNull(selector['exact']?.toString()),
      prefix: emptyToNull(selector['prefix']?.toString()),
      suffix: emptyToNull(selector['suffix']?.toString()),
      start: selector['start'] is int ? selector['start'] as int : int.tryParse(selector['start']?.toString() ?? ''),
      end: selector['end'] is int ? selector['end'] as int : int.tryParse(selector['end']?.toString() ?? ''),
      value: emptyToNull(selector['value']?.toString()),
      conformsTo: emptyToNull(selector['conformsTo']?.toString()),
    );
  }

  Map<String, Object?> _selectorToLocalJson(margin_selector.Selector selector) => {
    'type': selector.type.toJson(),
    if (selector.exact != null) 'exact': selector.exact,
    if (selector.prefix != null) 'prefix': selector.prefix,
    if (selector.suffix != null) 'suffix': selector.suffix,
    if (selector.start != null) 'start': selector.start,
    if (selector.end != null) 'end': selector.end,
    if (selector.value != null) 'value': selector.value,
    if (selector.conformsTo != null) 'conformsTo': selector.conformsTo,
  };

  margin_motivation.NoteMotivation _noteMotivation(String motivation) =>
      margin_motivation.NoteMotivation.valueOf(motivation) ??
      margin_motivation.NoteMotivation.unknown(data: motivation);

  margin_body.Body? _marginBody(List<AnnotationBody> bodies, String? noteBody) {
    for (final body in bodies) {
      if (body.type != 'TextualBody') continue;
      final uri = emptyToNull(body.uri);
      if (noteBody == null && uri == null) return null;
      return margin_body.Body(value: noteBody, format: body.format ?? 'text/markdown', uri: uri);
    }
    return null;
  }

  margin_time_state.TimeState? _targetState(String? stateJson) {
    final trimmed = emptyToNull(stateJson);
    if (trimmed == null) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, Object?>) {
        return margin_time_state.TimeState.fromJson(decoded);
      }
    } on Object catch (error) {
      _logger?.debug('Ignoring malformed Margin target state', error: error);
      return null;
    }
    return null;
  }

  List<Map<String, Object?>> _markdownLinkFacets(String markdown) {
    final facets = <Map<String, Object?>>[];
    final pattern = RegExp(r'\[([^\]]+)\]\((https?://[^\s)]+)\)');
    for (final match in pattern.allMatches(markdown)) {
      final labelStart = match.start + 1;
      final labelEnd = labelStart + (match.group(1)?.length ?? 0);
      facets.add({
        'index': {
          r'$type': 'app.bsky.richtext.facet#byteSlice',
          'byteStart': utf8.encode(markdown.substring(0, labelStart)).length,
          'byteEnd': utf8.encode(markdown.substring(0, labelEnd)).length,
        },
        'features': [
          {r'$type': 'app.bsky.richtext.facet#link', 'uri': match.group(2)},
        ],
      });
    }
    return facets;
  }

  List<String> _normalizeTags(Iterable<String>? tags) {
    if (tags == null) return const [];
    final seen = <String>{};
    final normalized = <String>[];
    for (final tag in tags) {
      final value = emptyToNull(tag)?.replaceAll(RegExp(r'\\s+'), ' ');
      if (value == null) continue;
      final key = value.toLowerCase();
      if (seen.add(key)) normalized.add(value);
    }
    return normalized;
  }

  String? _remoteMarkerStyle(Map<String, dynamic> remoteValue) {
    return emptyToNull(remoteValue[markerMarginStyleField]?.toString());
  }

  String? _marginMetadataJson(Map<String, dynamic> remoteValue) {
    final metadata = <String, Object?>{};
    for (final key in ['tags', 'facets', 'generator', 'rights', 'labels']) {
      if (remoteValue.containsKey(key)) metadata[key] = remoteValue[key];
    }
    final unknown = <String, Object?>{};
    const known = {
      r'$type',
      'motivation',
      'color',
      'body',
      'target',
      'tags',
      'facets',
      'generator',
      'rights',
      'labels',
      'createdAt',
      'modifiedAt',
    };
    for (final entry in remoteValue.entries) {
      if (!known.contains(entry.key)) unknown[entry.key] = entry.value;
    }
    if (unknown.isNotEmpty) metadata['unknown'] = unknown;
    return metadata.isEmpty ? null : jsonEncode(metadata);
  }

  List<String>? _metadataList(String? metadataJson, String key) {
    final value = _metadataValue(metadataJson, key);
    if (value is! List) return null;
    final items = [
      for (final item in value)
        if (emptyToNull(item?.toString()) != null) item.toString().trim(),
    ];
    return items.isEmpty ? null : items;
  }

  String? _metadataString(String? metadataJson, String key) =>
      emptyToNull(_metadataValue(metadataJson, key)?.toString());

  Object? _metadataValue(String? metadataJson, String key) {
    final trimmed = emptyToNull(metadataJson);
    if (trimmed == null) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, Object?>) return decoded[key];
    } on Object catch (error) {
      _logger?.debug('Ignoring malformed Margin metadata value', error: error);
      return null;
    }
    return null;
  }

  void _applyMarginMetadata(Map<String, dynamic> record, String? metadataJson) {
    final trimmed = emptyToNull(metadataJson);
    if (trimmed == null) return;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, Object?>) return;
      for (final key in ['tags', 'facets', 'rights', 'labels']) {
        if (decoded.containsKey(key) && decoded[key] != null) record[key] = decoded[key];
      }
      final unknown = decoded['unknown'];
      if (unknown is Map<String, Object?>) {
        for (final entry in unknown.entries) {
          record.putIfAbsent(entry.key, () => entry.value);
        }
      }
    } on Object catch (error) {
      _logger?.debug('Ignoring malformed Margin metadata', error: error);
      return;
    }
  }

  bool _isDue(AtprotoSyncOutboxData item) {
    if (item.attemptCount <= 0) return true;
    final backoff = Duration(minutes: 1 << (item.attemptCount - 1).clamp(0, 5));
    return !item.updatedAt.add(backoff).isAfter(_now());
  }

  String _rkeyForLocal(String localId) {
    final safe = localId.replaceAll(RegExp(r'[^A-Za-z0-9._~-]'), '-');
    if (safe.isNotEmpty && safe.length <= 512 && !safe.startsWith('.')) return safe;
    return 'm-${stableJenkinsOneAtATimeHash('margin:$localId')}';
  }

  String _shortError(Object error) {
    final value = error.toString();
    return value.length <= 240 ? value : '${value.substring(0, 240)}…';
  }
}
