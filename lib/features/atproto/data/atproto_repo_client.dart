import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/domain/atproto_repo_models.dart';
import 'package:poptart_lex/com/atproto/repo/create_record.dart' as create_record;
import 'package:poptart_lex/com/atproto/repo/delete_record.dart' as delete_record;
import 'package:poptart_lex/com/atproto/repo/get_record.dart' as get_record;
import 'package:poptart_lex/com/atproto/repo/list_records.dart' as list_records;
import 'package:poptart_lex/com/atproto/repo/put_record.dart' as put_record;

final atprotoRepoClientProvider = Provider<AtprotoRepoClient>((ref) {
  return PoptartAtprotoRepoClient(ref.watch(atprotoAuthRepositoryProvider));
});

abstract interface class AtprotoRepoClient {
  Future<AtprotoRepoWriteResult> createRecord({
    required String did,
    required String collection,
    String? rkey,
    required Map<String, dynamic> record,
  });

  Future<AtprotoRepoWriteResult> putRecord({
    required String did,
    required String collection,
    required String rkey,
    required Map<String, dynamic> record,
    String? swapRecord,
  });

  Future<void> deleteRecord({
    required String did,
    required String collection,
    required String rkey,
    String? swapRecord,
  });

  Future<AtprotoRepoRecord?> getRecord({required String did, required String collection, required String rkey});

  Future<AtprotoRepoListPage> listRecords({
    required String did,
    required String collection,
    String? cursor,
    int limit = 50,
  });
}

class PoptartAtprotoRepoClient implements AtprotoRepoClient {
  PoptartAtprotoRepoClient(this._authRepository);

  final AtprotoAuthRepository _authRepository;

  @override
  Future<AtprotoRepoWriteResult> createRecord({
    required String did,
    required String collection,
    String? rkey,
    required Map<String, dynamic> record,
  }) async {
    final client = await _authRepository.requireClient(did);
    final response = await client.call(
      create_record.comAtprotoRepoCreateRecord,
      input: create_record.RepoCreateRecordInput(repo: did, collection: collection, rkey: rkey, record: record),
    );
    await _authRepository.persistClientSession(did);
    return AtprotoRepoWriteResult(uri: response.data.uri.toString(), cid: response.data.cid);
  }

  @override
  Future<AtprotoRepoWriteResult> putRecord({
    required String did,
    required String collection,
    required String rkey,
    required Map<String, dynamic> record,
    String? swapRecord,
  }) async {
    final client = await _authRepository.requireClient(did);
    final response = await client.call(
      put_record.comAtprotoRepoPutRecord,
      input: put_record.RepoPutRecordInput(
        repo: did,
        collection: collection,
        rkey: rkey,
        record: record,
        swapRecord: swapRecord,
      ),
    );
    await _authRepository.persistClientSession(did);
    return AtprotoRepoWriteResult(uri: response.data.uri.toString(), cid: response.data.cid);
  }

  @override
  Future<void> deleteRecord({
    required String did,
    required String collection,
    required String rkey,
    String? swapRecord,
  }) async {
    final client = await _authRepository.requireClient(did);
    await client.call(
      delete_record.comAtprotoRepoDeleteRecord,
      input: delete_record.RepoDeleteRecordInput(repo: did, collection: collection, rkey: rkey, swapRecord: swapRecord),
    );
    await _authRepository.persistClientSession(did);
  }

  @override
  Future<AtprotoRepoRecord?> getRecord({required String did, required String collection, required String rkey}) async {
    final client = await _authRepository.requireClient(did);
    final response = await client.call(
      get_record.comAtprotoRepoGetRecord,
      parameters: get_record.RepoGetRecordInput(repo: did, collection: collection, rkey: rkey),
    );
    await _authRepository.persistClientSession(did);
    return AtprotoRepoRecord(uri: response.data.uri.toString(), cid: response.data.cid, value: response.data.value);
  }

  @override
  Future<AtprotoRepoListPage> listRecords({
    required String did,
    required String collection,
    String? cursor,
    int limit = 50,
  }) async {
    final client = await _authRepository.requireClient(did);
    final response = await client.call(
      list_records.comAtprotoRepoListRecords,
      parameters: list_records.RepoListRecordsInput(repo: did, collection: collection, cursor: cursor, limit: limit),
    );
    await _authRepository.persistClientSession(did);
    return AtprotoRepoListPage(
      cursor: response.data.cursor,
      records: response.data.records
          .map((record) => AtprotoRepoRecord(uri: record.uri.toString(), cid: record.cid, value: record.value))
          .toList(growable: false),
    );
  }
}

class FakeAtprotoRepoClient implements AtprotoRepoClient {
  final List<Object> calls = <Object>[];
  final Map<String, AtprotoRepoRecord> records = <String, AtprotoRepoRecord>{};

  @override
  Future<AtprotoRepoWriteResult> createRecord({
    required String did,
    required String collection,
    String? rkey,
    required Map<String, dynamic> record,
  }) async {
    calls.add(('create', did, collection, rkey, record));
    final key = rkey ?? 'created-${records.length + 1}';
    final uri = 'at://$did/$collection/$key';
    final stored = AtprotoRepoRecord(uri: uri, cid: 'cid-${records.length + 1}', value: record);
    records[uri] = stored;
    return AtprotoRepoWriteResult(uri: uri, cid: stored.cid!);
  }

  @override
  Future<AtprotoRepoWriteResult> putRecord({
    required String did,
    required String collection,
    required String rkey,
    required Map<String, dynamic> record,
    String? swapRecord,
  }) async {
    calls.add(('put', did, collection, rkey, record, swapRecord));
    final uri = 'at://$did/$collection/$rkey';
    final stored = AtprotoRepoRecord(uri: uri, cid: 'cid-${records.length + 1}', value: record);
    records[uri] = stored;
    return AtprotoRepoWriteResult(uri: uri, cid: stored.cid!);
  }

  @override
  Future<void> deleteRecord({
    required String did,
    required String collection,
    required String rkey,
    String? swapRecord,
  }) async {
    calls.add(('delete', did, collection, rkey, swapRecord));
    records.remove('at://$did/$collection/$rkey');
  }

  @override
  Future<AtprotoRepoRecord?> getRecord({required String did, required String collection, required String rkey}) async {
    calls.add(('get', did, collection, rkey));
    return records['at://$did/$collection/$rkey'];
  }

  @override
  Future<AtprotoRepoListPage> listRecords({
    required String did,
    required String collection,
    String? cursor,
    int limit = 50,
  }) async {
    calls.add(('list', did, collection, cursor, limit));
    final prefix = 'at://$did/$collection/';
    return AtprotoRepoListPage(
      records: records.values.where((record) => record.uri.startsWith(prefix)).take(limit).toList(growable: false),
    );
  }
}
