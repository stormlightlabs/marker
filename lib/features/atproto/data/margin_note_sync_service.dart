import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:margin_poptart/at/margin/note/body.dart' as margin_body;
import 'package:margin_poptart/at/margin/note/main.dart' as margin_note;
import 'package:margin_poptart/at/margin/note/main_motivation.dart' as margin_motivation;
import 'package:margin_poptart/at/margin/note/selector.dart' as margin_selector;
import 'package:margin_poptart/at/margin/note/selector_type.dart' as margin_selector_type;
import 'package:margin_poptart/at/margin/note/target.dart' as margin_target;
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/core/shared/utils/atproto_utils.dart';
import 'package:marker/core/shared/utils/json_utils.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/domain/atproto_repo_models.dart';
import 'package:uuid/uuid.dart';

final marginNoteSyncServiceProvider = Provider<MarginNoteSyncService>((ref) {
  return MarginNoteSyncService(
    database: ref.watch(databaseProvider),
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    repoClient: ref.watch(atprotoRepoClientProvider),
  );
});

class MarginNoteSyncResult {
  const MarginNoteSyncResult({
    this.imported = 0,
    this.updated = 0,
    this.pushed = 0,
    this.duplicates = 0,
    this.conflicts = 0,
    this.malformed = 0,
    this.failed = 0,
    this.deferred = 0,
  });

  final int imported;
  final int updated;
  final int pushed;
  final int duplicates;
  final int conflicts;
  final int malformed;
  final int failed;
  final int deferred;

  MarginNoteSyncResult operator +(MarginNoteSyncResult other) => MarginNoteSyncResult(
    imported: imported + other.imported,
    updated: updated + other.updated,
    pushed: pushed + other.pushed,
    duplicates: duplicates + other.duplicates,
    conflicts: conflicts + other.conflicts,
    malformed: malformed + other.malformed,
    failed: failed + other.failed,
    deferred: deferred + other.deferred,
  );
}

