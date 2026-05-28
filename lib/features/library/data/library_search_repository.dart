import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzywuzzy;
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/shared/utils/text_utils.dart';

final librarySearchRepositoryProvider = Provider<LibrarySearchRepository>((ref) {
  return LibrarySearchRepository(ref.watch(databaseProvider));
});

final librarySearchProvider = FutureProvider.autoDispose.family<List<LibrarySearchResult>, String>((ref, query) {
  return ref.watch(librarySearchRepositoryProvider).search(query);
});

enum LibrarySearchResultType { page, annotation }

class LibrarySearchRepository {
  const LibrarySearchRepository(this._database);

  final AppDatabase _database;

  Future<void> rebuildIndex() async {
    await _database.createLibrarySearchIndex();
    await _database.transaction(() async {
      await _database.customStatement('DELETE FROM library_search_fts');
      final documents = await _documents();
      for (final document in documents) {
        await _database.customInsert(
          '''
INSERT INTO library_search_fts(
  document_type,
  document_id,
  page_id,
  title,
  url,
  description,
  folder_path,
  annotation_text,
  note_text
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
          variables: [
            Variable.withString(document.type.name),
            Variable.withString(document.id),
            Variable.withString(document.pageId ?? ''),
            Variable.withString(document.title),
            Variable.withString(document.url),
            Variable.withString(document.description ?? ''),
            Variable.withString(document.folderPath ?? ''),
            Variable.withString(document.annotationText ?? ''),
            Variable.withString(document.noteText ?? ''),
          ],
        );
      }
    });
  }

  Future<List<LibrarySearchResult>> search(String query, {int limit = 24}) async {
    final normalizedQuery = normalize(query);
    if (normalizedQuery == null) {
      return const [];
    }

    await rebuildIndex();
    final ftsQuery = _ftsQuery(normalizedQuery);
    final ftsResults = ftsQuery == null ? <LibrarySearchResult>[] : await _searchFts(normalizedQuery, ftsQuery, limit);
    if (ftsResults.length >= min(6, limit)) {
      return ftsResults.take(limit).toList(growable: false);
    }

    final byKey = {for (final result in ftsResults) result.key: result};
    for (final result in await _searchFuzzy(normalizedQuery, limit)) {
      byKey.putIfAbsent(result.key, () => result);
    }

    final results = byKey.values.toList()
      ..sort((left, right) {
        final score = right.score.compareTo(left.score);
        if (score != 0) {
          return score;
        }
        return right.modifiedAt.compareTo(left.modifiedAt);
      });
    return results.take(limit).toList(growable: false);
  }

  Future<List<LibrarySearchResult>> _searchFts(String query, String ftsQuery, int limit) async {
    final rows = await _database
        .customSelect(
          '''
SELECT rowid, document_type, document_id, page_id, title, url, description, folder_path, annotation_text, note_text,
       bm25(library_search_fts, 4.0, 3.0, 1.5, 1.2, 2.6) AS rank
FROM library_search_fts
WHERE library_search_fts MATCH ?
ORDER BY rank
LIMIT ?
''',
          variables: [Variable.withString(ftsQuery), Variable.withInt(limit)],
        )
        .get();

    return [for (final row in rows) _resultFromRow(row, score: 400 + (_score(query, _fieldsFromRow(row)) ?? 0))];
  }

  Future<List<LibrarySearchResult>> _searchFuzzy(String query, int limit) async {
    final rows = await _database.customSelect('SELECT rowid, * FROM library_search_fts').get();
    final results = <LibrarySearchResult>[];
    for (final row in rows) {
      final score = _score(query, _fieldsFromRow(row));
      if (score == null) {
        continue;
      }
      results.add(_resultFromRow(row, score: score));
    }
    results.sort((left, right) => right.score.compareTo(left.score));
    return results.take(limit).toList(growable: false);
  }

  LibrarySearchResult _resultFromRow(QueryRow row, {required int score}) {
    final type = _typeFromName(row.read<String>('document_type'));
    final pageId = normalize(row.read<String>('page_id'));
    final annotationText = normalize(row.read<String>('annotation_text'));
    final noteText = normalize(row.read<String>('note_text'));
    final folderPath = normalize(row.read<String>('folder_path'));
    final description = normalize(row.read<String>('description'));
    final title = row.read<String>('title');
    final url = Uri.parse(row.read<String>('url'));
    return LibrarySearchResult(
      type: type,
      id: row.read<String>('document_id'),
      pageId: pageId,
      url: url,
      title: type == LibrarySearchResultType.annotation ? annotationText ?? noteText ?? 'Untitled annotation' : title,
      subtitle: type == LibrarySearchResultType.annotation ? title : folderPath ?? description ?? url.host,
      description: description,
      annotationText: annotationText,
      noteText: noteText,
      score: score,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('rowid')),
    );
  }

  List<String> _fieldsFromRow(QueryRow row) => [
    row.read<String>('title'),
    row.read<String>('url'),
    row.read<String>('description'),
    row.read<String>('folder_path'),
    row.read<String>('annotation_text'),
    row.read<String>('note_text'),
  ];

  Future<List<_LibrarySearchDocument>> _documents() async {
    final documents = <_LibrarySearchDocument>[];
    final bookmarks = await (_database.select(
      _database.bookmarks,
    )..where((bookmark) => bookmark.deletedAt.isNull())).get();
    final bookmarkByUrl = {for (final bookmark in bookmarks) bookmark.url: bookmark};
    final pagesById = {for (final page in await _database.select(_database.pages).get()) page.id: page};
    final pagesByUrl = {for (final page in pagesById.values) page.url: page};
    final annotatedPageIds = <String>{};

    final annotations =
        await (_database.select(_database.annotations)
              ..where((annotation) => annotation.deletedAt.isNull())
              ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)]))
            .get();
    for (final annotation in annotations) {
      final page = pagesById[annotation.pageId];
      if (page == null) {
        continue;
      }
      annotatedPageIds.add(page.id);
      final targets = await (_database.select(
        _database.annotationTargets,
      )..where((target) => target.annotationId.equals(annotation.id))).get();
      final target = targets.firstOrNull;
      final bodies = await (_database.select(
        _database.annotationBodies,
      )..where((body) => body.annotationId.equals(annotation.id))).get();
      final sourceUrl = target?.sourceUrl ?? page.url;
      documents.add(
        _LibrarySearchDocument(
          type: LibrarySearchResultType.annotation,
          id: annotation.id,
          pageId: page.id,
          title: _fallbackTitle(page.title, sourceUrl),
          url: sourceUrl,
          description: page.description,
          folderPath: await _bookmarkFolderPathForBookmark(bookmarkByUrl[sourceUrl]?.id ?? bookmarkByUrl[page.url]?.id),
          annotationText: _exactSelectorValue(target?.selectorJson),
          noteText: _noteValue(bodies),
        ),
      );
    }

    for (final bookmark in bookmarks) {
      final page = pagesByUrl[bookmark.url];
      documents.add(
        _LibrarySearchDocument(
          type: LibrarySearchResultType.page,
          id: page?.id ?? bookmark.id,
          pageId: page?.id,
          title: _fallbackTitle(bookmark.title ?? page?.title, bookmark.url),
          url: bookmark.url,
          description: page?.description,
          folderPath: await _bookmarkFolderPathForBookmark(bookmark.id),
        ),
      );
    }

    for (final pageId in annotatedPageIds) {
      final page = pagesById[pageId];
      if (page == null || bookmarkByUrl.containsKey(page.url)) {
        continue;
      }
      documents.add(
        _LibrarySearchDocument(
          type: LibrarySearchResultType.page,
          id: page.id,
          pageId: page.id,
          title: _fallbackTitle(page.title, page.url),
          url: page.url,
          description: page.description,
          folderPath: null,
        ),
      );
    }

    return documents;
  }

  String? _ftsQuery(String query) {
    final terms = RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(query.toLowerCase())
        .map((match) => match.group(0))
        .whereType<String>()
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) {
      return null;
    }
    return terms.map((term) => '$term*').join(' ');
  }

  int? _score(String query, List<String?> fields) {
    final normalizedQuery = query.toLowerCase();
    int? bestScore;
    for (final field in fields) {
      final normalizedField = normalize(field)?.toLowerCase();
      if (normalizedField == null) {
        continue;
      }
      final contiguousIndex = normalizedField.indexOf(normalizedQuery);
      final score = contiguousIndex >= 0
          ? 220 + fuzzywuzzy.weightedRatio(normalizedQuery, normalizedField) - contiguousIndex.clamp(0, 100)
          : max(
              fuzzywuzzy.weightedRatio(normalizedQuery, normalizedField),
              fuzzywuzzy.partialRatio(normalizedQuery, normalizedField),
            );
      if (score < 55) {
        continue;
      }
      bestScore = bestScore == null || score > bestScore ? score : bestScore;
    }
    return bestScore;
  }

  String _fallbackTitle(String? title, String url) => normalize(title) ?? Uri.tryParse(url)?.host ?? url;

  String? _noteValue(List<AnnotationBody> bodies) {
    for (final body in bodies) {
      if (body.type == 'TextualBody') {
        return normalize(body.value);
      }
    }
    return null;
  }

  String? _exactSelectorValue(String? selectorJson) {
    if (selectorJson == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(selectorJson);
      if (decoded is Map<String, Object?>) {
        return _exactFromSelector(decoded['selector']);
      }
      return _exactFromSelector(decoded);
    } on FormatException {
      return normalize(selectorJson);
    }
  }

  String? _exactFromSelector(Object? selector) {
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

  Future<String?> _bookmarkFolderPathForBookmark(String? bookmarkId) async {
    if (bookmarkId == null) {
      return null;
    }
    final links =
        await (_database.select(_database.bookmarkCollectionLinks)
              ..where((row) => row.bookmarkId.equals(bookmarkId) & row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder), (row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return _bookmarkFolderPath(links.firstOrNull?.folderId);
  }

  Future<String?> _bookmarkFolderPath(String? folderId) async {
    if (folderId == null) {
      return null;
    }
    final names = <String>[];
    final seen = <String>{};
    String? currentId = folderId;
    while (currentId != null) {
      if (!seen.add(currentId)) {
        break;
      }
      final folder = await (_database.select(
        _database.bookmarkFolders,
      )..where((folder) => folder.id.equals(currentId!))).getSingleOrNull();
      if (folder == null) {
        break;
      }
      names.insert(0, folder.title);
      currentId = folder.parentId;
    }
    return names.isEmpty ? null : names.join(' / ');
  }

  LibrarySearchResultType _typeFromName(String name) => switch (name) {
    'page' => LibrarySearchResultType.page,
    'annotation' => LibrarySearchResultType.annotation,
    _ => LibrarySearchResultType.page,
  };
}

class LibrarySearchResult {
  const LibrarySearchResult({
    required this.type,
    required this.id,
    required this.pageId,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.annotationText,
    required this.noteText,
    required this.score,
    required this.modifiedAt,
  });

  final LibrarySearchResultType type;
  final String id;
  final String? pageId;
  final Uri url;
  final String title;
  final String subtitle;
  final String? description;
  final String? annotationText;
  final String? noteText;
  final int score;
  final DateTime modifiedAt;

  String get key => '${type.name}:$id';
}

class _LibrarySearchDocument {
  const _LibrarySearchDocument({
    required this.type,
    required this.id,
    required this.pageId,
    required this.title,
    required this.url,
    this.description,
    this.folderPath,
    this.annotationText,
    this.noteText,
  });

  final LibrarySearchResultType type;
  final String id;
  final String? pageId;
  final String title;
  final String url;
  final String? description;
  final String? folderPath;
  final String? annotationText;
  final String? noteText;
}
