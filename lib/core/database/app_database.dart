import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get url => text().unique()();
  TextColumn get canonicalUrl => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get faviconUrl => text().nullable()();
  TextColumn get faviconFilePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastVisitedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Annotations extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text().references(Pages, #id)();
  TextColumn get motivation => text()();
  TextColumn get marginMetadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AnnotationTargets extends Table {
  TextColumn get id => text()();
  TextColumn get annotationId => text().references(Annotations, #id)();
  TextColumn get sourceUrl => text()();
  TextColumn get sourceHash => text().nullable()();
  TextColumn get selectorJson => text()();
  TextColumn get stateJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AnnotationBodies extends Table {
  TextColumn get id => text()();
  TextColumn get annotationId => text().references(Annotations, #id)();
  TextColumn get type => text()();
  TextColumn get format => text().nullable()();
  TextColumn get value => text()();
  TextColumn get uri => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AnnotationTags extends Table {
  TextColumn get id => text()();
  TextColumn get annotationId => text().references(Annotations, #id)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {annotationId, name},
  ];
}

class AnnotationCollections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AnnotationCollectionItems extends Table {
  TextColumn get id => text()();
  TextColumn get collectionId => text().references(AnnotationCollections, #id)();
  TextColumn get annotationId => text().references(Annotations, #id)();
  IntColumn get position => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {collectionId, annotationId},
  ];
}

class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable().references(BookmarkFolders, #id)();
  TextColumn get url => text().unique()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BookmarkFolders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(BookmarkFolders, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get accessType => text().withDefault(const Constant('CLOSED'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BookmarkCollectionLinks extends Table {
  TextColumn get id => text()();
  TextColumn get bookmarkId => text().references(Bookmarks, #id)();
  TextColumn get folderId => text().references(BookmarkFolders, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {bookmarkId, folderId},
  ];
}

class BrowserHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get canonicalUrl => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get visitedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AtprotoAccounts extends Table {
  TextColumn get did => text()();
  TextColumn get handle => text().nullable()();
  TextColumn get pdsEndpoint => text().nullable()();
  TextColumn get authMethod => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {did};
}

class AtprotoRecordMirrors extends Table {
  TextColumn get id => text()();
  TextColumn get accountDid => text().references(AtprotoAccounts, #did)();
  TextColumn get localTable => text()();
  TextColumn get localId => text()();
  TextColumn get collection => text()();
  TextColumn get rkey => text()();
  TextColumn get uri => text()();
  TextColumn get cid => text().nullable()();
  TextColumn get lastSyncedRecordJson => text().nullable()();
  TextColumn get lastSyncedHash => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get dirtyAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {accountDid, localTable, localId, collection},
    {accountDid, uri},
  ];
}

class AtprotoSyncState extends Table {
  TextColumn get id => text()();
  TextColumn get accountDid => text().references(AtprotoAccounts, #did)();
  TextColumn get collection => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {accountDid, collection},
  ];
}

class AtprotoSyncOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get accountDid => text().references(AtprotoAccounts, #did)();
  TextColumn get operation => text()();
  TextColumn get localTable => text()();
  TextColumn get localId => text()();
  TextColumn get collection => text()();
  TextColumn get payloadJson => text().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Pages,
    Annotations,
    AnnotationTargets,
    AnnotationBodies,
    AnnotationTags,
    AnnotationCollections,
    AnnotationCollectionItems,
    BookmarkFolders,
    Bookmarks,
    BookmarkCollectionLinks,
    BrowserHistoryEntries,
    AtprotoAccounts,
    AtprotoRecordMirrors,
    AtprotoSyncState,
    AtprotoSyncOutbox,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await createLibrarySearchIndex();
      await createPerformanceIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(bookmarks);
      }
      if (from < 3) {
        await m.createTable(browserHistoryEntries);
      }
      if (from < 4) {
        await m.createTable(appSettings);
      }
      if (from < 5) {
        await m.createTable(bookmarkFolders);
        await m.addColumn(bookmarks, bookmarks.folderId);
      }
      if (from < 6) {
        await m.addColumn(bookmarks, bookmarks.sortOrder);
        await m.addColumn(bookmarkFolders, bookmarkFolders.sortOrder);
      }
      if (from < 7) {
        await m.addColumn(pages, pages.faviconUrl);
        await m.addColumn(pages, pages.faviconFilePath);
      }
      if (from < 8) {
        await m.addColumn(pages, pages.description);
        await m.addColumn(browserHistoryEntries, browserHistoryEntries.description);
      }
      if (from < 9) {
        await createLibrarySearchIndex();
      }
      if (from < 10) {
        await _upgradeToV10(m);
      }
      if (from < 11) {
        await _upgradeToV11(m);
      }
      if (from < 12) {
        await m.addColumn(bookmarks, bookmarks.description);
      }
      if (from < 13) {
        await m.addColumn(annotations, annotations.marginMetadataJson);
        await m.addColumn(annotationTargets, annotationTargets.sourceHash);
        await m.addColumn(annotationTargets, annotationTargets.stateJson);
        await m.addColumn(annotationBodies, annotationBodies.uri);
      }
      if (from < 14) {
        await m.createTable(annotationTags);
        await m.createTable(annotationCollections);
        await m.createTable(annotationCollectionItems);
      }
      if (from < 15) {
        await createPerformanceIndexes();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await createLibrarySearchIndex();
      await createPerformanceIndexes();
    },
  );

  Future<void> _upgradeToV10(Migrator m) async {
    await customStatement('ALTER TABLE bookmarks ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0');
    await m.addColumn(bookmarks, bookmarks.deletedAt);
    await m.addColumn(bookmarkFolders, bookmarkFolders.description);
    await m.addColumn(bookmarkFolders, bookmarkFolders.accessType);
    await m.addColumn(bookmarkFolders, bookmarkFolders.deletedAt);
    await m.createTable(bookmarkCollectionLinks);
    await customStatement('UPDATE bookmarks SET updated_at = created_at WHERE updated_at = 0');
    await customStatement('''
INSERT OR IGNORE INTO bookmark_collection_links (
  id,
  bookmark_id,
  folder_id,
  sort_order,
  created_at,
  updated_at,
  deleted_at
)
SELECT
  'backfill-' || id,
  id,
  folder_id,
  sort_order,
  created_at,
  created_at,
  NULL
FROM bookmarks
WHERE folder_id IS NOT NULL
''');
  }

  Future<void> _upgradeToV11(Migrator m) async {
    await m.createTable(atprotoAccounts);
    await m.createTable(atprotoRecordMirrors);
    await m.createTable(atprotoSyncState);
    await m.createTable(atprotoSyncOutbox);
  }

  Future<void> createLibrarySearchIndex() {
    return customStatement('''
CREATE VIRTUAL TABLE IF NOT EXISTS library_search_fts USING fts5(
  document_type UNINDEXED,
  document_id UNINDEXED,
  page_id UNINDEXED,
  title,
  url,
  description,
  folder_path,
  annotation_text,
  note_text,
  tokenize = 'unicode61'
)
''');
  }

  Future<void> createPerformanceIndexes() async {
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_annotations_deleted_modified
ON annotations(deleted_at, modified_at DESC)
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_annotations_page_deleted_modified
ON annotations(page_id, deleted_at, modified_at DESC)
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_annotation_targets_annotation
ON annotation_targets(annotation_id)
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_annotation_bodies_annotation_type
ON annotation_bodies(annotation_id, type)
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_bookmarks_deleted_created
ON bookmarks(deleted_at, created_at DESC)
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_bookmark_links_bookmark_deleted_order
ON bookmark_collection_links(bookmark_id, deleted_at, sort_order, created_at)
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_atproto_mirrors_annotation_lookup
ON atproto_record_mirrors(local_id, local_table, collection, deleted_at, last_synced_at)
''');
  }
}
