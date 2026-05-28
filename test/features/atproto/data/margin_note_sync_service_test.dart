import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:margin_poptart/at/margin/note/body.dart' as margin_body;
import 'package:margin_poptart/at/margin/note/main.dart' as margin_note;
import 'package:margin_poptart/at/margin/note/main_motivation.dart' as margin_motivation;
import 'package:margin_poptart/at/margin/note/selector.dart' as margin_selector;
import 'package:margin_poptart/at/margin/note/selector_type.dart' as margin_selector_type;
import 'package:margin_poptart/at/margin/note/target.dart' as margin_target;
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/margin_note_sync_service.dart';
import 'package:marker/features/atproto/domain/atproto_repo_models.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late FakeAtprotoRepoClient repoClient;
  late MarginNoteSyncService service;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 28, 12));
    repoClient = FakeAtprotoRepoClient();
    service = MarginNoteSyncService(
      database: database,
      syncRepository: syncRepository,
      repoClient: repoClient,
      now: () => DateTime.utc(2026, 5, 28, 12),
    );
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
  });

  tearDown(() async {
    await database.close();
  });

  test('pull imports remote note with selector, markdown body, and color', () async {
    repoClient.records['at://did:plc:alice/at.margin.note/note-1'] = AtprotoRepoRecord(
      uri: 'at://did:plc:alice/at.margin.note/note-1',
      cid: 'cid-note-1',
      value: _remoteNote(
        source: 'https://example.com/article',
        body: 'Remote note',
        selector: const margin_selector.Selector(
          type: margin_selector_type.SelectorType.knownValue(
            data: margin_selector_type.KnownSelectorType.textQuoteSelector,
          ),
          exact: 'quoted text',
          prefix: 'before ',
          suffix: ' after',
        ),
        color: '#FFCC00',
      ),
    );

    final result = await service.pull('did:plc:alice');

    expect(result.imported, 1);
    final annotations = await database.select(database.annotations).get();
    expect(annotations.single.motivation, 'commenting');
    final target = await database.select(database.annotationTargets).getSingle();
    expect(target.sourceUrl, 'https://example.com/article');
    expect(jsonDecode(target.selectorJson), [
      {'type': 'TextQuoteSelector', 'exact': 'quoted text', 'prefix': 'before ', 'suffix': ' after'},
    ]);
    final bodies = await database.select(database.annotationBodies).get();
    expect(bodies.map((body) => body.type), containsAll(['TextualBody', 'StyleHint']));
    expect(bodies.firstWhere((body) => body.type == 'TextualBody').value, 'Remote note');
    final mirror = await syncRepository.mirrorForUri(
      accountDid: 'did:plc:alice',
      uri: 'at://did:plc:alice/at.margin.note/note-1',
    );
    expect(mirror?.localId, annotations.single.id);
  });

  test('pull does not aggressively dedupe notes on the same URL and quote', () async {
    final value = _remoteNote(
      source: 'https://example.com/article',
      body: 'Same',
      selector: _textQuoteSelector('same quote'),
    );
    repoClient.records['at://did:plc:alice/at.margin.note/note-1'] = AtprotoRepoRecord(
      uri: 'at://did:plc:alice/at.margin.note/note-1',
      cid: 'cid-note-1',
      value: value,
    );
    repoClient.records['at://did:plc:alice/at.margin.note/note-2'] = AtprotoRepoRecord(
      uri: 'at://did:plc:alice/at.margin.note/note-2',
      cid: 'cid-note-2',
      value: value,
    );

    final result = await service.pull('did:plc:alice');

    expect(result.imported, 2);
    expect(await database.select(database.annotations).get(), hasLength(2));
  });

  test('pull counts malformed selector records without importing', () async {
    repoClient.records['at://did:plc:alice/at.margin.note/bad'] = const AtprotoRepoRecord(
      uri: 'at://did:plc:alice/at.margin.note/bad',
      cid: 'cid-bad',
      value: {
        r'$type': 'at.margin.note',
        'motivation': 'commenting',
        'target': {r'$type': 'at.margin.note#target', 'source': 'not a uri'},
        'createdAt': '2026-05-28T12:00:00.000Z',
      },
    );

    final result = await service.pull('did:plc:alice');

    expect(result.malformed, 1);
    expect(await database.select(database.annotations).get(), isEmpty);
  });

  test('push maps highlight, underline, and note while preserving local selector array', () async {
    await _seedAnnotation(
      database,
      id: 'annotation-1',
      motivation: 'commenting',
      note: '**Local note**',
      styleJson: {'style': 'underline', 'color': '#64D2FF'},
    );
    await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: SembleSyncLocalTable.annotations.value,
      localId: 'annotation-1',
      collection: MarginSyncCollection.note.value,
    );

    final result = await service.pushPending('did:plc:alice');

    expect(result.pushed, 1);
    final record = repoClient.records.values.single.value;
    expect(record['motivation'], 'commenting');
    expect(record['color'], '#64D2FF');
    expect((record['body'] as Map<String, Object?>)['value'], '**Local note**');
    final target = record['target'] as Map<String, Object?>;
    expect((target['selector'] as Map<String, Object?>)['type'], 'TextQuoteSelector');
    expect((target['selector'] as Map<String, Object?>)['exact'], 'quote');

    final storedTarget = await database.select(database.annotationTargets).getSingle();
    expect(jsonDecode(storedTarget.selectorJson), hasLength(2));
  });
}

