import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get url => text().unique()();
  TextColumn get canonicalUrl => text().nullable()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastVisitedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Annotations extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text().references(Pages, #id)();
  TextColumn get motivation => text()();
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
  TextColumn get selectorJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AnnotationBodies extends Table {
  TextColumn get id => text()();
  TextColumn get annotationId => text().references(Annotations, #id)();
  TextColumn get type => text()();
  TextColumn get format => text().nullable()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable().references(BookmarkFolders, #id)();
  TextColumn get url => text().unique()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BookmarkFolders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(BookmarkFolders, #id)();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BrowserHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get canonicalUrl => text().nullable()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get visitedAt => dateTime()();

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
    BookmarkFolders,
    Bookmarks,
    BrowserHistoryEntries,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
