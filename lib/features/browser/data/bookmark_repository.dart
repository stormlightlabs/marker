import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/browser/domain/reader_session_state.dart';
import 'package:uuid/uuid.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(databaseProvider));
});

class BookmarkRepository {
  BookmarkRepository(this._database, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<List<BrowserBookmark>> getBookmarks() async {
    final rows =
        await (_database.select(_database.bookmarks)
              ..where((bookmark) => bookmark.deletedAt.isNull())
              ..orderBy([(bookmark) => OrderingTerm.desc(bookmark.createdAt)]))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  Future<List<BrowserBookmark>> addBookmark({required Uri url, String? title}) async {
    final existing = await (_database.select(
      _database.bookmarks,
    )..where((bookmark) => bookmark.url.equals(url.toString()))).getSingleOrNull();
    if (existing == null) {
      final now = _now();
      await _database
          .into(_database.bookmarks)
          .insert(
            BookmarksCompanion.insert(
              id: _uuid.v4(),
              url: url.toString(),
              title: Value(normalize(title)),
              sortOrder: Value(await _nextRootSortOrder()),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(_database.bookmarks)..where((bookmark) => bookmark.id.equals(existing.id))).write(
        BookmarksCompanion(title: Value(normalize(title) ?? existing.title), updatedAt: Value(_now())),
      );
    }

    return getBookmarks();
  }

  Future<List<BrowserBookmark>> removeBookmark(Uri url) async {
    final bookmark = await (_database.select(
      _database.bookmarks,
    )..where((row) => row.url.equals(url.toString()))).getSingleOrNull();
    if (bookmark != null) {
      await (_database.delete(
        _database.bookmarkCollectionLinks,
      )..where((link) => link.bookmarkId.equals(bookmark.id))).go();
      await (_database.delete(_database.bookmarks)..where((row) => row.id.equals(bookmark.id))).go();
    }
    return getBookmarks();
  }

  BrowserBookmark _toDomain(Bookmark bookmark) => BrowserBookmark(
    id: bookmark.id,
    url: Uri.parse(bookmark.url),
    title: bookmark.title,
    createdAt: bookmark.createdAt,
  );

  Future<int> _nextRootSortOrder() async {
    final links = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((link) => link.deletedAt.isNull())).get();
    final linkedBookmarkIds = links.map((link) => link.bookmarkId).toSet();
    final rows = await (_database.select(_database.bookmarks)..where((bookmark) => bookmark.deletedAt.isNull())).get();
    return rows
            .where((bookmark) => !linkedBookmarkIds.contains(bookmark.id))
            .fold<int>(-1, (max, bookmark) => bookmark.sortOrder > max ? bookmark.sortOrder : max) +
        1;
  }
}