Map<String, dynamic> _remoteNote({
  required String source,
  required String body,
  required margin_selector.Selector selector,
  String? color,
}) {
  return const margin_note.NoteRecordConverter().toJson(
    margin_note.NoteRecord(
      motivation: const margin_motivation.NoteMotivation.knownValue(
        data: margin_motivation.KnownNoteMotivation.commenting,
      ),
      color: color,
      body: margin_body.Body(value: body, format: 'text/markdown'),
      target: margin_target.Target(source: source, title: 'Remote title', selector: selector),
      createdAt: DateTime.utc(2026, 5, 28, 12),
      modifiedAt: DateTime.utc(2026, 5, 28, 12, 30),
    ),
  );
}

margin_selector.Selector _textQuoteSelector(String exact) => margin_selector.Selector(
  type: const margin_selector_type.SelectorType.knownValue(
    data: margin_selector_type.KnownSelectorType.textQuoteSelector,
  ),
  exact: exact,
);

Future<void> _seedAnnotation(
  AppDatabase database, {
  required String id,
  required String motivation,
  String? note,
  Map<String, Object?>? styleJson,
}) async {
  await database
      .into(database.pages)
      .insert(
        PagesCompanion.insert(
          id: 'page-1',
          url: 'https://example.com/article',
          title: const Value('Local title'),
          createdAt: DateTime.utc(2026, 5, 28, 11),
          lastVisitedAt: DateTime.utc(2026, 5, 28, 11),
        ),
      );
  await database
      .into(database.annotations)
      .insert(
        AnnotationsCompanion.insert(
          id: id,
          pageId: 'page-1',
          motivation: motivation,
          createdAt: DateTime.utc(2026, 5, 28, 11),
          modifiedAt: DateTime.utc(2026, 5, 28, 11, 30),
        ),
      );
  await database
      .into(database.annotationTargets)
      .insert(
        AnnotationTargetsCompanion.insert(
          id: 'target-1',
          annotationId: id,
          sourceUrl: 'https://example.com/article',
          selectorJson: jsonEncode([
            {'type': 'TextQuoteSelector', 'exact': 'quote', 'prefix': 'pre', 'suffix': 'suf'},
            {'type': 'TextPositionSelector', 'start': 4, 'end': 9},
          ]),
        ),
      );
  if (note != null) {
    await database
        .into(database.annotationBodies)
        .insert(
          AnnotationBodiesCompanion.insert(
            id: 'body-note',
            annotationId: id,
            type: 'TextualBody',
            format: const Value('text/markdown'),
            value: note,
          ),
        );
  }
  if (styleJson != null) {
    await database
        .into(database.annotationBodies)
        .insert(
          AnnotationBodiesCompanion.insert(
            id: 'body-style',
            annotationId: id,
            type: 'StyleHint',
            format: const Value('application/json'),
            value: jsonEncode(styleJson),
          ),
        );
  }
}
