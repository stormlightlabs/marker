import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
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
    final rows = await (_database.select(
      _database.bookmarks,
    )..orderBy([(bookmark) => OrderingTerm.desc(bookmark.createdAt)])).get();
    return rows.map(_toDomain).toList(growable: false);
  }

  Future<List<BrowserBookmark>> addBookmark({required Uri url, String? title}) async {
    final existing = await (_database.select(
      _database.bookmarks,
    )..where((bookmark) => bookmark.url.equals(url.toString()))).getSingleOrNull();
    if (existing == null) {
      await _database
          .into(_database.bookmarks)
          .insert(
            BookmarksCompanion.insert(
              id: _uuid.v4(),
              url: url.toString(),
              title: Value(_normalizeTitle(title)),
              sortOrder: Value(await _nextRootSortOrder()),
              createdAt: _now(),
            ),
          );
    } else {
      await (_database.update(_database.bookmarks)..where((bookmark) => bookmark.id.equals(existing.id))).write(
        BookmarksCompanion(title: Value(_normalizeTitle(title) ?? existing.title)),
      );
    }

    return getBookmarks();
  }

  Future<List<BrowserBookmark>> removeBookmark(Uri url) async {
    await (_database.delete(_database.bookmarks)..where((bookmark) => bookmark.url.equals(url.toString()))).go();
    return getBookmarks();
  }

  BrowserBookmark _toDomain(Bookmark bookmark) {
    return BrowserBookmark(
      id: bookmark.id,
      url: Uri.parse(bookmark.url),
      title: bookmark.title,
      createdAt: bookmark.createdAt,
    );
  }

  String? _normalizeTitle(String? title) {
    final trimmed = title?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<int> _nextRootSortOrder() async {
    final rows = await (_database.select(_database.bookmarks)..where((bookmark) => bookmark.folderId.isNull())).get();
    return rows.fold<int>(-1, (max, bookmark) => bookmark.sortOrder > max ? bookmark.sortOrder : max) + 1;
  }
}
