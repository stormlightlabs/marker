import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_session_store.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/domain/atproto_account_session.dart';
import 'package:poptart/poptart.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late MemoryAtprotoSessionStore sessionStore;
  late FakeAtprotoOAuthClient oauthClient;
  late AtprotoAuthRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 26, 12));
    sessionStore = MemoryAtprotoSessionStore();
    oauthClient = FakeAtprotoOAuthClient();
    repository = AtprotoAuthRepository(
      syncRepository: syncRepository,
      sessionStore: sessionStore,
      oauthClient: oauthClient,
      now: () => DateTime.utc(2026, 5, 26, 12),
    );
  });

  tearDown(() async {
    repository.dispose();
    await database.close();
  });

  test('stores pending context when starting OAuth', () async {
    final url = await repository.startConnect(handle: 'alice.bsky.social');

    expect(url.toString(), 'https://bsky.social/oauth/authorize?request_uri=abc');
    expect(oauthClient.authorizedHandle, 'alice.bsky.social');
    expect(sessionStore.pendingContext?.state, 'state-1');
  });

  test('completes OAuth and stores account metadata separately from session', () async {
    await repository.startConnect(handle: 'alice.bsky.social');

    final account = await repository.completeConnect('marker://callback?code=code&state=state-1');

    expect(account.did, 'did:plc:alice');
    expect(account.authMethod, 'oauth');
    expect(account.pdsEndpoint, 'porcini.us-east.host.bsky.network');
    expect(sessionStore.pendingContext, isNull);
    expect(sessionStore.sessions.keys, ['did:plc:alice']);
    expect((await syncRepository.accounts()).single.did, 'did:plc:alice');
    expect(repository.state, isA<AtprotoAuthConnected>());
  });

  test('restores the first account that has a secure OAuth session', () async {
    await syncRepository.upsertAccount(did: 'did:plc:alice', authMethod: 'oauth');
    await sessionStore.saveOAuthSession('did:plc:alice', fakeSession());

    final restored = await repository.restore();

    expect(restored?.did, 'did:plc:alice');
    expect(repository.state, isA<AtprotoAuthConnected>());
  });

  test('refreshes expired sessions and persists the replacement', () async {
    await repository.startConnect();
    await repository.completeConnect('marker://callback?code=code&state=state-1');

    final account = await repository.refreshIfNeeded('did:plc:alice');

    expect(account.did, 'did:plc:alice');
    expect(oauthClient.refreshCount, 1);
    expect(sessionStore.sessions['did:plc:alice']?.accessToken, 'access-token-2');
  });

  test('disconnect clears secret session and leaves account metadata for sync diagnostics', () async {
    await repository.startConnect();
    await repository.completeConnect('marker://callback?code=code&state=state-1');

    await repository.disconnect('did:plc:alice');

    expect(sessionStore.sessions, isEmpty);
    expect((await syncRepository.accounts()).single.did, 'did:plc:alice');
    expect(repository.state, isA<AtprotoAuthDisconnected>());
  });
}

class FakeAtprotoOAuthClient implements AtprotoOAuthClient {
  String? authorizedHandle;
  int refreshCount = 0;

  @override
  Future<(Uri, OAuthContext)> authorize({String? handle}) async {
    authorizedHandle = handle;
    return (
      Uri.parse('https://bsky.social/oauth/authorize?request_uri=abc'),
      const OAuthContext(codeVerifier: 'verifier-1', state: 'state-1', dpopNonce: 'nonce-1'),
    );
  }

  @override
  Future<OAuthSession> callback({required String callbackUrl, required OAuthContext context}) async {
    expect(context.state, 'state-1');
    return fakeSession();
  }

  @override
  Future<OAuthSession> refresh(OAuthSession session) async {
    refreshCount += 1;
    return fakeSession(accessToken: 'access-token-2', expiresAt: DateTime.utc(2026, 5, 26, 13));
  }
}

OAuthSession fakeSession({String accessToken = 'access-token-1', DateTime? expiresAt}) {
  return OAuthSession(
    accessToken: accessToken,
    refreshToken: 'refresh-token-1',
    tokenType: 'DPoP',
    scope: 'atproto transition:generic',
    expiresAt: expiresAt ?? DateTime.utc(2026, 5, 26, 11),
    sub: 'did:plc:alice',
    $clientId: markerAtprotoOAuthClientId,
    $pdsEndpoint: 'porcini.us-east.host.bsky.network',
    $dPoPNonce: 'nonce-1',
    $publicKey: 'public-key-1',
    $privateKey: 'private-key-1',
  );
}
