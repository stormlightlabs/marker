import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';
import 'package:uuid/uuid.dart';

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return AnnotationRepository(ref.watch(databaseProvider));
});

class AnnotationRepository {
  AnnotationRepository(this._database, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<Page> recordPageVisit({required Uri url, Uri? canonicalUrl, String? title}) async {
    final now = _now();
    final normalizedUrl = url.toString();

    final existing = await (_database.select(
      _database.pages,
    )..where((page) => page.url.equals(normalizedUrl))).getSingleOrNull();

    if (existing != null) {
      final updatedTitle = title?.trim();
      await (_database.update(_database.pages)..where((page) => page.id.equals(existing.id))).write(
        PagesCompanion(
          canonicalUrl: Value(canonicalUrl?.toString()),
          title: updatedTitle == null || updatedTitle.isEmpty ? const Value.absent() : Value(updatedTitle),
          lastVisitedAt: Value(now),
        ),
      );

      return (_database.select(_database.pages)..where((page) => page.id.equals(existing.id))).getSingle();
    }

    final pageId = _uuid.v4();
    await _database
        .into(_database.pages)
        .insert(
          PagesCompanion.insert(
            id: pageId,
            url: normalizedUrl,
            canonicalUrl: Value(canonicalUrl?.toString()),
            title: Value(title?.trim().isEmpty ?? true ? null : title!.trim()),
            createdAt: now,
            lastVisitedAt: now,
          ),
        );

    return (_database.select(_database.pages)..where((page) => page.id.equals(pageId))).getSingle();
  }
}
