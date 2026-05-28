import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/semble_sync_constants.dart';
import 'package:uuid/uuid.dart';

final bookmarkManagerRepositoryProvider = Provider<BookmarkManagerRepository>((ref) {
  return BookmarkManagerRepository(
    ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
  );
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

enum BookmarkEntryType {
  folder,
  bookmark;

  factory BookmarkEntryType.fromName(String name) => switch (name) {
    'folder' => BookmarkEntryType.folder,
    'bookmark' => BookmarkEntryType.bookmark,
    _ => throw FormatException('Invalid bookmark entry type: $name'),
  };
}

class BookmarkEntryRef {
  const BookmarkEntryRef({required this.type, required this.id});

  factory BookmarkEntryRef.fromKey(String key) {
    final separator = key.indexOf(':');
    if (separator <= 0) {
      throw FormatException('Invalid bookmark entry key: $key');
    }
    final typeName = key.substring(0, separator);
    final id = key.substring(separator + 1);
    return BookmarkEntryRef(type: BookmarkEntryType.fromName(typeName), id: id);
  }

  final BookmarkEntryType type;
  final String id;

  String get key => '${type.name}:$id';
}

class BookmarkManagerRepository {
  BookmarkManagerRepository(
    this._database, {
    AtprotoSyncRepository? syncRepository,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _syncRepository = syncRepository,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final AtprotoSyncRepository? _syncRepository;
  final Uuid _uuid;
  final DateTime Function() _now;
  final HtmlEscape _htmlEscape = const HtmlEscape(HtmlEscapeMode.attribute);

  Future<BookmarkFolderContents> loadFolderContents({String? folderId}) async {
    final folder = folderId == null ? null : await _folder(folderId);
    if (folderId != null && folder == null) {
      return const BookmarkFolderContents(folder: null, folders: [], bookmarks: [], items: []);
    }

    final folderRows = await (_database.select(
      _database.bookmarkFolders,
    )..where((folder) => folder.parentId.equalsNullable(folderId) & folder.deletedAt.isNull())).get();
    final bookmarkRows = await _bookmarkRowsForFolder(folderId);
    final folders = folderRows.map(BookmarkFolderItem.fromRow).toList(growable: false);
    final bookmarks = bookmarkRows
        .map((entry) => BookmarkItem.fromRow(entry.bookmark, folderId: folderId, sortOrder: entry.sortOrder))
        .toList(growable: false);
    final items = <BookmarkListItem>[
      ...folders.map(BookmarkListItem.folder),
      ...bookmarks.map(BookmarkListItem.bookmark),
    ]..sort(_compareListItems);

    return BookmarkFolderContents(
      folder: folder == null ? null : BookmarkFolderItem.fromRow(folder),
      folders: folders,
      bookmarks: bookmarks,
      items: items,
    );
  }

  Future<BookmarkDetail?> loadDetail(String id) async {
    final folder = await _folder(id);
    if (folder != null) {
      return BookmarkDetail.folder(BookmarkFolderItem.fromRow(folder));
    }

    final bookmark = await (_database.select(
      _database.bookmarks,
    )..where((bookmark) => bookmark.id.equals(id) & bookmark.deletedAt.isNull())).getSingleOrNull();
    if (bookmark != null) {
      return BookmarkDetail.bookmark(BookmarkItem.fromRow(bookmark, folderId: await _bookmarkFolderId(bookmark.id)));
    }

    return null;
  }

  Future<List<BookmarkFolderItem>> loadFolders() async {
    final rows = await (_database.select(
      _database.bookmarkFolders,
    )..where((folder) => folder.deletedAt.isNull())).get();
    return rows.map(BookmarkFolderItem.fromRow).toList(growable: false)..sort((a, b) => a.title.compareTo(b.title));
  }

  Future<BookmarkFolderItem> createFolder({required String title, String? parentId}) async {
    final normalizedTitle = _normalizeRequiredTitle(title);
    final now = _now();
    final folder = BookmarkFoldersCompanion.insert(
      id: _uuid.v4(),
      parentId: Value(parentId),
      title: normalizedTitle,
      sortOrder: Value(await _nextSortOrder(parentId)),
      createdAt: now,
      updatedAt: now,
    );
    await _database.transaction(() async {
      await _database.into(_database.bookmarkFolders).insert(folder);
      await _enqueueFolderChange(folder.id.value);
    });
    return BookmarkFolderItem(
      id: folder.id.value,
      parentId: parentId,
      title: normalizedTitle,
      sortOrder: folder.sortOrder.value,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateFolder({required String id, required String title}) async {
    await _database.transaction(() async {
      await (_database.update(_database.bookmarkFolders)..where((folder) => folder.id.equals(id))).write(
        BookmarkFoldersCompanion(title: Value(_normalizeRequiredTitle(title)), updatedAt: Value(_now())),
      );
      await _enqueueFolderChange(id);
    });
  }

  Future<void> updateBookmark({required String id, required String title}) async {
    await _database.transaction(() async {
      await (_database.update(_database.bookmarks)..where((bookmark) => bookmark.id.equals(id))).write(
        BookmarksCompanion(title: Value(normalize(title)), updatedAt: Value(_now())),
      );
      await _enqueueBookmarkChange(id);
    });
  }

  Future<void> moveBookmark({required String bookmarkId, required String? folderId}) async => moveEntry(
    BookmarkEntryRef(type: BookmarkEntryType.bookmark, id: bookmarkId),
    folderId: folderId,
  );

  Future<void> moveEntry(BookmarkEntryRef entry, {required String? folderId}) async {
    final sortOrder = await _nextSortOrder(folderId);
    switch (entry.type) {
      case BookmarkEntryType.bookmark:
        await _replaceBookmarkMembership(bookmarkId: entry.id, folderId: folderId, sortOrder: sortOrder);
      case BookmarkEntryType.folder:
        if (entry.id == folderId || await _isDescendantFolder(folderId, entry.id)) {
          throw ArgumentError.value(folderId, 'folderId', 'Cannot move a folder into itself or its descendants.');
        }
        await _database.transaction(() async {
          await (_database.update(_database.bookmarkFolders)..where((folder) => folder.id.equals(entry.id))).write(
            BookmarkFoldersCompanion(parentId: Value(folderId), sortOrder: Value(sortOrder), updatedAt: Value(_now())),
          );
          await _enqueueFolderChange(entry.id);
        });
    }
  }

  Future<void> moveEntries(Iterable<BookmarkEntryRef> entries, {required String? folderId}) async {
    for (final entry in entries) {
      await moveEntry(entry, folderId: folderId);
    }
  }

  Future<void> reorderEntries({required String? folderId, required List<BookmarkEntryRef> entries}) async {
    await _database.transaction(() async {
      for (final MapEntry(key: index, value: entry) in entries.asMap().entries) {
        switch (entry.type) {
          case BookmarkEntryType.folder:
            await (_database.update(_database.bookmarkFolders)..where((folder) => folder.id.equals(entry.id))).write(
              BookmarkFoldersCompanion(parentId: Value(folderId), sortOrder: Value(index), updatedAt: Value(_now())),
            );
            await _enqueueFolderChange(entry.id);
          case BookmarkEntryType.bookmark:
            await _replaceBookmarkMembership(bookmarkId: entry.id, folderId: folderId, sortOrder: index);
        }
      }
    });
  }

  Future<void> deleteEntries(Iterable<BookmarkEntryRef> entries) async {
    await _database.transaction(() async {
      for (final entry in entries) {
        switch (entry.type) {
          case BookmarkEntryType.bookmark:
            await (_database.delete(
              _database.bookmarkCollectionLinks,
            )..where((link) => link.bookmarkId.equals(entry.id))).go();
            await (_database.delete(_database.bookmarks)..where((bookmark) => bookmark.id.equals(entry.id))).go();
          case BookmarkEntryType.folder:
            await _deleteFolderTree(entry.id);
        }
      }
    });
  }

  Future<String> exportNetscapeBookmarks({List<String>? selectedIds}) async {
    final selected = selectedIds == null || selectedIds.isEmpty ? null : selectedIds.toSet();
    final folders = await (_database.select(
      _database.bookmarkFolders,
    )..where((folder) => folder.deletedAt.isNull())).get();
    final bookmarks = await (_database.select(
      _database.bookmarks,
    )..where((bookmark) => bookmark.deletedAt.isNull())).get();
    final links = await _activeLinks();
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
      links: links,
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
    required List<BookmarkCollectionLink> links,
    required Set<String>? selectedFolderIds,
    required Set<String>? selectedBookmarkIds,
    required int depth,
  }) {
    final childFolders =
        folders
            .where(
              (folder) =>
                  folder.parentId == parentId &&
                  _shouldExportFolder(folder.id, selectedFolderIds, selectedBookmarkIds, folders, bookmarks, links),
            )
            .toList()
          ..sort((a, b) => _compareRows(a.sortOrder, a.title, b.sortOrder, b.title));
    final childBookmarks =
        bookmarks.where((bookmark) {
          if (!_bookmarkInFolder(bookmark.id, parentId, links)) {
            return false;
          }
          return selectedBookmarkIds == null || selectedBookmarkIds.contains(bookmark.id);
        }).toList()..sort(
          (a, b) => _compareRows(
            _sortOrderInFolder(a, parentId, links),
            a.title ?? a.url,
            _sortOrderInFolder(b, parentId, links),
            b.title ?? b.url,
          ),
        );

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
        links: links,
        selectedFolderIds: selectedFolderIds,
        selectedBookmarkIds: selectedBookmarkIds,
        depth: depth + 1,
      );
      buffer.writeln('$indent</DL><p>');
    }

    for (final bookmark in childBookmarks) {
      final indent = '  ' * depth;
      final addDate = _unixSeconds(bookmark.createdAt);
      final title = normalize(bookmark.title) ?? Uri.tryParse(bookmark.url)?.host ?? bookmark.url;
      buffer.writeln('$indent<DT><A HREF="${_escape(bookmark.url)}" ADD_DATE="$addDate">${_escape(title)}</A>');
    }
  }

  bool _shouldExportFolder(
    String folderId,
    Set<String>? selectedFolderIds,
    Set<String>? selectedBookmarkIds,
    List<BookmarkFolder> folders,
    List<Bookmark> bookmarks,
    List<BookmarkCollectionLink> links,
  ) {
    if (selectedFolderIds == null || selectedFolderIds.contains(folderId)) {
      return true;
    }

    final childFolderIds = folders.where((folder) => folder.parentId == folderId).map((folder) => folder.id);
    return bookmarks.any(
          (bookmark) => _bookmarkInFolder(bookmark.id, folderId, links) && selectedBookmarkIds!.contains(bookmark.id),
        ) ||
        childFolderIds.any(
          (childId) => _shouldExportFolder(childId, selectedFolderIds, selectedBookmarkIds, folders, bookmarks, links),
        );
  }

  Future<void> _deleteFolderTree(String folderId) async {
    final children = await (_database.select(
      _database.bookmarkFolders,
    )..where((folder) => folder.parentId.equals(folderId))).get();
    for (final child in children) {
      await _deleteFolderTree(child.id);
    }
    final links = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((link) => link.folderId.equals(folderId))).get();
    await (_database.delete(_database.bookmarkCollectionLinks)..where((link) => link.folderId.equals(folderId))).go();
    for (final link in links) {
      final remainingLinks = await (_database.select(
        _database.bookmarkCollectionLinks,
      )..where((row) => row.bookmarkId.equals(link.bookmarkId))).get();
      if (remainingLinks.isEmpty) {
        await (_database.delete(_database.bookmarks)..where((bookmark) => bookmark.id.equals(link.bookmarkId))).go();
      }
    }
    await (_database.delete(_database.bookmarkFolders)..where((folder) => folder.id.equals(folderId))).go();
  }

  Future<int> _nextSortOrder(String? folderId) async {
    final folders = await (_database.select(
      _database.bookmarkFolders,
    )..where((folder) => folder.parentId.equalsNullable(folderId) & folder.deletedAt.isNull())).get();
    final bookmarkEntries = await _bookmarkRowsForFolder(folderId);
    final folderMax = folders.fold<int>(-1, (max, folder) => folder.sortOrder > max ? folder.sortOrder : max);
    final bookmarkMax = bookmarkEntries.fold<int>(-1, (max, entry) => entry.sortOrder > max ? entry.sortOrder : max);
    return (folderMax > bookmarkMax ? folderMax : bookmarkMax) + 1;
  }

  Future<List<_BookmarkFolderEntry>> _bookmarkRowsForFolder(String? folderId) async {
    final bookmarks = await (_database.select(
      _database.bookmarks,
    )..where((bookmark) => bookmark.deletedAt.isNull())).get();
    final links = await _activeLinks();
    if (folderId == null) {
      final linkedBookmarkIds = links.map((link) => link.bookmarkId).toSet();
      return [
        for (final bookmark in bookmarks)
          if (!linkedBookmarkIds.contains(bookmark.id))
            _BookmarkFolderEntry(bookmark: bookmark, sortOrder: bookmark.sortOrder),
      ];
    }

    final linksByBookmarkId = {
      for (final link in links.where((link) => link.folderId == folderId)) link.bookmarkId: link,
    };
    return [
      for (final bookmark in bookmarks)
        if (linksByBookmarkId[bookmark.id] case final link?)
          _BookmarkFolderEntry(bookmark: bookmark, sortOrder: link.sortOrder),
    ];
  }

  Future<List<BookmarkCollectionLink>> _activeLinks() {
    return (_database.select(_database.bookmarkCollectionLinks)..where((link) => link.deletedAt.isNull())).get();
  }

  Future<String?> _bookmarkFolderId(String bookmarkId) async {
    final link =
        await (_database.select(_database.bookmarkCollectionLinks)
              ..where((row) => row.bookmarkId.equals(bookmarkId) & row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder), (row) => OrderingTerm.asc(row.createdAt)]))
            .getSingleOrNull();
    return link?.folderId;
  }

  Future<void> addBookmarkToFolder({required String bookmarkId, required String folderId}) async {
    await _database.transaction(() async {
      await _upsertBookmarkLink(bookmarkId: bookmarkId, folderId: folderId, sortOrder: await _nextSortOrder(folderId));
    });
  }

  Future<void> _replaceBookmarkMembership({
    required String bookmarkId,
    required String? folderId,
    required int sortOrder,
  }) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.bookmarkCollectionLinks,
      )..where((link) => link.bookmarkId.equals(bookmarkId))).go();
      if (folderId == null) {
        await (_database.update(_database.bookmarks)..where((bookmark) => bookmark.id.equals(bookmarkId))).write(
          BookmarksCompanion(sortOrder: Value(sortOrder), updatedAt: Value(_now())),
        );
        return;
      }
      await _upsertBookmarkLink(bookmarkId: bookmarkId, folderId: folderId, sortOrder: sortOrder);
    });
  }

  Future<void> _upsertBookmarkLink({
    required String bookmarkId,
    required String folderId,
    required int sortOrder,
  }) async {
    final now = _now();
    final insertedId = _uuid.v4();
    await _database
        .into(_database.bookmarkCollectionLinks)
        .insert(
          BookmarkCollectionLinksCompanion.insert(
            id: insertedId,
            bookmarkId: bookmarkId,
            folderId: folderId,
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await (_database.update(_database.bookmarkCollectionLinks)
          ..where((link) => link.bookmarkId.equals(bookmarkId) & link.folderId.equals(folderId)))
        .write(BookmarkCollectionLinksCompanion(sortOrder: Value(sortOrder), updatedAt: Value(now)));
    final link = await (_database.select(
      _database.bookmarkCollectionLinks,
    )..where((row) => row.bookmarkId.equals(bookmarkId) & row.folderId.equals(folderId))).getSingle();
    await (_database.update(
      _database.bookmarks,
    )..where((bookmark) => bookmark.id.equals(bookmarkId))).write(BookmarksCompanion(updatedAt: Value(now)));
    await _enqueueBookmarkChange(bookmarkId);
    await _enqueueLinkChange(link.id);
  }

  Future<void> _enqueueBookmarkChange(String bookmarkId) async {
    await _syncRepository?.enqueueLocalChangeForAllAccounts(
      localTable: SembleSyncLocalTable.bookmarks.value,
      localId: bookmarkId,
      collection: SembleSyncCollection.card.value,
    );
  }

  Future<void> _enqueueFolderChange(String folderId) async => await _syncRepository?.enqueueLocalChangeForAllAccounts(
    localTable: SembleSyncLocalTable.bookmarkFolders.value,
    localId: folderId,
    collection: SembleSyncCollection.collection.value,
  );

  Future<void> _enqueueLinkChange(String linkId) async => await _syncRepository?.enqueueLocalChangeForAllAccounts(
    localTable: SembleSyncLocalTable.bookmarkCollectionLinks.value,
    localId: linkId,
    collection: SembleSyncCollection.collectionLink.value,
  );

  bool _bookmarkInFolder(String bookmarkId, String? folderId, List<BookmarkCollectionLink> links) => (folderId == null)
      ? !links.any((link) => link.bookmarkId == bookmarkId)
      : links.any((link) => link.bookmarkId == bookmarkId && link.folderId == folderId);

  int _sortOrderInFolder(Bookmark bookmark, String? folderId, List<BookmarkCollectionLink> links) => folderId == null
      ? bookmark.sortOrder
      : links
            .where((link) => link.bookmarkId == bookmark.id && link.folderId == folderId)
            .fold<int>(bookmark.sortOrder, (sortOrder, link) => link.sortOrder);

  Future<bool> _isDescendantFolder(String? candidateFolderId, String ancestorFolderId) async {
    var currentId = candidateFolderId;
    while (currentId != null) {
      if (currentId == ancestorFolderId) {
        return true;
      }
      currentId = (await _folder(currentId))?.parentId;
    }
    return false;
  }

  Future<BookmarkFolder?> _folder(String id) {
    return (_database.select(_database.bookmarkFolders)..where((folder) => folder.id.equals(id))).getSingleOrNull();
  }

  int _compareListItems(BookmarkListItem a, BookmarkListItem b) {
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) {
      return order;
    }
    if (a.type != b.type) {
      return a.type == BookmarkEntryType.folder ? -1 : 1;
    }
    return a.title.compareTo(b.title);
  }

  int _compareRows(int aSortOrder, String aTitle, int bSortOrder, String bTitle) {
    final order = aSortOrder.compareTo(bSortOrder);
    return order == 0 ? aTitle.compareTo(bTitle) : order;
  }

  int _unixSeconds(DateTime value) => value.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

  String _escape(String value) => _htmlEscape.convert(value);

  String _normalizeRequiredTitle(String title) => normalize(title) ?? 'Untitled Folder';
}

