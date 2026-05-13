import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';

const String adBlockEnabledSettingKey = 'ad_block_enabled';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final adBlockEnabledProvider = AsyncNotifierProvider<AdBlockEnabledController, bool>(AdBlockEnabledController.new);

class SettingsRepository {
  const SettingsRepository(this._database);

  final AppDatabase _database;

  Future<bool> isAdBlockEnabled() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.equals(adBlockEnabledSettingKey))).getSingleOrNull();
    return row?.value != 'false';
  }

  Future<void> setAdBlockEnabled(bool enabled) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: adBlockEnabledSettingKey,
            value: enabled ? 'true' : 'false',
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }
}

class AdBlockEnabledController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(settingsRepositoryProvider).isAdBlockEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.value ?? true;
    state = AsyncData(enabled);
    try {
      await ref.read(settingsRepositoryProvider).setAdBlockEnabled(enabled);
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
