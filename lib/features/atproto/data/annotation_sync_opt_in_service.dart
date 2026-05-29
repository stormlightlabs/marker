import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

final annotationSyncOptInServiceProvider = Provider<AnnotationSyncOptInService>((ref) {
  return AnnotationSyncOptInService(
    database: ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

class AnnotationSyncOptInService {
  const AnnotationSyncOptInService({
    required AppDatabase database,
    required AtprotoSyncRepository syncRepository,
    required SettingsRepository settingsRepository,
  }) : _database = database,
       _syncRepository = syncRepository,
       _settingsRepository = settingsRepository;

  final AppDatabase _database;
  final AtprotoSyncRepository _syncRepository;
  final SettingsRepository _settingsRepository;

  Future<void> setEnabled(bool enabled) async {
    await _settingsRepository.setAnnotationSyncEnabled(enabled);
    if (enabled) {
      await enqueueExistingForSync();
    }
  }

  Future<void> enqueueExistingForSync() async {
    if (!await _settingsRepository.isAnnotationSyncEnabled()) return;
    final accounts = await _syncRepository.accounts();
    if (accounts.isEmpty) return;
    final annotations = await (_database.select(_database.annotations)..where((row) => row.deletedAt.isNull())).get();
    final collections = await (_database.select(
      _database.annotationCollections,
    )..where((row) => row.deletedAt.isNull())).get();
    final items = await (_database.select(
      _database.annotationCollectionItems,
    )..where((row) => row.deletedAt.isNull())).get();

    for (final account in accounts) {
      for (final annotation in annotations) {
        await _syncRepository.selectForSync(
          accountDid: account.did,
          localTable: AtprotoSyncLocalTable.annotations.value,
          localId: annotation.id,
          collection: MarginSyncCollection.note.value,
        );
      }
      for (final collection in collections) {
        await _syncRepository.selectForSync(
          accountDid: account.did,
          localTable: AtprotoSyncLocalTable.annotationCollections.value,
          localId: collection.id,
          collection: MarginSyncCollection.collection.value,
        );
      }
      for (final item in items) {
        await _syncRepository.selectForSync(
          accountDid: account.did,
          localTable: AtprotoSyncLocalTable.annotationCollectionItems.value,
          localId: item.id,
          collection: MarginSyncCollection.collectionItem.value,
        );
      }
    }
  }
}
