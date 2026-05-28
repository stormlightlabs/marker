import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/settings/data/settings_repository.dart';
import 'package:uuid/uuid.dart';

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return AnnotationRepository(
    ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final annotationsForPageProvider = FutureProvider.autoDispose.family<List<PageAnnotation>, Uri>((ref, sourceUrl) {
  return ref.watch(annotationRepositoryProvider).listAnnotationsForPage(sourceUrl: sourceUrl);
});

final annotationDetailProvider = FutureProvider.autoDispose.family<AnnotationDetail?, String>((ref, annotationId) {
  return ref.watch(annotationRepositoryProvider).getAnnotationDetail(annotationId);
});

class AnnotationRepository {
  AnnotationRepository(
    this._database, {
    AtprotoSyncRepository? syncRepository,
    AppLogger? logger,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _syncRepository = syncRepository,
       _logger = logger,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final AtprotoSyncRepository? _syncRepository;
  final AppLogger? _logger;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<Page> recordPageVisit({
    required Uri url,
    Uri? canonicalUrl,
    String? title,
    String? description,
    Uri? faviconUrl,
    String? faviconFilePath,
  }) async {
    return _recordPage(
      url: url,
      canonicalUrl: canonicalUrl,
      title: title,
      description: description,
      faviconUrl: faviconUrl,
      faviconFilePath: faviconFilePath,
      recordHistory: true,
    );
  }

  Future<Page> _recordPage({
    required Uri url,
    Uri? canonicalUrl,
    String? title,
    String? description,
    Uri? faviconUrl,
    String? faviconFilePath,
    required bool recordHistory,
    bool preserveExistingCanonicalUrl = false,
  }) async {
    final now = _now();
    final normalizedUrl = url.toString();
    final normalizedTitle = title?.trim();
    final normalizedDescription = description?.trim();
    Page pageRow;

    final existing = await (_database.select(
      _database.pages,
    )..where((page) => page.url.equals(normalizedUrl))).getSingleOrNull();

    if (existing != null) {
      await (_database.update(_database.pages)..where((page) => page.id.equals(existing.id))).write(
        PagesCompanion(
          canonicalUrl: canonicalUrl == null && preserveExistingCanonicalUrl
              ? const Value.absent()
              : Value(canonicalUrl?.toString()),
          title: normalizedTitle == null || normalizedTitle.isEmpty ? const Value.absent() : Value(normalizedTitle),
          description: normalizedDescription == null || normalizedDescription.isEmpty
              ? const Value.absent()
              : Value(normalizedDescription),
          faviconUrl: faviconUrl == null ? const Value.absent() : Value(faviconUrl.toString()),
          faviconFilePath: faviconFilePath == null ? const Value.absent() : Value(faviconFilePath),
          lastVisitedAt: Value(now),
        ),
      );

      pageRow = await (_database.select(_database.pages)..where((page) => page.id.equals(existing.id))).getSingle();
    } else {
      final pageId = _uuid.v4();
      await _database
          .into(_database.pages)
          .insert(
            PagesCompanion.insert(
              id: pageId,
              url: normalizedUrl,
              canonicalUrl: Value(canonicalUrl?.toString()),
              title: Value(normalizedTitle == null || normalizedTitle.isEmpty ? null : normalizedTitle),
              description: Value(
                normalizedDescription == null || normalizedDescription.isEmpty ? null : normalizedDescription,
              ),
              faviconUrl: Value(faviconUrl?.toString()),
              faviconFilePath: Value(faviconFilePath),
              createdAt: now,
              lastVisitedAt: now,
            ),
          );

      pageRow = await (_database.select(_database.pages)..where((page) => page.id.equals(pageId))).getSingle();
    }

    if (recordHistory) {
      await _database
          .into(_database.browserHistoryEntries)
          .insert(
            BrowserHistoryEntriesCompanion.insert(
              id: _uuid.v4(),
              url: normalizedUrl,
              canonicalUrl: Value(canonicalUrl?.toString()),
              title: Value(normalizedTitle == null || normalizedTitle.isEmpty ? null : normalizedTitle),
              description: Value(
                normalizedDescription == null || normalizedDescription.isEmpty ? null : normalizedDescription,
              ),
              visitedAt: now,
            ),
          );
    }

    return pageRow;
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
    List<String> tags = const [],
  }) async {
    final page = await _recordPage(
      url: sourceUrl,
      title: pageTitle,
      faviconUrl: null,
      faviconFilePath: null,
      recordHistory: false,
      preserveExistingCanonicalUrl: true,
    );
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
                if (normalize(cssSelector) != null) {'type': 'CssSelector', 'value': cssSelector!.trim()},
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

      for (final tag in _normalizeTags(tags)) {
        await _database
            .into(_database.annotationTags)
            .insert(
              AnnotationTagsCompanion.insert(id: _uuid.v4(), annotationId: annotationId, name: tag, createdAt: now),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await _enqueueAnnotationSync(annotationId);
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

      final tags = await (_database.select(
        _database.annotationTags,
      )..where((tag) => tag.annotationId.equals(annotation.id))).get();

      items.add(PageAnnotation(annotation: annotation, target: target, bodies: bodies, tags: tags, logger: _logger));
    }

    return items;
  }

  Future<void> deleteAnnotation(String annotationId) async {
    final now = _now();
    await _database.transaction(() async {
      await (_database.update(_database.annotations)..where((annotation) => annotation.id.equals(annotationId))).write(
        AnnotationsCompanion(deletedAt: Value(now), modifiedAt: Value(now)),
      );
      await _enqueueAnnotationSync(annotationId, operation: AtprotoSyncOperation.delete);
    });
  }

  Future<void> deleteAnnotations(Iterable<String> annotationIds) async {
    final ids = annotationIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    final now = _now();
    await _database.transaction(() async {
      await (_database.update(_database.annotations)..where((annotation) => annotation.id.isIn(ids))).write(
        AnnotationsCompanion(deletedAt: Value(now), modifiedAt: Value(now)),
      );
      for (final id in ids) {
        await _enqueueAnnotationSync(id, operation: AtprotoSyncOperation.delete);
      }
    });
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
    final targets = await (_database.select(
      _database.annotationTargets,
    )..where((target) => target.annotationId.equals(annotation.id))).get();
    final target = targets.firstOrNull;
    if (page == null || target == null) {
      return null;
    }

    final bodies = await (_database.select(
      _database.annotationBodies,
    )..where((body) => body.annotationId.equals(annotation.id))).get();

    final tags = await (_database.select(
      _database.annotationTags,
    )..where((tag) => tag.annotationId.equals(annotation.id))).get();

    return AnnotationDetail.build(
      page,
      PageAnnotation(annotation: annotation, target: target, bodies: bodies, tags: tags, logger: _logger),
    );
  }

  Future<void> updateTags({required String annotationId, required List<String> tags}) async {
    final now = _now();
    await _database.transaction(() async {
      await (_database.delete(_database.annotationTags)..where((tag) => tag.annotationId.equals(annotationId))).go();
      for (final tag in _normalizeTags(tags)) {
        await _database
            .into(_database.annotationTags)
            .insert(
              AnnotationTagsCompanion.insert(id: _uuid.v4(), annotationId: annotationId, name: tag, createdAt: now),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await (_database.update(
        _database.annotations,
      )..where((annotation) => annotation.id.equals(annotationId))).write(AnnotationsCompanion(modifiedAt: Value(now)));
      await _enqueueAnnotationSync(annotationId);
    });
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
      await _enqueueAnnotationSync(annotationId);
    });
  }

  Future<String> exportAnnotationsMarkdown({Iterable<String>? annotationIds}) async {
    final details = await _exportDetails(annotationIds: annotationIds);
    final buffer = StringBuffer()
      ..writeln('# Marker Annotations')
      ..writeln();
    String? currentPageId;
    for (final detail in details) {
      if (currentPageId != detail.page.id) {
        currentPageId = detail.page.id;
        buffer
          ..writeln('## ${detail.pageTitle}')
          ..writeln()
          ..writeln(detail.sourceUrl)
          ..writeln();
      }
      final annotation = detail.annotation;
      buffer
        ..writeln('- Type: ${annotation.typeLabel}')
        ..writeln('  Quote: ${annotation.exact ?? 'Untitled annotation'}');
      final note = annotation.note;
      if (note != null) {
        buffer.writeln('  Note: $note');
      }
      buffer
        ..writeln('  Created: ${annotation.annotation.createdAt.toIso8601String()}')
        ..writeln('  Modified: ${annotation.annotation.modifiedAt.toIso8601String()}')
        ..writeln();
    }
    return buffer.toString();
  }

  Future<String> exportAnnotationsJson({Iterable<String>? annotationIds}) async {
    final details = await _exportDetails(annotationIds: annotationIds);
    final payload = [
      for (final detail in details)
        {
          '@context': 'http://www.w3.org/ns/anno.jsonld',
          'id': detail.annotation.annotation.id,
          'type': 'Annotation',
          'motivation': detail.annotation.annotation.motivation,
          'created': detail.annotation.annotation.createdAt.toIso8601String(),
          'modified': detail.annotation.annotation.modifiedAt.toIso8601String(),
          'target': {'source': detail.annotation.target.sourceUrl, 'selector': detail.annotation.selectors},
          'body': [
            for (final body in detail.annotation.bodies)
              {'type': body.type, if (body.format != null) 'format': body.format, 'value': body.value},
          ],
          'page': {
            'id': detail.page.id,
            'url': detail.page.url,
            if (detail.page.canonicalUrl != null) 'canonicalUrl': detail.page.canonicalUrl,
            if (detail.page.title != null) 'title': detail.page.title,
            if (detail.page.description != null) 'description': detail.page.description,
          },
        },
    ];
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<List<AnnotationDetail>> _exportDetails({Iterable<String>? annotationIds}) async {
    final selectedIds = annotationIds?.toSet();
    final query = _database.select(_database.annotations)
      ..where((annotation) => annotation.deletedAt.isNull())
      ..orderBy([(annotation) => OrderingTerm.desc(annotation.modifiedAt)]);
    if (selectedIds != null && selectedIds.isNotEmpty) {
      query.where((annotation) => annotation.id.isIn(selectedIds));
    }
    final rows = await query.get();
    final details = <AnnotationDetail>[];
    for (final annotation in rows) {
      final detail = await getAnnotationDetail(annotation.id);
      if (detail != null) {
        details.add(detail);
      }
    }
    return details;
  }

  Future<void> _enqueueAnnotationSync(
    String annotationId, {
    AtprotoSyncOperation operation = AtprotoSyncOperation.update,
  }) async {
    final syncRepository = _syncRepository;
    if (syncRepository == null || !await _isAnnotationSyncEnabled()) return;
    final accounts = await syncRepository.accounts();
    for (final account in accounts) {
      await syncRepository.enqueueOutbox(
        accountDid: account.did,
        operation: operation.value,
        localTable: SembleSyncLocalTable.annotations.value,
        localId: annotationId,
        collection: MarginSyncCollection.note.value,
      );
    }
  }

  Future<bool> _isAnnotationSyncEnabled() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.key.equals(annotationSyncEnabledSettingKey))).getSingleOrNull();
    return row?.value == 'true';
  }

  List<String> _normalizeTags(Iterable<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in tags) {
      final normalized = normalize(tag)?.replaceAll(RegExp(r'\\s+'), ' ');
      if (normalized == null) continue;
      final key = normalized.toLowerCase();
      if (seen.add(key)) result.add(normalized);
    }
    return result;
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

    final targets = await (_database.select(
      _database.annotationTargets,
    )..where((target) => target.annotationId.equals(annotationId))).get();
    return targets.firstOrNull;
  }
}

