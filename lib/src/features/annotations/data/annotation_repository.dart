import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/core/database/database_provider.dart';
import 'package:uuid/uuid.dart';

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return AnnotationRepository(ref.watch(databaseProvider));
});

final annotationsForPageProvider = FutureProvider.autoDispose.family<List<PageAnnotation>, Uri>((ref, sourceUrl) {
  return ref.watch(annotationRepositoryProvider).listAnnotationsForPage(sourceUrl: sourceUrl);
});

final annotationDetailProvider = FutureProvider.autoDispose.family<AnnotationDetail?, String>((ref, annotationId) {
  return ref.watch(annotationRepositoryProvider).getAnnotationDetail(annotationId);
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

  Future<List<PageAnnotation>> listAnnotationsForPage({required Uri sourceUrl}) async {
    final source = sourceUrl.toString();
    final pages = await (_database.select(
      _database.pages,
    )..where((page) => page.url.equals(source) | page.canonicalUrl.equals(source))).get();
    final pageIds = pages.map((page) => page.id).toSet();

    final targetRows = await (_database.select(
      _database.annotationTargets,
    )..where((target) => target.sourceUrl.equals(source))).get();
    final targetAnnotationIds = targetRows.map((target) => target.annotationId).toSet();

    if (pageIds.isEmpty && targetAnnotationIds.isEmpty) {
      return const [];
    }

    final annotationQuery = _database.select(_database.annotations)
      ..where((annotation) => annotation.deletedAt.isNull());
    if (pageIds.isNotEmpty && targetAnnotationIds.isNotEmpty) {
      annotationQuery.where((annotation) => annotation.pageId.isIn(pageIds) | annotation.id.isIn(targetAnnotationIds));
    } else if (pageIds.isNotEmpty) {
      annotationQuery.where((annotation) => annotation.pageId.isIn(pageIds));
    } else {
      annotationQuery.where((annotation) => annotation.id.isIn(targetAnnotationIds));
    }
    annotationQuery.orderBy([(annotation) => OrderingTerm.asc(annotation.createdAt)]);
    final annotations = await annotationQuery.get();

    final items = <PageAnnotation>[];
    for (final annotation in annotations) {
      final target = await _targetForAnnotation(annotation.id, fallbackTargets: targetRows);
      if (target == null) {
        continue;
      }

      final bodies = await (_database.select(
        _database.annotationBodies,
      )..where((body) => body.annotationId.equals(annotation.id))).get();

      items.add(PageAnnotation(annotation: annotation, target: target, bodies: bodies));
    }

    return items;
  }

  Future<void> deleteAnnotation(String annotationId) async {
    final now = _now();
    await (_database.update(_database.annotations)..where((annotation) => annotation.id.equals(annotationId))).write(
      AnnotationsCompanion(deletedAt: Value(now), modifiedAt: Value(now)),
    );
  }

  Future<AnnotationDetail?> getAnnotationDetail(String annotationId) async {
    final annotation = await (_database.select(
      _database.annotations,
    )..where((annotation) => annotation.id.equals(annotationId) & annotation.deletedAt.isNull())).getSingleOrNull();
    if (annotation == null) {
      return null;
    }

    final page = await (_database.select(
      _database.pages,
    )..where((page) => page.id.equals(annotation.pageId))).getSingleOrNull();
    final target = await (_database.select(
      _database.annotationTargets,
    )..where((target) => target.annotationId.equals(annotation.id))).getSingleOrNull();
    if (page == null || target == null) {
      return null;
    }

    final bodies = await (_database.select(
      _database.annotationBodies,
    )..where((body) => body.annotationId.equals(annotation.id))).get();

    return AnnotationDetail(
      page: page,
      annotation: PageAnnotation(annotation: annotation, target: target, bodies: bodies),
    );
  }

  Future<void> updateMarkdownBody({required String annotationId, required String value}) async {
    final now = _now();
    final trimmed = value.trim();

    await _database.transaction(() async {
      final existingBodies = await (_database.select(
        _database.annotationBodies,
      )..where((body) => body.annotationId.equals(annotationId) & body.type.equals('TextualBody'))).get();

      if (trimmed.isEmpty) {
        await (_database.delete(
          _database.annotationBodies,
        )..where((body) => body.annotationId.equals(annotationId) & body.type.equals('TextualBody'))).go();
      } else if (existingBodies.isEmpty) {
        await _database
            .into(_database.annotationBodies)
            .insert(
              AnnotationBodiesCompanion.insert(
                id: _uuid.v4(),
                annotationId: annotationId,
                type: 'TextualBody',
                format: const Value('text/markdown'),
                value: trimmed,
              ),
            );
      } else {
        final firstBody = existingBodies.first;
        await (_database.update(_database.annotationBodies)..where((body) => body.id.equals(firstBody.id))).write(
          AnnotationBodiesCompanion(format: const Value('text/markdown'), value: Value(trimmed)),
        );

        for (final duplicate in existingBodies.skip(1)) {
          await (_database.delete(_database.annotationBodies)..where((body) => body.id.equals(duplicate.id))).go();
        }
      }

      await (_database.update(_database.annotations)..where((annotation) => annotation.id.equals(annotationId))).write(
        AnnotationsCompanion(
          motivation: Value(trimmed.isEmpty ? 'highlighting' : 'commenting'),
          modifiedAt: Value(now),
        ),
      );
    });
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<AnnotationTarget?> _targetForAnnotation(
    String annotationId, {
    required List<AnnotationTarget> fallbackTargets,
  }) async {
    for (final target in fallbackTargets) {
      if (target.annotationId == annotationId) {
        return target;
      }
    }

    return (_database.select(
      _database.annotationTargets,
    )..where((target) => target.annotationId.equals(annotationId))).getSingleOrNull();
  }
}

class AnnotationDetail {
  const AnnotationDetail({required this.page, required this.annotation});

  final Page page;
  final PageAnnotation annotation;

  Uri get sourceUrl => Uri.parse(annotation.target.sourceUrl);

  String get pageTitle {
    final trimmed = page.title?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return Uri.tryParse(page.url)?.host ?? page.url;
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

class PageAnnotation {
  const PageAnnotation({required this.annotation, required this.target, required this.bodies});

  final Annotation annotation;
  final AnnotationTarget target;
  final List<AnnotationBody> bodies;

  String? get exact {
    for (final selector in selectors) {
      if (selector['type'] == 'TextQuoteSelector') {
        return _normalize(selector['exact']?.toString());
      }
    }
    return null;
  }

  String? get note {
    for (final body in bodies) {
      if (body.type == 'TextualBody') {
        return _normalize(body.value);
      }
    }
    return null;
  }

  AnnotationVisualStyle get visualStyle {
    final styleBody = _styleBody;
    if (styleBody == null) {
      return AnnotationVisualStyle.highlight;
    }

    try {
      final decoded = jsonDecode(styleBody.value);
      if (decoded is Map<String, Object?> && decoded['style'] == AnnotationVisualStyle.underline.name) {
        return AnnotationVisualStyle.underline;
      }
    } on FormatException catch (error) {
      // Bad style hints should not make saved annotations disappear.
      // The default highlight keeps the annotation visible.
      debugPrint('Ignoring malformed annotation style hint: $error');
    }

    return AnnotationVisualStyle.highlight;
  }

  String get colorHex {
    final styleBody = _styleBody;
    if (styleBody == null) {
      return visualStyle == AnnotationVisualStyle.underline ? '#64D2FF' : '#FFCC00';
    }

    try {
      final decoded = jsonDecode(styleBody.value);
      if (decoded is Map<String, Object?>) {
        final color = _normalize(decoded['color']?.toString());
        if (color != null) {
          return color;
        }
      }
    } on FormatException catch (error) {
      debugPrint('Ignoring malformed annotation color hint: $error');
    }

    return visualStyle == AnnotationVisualStyle.underline ? '#64D2FF' : '#FFCC00';
  }

  List<Map<String, Object?>> get selectors {
    try {
      final decoded = jsonDecode(target.selectorJson);
      final selector = decoded is Map<String, Object?> ? decoded['selector'] : decoded;
      if (selector is List<Object?>) {
        return [
          for (final value in selector)
            if (value is Map<String, Object?>) value,
        ];
      }
    } on FormatException catch (error) {
      debugPrint('Ignoring malformed annotation selector JSON: $error');
    }

    return const [];
  }

  Map<String, Object?> toRenderPayload() {
    return {
      'id': annotation.id,
      'motivation': annotation.motivation,
      'sourceUrl': target.sourceUrl,
      'selector': selectors,
      'style': visualStyle.name,
      'color': colorHex,
      if (note != null) 'note': note,
    };
  }

  AnnotationBody? get _styleBody {
    for (final body in bodies) {
      if (body.type == 'StyleHint') {
        return body;
      }
    }
    return null;
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