class MarginNoteSyncService {
  MarginNoteSyncService({
    required AppDatabase database,
    required AtprotoSyncRepository syncRepository,
    required AtprotoRepoClient repoClient,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _database = database,
       _syncRepository = syncRepository,
       _repoClient = repoClient,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final AtprotoSyncRepository _syncRepository;
  final AtprotoRepoClient _repoClient;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<MarginNoteSyncResult> pull(String accountDid) async {
    var result = const MarginNoteSyncResult();
    String? cursor;
    do {
      final page = await _repoClient.listRecords(
        did: accountDid,
        collection: MarginSyncCollection.note.value,
        cursor: cursor,
        limit: 100,
      );
      for (final record in page.records) {
        result += await _importNote(accountDid, record);
      }
      cursor = page.cursor;
    } while (cursor != null);

    await _syncRepository.saveCursor(
      accountDid: accountDid,
      collection: MarginSyncCollection.note.value,
      cursor: null,
      lastSuccessfulSyncAt: _now(),
    );
    return result;
  }

  Future<MarginNoteSyncResult> pushPending(String accountDid, {int limit = 100}) async {
    final pending = await _syncRepository.pendingOutbox(accountDid: accountDid, limit: limit);
    var result = const MarginNoteSyncResult();
    for (final item in pending.where(
      (item) =>
          item.localTable == SembleSyncLocalTable.annotations.value &&
          item.collection == MarginSyncCollection.note.value &&
          (item.operation == AtprotoSyncOperation.create.value || item.operation == AtprotoSyncOperation.update.value),
    )) {
      if (!_isDue(item)) {
        result += const MarginNoteSyncResult(deferred: 1);
        continue;
      }
      try {
        await _pushItem(item);
        await _syncRepository.deleteOutbox(item.id);
        result += const MarginNoteSyncResult(pushed: 1);
      } on Object catch (error) {
        await _syncRepository.markOutboxAttempt(
          id: item.id,
          attemptCount: item.attemptCount + 1,
          lastError: _shortError(error),
        );
        result += const MarginNoteSyncResult(failed: 1);
      }
    }
    return result;
  }

  Future<MarginNoteSyncResult> _importNote(String accountDid, AtprotoRepoRecord remote) async {
    try {
      final note = const margin_note.NoteRecordConverter().fromJson(remote.value);
      final source = emptyToNull(note.target.source);
      if (source == null) return const MarginNoteSyncResult(malformed: 1);
      final sourceUri = Uri.tryParse(source);
      if (sourceUri == null || !sourceUri.hasScheme) return const MarginNoteSyncResult(malformed: 1);

      final mirror = await _syncRepository.mirrorForUri(accountDid: accountDid, uri: remote.uri);
      if (mirror?.dirtyAt != null) return const MarginNoteSyncResult(conflicts: 1);

      final json = canonicalJson(remote.value);
      final hash = stableJenkinsOneAtATimeHash(json);
      if (mirror != null && mirror.lastSyncedHash == hash && mirror.deletedAt == null) {
        return const MarginNoteSyncResult(duplicates: 1);
      }

      final page = await _upsertPage(source, note.target.title);
      final annotationId = mirror?.localId ?? _uuid.v4();
      final motivation = note.motivation.toJson();
      final createdAt = note.createdAt;
      final modifiedAt = note.modifiedAt ?? createdAt;
      final selectorJson = jsonEncode([if (note.target.selector != null) _selectorToLocalJson(note.target.selector!)]);
      final body = emptyToNull(note.body?.value);
      final color = emptyToNull(note.color);

      await _database.transaction(() async {
        if (mirror == null) {
          await _database
              .into(_database.annotations)
              .insert(
                AnnotationsCompanion.insert(
                  id: annotationId,
                  pageId: page.id,
                  motivation: motivation,
                  createdAt: createdAt,
                  modifiedAt: modifiedAt,
                ),
              );
        } else {
          await (_database.update(_database.annotations)..where((row) => row.id.equals(annotationId))).write(
            AnnotationsCompanion(
              pageId: Value(page.id),
              motivation: Value(motivation),
              modifiedAt: Value(modifiedAt),
              deletedAt: const Value(null),
            ),
          );
          await (_database.delete(
            _database.annotationTargets,
          )..where((row) => row.annotationId.equals(annotationId))).go();
          await (_database.delete(
            _database.annotationBodies,
          )..where((row) => row.annotationId.equals(annotationId))).go();
        }

        await _database
            .into(_database.annotationTargets)
            .insert(
              AnnotationTargetsCompanion.insert(
                id: _uuid.v4(),
                annotationId: annotationId,
                sourceUrl: source,
                selectorJson: selectorJson,
              ),
            );
        if (body != null) {
          await _database
              .into(_database.annotationBodies)
              .insert(
                AnnotationBodiesCompanion.insert(
                  id: _uuid.v4(),
                  annotationId: annotationId,
                  type: 'TextualBody',
                  format: Value(emptyToNull(note.body?.format) ?? 'text/plain'),
                  value: body,
                ),
              );
        }
        if (color != null) {
          await _database
              .into(_database.annotationBodies)
              .insert(
                AnnotationBodiesCompanion.insert(
                  id: _uuid.v4(),
                  annotationId: annotationId,
                  type: 'StyleHint',
                  format: const Value('application/json'),
                  value: jsonEncode({'style': AnnotationVisualStyle.highlight.name, 'color': color}),
                ),
              );
        }
      });

      await _syncRepository.upsertMirror(
        accountDid: accountDid,
        localTable: SembleSyncLocalTable.annotations.value,
        localId: annotationId,
        collection: MarginSyncCollection.note.value,
        rkey: rkeyFromUri(remote.uri),
        uri: remote.uri,
        cid: remote.cid,
        lastSyncedRecordJson: json,
        lastSyncedHash: hash,
        lastSyncedAt: _now(),
      );
      return MarginNoteSyncResult(imported: mirror == null ? 1 : 0, updated: mirror == null ? 0 : 1);
    } on Object {
      return const MarginNoteSyncResult(malformed: 1);
    }
  }

  Future<void> _pushItem(AtprotoSyncOutboxData item) async {
    final mirror = await _syncRepository.mirrorForLocal(
      accountDid: item.accountDid,
      localTable: item.localTable,
      localId: item.localId,
      collection: item.collection,
    );
    final record = await mapLocalAnnotationToMarginNote(item.localId);
    final json = canonicalJson(record);
    final hash = stableJenkinsOneAtATimeHash(json);
    if (mirror?.lastSyncedHash == hash && mirror?.deletedAt == null) return;

    final rkey = mirror?.rkey ?? _rkeyForLocal(item.localId);
    final write = await _repoClient.putRecord(
      did: item.accountDid,
      collection: item.collection,
      rkey: rkey,
      record: record,
      swapRecord: mirror?.cid,
    );
    await _syncRepository.upsertMirror(
      accountDid: item.accountDid,
      localTable: item.localTable,
      localId: item.localId,
      collection: item.collection,
      rkey: rkeyFromUri(write.uri),
      uri: write.uri,
      cid: write.cid,
      lastSyncedRecordJson: json,
      lastSyncedHash: hash,
      lastSyncedAt: _now(),
    );
  }

  Future<Map<String, dynamic>> mapLocalAnnotationToMarginNote(String annotationId) async {
    final annotation = await (_database.select(
      _database.annotations,
    )..where((row) => row.id.equals(annotationId) & row.deletedAt.isNull())).getSingleOrNull();
    if (annotation == null) throw StateError('Annotation no longer exists locally.');
    final page = await (_database.select(
      _database.pages,
    )..where((row) => row.id.equals(annotation.pageId))).getSingle();
    final target = await (_database.select(
      _database.annotationTargets,
    )..where((row) => row.annotationId.equals(annotation.id))).getSingleOrNull();
    if (target == null) throw StateError('Annotation target no longer exists locally.');
    final bodies = await (_database.select(
      _database.annotationBodies,
    )..where((row) => row.annotationId.equals(annotation.id))).get();
    final local = PageAnnotation(annotation: annotation, target: target, bodies: bodies);
    final noteBody = local.note;

    return const margin_note.NoteRecordConverter().toJson(
      margin_note.NoteRecord(
        motivation: _noteMotivation(annotation.motivation),
        color: emptyToNull(local.colorHex),
        body: noteBody == null
            ? null
            : margin_body.Body(
                value: noteBody,
                format: bodies.firstWhere((body) => body.type == 'TextualBody').format ?? 'text/markdown',
              ),
        target: margin_target.Target(
          source: target.sourceUrl,
          title: emptyToNull(page.title),
          selector: _chooseRemoteSelector(local.selectors),
        ),
        createdAt: annotation.createdAt,
        modifiedAt: annotation.modifiedAt,
      ),
    );
  }

  Future<Page> _upsertPage(String url, String? title) async {
    final existing = await (_database.select(_database.pages)..where((row) => row.url.equals(url))).getSingleOrNull();
    if (existing != null) {
      if (emptyToNull(title) != null) {
        await (_database.update(
          _database.pages,
        )..where((row) => row.id.equals(existing.id))).write(PagesCompanion(title: Value(title)));
      }
      return (_database.select(_database.pages)..where((row) => row.id.equals(existing.id))).getSingle();
    }
    final now = _now();
    final id = _uuid.v4();
    await _database
        .into(_database.pages)
        .insert(
          PagesCompanion.insert(id: id, url: url, title: Value(emptyToNull(title)), createdAt: now, lastVisitedAt: now),
        );
    return (_database.select(_database.pages)..where((row) => row.id.equals(id))).getSingle();
  }

  margin_selector.Selector? _chooseRemoteSelector(List<Map<String, Object?>> selectors) {
    for (final selector in selectors) {
      if (selector['type'] == 'TextQuoteSelector' || selector['type'] == 'TextPositionSelector') {
        return _localSelectorToRemote(selector);
      }
    }
    for (final selector in selectors) {
      final mapped = _localSelectorToRemote(selector);
      if (mapped != null) return mapped;
    }
    return null;
  }

  margin_selector.Selector? _localSelectorToRemote(Map<String, Object?> selector) {
    final type = margin_selector_type.SelectorType.valueOf(emptyToNull(selector['type']?.toString()));
    if (type == null) return null;
    return margin_selector.Selector(
      type: type,
      exact: emptyToNull(selector['exact']?.toString()),
      prefix: emptyToNull(selector['prefix']?.toString()),
      suffix: emptyToNull(selector['suffix']?.toString()),
      start: selector['start'] is int ? selector['start'] as int : int.tryParse(selector['start']?.toString() ?? ''),
      end: selector['end'] is int ? selector['end'] as int : int.tryParse(selector['end']?.toString() ?? ''),
      value: emptyToNull(selector['value']?.toString()),
      conformsTo: emptyToNull(selector['conformsTo']?.toString()),
    );
  }

  Map<String, Object?> _selectorToLocalJson(margin_selector.Selector selector) => {
    'type': selector.type.toJson(),
    if (selector.exact != null) 'exact': selector.exact,
    if (selector.prefix != null) 'prefix': selector.prefix,
    if (selector.suffix != null) 'suffix': selector.suffix,
    if (selector.start != null) 'start': selector.start,
    if (selector.end != null) 'end': selector.end,
    if (selector.value != null) 'value': selector.value,
    if (selector.conformsTo != null) 'conformsTo': selector.conformsTo,
  };

  margin_motivation.NoteMotivation _noteMotivation(String motivation) =>
      margin_motivation.NoteMotivation.valueOf(motivation) ??
      margin_motivation.NoteMotivation.unknown(data: motivation);

  bool _isDue(AtprotoSyncOutboxData item) {
    if (item.attemptCount <= 0) return true;
    final backoff = Duration(minutes: 1 << (item.attemptCount - 1).clamp(0, 5));
    return !item.updatedAt.add(backoff).isAfter(_now());
  }

  String _rkeyForLocal(String localId) {
    final safe = localId.replaceAll(RegExp(r'[^A-Za-z0-9._~-]'), '-');
    if (safe.isNotEmpty && safe.length <= 512 && !safe.startsWith('.')) return safe;
    return 'm-${stableJenkinsOneAtATimeHash('annotations:$localId')}';
  }

  String _shortError(Object error) {
    final value = error.toString();
    return value.length <= 240 ? value : '${value.substring(0, 240)}…';
  }
}
