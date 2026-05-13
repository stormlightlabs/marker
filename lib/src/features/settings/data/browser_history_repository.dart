import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';

final browserHistoryRepositoryProvider = Provider<BrowserHistoryRepository>((ref) {
  return BrowserHistoryRepository(ref.watch(databaseProvider));
});

final browserHistoryProvider = FutureProvider.autoDispose<List<BrowserHistoryItem>>((ref) {
  return ref.watch(browserHistoryRepositoryProvider).listHistory();
});

class BrowserHistoryRepository {
  const BrowserHistoryRepository(this._database);

  final AppDatabase _database;

  Future<List<BrowserHistoryItem>> listHistory({int limit = 100}) async {
    final rows =
        await (_database.select(_database.browserHistoryEntries)
              ..orderBy([(entry) => OrderingTerm.desc(entry.visitedAt)])
              ..limit(limit))
            .get();

    return rows.map(BrowserHistoryItem.fromRow).toList(growable: false);
  }

  Future<void> clearHistory() {
    return _database.delete(_database.browserHistoryEntries).go();
  }
}

class BrowserHistoryItem {
  const BrowserHistoryItem({
    required this.id,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.visitedAt,
  });

  factory BrowserHistoryItem.fromRow(BrowserHistoryEntry row) {
    final url = Uri.parse(row.url);
    return BrowserHistoryItem(
      id: row.id,
      url: url,
      title: _fallbackTitle(row.title, row.url),
      subtitle: _subtitleFor(row),
      visitedAt: row.visitedAt,
    );
  }

  final String id;
  final Uri url;
  final String title;
  final String subtitle;
  final DateTime visitedAt;

  static String _fallbackTitle(String? title, String url) {
    final trimmed = title?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return Uri.tryParse(url)?.host ?? url;
  }

  static String _subtitleFor(BrowserHistoryEntry row) {
    final canonical = row.canonicalUrl?.trim();
    if (canonical != null && canonical.isNotEmpty && canonical != row.url) {
      return Uri.tryParse(canonical)?.host ?? canonical;
    }
    return Uri.tryParse(row.url)?.host ?? row.url;
  }
}
