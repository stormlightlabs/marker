import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/annotation_sync_opt_in_service.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late AnnotationSyncOptInService service;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 28, 12));
    service = AnnotationSyncOptInService(
      database: database,
      syncRepository: syncRepository,
      settingsRepository: SettingsRepository(database),
    );
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    await _seedAnnotationCollectionAndItem(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('enabling annotation sync enqueues existing annotation domain rows', () async {
    await service.setEnabled(true);

    final outbox = await syncRepository.pendingOutbox(accountDid: 'did:plc:alice');
    expect(
      outbox.map((row) => (row.localTable, row.localId, row.collection)),
      containsAll([
        (SembleSyncLocalTable.annotations.value, 'annotation-1', MarginSyncCollection.note.value),
        (SembleSyncLocalTable.annotationCollections.value, 'collection-1', MarginSyncCollection.collection.value),
        (SembleSyncLocalTable.annotationCollectionItems.value, 'item-1', MarginSyncCollection.collectionItem.value),
      ]),
    );
    expect(await SettingsRepository(database).isAnnotationSyncEnabled(), isTrue);
  });
}

Future<void> _seedAnnotationCollectionAndItem(AppDatabase database) async {
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
  await database
      .into(database.annotationCollections)
      .insert(
        AnnotationCollectionsCompanion.insert(
          id: 'collection-1',
          name: 'Research',
          createdAt: DateTime.utc(2026, 5, 28, 11),
          updatedAt: DateTime.utc(2026, 5, 28, 11),
        ),
      );
  await database
      .into(database.annotationCollectionItems)
      .insert(
        AnnotationCollectionItemsCompanion.insert(
          id: 'item-1',
          collectionId: 'collection-1',
          annotationId: 'annotation-1',
          createdAt: DateTime.utc(2026, 5, 28, 11),
          updatedAt: DateTime.utc(2026, 5, 28, 11),
        ),
      );
}
