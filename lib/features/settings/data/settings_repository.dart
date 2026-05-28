import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';

const String adBlockEnabledSettingKey = 'ad_block_enabled';
const String funEnabledSettingKey = 'fun_enabled';
const String annotationSyncEnabledSettingKey = 'annotation_sync_enabled';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final adBlockEnabledProvider = AsyncNotifierProvider<AdBlockEnabledController, bool>(AdBlockEnabledController.new);
final funEnabledProvider = AsyncNotifierProvider<FunEnabledController, bool>(FunEnabledController.new);

class SettingsRepository {
  const SettingsRepository(this._database);

  final AppDatabase _database;

  Future<bool> isAdBlockEnabled() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.equals(adBlockEnabledSettingKey))).getSingleOrNull();
    return row?.value != 'false';
  }

  Future<void> setAdBlockEnabled(bool enabled) => _setBool(adBlockEnabledSettingKey, enabled);

  Future<bool> isFunEnabled() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.equals(funEnabledSettingKey))).getSingleOrNull();
    return row?.value != 'false';
  }

  Future<void> setFunEnabled(bool enabled) => _setBool(funEnabledSettingKey, enabled);

  Future<bool> isAnnotationSyncEnabled() async => _getBool(annotationSyncEnabledSettingKey, defaultValue: false);

  Future<void> setAnnotationSyncEnabled(bool enabled) => _setBool(annotationSyncEnabledSettingKey, enabled);

  Future<bool> _getBool(String key, {required bool defaultValue}) async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.equals(key))).getSingleOrNull();
    if (row == null) return defaultValue;
    return row.value == 'true';
  }

  Future<void> _setBool(String key, bool enabled) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: enabled ? 'true' : 'false', updatedAt: DateTime.now().toUtc()),
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

class FunEnabledController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(settingsRepositoryProvider).isFunEnabled();

  Future<void> setEnabled(bool enabled) async {
    final previous = state.value ?? true;
    state = AsyncData(enabled);
    try {
      await ref.read(settingsRepositoryProvider).setFunEnabled(enabled);
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
