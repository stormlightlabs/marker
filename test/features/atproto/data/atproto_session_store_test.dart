import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/atproto/data/atproto_session_store.dart';
import 'package:poptart/poptart.dart';

void main() {
  test('memory session store preserves pending context and OAuth sessions', () async {
    final store = MemoryAtprotoSessionStore();
    const context = OAuthContext(codeVerifier: 'verifier', state: 'state', dpopNonce: 'nonce');
    final session = OAuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      tokenType: 'DPoP',
      scope: 'atproto transition:generic',
      expiresAt: DateTime.utc(2026, 5, 26, 13),
      sub: 'did:plc:alice',
      $clientId: 'https://marker.stormlightlabs.org/client-metadata.json',
      $pdsEndpoint: 'https://pds.example',
      $dPoPNonce: 'nonce',
      $publicKey: 'public',
      $privateKey: 'private',
    );

    await store.savePendingOAuthContext(context);
    expect(await store.readPendingOAuthContext(), context);

    await store.saveOAuthSession('did:plc:alice', session);
    expect((await store.readOAuthSession('did:plc:alice'))?.accessToken, 'access');

    await store.clearPendingOAuthContext();
    await store.deleteOAuthSession('did:plc:alice');
    expect(await store.readPendingOAuthContext(), isNull);
    expect(await store.readOAuthSession('did:plc:alice'), isNull);
  });
}
