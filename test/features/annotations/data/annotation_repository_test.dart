import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';

void main() {
  late AppDatabase database;
  late AnnotationRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = AnnotationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('records a first page visit', () async {
    final page = await repository.recordPageVisit(
      url: Uri.parse('https://example.com/article'),
      canonicalUrl: Uri.parse('https://example.com/canonical'),
      title: 'Example Article',
    );

    expect(page.url, 'https://example.com/article');
    expect(page.canonicalUrl, 'https://example.com/canonical');
    expect(page.title, 'Example Article');
    expect(page.createdAt, page.lastVisitedAt);

    final history = await database.select(database.browserHistoryEntries).get();
    expect(history.single.url, 'https://example.com/article');
    expect(history.single.canonicalUrl, 'https://example.com/canonical');
    expect(history.single.title, 'Example Article');
  });

  test('updates title and visit time for an existing URL', () async {
    var now = DateTime.utc(2026, 5, 13, 12);
    repository = AnnotationRepository(database, now: () => now);

    final first = await repository.recordPageVisit(url: Uri.parse('https://example.com/article'), title: 'Old title');

    now = now.add(const Duration(minutes: 5));

    final second = await repository.recordPageVisit(
      url: Uri.parse('https://example.com/article'),
      canonicalUrl: Uri.parse('https://example.com/canonical'),
      title: 'New title',
    );

    expect(second.id, first.id);
    expect(second.title, 'New title');
    expect(second.canonicalUrl, 'https://example.com/canonical');
    expect(second.createdAt, first.createdAt);
    expect(second.lastVisitedAt.isAfter(first.lastVisitedAt), isTrue);

    final history = await database.select(database.browserHistoryEntries).get();
    expect(history, hasLength(2));
    expect(history.last.title, 'New title');
  });

  test('creates an annotation with target selectors and bodies', () async {
    final annotation = await repository.createAnnotation(
      sourceUrl: Uri.parse('https://example.com/article'),
      exact: 'selected text',
      prefix: 'before ',
      suffix: ' after',
      motivation: 'commenting',
      textPositionStart: 7,
      textPositionEnd: 20,
      pageTitle: 'Example Article',
      cssSelector: 'article > p:nth-of-type(1)',
      bodies: [
        AnnotationBodyInput.markdownNote('**Important** note'),
        AnnotationBodyInput.style(style: AnnotationVisualStyle.highlight, colorHex: '#FFCC00'),
      ],
    );

    final pages = await database.select(database.pages).get();
    final history = await database.select(database.browserHistoryEntries).get();
    final targets = await database.select(database.annotationTargets).get();
    final bodies = await database.select(database.annotationBodies).get();

    expect(annotation.motivation, 'commenting');
    expect(pages.single.url, 'https://example.com/article');
    expect(history, isEmpty);
    expect(targets.single.sourceUrl, 'https://example.com/article');
    expect(jsonDecode(targets.single.selectorJson), hasLength(3));
    expect(bodies.map((body) => body.type), containsAll(['TextualBody', 'StyleHint']));
    expect(bodies.firstWhere((body) => body.type == 'TextualBody').format, 'text/markdown');
  });

  test('lists renderable annotations for a page', () async {
    await repository.createAnnotation(
      sourceUrl: Uri.parse('https://example.com/article'),
      exact: 'selected text',
      prefix: 'before ',
      suffix: ' after',
      motivation: 'highlighting',
      textPositionStart: 7,
      textPositionEnd: 20,
      cssSelector: 'article > p:nth-of-type(1)',
      bodies: [AnnotationBodyInput.style(style: AnnotationVisualStyle.underline, colorHex: '#64D2FF')],
    );

    final annotations = await repository.listAnnotationsForPage(sourceUrl: Uri.parse('https://example.com/article'));

    expect(annotations, hasLength(1));
    expect(annotations.single.exact, 'selected text');
    expect(annotations.single.visualStyle, AnnotationVisualStyle.underline);
    expect(annotations.single.colorHex, '#64D2FF');
    expect(annotations.single.toRenderPayload(), {
      'id': annotations.single.annotation.id,
      'motivation': 'highlighting',
      'sourceUrl': 'https://example.com/article',
      'selector': [
        {'type': 'TextQuoteSelector', 'exact': 'selected text', 'prefix': 'before ', 'suffix': ' after'},
        {'type': 'TextPositionSelector', 'start': 7, 'end': 20},
        {'type': 'CssSelector', 'value': 'article > p:nth-of-type(1)'},
      ],
      'style': 'underline',
      'color': '#64D2FF',
    });
  });

  test('keeps canonical page mapping when creating an annotation', () async {
    await repository.recordPageVisit(
      url: Uri.parse('https://example.com/article?utm=reader'),
      canonicalUrl: Uri.parse('https://example.com/article'),
      title: 'Example Article',
    );

    await repository.createAnnotation(
      sourceUrl: Uri.parse('https://example.com/article?utm=reader'),
      exact: 'selected text',
      motivation: 'highlighting',
      textPositionStart: 0,
      textPositionEnd: 13,
      bodies: [AnnotationBodyInput.style(style: AnnotationVisualStyle.highlight, colorHex: '#FFCC00')],
    );

    final page = await database.select(database.pages).getSingle();
    final annotations = await repository.listAnnotationsForPage(sourceUrl: Uri.parse('https://example.com/article'));

    expect(page.canonicalUrl, 'https://example.com/article');
    expect(annotations, hasLength(1));
    expect(annotations.single.exact, 'selected text');
  });

  test('soft deletes annotations and excludes them from page listings', () async {
    final annotation = await repository.createAnnotation(
      sourceUrl: Uri.parse('https://example.com/article'),
      exact: 'selected text',
      motivation: 'highlighting',
      textPositionStart: 0,
      textPositionEnd: 13,
      bodies: [AnnotationBodyInput.style(style: AnnotationVisualStyle.highlight, colorHex: '#FFCC00')],
    );

    await repository.deleteAnnotation(annotation.id);

    final annotations = await repository.listAnnotationsForPage(sourceUrl: Uri.parse('https://example.com/article'));
    final deleted = await (database.select(
      database.annotations,
    )..where((row) => row.id.equals(annotation.id))).getSingle();

    expect(annotations, isEmpty);
    expect(deleted.deletedAt, isNotNull);
  });

  test('loads annotation detail and edits markdown body', () async {
    final annotation = await repository.createAnnotation(
      sourceUrl: Uri.parse('https://example.com/article'),
      exact: 'selected text',
      motivation: 'highlighting',
      textPositionStart: 0,
      textPositionEnd: 13,
      pageTitle: 'Example Article',
      bodies: [AnnotationBodyInput.style(style: AnnotationVisualStyle.highlight, colorHex: '#FFCC00')],
    );

    await repository.updateMarkdownBody(annotationId: annotation.id, value: 'Updated **note**');
    final detail = await repository.getAnnotationDetail(annotation.id);

    expect(detail, isNotNull);
    expect(detail!.pageTitle, 'Example Article');
    expect(detail.annotation.note, 'Updated **note**');
    expect(detail.annotation.annotation.motivation, 'commenting');

    await repository.updateMarkdownBody(annotationId: annotation.id, value: '');
    final updated = await repository.getAnnotationDetail(annotation.id);

    expect(updated!.annotation.note, isNull);
    expect(updated.annotation.annotation.motivation, 'highlighting');
  });
}
