import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/browser/data/favicon_cache.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(databaseProvider), faviconCache: ref.watch(faviconCacheProvider));
});

enum LibraryAnnotationQueryFilter { all, highlights, notes, underlines }

final librarySnapshotProvider = FutureProvider.autoDispose<LibrarySnapshot>((ref) async {
  _keepAliveBriefly(ref);
  try {
    final repository = ref.watch(libraryRepositoryProvider);
    final snapshot = await repository.loadSnapshot();
    unawaited(_refreshSnapshotFavicons(ref, repository, snapshot));
    return snapshot;
  } on Object catch (error, stackTrace) {
    ref.read(appLoggerProvider).error('Failed to load library snapshot.', error: error, stackTrace: stackTrace);
    rethrow;
  }
});

final allAnnotationGroupsProvider = FutureProvider.autoDispose<List<LibraryAnnotationGroup>>((ref) async {
  _keepAliveBriefly(ref);
  try {
    final repository = ref.watch(libraryRepositoryProvider);
    final groups = await repository.loadAnnotationGroups();
    unawaited(_refreshAnnotationGroupFavicons(ref, repository, groups));
    return groups;
  } on Object catch (error, stackTrace) {
    ref
        .read(appLoggerProvider)
        .error('Failed to load library annotation groups.', error: error, stackTrace: stackTrace);
    rethrow;
  }
});

final libraryPageDetailProvider = FutureProvider.autoDispose.family<LibraryPageDetail?, String>((ref, id) async {
  _keepAliveBriefly(ref);
  try {
    return await ref.watch(libraryRepositoryProvider).loadPageDetail(id);
  } on Object catch (error, stackTrace) {
    ref.read(appLoggerProvider).error('Failed to load library page detail.', error: error, stackTrace: stackTrace);
    rethrow;
  }
});

const Duration _libraryProviderCacheDuration = Duration(minutes: 2);

void _keepAliveBriefly(Ref ref) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() {
    timer = Timer(_libraryProviderCacheDuration, link.close);
  });
  ref.onResume(() {
    timer?.cancel();
    timer = null;
  });
  ref.onDispose(() {
    timer?.cancel();
  });
}

Future<void> _refreshSnapshotFavicons(Ref ref, LibraryRepository repository, LibrarySnapshot snapshot) async {
  try {
    final changed = await repository.refreshMissingFaviconsForPageIds([
      for (final page in snapshot.bookmarkedPages) page.id,
      for (final page in snapshot.recentPages) page.id,
    ]);
    if (changed) {
      ref.invalidateSelf();
    }
  } on Object catch (error, stackTrace) {
    ref.read(appLoggerProvider).debug('Failed to refresh library favicons.', error: error, stackTrace: stackTrace);
  }
}

Future<void> _refreshAnnotationGroupFavicons(
  Ref ref,
  LibraryRepository repository,
  List<LibraryAnnotationGroup> groups,
) async {
  try {
    final changed = await repository.refreshMissingFaviconsForPageIds(groups.map((group) => group.id));
    if (changed) {
      ref.invalidateSelf();
    }
  } on Object catch (error, stackTrace) {
    ref.read(appLoggerProvider).debug('Failed to refresh annotation favicons.', error: error, stackTrace: stackTrace);
  }
}

class LibraryRepository {
  LibraryRepository(this._database, {FaviconCache? faviconCache}) : _faviconCache = faviconCache;

  final AppDatabase _database;
  final FaviconCache? _faviconCache;

  Future<LibrarySnapshot> loadSnapshot() async {
    final results = await Future.wait<Object>([
      _loadBookmarkedPages(limit: 12),
      _loadRecentPages(limit: 12),
      _loadRecentAnnotations(limit: 12),
    ]);

    return LibrarySnapshot(
      bookmarkedPages: results[0] as List<LibraryPageItem>,
      recentPages: results[1] as List<LibraryPageItem>,
      recentAnnotations: results[2] as List<LibraryAnnotationItem>,
    );
  }

