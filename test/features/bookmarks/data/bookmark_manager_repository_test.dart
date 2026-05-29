import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/bookmarks/data/bookmark_manager_repository.dart';

void main() {
  late AppDatabase database;
  late BookmarkManagerRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = BookmarkManagerRepository(database, now: () => DateTime.utc(2026, 5, 13, 12));
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and lists bookmark folders with root bookmarks', () async {
    await _insertBookmark(database, id: 'bookmark', url: 'https://example.com', title: 'Example');
    final folder = await repository.createFolder(title: 'Programming');
    final contents = await repository.loadFolderContents();

    expect(contents.folders.single.id, folder.id);
    expect(contents.folders.single.title, 'Programming');
    expect(contents.bookmarks.single.displayTitle, 'Example');
  });

  test('updates folders and bookmark titles', () async {
    final folder = await repository.createFolder(title: ' Programming ');
    await _insertBookmark(database, id: 'bookmark', url: 'https://example.com', title: 'Example');

    await repository.updateFolder(id: folder.id, title: 'Docs');
    await repository.updateBookmark(id: 'bookmark', title: 'Example Docs');

    final updatedFolder = await repository.loadDetail(folder.id);
    final updatedBookmark = await repository.loadDetail('bookmark');
    expect(updatedFolder?.folder?.title, 'Docs');
    expect(updatedBookmark?.bookmark?.displayTitle, 'Example Docs');
  });

  test('moves bookmarks into a folder', () async {
    final folder = await repository.createFolder(title: 'Programming');
    await _insertBookmark(database, id: 'bookmark', url: 'https://dart.dev', title: 'Dart');
    await repository.moveBookmark(bookmarkId: 'bookmark', folderId: folder.id);

    final rootContents = await repository.loadFolderContents();
    final folderContents = await repository.loadFolderContents(folderId: folder.id);
    expect(rootContents.bookmarks, isEmpty);
    expect(folderContents.folder?.title, 'Programming');
    expect(folderContents.bookmarks.single.url, Uri.parse('https://dart.dev'));
  });

  test('reorders mixed folder and bookmark entries', () async {
    final folder = await repository.createFolder(title: 'Programming');
    await _insertBookmark(database, id: 'bookmark', url: 'https://dart.dev', title: 'Dart');
    await repository.reorderEntries(
      folderId: null,
      entries: [
        const BookmarkEntryRef(type: BookmarkEntryType.bookmark, id: 'bookmark'),
        BookmarkEntryRef(type: BookmarkEntryType.folder, id: folder.id),
      ],
    );

    final contents = await repository.loadFolderContents();
    expect(contents.items.map((item) => item.title), ['Dart', 'Programming']);
  });

  test('moves folders and prevents folder cycles', () async {
    final parent = await repository.createFolder(title: 'Parent');
    final child = await repository.createFolder(title: 'Child', parentId: parent.id);

    expect(
      () => repository.moveEntry(
        BookmarkEntryRef(type: BookmarkEntryType.folder, id: parent.id),
        folderId: child.id,
      ),
      throwsArgumentError,
    );

    await repository.moveEntry(BookmarkEntryRef(type: BookmarkEntryType.folder, id: child.id), folderId: null);
    final rootContents = await repository.loadFolderContents();
    expect(rootContents.folders.map((folder) => folder.title), contains('Child'));
  });

  test('groups Semble-backed bookmark entries before local entries', () async {
    final syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 13, 12));
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    await _insertBookmark(database, id: 'local', url: 'https://local.example', title: 'Local');
    await _insertBookmark(database, id: 'remote', url: 'https://remote.example', title: 'Remote');
    await syncRepository.upsertMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'remote',
      collection: SembleSyncCollection.card.value,
      rkey: 'remote',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/remote',
      lastSyncedAt: DateTime.utc(2026, 5, 13, 12),
    );

    final contents = await repository.loadFolderContents();
    expect(contents.items.map((item) => item.title), ['Remote', 'Local']);
    expect(contents.items.first.isSembleBacked, isTrue);
    expect(contents.items.last.isSembleBacked, isFalse);
  });

  test('supports bookmark membership in multiple folders', () async {
    final first = await repository.createFolder(title: 'Programming');
    final second = await repository.createFolder(title: 'Research');
    await _insertBookmark(database, id: 'bookmark', url: 'https://dart.dev', title: 'Dart');
    await repository.addBookmarkToFolder(bookmarkId: 'bookmark', folderId: first.id);
    await repository.addBookmarkToFolder(bookmarkId: 'bookmark', folderId: second.id);

    final firstContents = await repository.loadFolderContents(folderId: first.id);
    final secondContents = await repository.loadFolderContents(folderId: second.id);
    final rootContents = await repository.loadFolderContents();
    expect(rootContents.bookmarks, isEmpty);
    expect(firstContents.bookmarks.single.url, Uri.parse('https://dart.dev'));
    expect(secondContents.bookmarks.single.url, Uri.parse('https://dart.dev'));
  });

  test('deletes folders recursively with child bookmarks', () async {
    final folder = await repository.createFolder(title: 'Programming');
    await _insertBookmark(database, id: 'bookmark', folderId: folder.id, url: 'https://dart.dev', title: 'Dart');
    await repository.deleteEntries([BookmarkEntryRef(type: BookmarkEntryType.folder, id: folder.id)]);
    expect(await database.select(database.bookmarkFolders).get(), isEmpty);
    expect(await database.select(database.bookmarks).get(), isEmpty);
  });

  test('exports Netscape bookmarks with folders and escaped values', () async {
    final folder = await repository.createFolder(title: 'Programming & Docs');
    await _insertBookmark(
      database,
      id: 'rust',
      folderId: folder.id,
      url: 'https://www.rust-lang.org/?q=rust&lang=en',
      title: 'Rust & Friends',
    );
    await _insertBookmark(database, id: 'root', url: 'https://example.com/article', title: 'Example Article');

    final html = await repository.exportNetscapeBookmarks();
    expect(html, contains('<!DOCTYPE NETSCAPE-Bookmark-file-1>'));
    expect(html, contains('<DT><H3 ADD_DATE="1778673600" LAST_MODIFIED="1778673600">Programming &amp; Docs</H3>'));
    expect(
      html,
      contains(
        '<DT><A HREF="https://www.rust-lang.org/?q=rust&amp;lang=en" ADD_DATE="1778673600">Rust &amp; Friends</A>',
      ),
    );
    expect(html, contains('<DT><A HREF="https://example.com/article" ADD_DATE="1778673600">Example Article</A>'));
  });

  test('enqueues synced folder bookmark and membership changes for connected accounts', () async {
    final syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 13, 12));
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    repository = BookmarkManagerRepository(
      database,
      syncRepository: syncRepository,
      now: () => DateTime.utc(2026, 5, 13, 12),
    );

    final folder = await repository.createFolder(title: 'Research');
    await _insertBookmark(database, id: 'bookmark', url: 'https://example.com', title: 'Example');
    await repository.updateBookmark(id: 'bookmark', title: 'Updated');
    await repository.addBookmarkToFolder(bookmarkId: 'bookmark', folderId: folder.id);

    final outbox = await syncRepository.pendingOutbox(accountDid: 'did:plc:alice');
    expect(
      outbox.map((item) => (item.localTable, item.collection)),
      containsAll([
        (AtprotoSyncLocalTable.bookmarkFolders.value, SembleSyncCollection.collection.value),
        (AtprotoSyncLocalTable.bookmarks.value, SembleSyncCollection.card.value),
        (AtprotoSyncLocalTable.bookmarkCollectionLinks.value, SembleSyncCollection.collectionLink.value),
      ]),
    );
  });

  test('exports selected bookmark ids without unrelated rows', () async {
    await _insertBookmark(database, id: 'selected', url: 'https://selected.example', title: 'Selected');
    await _insertBookmark(database, id: 'other', url: 'https://other.example', title: 'Other');
    final html = await repository.exportNetscapeBookmarks(selectedIds: ['selected']);
    expect(html, contains('https://selected.example'));
    expect(html, isNot(contains('https://other.example')));
  });
}

Future<void> _insertBookmark(
  AppDatabase database, {
  required String id,
  required String url,
  required String title,
  String? folderId,
}) async {
  final now = DateTime.utc(2026, 5, 13, 12);
  await database
      .into(database.bookmarks)
      .insert(BookmarksCompanion.insert(id: id, url: url, title: Value(title), createdAt: now, updatedAt: now));
  if (folderId != null) {
    await database
        .into(database.bookmarkCollectionLinks)
        .insert(
          BookmarkCollectionLinksCompanion.insert(
            id: 'link-$id-$folderId',
            bookmarkId: id,
            folderId: folderId,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
}
