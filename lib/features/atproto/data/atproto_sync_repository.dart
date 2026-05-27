import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:uuid/uuid.dart';

final atprotoSyncRepositoryProvider = Provider<AtprotoSyncRepository>((ref) {
  return AtprotoSyncRepository(ref.watch(databaseProvider));
});

class AtprotoSyncRepository {
  AtprotoSyncRepository(this._database, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _database;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<T> transaction<T>(Future<T> Function(AtprotoSyncRepository repository) action) {
    return _database.transaction(() => action(this));
  }

  Future<List<AtprotoAccount>> accounts() {
    return (_database.select(
      _database.atprotoAccounts,
    )..orderBy([(account) => OrderingTerm.desc(account.updatedAt)])).get();
  }

  Future<AtprotoAccount?> accountByDid(String did) {
    return (_database.select(_database.atprotoAccounts)..where((account) => account.did.equals(did))).getSingleOrNull();
  }

  Future<void> deleteAccount(String did) async {
    await (_database.delete(_database.atprotoAccounts)..where((account) => account.did.equals(did))).go();
  }

  Future<AtprotoAccount> upsertAccount({
    required String did,
    required String authMethod,
    String? handle,
    String? pdsEndpoint,
  }) async {
    final existing = await (_database.select(
      _database.atprotoAccounts,
    )..where((account) => account.did.equals(did))).getSingleOrNull();
    final now = _now();
    if (existing == null) {
      await _database
          .into(_database.atprotoAccounts)
          .insert(
            AtprotoAccountsCompanion.insert(
              did: did,
              authMethod: authMethod,
              handle: Value(handle),
              pdsEndpoint: Value(pdsEndpoint),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(_database.atprotoAccounts)..where((account) => account.did.equals(did))).write(
        AtprotoAccountsCompanion(
          authMethod: Value(authMethod),
          handle: Value(handle),
          pdsEndpoint: Value(pdsEndpoint),
          updatedAt: Value(now),
        ),
      );
    }
    return (_database.select(_database.atprotoAccounts)..where((account) => account.did.equals(did))).getSingle();
  }

  Future<AtprotoRecordMirror> upsertMirror({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
    required String rkey,
    required String uri,
    String? cid,
    String? lastSyncedRecordJson,
    String? lastSyncedHash,
    DateTime? lastSyncedAt,
    DateTime? dirtyAt,
    DateTime? deletedAt,
  }) async {
    final byUri = await mirrorForUri(accountDid: accountDid, uri: uri);
    final existing =
        byUri ??
        await mirrorForLocal(accountDid: accountDid, localTable: localTable, localId: localId, collection: collection);
    if (existing == null) {
      return createMirror(
        accountDid: accountDid,
        localTable: localTable,
        localId: localId,
        collection: collection,
        rkey: rkey,
        uri: uri,
        cid: cid,
        lastSyncedRecordJson: lastSyncedRecordJson,
        lastSyncedHash: lastSyncedHash,
        lastSyncedAt: lastSyncedAt,
        dirtyAt: dirtyAt,
        deletedAt: deletedAt,
      );
    }

    await (_database.update(_database.atprotoRecordMirrors)..where((mirror) => mirror.id.equals(existing.id))).write(
      AtprotoRecordMirrorsCompanion(
        localTable: Value(localTable),
        localId: Value(localId),
        collection: Value(collection),
        rkey: Value(rkey),
        uri: Value(uri),
        cid: Value(cid),
        lastSyncedRecordJson: Value(lastSyncedRecordJson),
        lastSyncedHash: Value(lastSyncedHash),
        lastSyncedAt: Value(lastSyncedAt),
        dirtyAt: Value(dirtyAt),
        deletedAt: Value(deletedAt),
      ),
    );
    return (_database.select(
      _database.atprotoRecordMirrors,
    )..where((mirror) => mirror.id.equals(existing.id))).getSingle();
  }

  Future<AtprotoRecordMirror> createMirror({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
    required String rkey,
    required String uri,
    String? cid,
    String? lastSyncedRecordJson,
    String? lastSyncedHash,
    DateTime? lastSyncedAt,
    DateTime? dirtyAt,
    DateTime? deletedAt,
  }) async {
    final id = _uuid.v4();
    await _database
        .into(_database.atprotoRecordMirrors)
        .insert(
          AtprotoRecordMirrorsCompanion.insert(
            id: id,
            accountDid: accountDid,
            localTable: localTable,
            localId: localId,
            collection: collection,
            rkey: rkey,
            uri: uri,
            cid: Value(cid),
            lastSyncedRecordJson: Value(lastSyncedRecordJson),
            lastSyncedHash: Value(lastSyncedHash),
            lastSyncedAt: Value(lastSyncedAt),
            dirtyAt: Value(dirtyAt),
            deletedAt: Value(deletedAt),
          ),
        );
    return (_database.select(_database.atprotoRecordMirrors)..where((mirror) => mirror.id.equals(id))).getSingle();
  }

  Future<AtprotoRecordMirror?> mirrorForLocal({
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
  }) =>
      (_database.select(_database.atprotoRecordMirrors)..where(
            (mirror) =>
                mirror.accountDid.equals(accountDid) &
                mirror.localTable.equals(localTable) &
                mirror.localId.equals(localId) &
                mirror.collection.equals(collection),
          ))
          .getSingleOrNull();

  Future<AtprotoRecordMirror?> mirrorForUri({required String accountDid, required String uri}) => (_database.select(
    _database.atprotoRecordMirrors,
  )..where((mirror) => mirror.accountDid.equals(accountDid) & mirror.uri.equals(uri))).getSingleOrNull();

  Future<void> markMirrorSynced({
    required String id,
    required String cid,
    required String lastSyncedRecordJson,
    required String lastSyncedHash,
    DateTime? lastSyncedAt,
  }) async {
    await (_database.update(_database.atprotoRecordMirrors)..where((mirror) => mirror.id.equals(id))).write(
      AtprotoRecordMirrorsCompanion(
        cid: Value(cid),
        lastSyncedRecordJson: Value(lastSyncedRecordJson),
        lastSyncedHash: Value(lastSyncedHash),
        lastSyncedAt: Value(lastSyncedAt ?? _now()),
        dirtyAt: const Value(null),
      ),
    );
  }

  Future<AtprotoSyncStateData?> syncState({required String accountDid, required String collection}) {
    return (_database.select(
      _database.atprotoSyncState,
    )..where((state) => state.accountDid.equals(accountDid) & state.collection.equals(collection))).getSingleOrNull();
  }

  Future<AtprotoSyncStateData> saveCursor({
    required String accountDid,
    required String collection,
    String? cursor,
    DateTime? lastSuccessfulSyncAt,
    String? lastError,
  }) async {
    final existing = await syncState(accountDid: accountDid, collection: collection);
    if (existing == null) {
      final id = _uuid.v4();
      await _database
          .into(_database.atprotoSyncState)
          .insert(
            AtprotoSyncStateCompanion.insert(
              id: id,
              accountDid: accountDid,
              collection: collection,
              cursor: Value(cursor),
              lastSuccessfulSyncAt: Value(lastSuccessfulSyncAt),
              lastError: Value(lastError),
            ),
          );
      return (_database.select(_database.atprotoSyncState)..where((state) => state.id.equals(id))).getSingle();
    }

    await (_database.update(_database.atprotoSyncState)..where((state) => state.id.equals(existing.id))).write(
      AtprotoSyncStateCompanion(
        cursor: Value(cursor),
        lastSuccessfulSyncAt: Value(lastSuccessfulSyncAt),
        lastError: Value(lastError),
      ),
    );
    return (_database.select(_database.atprotoSyncState)..where((state) => state.id.equals(existing.id))).getSingle();
  }

  Future<AtprotoSyncOutboxData> enqueueOutbox({
    required String accountDid,
    required String operation,
    required String localTable,
    required String localId,
    required String collection,
    String? payloadJson,
  }) async {
    final now = _now();
    final id = _uuid.v4();
    await _database
        .into(_database.atprotoSyncOutbox)
        .insert(
          AtprotoSyncOutboxCompanion.insert(
            id: id,
            accountDid: accountDid,
            operation: operation,
            localTable: localTable,
            localId: localId,
            collection: collection,
            payloadJson: Value(payloadJson),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_database.select(_database.atprotoSyncOutbox)..where((outbox) => outbox.id.equals(id))).getSingle();
  }

  Future<List<AtprotoSyncOutboxData>> pendingOutbox({String? accountDid, int limit = 100}) {
    final query = _database.select(_database.atprotoSyncOutbox)
      ..orderBy([(outbox) => OrderingTerm.asc(outbox.createdAt)])
      ..limit(limit);
    if (accountDid != null) {
      query.where((outbox) => outbox.accountDid.equals(accountDid));
    }
    return query.get();
  }

  Future<void> markOutboxAttempt({required String id, required int attemptCount, String? lastError}) async {
    await (_database.update(_database.atprotoSyncOutbox)..where((outbox) => outbox.id.equals(id))).write(
      AtprotoSyncOutboxCompanion(
        attemptCount: Value(attemptCount),
        lastError: Value(lastError),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<void> deleteOutbox(String id) async {
    await (_database.delete(_database.atprotoSyncOutbox)..where((outbox) => outbox.id.equals(id))).go();
  }
}
