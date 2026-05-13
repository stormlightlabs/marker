import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:marker/src/features/annotations/data/annotation_repository.dart';

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
    final targets = await database.select(database.annotationTargets).get();
    final bodies = await database.select(database.annotationBodies).get();

    expect(annotation.motivation, 'commenting');
    expect(pages.single.url, 'https://example.com/article');
    expect(targets.single.sourceUrl, 'https://example.com/article');
    expect(jsonDecode(targets.single.selectorJson), hasLength(3));
    expect(bodies.map((body) => body.type), containsAll(['TextualBody', 'StyleHint']));
    expect(bodies.firstWhere((body) => body.type == 'TextualBody').format, 'text/markdown');
  });
}
