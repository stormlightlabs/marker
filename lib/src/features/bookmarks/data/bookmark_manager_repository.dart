import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';
import 'package:uuid/uuid.dart';

final bookmarkManagerRepositoryProvider = Provider<BookmarkManagerRepository>((ref) {
  return BookmarkManagerRepository(ref.watch(databaseProvider));
});

final bookmarkFolderContentsProvider = FutureProvider.autoDispose.family<BookmarkFolderContents, String?>((
  ref,
  folderId,
) {
  return ref.watch(bookmarkManagerRepositoryProvider).loadFolderContents(folderId: folderId);
});

final bookmarkDetailProvider = FutureProvider.autoDispose.family<BookmarkDetail?, String>((ref, id) {
  return ref.watch(bookmarkManagerRepositoryProvider).loadDetail(id);
});

final bookmarksExportProvider = FutureProvider.autoDispose.family<String, List<String>?>((ref, selectedIds) {
  return ref.watch(bookmarkManagerRepositoryProvider).exportNetscapeBookmarks(selectedIds: selectedIds);
});

class BookmarkManagerRepository {
  BookmarkManagerRepository(this._database, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final Uuid _uuid;
  final DateTime Function() _now;
  final HtmlEscape _htmlEscape = const HtmlEscape(HtmlEscapeMode.attribute);

  Future<BookmarkFolderContents> loadFolderContents({String? folderId}) async {
    final folder = folderId == null ? null : await _folder(folderId);
    if (folderId != null && folder == null) {
      return const BookmarkFolderContents(folder: null, folders: [], bookmarks: []);
    }

    final folderRows =
        await (_database.select(_database.bookmarkFolders)
              ..where((folder) => folder.parentId.equalsNullable(folderId))
              ..orderBy([(folder) => OrderingTerm.asc(folder.title)]))
            .get();
    final bookmarkRows =
        await (_database.select(_database.bookmarks)
              ..where((bookmark) => bookmark.folderId.equalsNullable(folderId))
              ..orderBy([(bookmark) => OrderingTerm.desc(bookmark.createdAt)]))
            .get();

    return BookmarkFolderContents(
      folder: folder == null ? null : BookmarkFolderItem.fromRow(folder),
      folders: folderRows.map(BookmarkFolderItem.fromRow).toList(growable: false),
      bookmarks: bookmarkRows.map(BookmarkItem.fromRow).toList(growable: false),
    );
  }

  Future<BookmarkDetail?> loadDetail(String id) async {
    final folder = await _folder(id);
    if (folder != null) {
      return BookmarkDetail.folder(BookmarkFolderItem.fromRow(folder));
    }

    final bookmark = await (_database.select(
      _database.bookmarks,
    )..where((bookmark) => bookmark.id.equals(id))).getSingleOrNull();
    if (bookmark != null) {
      return BookmarkDetail.bookmark(BookmarkItem.fromRow(bookmark));
    }

    return null;
  }

  Future<BookmarkFolderItem> createFolder({required String title, String? parentId}) async {
    final normalizedTitle = _normalizeRequiredTitle(title);
    final folder = BookmarkFoldersCompanion.insert(
      id: _uuid.v4(),
      parentId: Value(parentId),
      title: normalizedTitle,
      createdAt: _now(),
      updatedAt: _now(),
    );
    await _database.into(_database.bookmarkFolders).insert(folder);
    return BookmarkFolderItem(
      id: folder.id.value,
      parentId: parentId,
      title: normalizedTitle,
      createdAt: folder.createdAt.value,
      updatedAt: folder.updatedAt.value,
    );
  }

  Future<void> updateFolder({required String id, required String title}) async {
    await (_database.update(_database.bookmarkFolders)..where((folder) => folder.id.equals(id))).write(
      BookmarkFoldersCompanion(title: Value(_normalizeRequiredTitle(title)), updatedAt: Value(_now())),
    );
  }

  Future<void> updateBookmark({required String id, required String title}) async {
    await (_database.update(
      _database.bookmarks,
    )..where((bookmark) => bookmark.id.equals(id))).write(BookmarksCompanion(title: Value(_normalize(title))));
  }

  Future<void> moveBookmark({required String bookmarkId, required String? folderId}) async {
    await (_database.update(
      _database.bookmarks,
    )..where((bookmark) => bookmark.id.equals(bookmarkId))).write(BookmarksCompanion(folderId: Value(folderId)));
  }

  Future<String> exportNetscapeBookmarks({List<String>? selectedIds}) async {
    final selected = selectedIds == null || selectedIds.isEmpty ? null : selectedIds.toSet();
    final folders = await _database.select(_database.bookmarkFolders).get();
    final bookmarks = await _database.select(_database.bookmarks).get();
    final selectedFolderIds = selected == null
        ? null
        : folders.where((folder) => selected.contains(folder.id)).map((f) => f.id).toSet();
    final selectedBookmarkIds = selected == null
        ? null
        : bookmarks.where((bookmark) => selected.contains(bookmark.id)).map((b) => b.id).toSet();

    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
      ..writeln('<!-- This is an automatically generated file. -->')
      ..writeln('<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">')
      ..writeln('<TITLE>Bookmarks</TITLE>')
      ..writeln('<H1>Bookmarks</H1>')
      ..writeln()
      ..writeln('<DL><p>');

    _writeFolderContents(
      buffer: buffer,
      parentId: null,
      folders: folders,
      bookmarks: bookmarks,
      selectedFolderIds: selectedFolderIds,
      selectedBookmarkIds: selectedBookmarkIds,
      depth: 0,
    );

    buffer.writeln('</DL><p>');
    return buffer.toString();
  }

  void _writeFolderContents({
    required StringBuffer buffer,
    required String? parentId,
    required List<BookmarkFolder> folders,
    required List<Bookmark> bookmarks,
    required Set<String>? selectedFolderIds,
    required Set<String>? selectedBookmarkIds,
    required int depth,
  }) {
    final childFolders =
        folders
            .where(
              (folder) =>
                  folder.parentId == parentId &&
                  _shouldExportFolder(folder.id, selectedFolderIds, selectedBookmarkIds, folders, bookmarks),
            )
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title));
    final childBookmarks = bookmarks.where((bookmark) {
      if (bookmark.folderId != parentId) {
        return false;
      }
      return selectedBookmarkIds == null || selectedBookmarkIds.contains(bookmark.id);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final folder in childFolders) {
      final indent = '  ' * depth;
      final addDate = _unixSeconds(folder.createdAt);
      final modified = _unixSeconds(folder.updatedAt);
      buffer.writeln('$indent<DT><H3 ADD_DATE="$addDate" LAST_MODIFIED="$modified">${_escape(folder.title)}</H3>');
      buffer.writeln('$indent<DL><p>');
      _writeFolderContents(
        buffer: buffer,
        parentId: folder.id,
        folders: folders,
        bookmarks: bookmarks,
        selectedFolderIds: selectedFolderIds,
        selectedBookmarkIds: selectedBookmarkIds,
        depth: depth + 1,
      );
      buffer.writeln('$indent</DL><p>');
    }

    for (final bookmark in childBookmarks) {
      final indent = '  ' * depth;
      final addDate = _unixSeconds(bookmark.createdAt);
      final title = _normalize(bookmark.title) ?? Uri.tryParse(bookmark.url)?.host ?? bookmark.url;
      buffer.writeln('$indent<DT><A HREF="${_escape(bookmark.url)}" ADD_DATE="$addDate">${_escape(title)}</A>');
    }
  }

