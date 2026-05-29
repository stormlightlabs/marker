import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';

void main() {
  test('creates library performance indexes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final rows = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'", readsFrom: const {})
        .get();
    final indexNames = rows.map((row) => row.read<String>('name')).toSet();

    expect(indexNames, contains('idx_annotations_deleted_modified'));
    expect(indexNames, contains('idx_annotations_page_deleted_modified'));
    expect(indexNames, contains('idx_annotation_targets_annotation'));
    expect(indexNames, contains('idx_annotation_bodies_annotation_type'));
    expect(indexNames, contains('idx_bookmarks_deleted_created'));
    expect(indexNames, contains('idx_bookmark_links_bookmark_deleted_order'));
    expect(indexNames, contains('idx_atproto_mirrors_annotation_lookup'));
  });
}
