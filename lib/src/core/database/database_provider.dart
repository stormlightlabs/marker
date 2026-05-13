import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(_openConnection());
  ref.onDispose(database.close);
  return database;
});

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'marker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
