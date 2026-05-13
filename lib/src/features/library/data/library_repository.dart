import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(databaseProvider));
});

final librarySnapshotProvider = FutureProvider.autoDispose<LibrarySnapshot>((ref) {
  return ref.watch(libraryRepositoryProvider).loadSnapshot();
});

class LibraryRepository {
  const LibraryRepository(this._database);

  final AppDatabase _database;

  Future<LibrarySnapshot> loadSnapshot() async {
    final bookmarks = await _loadBookmarkedPages(limit: 12);
    final recentPages = await _loadRecentPages(limit: 12);
    final recentAnnotations = await _loadRecentAnnotations(limit: 12);

    return LibrarySnapshot(bookmarkedPages: bookmarks, recentPages: recentPages, recentAnnotations: recentAnnotations);
  }

  Future<List<LibraryPageItem>> _loadBookmarkedPages({required int limit}) async {
    final rows =
        await (_database.select(_database.bookmarks)
              ..orderBy([(bookmark) => OrderingTerm.desc(bookmark.createdAt)])
              ..limit(limit))
            .get();

    final items = <LibraryPageItem>[];
    for (final bookmark in rows) {
      final page = await _pageForUrl(bookmark.url);
      items.add(
        LibraryPageItem(
          id: page?.id ?? bookmark.id,
          url: Uri.parse(bookmark.url),
          title: _fallbackTitle(bookmark.title, bookmark.url),
          subtitle: _hostFor(bookmark.url),
          annotationCount: page == null ? 0 : await _annotationCountForPage(page.id),
          timestamp: page?.lastVisitedAt ?? bookmark.createdAt,
        ),
      );
    }

    return items;
  }

  Future<List<LibraryPageItem>> _loadRecentPages({required int limit}) async {
    final bookmarkedUrls = await _bookmarkedUrls();
    final query = _database.select(_database.pages)
      ..orderBy([(page) => OrderingTerm.desc(page.lastVisitedAt)])
      ..limit(limit + bookmarkedUrls.length);

    final rows = await query.get();
    final unbookmarkedRows = rows.where((page) => !bookmarkedUrls.contains(page.url)).take(limit);

    final items = <LibraryPageItem>[];
    for (final page in unbookmarkedRows) {
      items.add(
        LibraryPageItem(
          id: page.id,
          url: Uri.parse(page.url),
          title: _fallbackTitle(page.title, page.url),
          subtitle: _hostFor(page.canonicalUrl ?? page.url),
          annotationCount: await _annotationCountForPage(page.id),
          timestamp: page.lastVisitedAt,
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

      final body = await (_database.select(
        _database.annotationBodies,
      )..where((body) => body.annotationId.equals(annotation.id))).getSingleOrNull();
      final target = await (_database.select(
        _database.annotationTargets,
      )..where((target) => target.annotationId.equals(annotation.id))).getSingleOrNull();

      items.add(
        LibraryAnnotationItem(
          id: annotation.id,
          url: Uri.parse(target?.sourceUrl ?? page.url),
          pageTitle: _fallbackTitle(page.title, page.url),
          motivation: annotation.motivation,
          excerpt: _annotationExcerpt(body?.value, target?.selectorJson),
          modifiedAt: annotation.modifiedAt,
        ),
      );
    }

    return items;
  }

  Future<Set<String>> _bookmarkedUrls() async {
    final rows = await _database.select(_database.bookmarks).get();
    return rows.map((bookmark) => bookmark.url).toSet();
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

  String _annotationExcerpt(String? bodyValue, String? selectorJson) {
    final normalizedBody = _normalize(bodyValue);
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
      return _normalize(selector['exact']?.toString());
    }

    if (selector is List<Object?>) {
      for (final value in selector) {
        if (value is Map<String, Object?>) {
          final exact = _normalize(value['exact']?.toString());
          if (exact != null) {
            return exact;
          }
        }
      }
    }

    return null;
  }

  String _fallbackTitle(String? title, String url) {
    return _normalize(title) ?? Uri.tryParse(url)?.host ?? url;
  }

  String _hostFor(String url) {
    return Uri.tryParse(url)?.host ?? url;
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class LibrarySnapshot {
  const LibrarySnapshot({required this.bookmarkedPages, required this.recentPages, required this.recentAnnotations});

  final List<LibraryPageItem> bookmarkedPages;
  final List<LibraryPageItem> recentPages;
  final List<LibraryAnnotationItem> recentAnnotations;

  bool get isEmpty => bookmarkedPages.isEmpty && recentPages.isEmpty && recentAnnotations.isEmpty;
}

class LibraryPageItem {
  const LibraryPageItem({
    required this.id,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.annotationCount,
    required this.timestamp,
  });

  final String id;
  final Uri url;
  final String title;
  final String subtitle;
  final int annotationCount;
  final DateTime timestamp;
}

class LibraryAnnotationItem {
  const LibraryAnnotationItem({
    required this.id,
    required this.url,
    required this.pageTitle,
    required this.motivation,
    required this.excerpt,
    required this.modifiedAt,
  });

  final String id;
  final Uri url;
  final String pageTitle;
  final String motivation;
  final String excerpt;
  final DateTime modifiedAt;
}
