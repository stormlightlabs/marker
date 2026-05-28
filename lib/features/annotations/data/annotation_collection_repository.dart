import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/settings/data/settings_repository.dart';
import 'package:uuid/uuid.dart';

final annotationCollectionRepositoryProvider = Provider<AnnotationCollectionRepository>((ref) {
  return AnnotationCollectionRepository(
    ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
  );
});

class AnnotationCollectionRepository {
  AnnotationCollectionRepository(
    this._database, {
    AtprotoSyncRepository? syncRepository,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _syncRepository = syncRepository,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final AtprotoSyncRepository? _syncRepository;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<AnnotationCollection> createCollection({required String name, String? description, String? icon}) async {
    final now = _now();
    final id = _uuid.v4();
    await _database.transaction(() async {
      await _database
          .into(_database.annotationCollections)
          .insert(
            AnnotationCollectionsCompanion.insert(
              id: id,
              name: name.trim(),
              description: Value(emptyToNull(description)),
              icon: Value(emptyToNull(icon)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _enqueue(id, SembleSyncLocalTable.annotationCollections, MarginSyncCollection.collection);
    });
    return (_database.select(_database.annotationCollections)..where((row) => row.id.equals(id))).getSingle();
  }

  Future<AnnotationCollectionItem> addAnnotation({
    required String collectionId,
    required String annotationId,
    int? position,
  }) async {
    final now = _now();
    final id = _uuid.v4();
    await _database.transaction(() async {
      await _database
          .into(_database.annotationCollectionItems)
          .insert(
            AnnotationCollectionItemsCompanion.insert(
              id: id,
              collectionId: collectionId,
              annotationId: annotationId,
              position: Value(position),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      final item = await (_database.select(
        _database.annotationCollectionItems,
      )..where((row) => row.collectionId.equals(collectionId) & row.annotationId.equals(annotationId))).getSingle();
      await _enqueue(item.id, SembleSyncLocalTable.annotationCollectionItems, MarginSyncCollection.collectionItem);
    });
    return (_database.select(
      _database.annotationCollectionItems,
    )..where((row) => row.collectionId.equals(collectionId) & row.annotationId.equals(annotationId))).getSingle();
  }

  Future<void> deleteCollection(String collectionId) async {
    final now = _now();
    await _database.transaction(() async {
      await (_database.update(_database.annotationCollections)..where((row) => row.id.equals(collectionId))).write(
        AnnotationCollectionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await _enqueue(
        collectionId,
        SembleSyncLocalTable.annotationCollections,
        MarginSyncCollection.collection,
        operation: AtprotoSyncOperation.delete,
      );
    });
  }

  Future<void> removeAnnotation(String itemId) async {
    final now = _now();
    await _database.transaction(() async {
      await (_database.update(_database.annotationCollectionItems)..where((row) => row.id.equals(itemId))).write(
        AnnotationCollectionItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await _enqueue(
        itemId,
        SembleSyncLocalTable.annotationCollectionItems,
        MarginSyncCollection.collectionItem,
        operation: AtprotoSyncOperation.delete,
      );
    });
  }

  Future<void> _enqueue(
    String localId,
    SembleSyncLocalTable table,
    MarginSyncCollection collection, {
    AtprotoSyncOperation operation = AtprotoSyncOperation.update,
  }) async {
    final syncRepository = _syncRepository;
    if (syncRepository == null || !await _isAnnotationSyncEnabled()) return;
    final accounts = await syncRepository.accounts();
    for (final account in accounts) {
      await syncRepository.enqueueOutbox(
        accountDid: account.did,
        operation: operation.value,
        localTable: table.value,
        localId: localId,
        collection: collection.value,
      );
    }
  }

  Future<bool> _isAnnotationSyncEnabled() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.equals(annotationSyncEnabledSettingKey))).getSingleOrNull();
    return row?.value == 'true';
  }
}