  Future<List<LibraryPageItem>> _loadBookmarkedPages({required int limit}) async {
    final rows =
        await (_database.select(_database.bookmarks)
              ..where((bookmark) => bookmark.deletedAt.isNull())
              ..orderBy([(bookmark) => OrderingTerm.desc(bookmark.createdAt)])
              ..limit(limit))
            .get();
    if (rows.isEmpty) {
      return const [];
    }

    final pagesByUrl = await _pagesByUrls(rows.map((bookmark) => bookmark.url).toSet());
    final countsByPageId = await _annotationCountsByPageIds({for (final page in pagesByUrl.values) page.id});
    final folderPathsByBookmarkId = await _bookmarkFolderPathsByBookmarkIds(
      rows.map((bookmark) => bookmark.id).toSet(),
    );

    return [
      for (final bookmark in rows)
        LibraryPageItem(
          id: pagesByUrl[bookmark.url]?.id ?? bookmark.id,
          url: Uri.parse(bookmark.url),
          title: _fallbackTitle(bookmark.title, bookmark.url),
          subtitle: _hostFor(bookmark.url),
          faviconUrl: _parseOptionalUri(pagesByUrl[bookmark.url]?.faviconUrl),
          faviconFilePath: _storedFaviconFilePathForPage(pagesByUrl[bookmark.url]),
          bookmarkFolderPath: folderPathsByBookmarkId[bookmark.id],
          annotationPreview: null,
          annotationCount: countsByPageId[pagesByUrl[bookmark.url]?.id] ?? 0,
          timestamp: pagesByUrl[bookmark.url]?.lastVisitedAt ?? bookmark.createdAt,
        ),
    ];
  }

  Future<List<LibraryPageItem>> _loadRecentPages({required int limit}) async {
    final latestAnnotations = await _latestAnnotationsByPage(limit: limit);
    if (latestAnnotations.isEmpty) {
      return const [];
    }

    final pageIds = latestAnnotations.map((annotation) => annotation.pageId).toSet();
    final pagesById = await _pagesByIds(pageIds);
    final countsByPageId = await _annotationCountsByPageIds(pageIds);
    final bodiesByAnnotationId = await _bodiesByAnnotationIds(
      latestAnnotations.map((annotation) => annotation.id).toSet(),
    );
    final targetsByAnnotationId = await _targetsByAnnotationIds(
      latestAnnotations.map((annotation) => annotation.id).toSet(),
    );
    final bookmarksByUrl = await _bookmarksByUrl();
    final usedBookmarkIds = <String>{
      for (final page in pagesById.values)
        if (bookmarksByUrl[page.url] != null) bookmarksByUrl[page.url]!.id,
    };
    final folderPathsByBookmarkId = await _bookmarkFolderPathsByBookmarkIds(usedBookmarkIds);

    final items = <LibraryPageItem>[];
    for (final annotation in latestAnnotations) {
      final page = pagesById[annotation.pageId];
      if (page == null) {
        continue;
      }
      final bookmark = bookmarksByUrl[page.url];
      items.add(
        LibraryPageItem(
          id: page.id,
          url: Uri.parse(page.url),
          title: _fallbackTitle(page.title, page.url),
          subtitle: _hostFor(page.canonicalUrl ?? page.url),
          faviconUrl: _parseOptionalUri(page.faviconUrl),
          faviconFilePath: _storedFaviconFilePathForPage(page),
          bookmarkFolderPath: bookmark == null ? null : folderPathsByBookmarkId[bookmark.id],
          annotationPreview: _excerptForAnnotationData(
            bodiesByAnnotationId[annotation.id] ?? const [],
            targetsByAnnotationId[annotation.id],
          ),
          annotationCount: countsByPageId[page.id] ?? 0,
          timestamp: annotation.modifiedAt,
        ),
      );
    }

    return items;
  }

