import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzywuzzy;
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/shared/utils/text_utils.dart';

final browserHistorySearchRepositoryProvider = Provider<BrowserHistorySearchRepository>((ref) {
  return BrowserHistorySearchRepository(ref.watch(databaseProvider));
});

final browserHistorySearchProvider = FutureProvider.autoDispose.family<List<BrowserHistorySearchMatch>, String>((
  ref,
  query,
) {
  return ref.watch(browserHistorySearchRepositoryProvider).search(query);
});

class BrowserHistorySearchRepository {
  const BrowserHistorySearchRepository(this._database);

  final AppDatabase _database;

  Future<List<BrowserHistorySearchMatch>> search(String query, {int limit = 8}) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final rows = await _database
        .customSelect(
          '''
SELECT
  h.url AS url,
  COALESCE(h.title, p.title) AS title,
  COALESCE(h.description, p.description) AS description,
  h.canonical_url AS canonical_url,
  p.favicon_url AS favicon_url,
  p.favicon_file_path AS favicon_file_path,
  MAX(h.visited_at) AS visited_at
FROM browser_history_entries h
LEFT JOIN pages p ON p.url = h.url
GROUP BY h.url
ORDER BY visited_at DESC
LIMIT 200
''',
          readsFrom: {_database.browserHistoryEntries, _database.pages},
        )
        .get();

    final matches = <BrowserHistorySearchMatch>[];
    for (final row in rows) {
      final url = row.read<String>('url');
      final title = _fallbackTitle(row.readNullable<String>('title'), url);
      final description = normalize(row.readNullable<String>('description'));
      final canonicalUrl = normalize(row.readNullable<String>('canonical_url'));
      final score = _scoreHistoryMatch(normalizedQuery, fields: [title, url, ?description, ?canonicalUrl]);
      if (score == null) {
        continue;
      }
      matches.add(
        BrowserHistorySearchMatch(
          url: Uri.parse(url),
          title: title,
          description: description,
          faviconUrl: _parseUri(row.readNullable<String>('favicon_url')),
          faviconFilePath: normalize(row.readNullable<String>('favicon_file_path')),
          score: score,
        ),
      );
    }

    matches.sort((left, right) => right.score.compareTo(left.score));
    return matches.take(limit).toList(growable: false);
  }

  static String _fallbackTitle(String? title, String url) {
    final trimmed = normalize(title);
    if (trimmed != null) {
      return trimmed;
    }
    return Uri.tryParse(url)?.host ?? url;
  }
}

class BrowserHistorySearchMatch {
  const BrowserHistorySearchMatch({
    required this.url,
    required this.title,
    required this.description,
    required this.faviconUrl,
    required this.faviconFilePath,
    required this.score,
  });

  final Uri url;
  final String title;
  final String? description;
  final Uri? faviconUrl;
  final String? faviconFilePath;
  final int score;

  String get subtitle => description ?? url.toString();
}

int? _scoreHistoryMatch(String query, {required List<String> fields}) {
  final normalizedQuery = query.toLowerCase();
  int? bestScore;
  for (final field in fields) {
    final normalizedField = field.toLowerCase();
    final contiguousIndex = normalizedField.indexOf(normalizedQuery);
    final score = contiguousIndex >= 0
        ? 200 + fuzzywuzzy.weightedRatio(normalizedQuery, normalizedField) - contiguousIndex.clamp(0, 100)
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

Uri? _parseUri(String? value) {
  final normalized = normalize(value);
  if (normalized == null) {
    return null;
  }
  final uri = Uri.tryParse(normalized);
  return uri != null && uri.hasScheme && uri.hasAuthority ? uri : null;
}
