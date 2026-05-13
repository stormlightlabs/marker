import 'dart:convert';

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

  Future<Annotation> createAnnotation({
    required Uri sourceUrl,
    required String exact,
    required String motivation,
    required int textPositionStart,
    required int textPositionEnd,
    String prefix = '',
    String suffix = '',
    String? pageTitle,
    String? cssSelector,
    List<AnnotationBodyInput> bodies = const [],
  }) async {
    final page = await recordPageVisit(url: sourceUrl, title: pageTitle);
    final now = _now();
    final annotationId = _uuid.v4();

    await _database.transaction(() async {
      await _database
          .into(_database.annotations)
          .insert(
            AnnotationsCompanion.insert(
              id: annotationId,
              pageId: page.id,
              motivation: motivation,
              createdAt: now,
              modifiedAt: now,
            ),
          );

      await _database
          .into(_database.annotationTargets)
          .insert(
            AnnotationTargetsCompanion.insert(
              id: _uuid.v4(),
              annotationId: annotationId,
              sourceUrl: sourceUrl.toString(),
              selectorJson: jsonEncode([
                {'type': 'TextQuoteSelector', 'exact': exact, 'prefix': prefix, 'suffix': suffix},
                {'type': 'TextPositionSelector', 'start': textPositionStart, 'end': textPositionEnd},
                if (_normalize(cssSelector) != null) {'type': 'CssSelector', 'value': cssSelector!.trim()},
              ]),
            ),
          );

      for (final body in bodies) {
        await _database
            .into(_database.annotationBodies)
            .insert(
              AnnotationBodiesCompanion.insert(
                id: _uuid.v4(),
                annotationId: annotationId,
                type: body.type,
                format: Value(body.format),
                value: body.value,
              ),
            );
      }
    });

    return (_database.select(
      _database.annotations,
    )..where((annotation) => annotation.id.equals(annotationId))).getSingle();
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class AnnotationBodyInput {
  const AnnotationBodyInput({required this.type, required this.value, this.format});

  factory AnnotationBodyInput.style({required AnnotationVisualStyle style, required String colorHex}) {
    return AnnotationBodyInput(
      type: 'StyleHint',
      format: 'application/json',
      value: jsonEncode({'style': style.name, 'color': colorHex}),
    );
  }

  factory AnnotationBodyInput.markdownNote(String value) {
    return AnnotationBodyInput(type: 'TextualBody', format: 'text/markdown', value: value.trim());
  }

  final String type;
  final String? format;
  final String value;
}

enum AnnotationVisualStyle { highlight, underline }
