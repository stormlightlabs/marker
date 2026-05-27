import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/atproto/data/atproto_repo_client.dart';

void main() {
  test('fake repo client supports create put get list and delete', () async {
    final client = FakeAtprotoRepoClient();

    final created = await client.createRecord(
      did: 'did:plc:alice',
      collection: 'network.cosmik.card',
      rkey: 'card-1',
      record: {'url': 'https://example.com'},
    );
    expect(created.uri, 'at://did:plc:alice/network.cosmik.card/card-1');

    await client.putRecord(
      did: 'did:plc:alice',
      collection: 'network.cosmik.card',
      rkey: 'card-1',
      record: {'url': 'https://example.com/updated'},
      swapRecord: created.cid,
    );
    final record = await client.getRecord(did: 'did:plc:alice', collection: 'network.cosmik.card', rkey: 'card-1');
    expect(record?.value['url'], 'https://example.com/updated');

    final page = await client.listRecords(did: 'did:plc:alice', collection: 'network.cosmik.card');
    expect(page.records, hasLength(1));

    await client.deleteRecord(did: 'did:plc:alice', collection: 'network.cosmik.card', rkey: 'card-1');
    expect(await client.getRecord(did: 'did:plc:alice', collection: 'network.cosmik.card', rkey: 'card-1'), isNull);
  });
}
