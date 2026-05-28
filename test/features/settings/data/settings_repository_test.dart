import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase database;
  late SettingsRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = SettingsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('defaults ad blocking to enabled', () async {
    expect(await repository.isAdBlockEnabled(), isTrue);
  });

  test('persists and reloads ad blocking setting', () async {
    await repository.setAdBlockEnabled(false);

    expect(await repository.isAdBlockEnabled(), isFalse);

    await repository.setAdBlockEnabled(true);

    expect(await repository.isAdBlockEnabled(), isTrue);
    final row = await database.select(database.appSettings).getSingle();
    expect(row.key, adBlockEnabledSettingKey);
    expect(row.value, 'true');
  });

  test('defaults fun to enabled and persists changes', () async {
    expect(await repository.isFunEnabled(), isTrue);

    await repository.setFunEnabled(false);

    expect(await repository.isFunEnabled(), isFalse);
    final row = await database.select(database.appSettings).getSingle();
    expect(row.key, funEnabledSettingKey);
    expect(row.value, 'false');
  });
}