  Future<List<LibraryAnnotationItem>> _loadRecentAnnotations({required int limit}) async {
    final rows =
        await (_database.select(_database.annotations)
              ..where((annotation) => annotation.deletedAt.isNull())
              ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)])
              ..limit(limit))
            .get();

    final items = await _annotationItemsForRows(rows);
    return items..sort(_compareAnnotationsBySource);
  }

  Future<List<LibraryAnnotationGroup>> loadAnnotationGroups() async {
    final rows =
        await (_database.select(_database.annotations)
              ..where((annotation) => annotation.deletedAt.isNull())
              ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)]))
            .get();
    return _annotationGroupsForRows(rows);
  }

  Future<LibraryAnnotationPage> loadAnnotationGroupsPage({
    required int limit,
    LibraryAnnotationQueryFilter filter = LibraryAnnotationQueryFilter.all,
    LibraryAnnotationCursor? cursor,
  }) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Annotation page limit must be positive.');
    }

    final rows = await _annotationRowsPage(limit: limit + 1, filter: filter, cursor: cursor);
    final hasMore = rows.length > limit;
    final visibleRows = hasMore ? rows.take(limit).toList(growable: false) : rows;
    return LibraryAnnotationPage(
      groups: await _annotationGroupsForRows(visibleRows),
      nextCursor: hasMore && visibleRows.isNotEmpty ? LibraryAnnotationCursor.fromAnnotation(visibleRows.last) : null,
      hasMore: hasMore,
    );
  }

  Future<List<Annotation>> _annotationRowsPage({
    required int limit,
    required LibraryAnnotationQueryFilter filter,
    LibraryAnnotationCursor? cursor,
  }) {
    final query = _database.select(_database.annotations)
      ..where((annotation) {
        Expression<bool> predicate = annotation.deletedAt.isNull();
        if (cursor != null) {
          predicate =
              predicate &
              (annotation.modifiedAt.isSmallerThanValue(cursor.modifiedAt) |
                  (annotation.modifiedAt.equals(cursor.modifiedAt) & annotation.id.isSmallerThanValue(cursor.id)));
        }

        final isUnderline = CustomExpression<bool>(
          '''EXISTS (SELECT 1 FROM annotation_bodies body WHERE body.annotation_id = annotations.id AND body.type = 'StyleHint' AND body.value LIKE '%${AnnotationVisualStyle.underline.name}%')''',
        );
        return switch (filter) {
          LibraryAnnotationQueryFilter.all => predicate,
          LibraryAnnotationQueryFilter.notes => predicate & annotation.motivation.equals('commenting'),
          LibraryAnnotationQueryFilter.underlines => predicate & isUnderline,
          LibraryAnnotationQueryFilter.highlights =>
            predicate & annotation.motivation.equals('commenting').not() & isUnderline.not(),
        };
      })
      ..orderBy([
        (annotation) => OrderingTerm.desc(annotation.modifiedAt),
        (annotation) => OrderingTerm.desc(annotation.id),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<List<LibraryAnnotationGroup>> _annotationGroupsForRows(List<Annotation> rows) async {
    if (rows.isEmpty) {
      return const [];
    }

    final pageIds = rows.map((annotation) => annotation.pageId).toSet();
    final annotationIds = rows.map((annotation) => annotation.id).toSet();
    final pagesById = await _pagesByIds(pageIds);
    final targetsByAnnotationId = await _targetsByAnnotationIds(annotationIds);
    final bodiesByAnnotationId = await _bodiesByAnnotationIds(annotationIds);
    final marginBackedIds = await _marginBackedAnnotationIds(annotationIds);
    final bookmarksByUrl = await _bookmarksByUrl();
    final usedBookmarkIds = <String>{};
    for (final annotation in rows) {
      final page = pagesById[annotation.pageId];
      if (page == null) {
        continue;
      }
      final target = targetsByAnnotationId[annotation.id];
      final sourceUrl = target?.sourceUrl ?? page.url;
      final bookmark = bookmarksByUrl[sourceUrl] ?? bookmarksByUrl[page.url];
      if (bookmark != null) {
        usedBookmarkIds.add(bookmark.id);
      }
    }
    final folderPathsByBookmarkId = await _bookmarkFolderPathsByBookmarkIds(usedBookmarkIds);
    final builders = <String, _LibraryAnnotationGroupBuilder>{};

    for (final annotation in rows) {
      final page = pagesById[annotation.pageId];
      if (page == null) {
        continue;
      }
      final target = targetsByAnnotationId[annotation.id];
      final sourceUrl = target?.sourceUrl ?? page.url;
      final url = Uri.parse(sourceUrl);
      final bookmark = bookmarksByUrl[sourceUrl] ?? bookmarksByUrl[page.url];
      final builder = builders.putIfAbsent(
        url.toString(),
        () => _LibraryAnnotationGroupBuilder(
          id: page.id,
          url: url,
          title: _fallbackTitle(page.title, sourceUrl),
          subtitle: _hostFor(page.canonicalUrl ?? sourceUrl),
          faviconUrl: _parseOptionalUri(page.faviconUrl),
        ),
      );
      builder.faviconFilePath ??= _storedFaviconFilePathForPage(page);
      builder.bookmarkFolderPath ??= bookmark == null ? null : folderPathsByBookmarkId[bookmark.id];
      builder.annotations.add(
        LibraryAnnotationItem(
          id: annotation.id,
          url: url,
          pageTitle: _fallbackTitle(page.title, page.url),
          motivation: annotation.motivation,
          visualStyle: _visualStyleForAnnotationBodies(bodiesByAnnotationId[annotation.id] ?? const []),
          excerpt: _excerptForAnnotationData(bodiesByAnnotationId[annotation.id] ?? const [], target),
          modifiedAt: annotation.modifiedAt,
          isMarginBacked: marginBackedIds.contains(annotation.id),
        ),
      );
    }

    for (final builder in builders.values) {
      builder.annotations.sort(_compareAnnotationsBySource);
    }
    return builders.values.map((builder) => builder.build()).toList(growable: false);
  }

  Future<LibraryPageDetail?> loadPageDetail(String id) async {
    Page? page = await (_database.select(_database.pages)..where((page) => page.id.equals(id))).getSingleOrNull();
    Bookmark? bookmark;
    if (page == null) {
      bookmark = await (_database.select(
        _database.bookmarks,
      )..where((bookmark) => bookmark.id.equals(id))).getSingleOrNull();
      if (bookmark == null) {
        return null;
      }
      page = await _pageForUrl(bookmark.url);
    } else {
      bookmark = await _bookmarkForUrl(page.url);
    }

    final urlText = page?.url ?? bookmark!.url;
    final annotations = page == null ? <LibraryAnnotationItem>[] : await _annotationsForPage(page.id);
    return LibraryPageDetail(
      id: id,
      pageId: page?.id,
      url: Uri.parse(urlText),
      title: _fallbackTitle(bookmark?.title ?? page?.title, urlText),
      subtitle: _hostFor(page?.canonicalUrl ?? urlText),
      description: page?.description,
      faviconUrl: _parseOptionalUri(page?.faviconUrl),
      faviconFilePath: _storedFaviconFilePathForPage(page),
      bookmarkFolderPath: bookmark == null ? null : await _bookmarkFolderPathForBookmark(bookmark.id),
      annotations: annotations,
    );
  }

  Future<List<LibraryAnnotationItem>> _annotationsForPage(String pageId) async {
    final rows =
        await (_database.select(_database.annotations)
              ..where((annotation) => annotation.pageId.equals(pageId) & annotation.deletedAt.isNull())
              ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)]))
            .get();
    final items = await _annotationItemsForRows(rows);
    return items..sort(_compareAnnotationsBySource);
  }

  Future<Map<String, Bookmark>> _bookmarksByUrl() async {
    final rows = await (_database.select(_database.bookmarks)..where((bookmark) => bookmark.deletedAt.isNull())).get();
    return {for (final bookmark in rows) bookmark.url: bookmark};
  }

  Future<Page?> _pageForUrl(String url) async {
    final rows =
        await (_database.select(_database.pages)
              ..where((page) => page.url.equals(url))
              ..orderBy([(page) => OrderingTerm.desc(page.lastVisitedAt), (page) => OrderingTerm.desc(page.createdAt)]))
            .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<Bookmark?> _bookmarkForUrl(String url) async {
    final rows =
        await (_database.select(_database.bookmarks)
              ..where((bookmark) => bookmark.url.equals(url) & bookmark.deletedAt.isNull())
              ..orderBy([
                (bookmark) => OrderingTerm.desc(bookmark.updatedAt),
                (bookmark) => OrderingTerm.desc(bookmark.createdAt),
              ]))
            .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<bool> refreshMissingFaviconsForPageIds(Iterable<String> pageIds) async {
    final faviconCache = _faviconCache;
    final ids = pageIds.toSet();
    if (faviconCache == null || ids.isEmpty) {
      return false;
    }

    final pagesById = await _pagesByIds(ids);
    var changed = false;
    for (final page in pagesById.values) {
      final faviconUrl = _parseOptionalUri(page.faviconUrl);
      if (faviconUrl == null) {
        continue;
      }

      final storedPath = normalize(page.faviconFilePath);
      if (storedPath != null && await File(storedPath).exists()) {
        continue;
      }

      final refreshedPath = await faviconCache.cacheFavicon(faviconUrl);
      if (refreshedPath == null || refreshedPath == storedPath) {
        continue;
      }

      await (_database.update(
        _database.pages,
      )..where((row) => row.id.equals(page.id))).write(PagesCompanion(faviconFilePath: Value(refreshedPath)));
      changed = true;
    }
    return changed;
  }

  Future<Map<String, Page>> _pagesByUrls(Set<String> urls) async {
    if (urls.isEmpty) {
      return const {};
    }
    final rows = await (_database.select(_database.pages)..where((page) => page.url.isIn(urls))).get();
    return {for (final page in rows) page.url: page};
  }

  Future<Map<String, Page>> _pagesByIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return const {};
    }
    final rows = await (_database.select(_database.pages)..where((page) => page.id.isIn(ids))).get();
    return {for (final page in rows) page.id: page};
  }

  Future<Map<String, int>> _annotationCountsByPageIds(Set<String> pageIds) async {
    if (pageIds.isEmpty) {
      return const {};
    }
    final count = _database.annotations.id.count();
    final query = _database.selectOnly(_database.annotations)
      ..addColumns([_database.annotations.pageId, count])
      ..where(_database.annotations.pageId.isIn(pageIds) & _database.annotations.deletedAt.isNull())
      ..groupBy([_database.annotations.pageId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.read(_database.annotations.pageId) != null)
          row.read(_database.annotations.pageId)!: row.read(count) ?? 0,
    };
  }

  Future<List<Annotation>> _latestAnnotationsByPage({required int limit}) async {
    final latestModified = _database.annotations.modifiedAt.max();
    final query = _database.selectOnly(_database.annotations)
      ..addColumns([_database.annotations.pageId, latestModified])
      ..where(_database.annotations.deletedAt.isNull())
      ..groupBy([_database.annotations.pageId])
      ..orderBy([OrderingTerm(expression: latestModified, mode: OrderingMode.desc)])
      ..limit(limit);
    final groupedRows = await query.get();

    final annotations = <Annotation>[];
    for (final row in groupedRows) {
      final pageId = row.read(_database.annotations.pageId);
      final modifiedAt = row.read(latestModified);
      if (pageId == null || modifiedAt == null) {
        continue;
      }
      final annotation =
          await (_database.select(_database.annotations)
                ..where(
                  (annotation) =>
                      annotation.pageId.equals(pageId) &
                      annotation.modifiedAt.equals(modifiedAt) &
                      annotation.deletedAt.isNull(),
                )
                ..orderBy([(annotation) => OrderingTerm.desc(annotation.id)])
                ..limit(1))
              .getSingleOrNull();
      if (annotation != null) {
        annotations.add(annotation);
      }
    }
    return annotations;
  }

  Future<Map<String, AnnotationTarget>> _targetsByAnnotationIds(Set<String> annotationIds) async {
    if (annotationIds.isEmpty) {
      return const {};
    }
    final rows =
        await (_database.select(_database.annotationTargets)
              ..where((target) => target.annotationId.isIn(annotationIds))
              ..orderBy([(target) => OrderingTerm.asc(target.id)]))
            .get();
    final targets = <String, AnnotationTarget>{};
    for (final target in rows) {
      targets.putIfAbsent(target.annotationId, () => target);
    }
    return targets;
  }

  Future<Map<String, List<AnnotationBody>>> _bodiesByAnnotationIds(Set<String> annotationIds) async {
    if (annotationIds.isEmpty) {
      return const {};
    }
    final rows =
        await (_database.select(_database.annotationBodies)
              ..where((body) => body.annotationId.isIn(annotationIds))
              ..orderBy([(body) => OrderingTerm.asc(body.id)]))
            .get();
    final bodies = <String, List<AnnotationBody>>{};
    for (final body in rows) {
      bodies.putIfAbsent(body.annotationId, () => []).add(body);
    }
    return bodies;
  }

  Future<Set<String>> _marginBackedAnnotationIds(Set<String> annotationIds) async {
    if (annotationIds.isEmpty) {
      return const {};
    }
    final rows =
        await (_database.select(_database.atprotoRecordMirrors)..where(
              (mirror) =>
                  mirror.localId.isIn(annotationIds) &
                  mirror.localTable.equals(AtprotoSyncLocalTable.annotations.value) &
                  mirror.collection.equals(MarginSyncCollection.note.value) &
                  mirror.deletedAt.isNull() &
                  mirror.lastSyncedAt.isNotNull(),
            ))
            .get();
    return {for (final row in rows) row.localId};
  }

  Future<List<LibraryAnnotationItem>> _annotationItemsForRows(List<Annotation> rows) async {
    if (rows.isEmpty) {
      return [];
    }

    final pageIds = rows.map((annotation) => annotation.pageId).toSet();
    final annotationIds = rows.map((annotation) => annotation.id).toSet();
    final pagesById = await _pagesByIds(pageIds);
    final targetsByAnnotationId = await _targetsByAnnotationIds(annotationIds);
    final bodiesByAnnotationId = await _bodiesByAnnotationIds(annotationIds);
    final marginBackedIds = await _marginBackedAnnotationIds(annotationIds);

    final items = <LibraryAnnotationItem>[];
    for (final annotation in rows) {
      final page = pagesById[annotation.pageId];
      if (page == null) {
        continue;
      }
      final target = targetsByAnnotationId[annotation.id];
      items.add(
        LibraryAnnotationItem(
          id: annotation.id,
          url: Uri.parse(target?.sourceUrl ?? page.url),
          pageTitle: _fallbackTitle(page.title, page.url),
          motivation: annotation.motivation,
          visualStyle: _visualStyleForAnnotationBodies(bodiesByAnnotationId[annotation.id] ?? const []),
          excerpt: _excerptForAnnotationData(bodiesByAnnotationId[annotation.id] ?? const [], target),
          modifiedAt: annotation.modifiedAt,
          isMarginBacked: marginBackedIds.contains(annotation.id),
        ),
      );
    }
    return items;
  }

  String? _storedFaviconFilePathForPage(Page? page) => page == null ? null : normalize(page.faviconFilePath);

  int _compareAnnotationsBySource(LibraryAnnotationItem a, LibraryAnnotationItem b) {
    if (a.isMarginBacked != b.isMarginBacked) {
      return a.isMarginBacked ? -1 : 1;
    }
    return b.modifiedAt.compareTo(a.modifiedAt);
  }

  AnnotationVisualStyle _visualStyleForAnnotationBodies(List<AnnotationBody> bodies) {
    for (final body in bodies) {
      if (body.type != 'StyleHint') {
        continue;
      }
      try {
        final decoded = jsonDecode(body.value);
        if (decoded is Map<String, Object?> && decoded['style'] == AnnotationVisualStyle.underline.name) {
          return AnnotationVisualStyle.underline;
        }
      } on FormatException {
        return AnnotationVisualStyle.highlight;
      }
    }
    return AnnotationVisualStyle.highlight;
  }

  String _excerptForAnnotationData(List<AnnotationBody> bodies, AnnotationTarget? target) {
    AnnotationBody? textualBody;
    for (final body in bodies) {
      if (body.type == 'TextualBody') {
        textualBody = body;
        break;
      }
    }
    return _annotationExcerpt(textualBody?.value, target?.selectorJson);
  }

  String _annotationExcerpt(String? bodyValue, String? selectorJson) {
    final normalizedBody = normalize(bodyValue);
    if (normalizedBody != null) {
      return normalizedBody;
    }

    if (selectorJson == null || selectorJson.trim().isEmpty) {
      return 'Untitled annotation';
    }

    try {
      final decoded = jsonDecode(selectorJson);
      if (decoded is Map<String, Object?>) {
        final selector = decoded['selector'];
        final exact = _exactSelectorValue(selector);
        if (exact != null) {
          return exact;
        }
      }
      if (decoded is List<Object?>) {
        final exact = _exactSelectorValue(decoded);
        if (exact != null) {
          return exact;
        }
      }
    } on FormatException {
      return selectorJson;
    }

    return 'Untitled annotation';
  }

  String? _exactSelectorValue(Object? selector) {
    if (selector is Map<String, Object?>) {
      return normalize(selector['exact']?.toString());
    }

    if (selector is List<Object?>) {
      for (final value in selector) {
        if (value is Map<String, Object?>) {
          final exact = normalize(value['exact']?.toString());
          if (exact != null) {
            return exact;
          }
        }
      }
    }

    return null;
  }

  String _fallbackTitle(String? title, String url) => normalize(title) ?? Uri.tryParse(url)?.host ?? url;

  String _hostFor(String url) => Uri.tryParse(url)?.host ?? url;

  Uri? _parseOptionalUri(String? value) {
    final normalized = normalize(value);
    return normalized == null ? null : Uri.tryParse(normalized);
  }

  Future<Map<String, String>> _bookmarkFolderPathsByBookmarkIds(Set<String> bookmarkIds) async {
    if (bookmarkIds.isEmpty) {
      return const {};
    }

    final links =
        await (_database.select(_database.bookmarkCollectionLinks)
              ..where((row) => row.bookmarkId.isIn(bookmarkIds) & row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder), (row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    final firstFolderIdByBookmarkId = <String, String>{};
    for (final link in links) {
      firstFolderIdByBookmarkId.putIfAbsent(link.bookmarkId, () => link.folderId);
    }
    if (firstFolderIdByBookmarkId.isEmpty) {
      return const {};
    }

    final folders = await _database.select(_database.bookmarkFolders).get();
    final foldersById = {for (final folder in folders) folder.id: folder};
    return {
      for (final entry in firstFolderIdByBookmarkId.entries)
        if (_bookmarkFolderPathFromMap(entry.value, foldersById) != null)
          entry.key: _bookmarkFolderPathFromMap(entry.value, foldersById)!,
    };
  }

  Future<String?> _bookmarkFolderPathForBookmark(String bookmarkId) async {
    final paths = await _bookmarkFolderPathsByBookmarkIds({bookmarkId});
    return paths[bookmarkId];
  }

  String? _bookmarkFolderPathFromMap(String? folderId, Map<String, BookmarkFolder> foldersById) {
    if (folderId == null) {
      return null;
    }

    final names = <String>[];
    final seen = <String>{};
    String? currentId = folderId;
    while (currentId != null) {
      final folderKey = currentId;
      if (!seen.add(folderKey)) {
        break;
      }
      final folder = foldersById[folderKey];
      if (folder == null) {
        break;
      }
      names.insert(0, folder.title);
      currentId = folder.parentId;
    }

    return names.isEmpty ? null : names.join(' / ');
  }
}

class LibrarySnapshot {
  const LibrarySnapshot({required this.bookmarkedPages, required this.recentPages, required this.recentAnnotations});

  final List<LibraryPageItem> bookmarkedPages;
  final List<LibraryPageItem> recentPages;
  final List<LibraryAnnotationItem> recentAnnotations;

  bool get isEmpty => bookmarkedPages.isEmpty && recentPages.isEmpty && recentAnnotations.isEmpty;
}

class LibraryPageDetail {
  const LibraryPageDetail({
    required this.id,
    required this.pageId,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.faviconUrl,
    required this.faviconFilePath,
    required this.bookmarkFolderPath,
    required this.annotations,
  });

  final String id;
  final String? pageId;
  final Uri url;
  final String title;
  final String subtitle;
  final String? description;
  final Uri? faviconUrl;
  final String? faviconFilePath;
  final String? bookmarkFolderPath;
  final List<LibraryAnnotationItem> annotations;
}

class LibraryPageItem {
  const LibraryPageItem({
    required this.id,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.faviconUrl,
    required this.faviconFilePath,
    required this.bookmarkFolderPath,
    required this.annotationPreview,
    required this.annotationCount,
    required this.timestamp,
  });

  final String id;
  final Uri url;
  final String title;
  final String subtitle;
  final Uri? faviconUrl;
  final String? faviconFilePath;
  final String? bookmarkFolderPath;
  final String? annotationPreview;
  final int annotationCount;
  final DateTime timestamp;
}

class LibraryAnnotationPage {
  const LibraryAnnotationPage({required this.groups, required this.nextCursor, required this.hasMore});

  final List<LibraryAnnotationGroup> groups;
  final LibraryAnnotationCursor? nextCursor;
  final bool hasMore;
}

class LibraryAnnotationCursor {
  const LibraryAnnotationCursor({required this.modifiedAt, required this.id});

  factory LibraryAnnotationCursor.fromAnnotation(Annotation annotation) {
    return LibraryAnnotationCursor(modifiedAt: annotation.modifiedAt, id: annotation.id);
  }

  final DateTime modifiedAt;
  final String id;
}

class LibraryAnnotationGroup {
  const LibraryAnnotationGroup({
    required this.id,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.faviconUrl,
    required this.faviconFilePath,
    required this.bookmarkFolderPath,
    required this.annotations,
  });

  final String id;
  final Uri url;
  final String title;
  final String subtitle;
  final Uri? faviconUrl;
  final String? faviconFilePath;
  final String? bookmarkFolderPath;
  final List<LibraryAnnotationItem> annotations;
}

class _LibraryAnnotationGroupBuilder {
  _LibraryAnnotationGroupBuilder({
    required this.id,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.faviconUrl,
  });

  final String id;
  final Uri url;
  final String title;
  final String subtitle;
  final Uri? faviconUrl;
  String? faviconFilePath;
  String? bookmarkFolderPath;
  final List<LibraryAnnotationItem> annotations = [];

  LibraryAnnotationGroup build() => LibraryAnnotationGroup(
    id: id,
    url: url,
    title: title,
    subtitle: subtitle,
    faviconUrl: faviconUrl,
    faviconFilePath: faviconFilePath,
    bookmarkFolderPath: bookmarkFolderPath,
    annotations: annotations,
  );
}

class LibraryAnnotationItem {
  const LibraryAnnotationItem({
    required this.id,
    required this.url,
    required this.pageTitle,
    required this.motivation,
    required this.visualStyle,
    required this.excerpt,
    required this.modifiedAt,
    required this.isMarginBacked,
  });

  final String id;
  final Uri url;
  final String pageTitle;
  final String motivation;
  final AnnotationVisualStyle visualStyle;
  final String excerpt;
  final DateTime modifiedAt;
  final bool isMarginBacked;

  bool get isNote => motivation == 'commenting';
  String get typeLabel =>
      isNote ? 'Note' : (visualStyle == AnnotationVisualStyle.underline ? 'Underline' : 'Highlight');
}
