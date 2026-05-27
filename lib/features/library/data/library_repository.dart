import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/browser/data/favicon_cache.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(databaseProvider), faviconCache: ref.watch(faviconCacheProvider));
});

final librarySnapshotProvider = FutureProvider.autoDispose<LibrarySnapshot>((ref) {
  return ref.watch(libraryRepositoryProvider).loadSnapshot();
});

final allAnnotationGroupsProvider = FutureProvider.autoDispose<List<LibraryAnnotationGroup>>((ref) {
  return ref.watch(libraryRepositoryProvider).loadAnnotationGroups();
});

final libraryPageDetailProvider = FutureProvider.autoDispose.family<LibraryPageDetail?, String>((ref, id) {
  return ref.watch(libraryRepositoryProvider).loadPageDetail(id);
});

class LibraryRepository {
  LibraryRepository(this._database, {FaviconCache? faviconCache}) : _faviconCache = faviconCache;

  final AppDatabase _database;
  final FaviconCache? _faviconCache;

  Future<LibrarySnapshot> loadSnapshot() async {
    final bookmarks = await _loadBookmarkedPages(limit: 12);
    final recentPages = await _loadRecentPages(limit: 12);
    final recentAnnotations = await _loadRecentAnnotations(limit: 12);

    return LibrarySnapshot(bookmarkedPages: bookmarks, recentPages: recentPages, recentAnnotations: recentAnnotations);
  }

  Future<List<LibraryPageItem>> _loadBookmarkedPages({required int limit}) async {
    final rows =
        await (_database.select(_database.bookmarks)
              ..where((bookmark) => bookmark.deletedAt.isNull())
              ..orderBy([(bookmark) => OrderingTerm.desc(bookmark.createdAt)])
              ..limit(limit))
            .get();

    final items = <LibraryPageItem>[];
    for (final bookmark in rows) {
      final page = await _pageForUrl(bookmark.url);
      final faviconFilePath = page == null ? null : await _faviconFilePathForPage(page);
      final bookmarkFolderPath = await _bookmarkFolderPathForBookmark(bookmark.id);
      items.add(
        LibraryPageItem(
          id: page?.id ?? bookmark.id,
          url: Uri.parse(bookmark.url),
          title: _fallbackTitle(bookmark.title, bookmark.url),
          subtitle: _hostFor(bookmark.url),
          faviconUrl: _parseOptionalUri(page?.faviconUrl),
          faviconFilePath: faviconFilePath,
          bookmarkFolderPath: bookmarkFolderPath,
          annotationPreview: null,
          annotationCount: page == null ? 0 : await _annotationCountForPage(page.id),
          timestamp: page?.lastVisitedAt ?? bookmark.createdAt,
        ),
      );
    }

    return items;
  }