  bool _shouldExportFolder(
    String folderId,
    Set<String>? selectedFolderIds,
    Set<String>? selectedBookmarkIds,
    List<BookmarkFolder> folders,
    List<Bookmark> bookmarks,
  ) {
    if (selectedFolderIds == null || selectedFolderIds.contains(folderId)) {
      return true;
    }

    final childFolderIds = folders.where((folder) => folder.parentId == folderId).map((folder) => folder.id);
    return bookmarks.any((bookmark) => bookmark.folderId == folderId && selectedBookmarkIds!.contains(bookmark.id)) ||
        childFolderIds.any(
          (childId) => _shouldExportFolder(childId, selectedFolderIds, selectedBookmarkIds, folders, bookmarks),
        );
  }

  Future<BookmarkFolder?> _folder(String id) {
    return (_database.select(_database.bookmarkFolders)..where((folder) => folder.id.equals(id))).getSingleOrNull();
  }

  int _unixSeconds(DateTime value) => value.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

  String _escape(String value) => _htmlEscape.convert(value);

  String _normalizeRequiredTitle(String title) {
    return _normalize(title) ?? 'Untitled Folder';
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class BookmarkFolderContents {
  const BookmarkFolderContents({required this.folder, required this.folders, required this.bookmarks});

  final BookmarkFolderItem? folder;
  final List<BookmarkFolderItem> folders;
  final List<BookmarkItem> bookmarks;

  bool get isEmpty => folders.isEmpty && bookmarks.isEmpty;
}

class BookmarkFolderItem {
  const BookmarkFolderItem({
    required this.id,
    required this.parentId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookmarkFolderItem.fromRow(BookmarkFolder row) {
    return BookmarkFolderItem(
      id: row.id,
      parentId: row.parentId,
      title: row.title,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  final String id;
  final String? parentId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class BookmarkItem {
  const BookmarkItem({
    required this.id,
    required this.folderId,
    required this.url,
    required this.title,
    required this.createdAt,
  });

  factory BookmarkItem.fromRow(Bookmark row) {
    return BookmarkItem(
      id: row.id,
      folderId: row.folderId,
      url: Uri.parse(row.url),
      title: row.title,
      createdAt: row.createdAt,
    );
  }

  final String id;
  final String? folderId;
  final Uri url;
  final String? title;
  final DateTime createdAt;

  String get displayTitle => title?.trim().isNotEmpty == true ? title!.trim() : url.host;
}

class BookmarkDetail {
  const BookmarkDetail._({required this.folder, required this.bookmark});

  const BookmarkDetail.folder(BookmarkFolderItem folder) : this._(folder: folder, bookmark: null);

  const BookmarkDetail.bookmark(BookmarkItem bookmark) : this._(folder: null, bookmark: bookmark);

  final BookmarkFolderItem? folder;
  final BookmarkItem? bookmark;

  bool get isFolder => folder != null;
}