class AnnotationDetail {
  const AnnotationDetail({required this.page, required this.annotation});

  factory AnnotationDetail.build(Page page, PageAnnotation annotation) {
    return AnnotationDetail(page: page, annotation: annotation);
  }

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
  const PageAnnotation({
    required this.annotation,
    required this.target,
    required this.bodies,
    this.tags = const [],
    AppLogger? logger,
  }) : _logger = logger;

  final Annotation annotation;
  final AnnotationTarget target;
  final List<AnnotationBody> bodies;
  final List<AnnotationTag> tags;
  final AppLogger? _logger;

  String? get exact {
    for (final selector in selectors) {
      if (selector['type'] == 'TextQuoteSelector') {
        return normalize(selector['exact']?.toString());
      }
    }
    return null;
  }

  String? get note {
    for (final body in bodies) {
      if (body.type == 'TextualBody') {
        return normalize(body.value);
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
      _logger?.debug('Ignoring malformed annotation style hint', error: error);
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
        final color = normalize(decoded['color']?.toString());
        if (color != null) {
          return color;
        }
      }
    } on FormatException catch (error) {
      _logger?.debug('Ignoring malformed annotation color hint', error: error);
    }

    return visualStyle == AnnotationVisualStyle.underline ? '#64D2FF' : '#FFCC00';
  }

  String get typeLabel {
    if (note != null || annotation.motivation == 'commenting') {
      return 'Note';
    }
    return visualStyle == AnnotationVisualStyle.underline ? 'Underline' : 'Highlight';
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
      _logger?.debug('Ignoring malformed annotation selector JSON', error: error);
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
      if (tags.isNotEmpty) 'tags': [for (final tag in tags) tag.name],
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
}
