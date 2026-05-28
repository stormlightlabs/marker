import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/annotations/data/annotation_collection_repository.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late AnnotationCollectionRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 28, 12));
    repository = AnnotationCollectionRepository(
      database,
      syncRepository: syncRepository,
      now: () => DateTime.utc(2026, 5, 28, 12),
    );
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    await SettingsRepository(database).setAnnotationSyncEnabled(true);
    await _seedAnnotation(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates curated annotation collections and enqueues collection/item sync', () async {
    final collection = await repository.createCollection(name: 'Research', description: 'Papers', icon: '📚');
    final item = await repository.addAnnotation(
      collectionId: collection.id,
      annotationId: 'annotation-1',
      position: 10,
    );

    final outbox = await syncRepository.pendingOutbox(accountDid: 'did:plc:alice');
    expect(outbox.map((row) => (row.localTable, row.localId, row.collection)), [
      (SembleSyncLocalTable.annotationCollections.value, collection.id, MarginSyncCollection.collection.value),
      (SembleSyncLocalTable.annotationCollectionItems.value, item.id, MarginSyncCollection.collectionItem.value),
    ]);
  });

  test('does not enqueue annotation collection sync when opt-in is disabled', () async {
    await SettingsRepository(database).setAnnotationSyncEnabled(false);

    await repository.createCollection(name: 'Private');

    expect(await syncRepository.pendingOutbox(accountDid: 'did:plc:alice'), isEmpty);
  });
}

Future<void> _seedAnnotation(AppDatabase database) async {
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'page-1',
          url: 'https://example.com',
          createdAt: DateTime.utc(2026, 5, 28, 11),
          lastVisitedAt: DateTime.utc(2026, 5, 28, 11),
        ),
      );
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: 'annotation-1',
          pageId: 'page-1',
          motivation: 'highlighting',
          createdAt: DateTime.utc(2026, 5, 28, 11),
          modifiedAt: DateTime.utc(2026, 5, 28, 11),
        ),
      );
}