  Future<List<LibraryPageItem>> _loadRecentPages({required int limit}) async {
    final bookmarksByUrl = await _bookmarksByUrl();
    final query = _database.select(_database.annotations)
      ..where((annotation) => annotation.deletedAt.isNull())
      ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)]);

    final rows = await query.get();
    final seenPageIds = <String>{};

    final items = <LibraryPageItem>[];
    for (final annotation in rows) {
      if (items.length >= limit || !seenPageIds.add(annotation.pageId)) {
        continue;
      }
      final page = await (_database.select(
        _database.pages,
      )..where((page) => page.id.equals(annotation.pageId))).getSingleOrNull();
      if (page == null) {
        continue;
      }
      final excerpt = await _excerptForAnnotation(annotation.id);
      final faviconFilePath = await _faviconFilePathForPage(page);
      final bookmark = bookmarksByUrl[page.url];
      final bookmarkFolderPath = bookmark == null ? null : await _bookmarkFolderPathForBookmark(bookmark.id);
      items.add(
        LibraryPageItem(
          id: page.id,
          url: Uri.parse(page.url),
          title: _fallbackTitle(page.title, page.url),
          subtitle: _hostFor(page.canonicalUrl ?? page.url),
          faviconUrl: _parseOptionalUri(page.faviconUrl),
          faviconFilePath: faviconFilePath,
          bookmarkFolderPath: bookmarkFolderPath,
          annotationPreview: excerpt,
          annotationCount: await _annotationCountForPage(page.id),
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

    final items = <LibraryAnnotationItem>[];
    for (final annotation in rows) {
      final page = await (_database.select(
        _database.pages,
      )..where((page) => page.id.equals(annotation.pageId))).getSingleOrNull();
      if (page == null) {
        continue;
      }
      final target = await (_database.select(
        _database.annotationTargets,
      )..where((target) => target.annotationId.equals(annotation.id))).getSingleOrNull();

      items.add(
        LibraryAnnotationItem(
          id: annotation.id,
          url: Uri.parse(target?.sourceUrl ?? page.url),
          pageTitle: _fallbackTitle(page.title, page.url),
          motivation: annotation.motivation,
          visualStyle: await _visualStyleForAnnotation(annotation.id),
          excerpt: await _excerptForAnnotation(annotation.id),
          modifiedAt: annotation.modifiedAt,
        ),
      );
    }

    return items;
  }

  Future<List<LibraryAnnotationGroup>> loadAnnotationGroups() async {
    final rows =
        await (_database.select(_database.annotations)
              ..where((annotation) => annotation.deletedAt.isNull())
              ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)]))
            .get();
    final bookmarksByUrl = await _bookmarksByUrl();
    final builders = <String, _LibraryAnnotationGroupBuilder>{};

    for (final annotation in rows) {
      final page = await (_database.select(
        _database.pages,
      )..where((page) => page.id.equals(annotation.pageId))).getSingleOrNull();
      if (page == null) {
        continue;
      }
      final target = await (_database.select(
        _database.annotationTargets,
      )..where((target) => target.annotationId.equals(annotation.id))).getSingleOrNull();
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
      builder.faviconFilePath ??= await _faviconFilePathForPage(page);
      builder.bookmarkFolderPath ??= bookmark == null ? null : await _bookmarkFolderPathForBookmark(bookmark.id);
      builder.annotations.add(
        LibraryAnnotationItem(
          id: annotation.id,
          url: url,
          pageTitle: _fallbackTitle(page.title, page.url),
          motivation: annotation.motivation,
          visualStyle: await _visualStyleForAnnotation(annotation.id),
          excerpt: await _excerptForAnnotation(annotation.id),
          modifiedAt: annotation.modifiedAt,
        ),
      );
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
      bookmark = await (_database.select(
        _database.bookmarks,
      )..where((bookmark) => bookmark.url.equals(page!.url))).getSingleOrNull();
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
      faviconFilePath: page == null ? null : await _faviconFilePathForPage(page),
      bookmarkFolderPath: bookmark == null ? null : await _bookmarkFolderPathForBookmark(bookmark.id),
      annotations: annotations,
    );
  }

  Future<List<LibraryAnnotationItem>> _annotationsForPage(String pageId) async {
    final page = await (_database.select(_database.pages)..where((page) => page.id.equals(pageId))).getSingleOrNull();
    final rows =
        await (_database.select(_database.annotations)
              ..where((annotation) => annotation.pageId.equals(pageId) & annotation.deletedAt.isNull())
              ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)]))
            .get();
    final items = <LibraryAnnotationItem>[];
    for (final annotation in rows) {
      final target = await (_database.select(
        _database.annotationTargets,
      )..where((target) => target.annotationId.equals(annotation.id))).getSingleOrNull();
      final sourceUrl = target?.sourceUrl ?? page?.url;
      if (sourceUrl == null) {
        continue;
      }
      items.add(
        LibraryAnnotationItem(
          id: annotation.id,
          url: Uri.parse(sourceUrl),
          pageTitle: _fallbackTitle(page?.title, sourceUrl),
          motivation: annotation.motivation,
          visualStyle: await _visualStyleForAnnotation(annotation.id),
          excerpt: await _excerptForAnnotation(annotation.id),
          modifiedAt: annotation.modifiedAt,
        ),
      );
    }
    return items;
  }

  Future<Map<String, Bookmark>> _bookmarksByUrl() async {
    final rows = await (_database.select(_database.bookmarks)..where((bookmark) => bookmark.deletedAt.isNull())).get();
    return {for (final bookmark in rows) bookmark.url: bookmark};
  }

  Future<Page?> _pageForUrl(String url) {
    return (_database.select(_database.pages)..where((page) => page.url.equals(url))).getSingleOrNull();
  }

  Future<int> _annotationCountForPage(String pageId) async {
    final count = _database.annotations.id.count();
    final query = _database.selectOnly(_database.annotations)
      ..addColumns([count])
      ..where(_database.annotations.pageId.equals(pageId) & _database.annotations.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<String?> _faviconFilePathForPage(Page page) async {
    final storedPath = normalize(page.faviconFilePath);
    if (storedPath != null && await File(storedPath).exists()) {
      return storedPath;
    }

    final faviconUrl = _parseOptionalUri(page.faviconUrl);
    final faviconCache = _faviconCache;
    if (faviconUrl == null || faviconCache == null) {
      return storedPath;
    }

    final refreshedPath = await faviconCache.cacheFavicon(faviconUrl);
    if (refreshedPath == null) {
      return storedPath;
    }

    await (_database.update(
      _database.pages,
    )..where((row) => row.id.equals(page.id))).write(PagesCompanion(faviconFilePath: Value(refreshedPath)));
    return refreshedPath;
  }

  Future<String> _excerptForAnnotation(String annotationId) async {
    final bodies = await (_database.select(
      _database.annotationBodies,
    )..where((body) => body.annotationId.equals(annotationId))).get();
    final target = await (_database.select(
      _database.annotationTargets,
    )..where((target) => target.annotationId.equals(annotationId))).getSingleOrNull();
    AnnotationBody? textualBody;
    for (final body in bodies) {
      if (body.type == 'TextualBody') {
        textualBody = body;
        break;
      }
    }

    return _annotationExcerpt(textualBody?.value, target?.selectorJson);
  }

  Future<AnnotationVisualStyle> _visualStyleForAnnotation(String annotationId) async {
    final bodies = await (_database.select(
      _database.annotationBodies,
    )..where((body) => body.annotationId.equals(annotationId))).get();
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

  Future<String?> _bookmarkFolderPathForBookmark(String bookmarkId) async {
    final link =
        await (_database.select(_database.bookmarkCollectionLinks)
              ..where((row) => row.bookmarkId.equals(bookmarkId) & row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder), (row) => OrderingTerm.asc(row.createdAt)]))
            .getSingleOrNull();
    return _bookmarkFolderPath(link?.folderId);
  }

  Future<String?> _bookmarkFolderPath(String? folderId) async {
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
      final folder = await (_database.select(
        _database.bookmarkFolders,
      )..where((folder) => folder.id.equals(folderKey))).getSingleOrNull();
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
  });

  final String id;
  final Uri url;
  final String pageTitle;
  final String motivation;
  final AnnotationVisualStyle visualStyle;
  final String excerpt;
  final DateTime modifiedAt;

  bool get isNote => motivation == 'commenting';
  String get typeLabel =>
      isNote ? 'Note' : (visualStyle == AnnotationVisualStyle.underline ? 'Underline' : 'Highlight');
}