class _BookmarkFolderEntry {
  const _BookmarkFolderEntry({required this.bookmark, required this.sortOrder});

  final Bookmark bookmark;
  final int sortOrder;
}

class BookmarkFolderContents {
  const BookmarkFolderContents({
    required this.folder,
    required this.folders,
    required this.bookmarks,
    required this.items,
  });

  final BookmarkFolderItem? folder;
  final List<BookmarkFolderItem> folders;
  final List<BookmarkItem> bookmarks;
  final List<BookmarkListItem> items;

  bool get isEmpty => items.isEmpty;
}

class BookmarkListItem {
  const BookmarkListItem._({required this.folder, required this.bookmark});

  const BookmarkListItem.folder(BookmarkFolderItem folder) : this._(folder: folder, bookmark: null);

  const BookmarkListItem.bookmark(BookmarkItem bookmark) : this._(folder: null, bookmark: bookmark);

  final BookmarkFolderItem? folder;
  final BookmarkItem? bookmark;

  BookmarkEntryType get type => folder == null ? BookmarkEntryType.bookmark : BookmarkEntryType.folder;

  String get id => folder?.id ?? bookmark!.id;

  String? get parentId => folder?.parentId ?? bookmark?.folderId;

  int get sortOrder => folder?.sortOrder ?? bookmark!.sortOrder;

  String get title => folder?.title ?? bookmark!.displayTitle;

  String get subtitle => folder == null ? bookmark!.url.toString() : 'Folder';

  BookmarkEntryRef get ref => BookmarkEntryRef(type: type, id: id);

  String get key => ref.key;
}

class BookmarkFolderItem {
  const BookmarkFolderItem({
    required this.id,
    required this.parentId,
    required this.title,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookmarkFolderItem.fromRow(BookmarkFolder row) => BookmarkFolderItem(
    id: row.id,
    parentId: row.parentId,
    title: row.title,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  final String id;
  final String? parentId;
  final String title;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class BookmarkItem {
  const BookmarkItem({
    required this.id,
    required this.folderId,
    required this.url,
    required this.title,
    required this.sortOrder,
    required this.createdAt,
  });

  factory BookmarkItem.fromRow(Bookmark row, {String? folderId, int? sortOrder}) => BookmarkItem(
    id: row.id,
    folderId: folderId,
    url: Uri.parse(row.url),
    title: row.title,
    sortOrder: sortOrder ?? row.sortOrder,
    createdAt: row.createdAt,
  );

  final String id;
  final String? folderId;
  final Uri url;
  final String? title;
  final int sortOrder;
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
