import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/application/atproto_login_controller.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_session_store.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:poptart/poptart.dart';

import '../../../helpers/harness.dart';

void main() {
  late AppDatabase database;
  late AtprotoAuthRepository authRepository;
  late FakeAtprotoOAuthClient oauthClient;
  late FakeAtprotoOAuthBrowser browser;

  setUp(() {
    FakeWebViewPlatform();
    database = AppDatabase(NativeDatabase.memory());
    oauthClient = FakeAtprotoOAuthClient();
    browser = FakeAtprotoOAuthBrowser();
    authRepository = AtprotoAuthRepository(
      syncRepository: AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 26, 12)),
      sessionStore: MemoryAtprotoSessionStore(),
      oauthClient: oauthClient,
      now: () => DateTime.utc(2026, 5, 26, 12),
    );
  });

  tearDown(() async {
    authRepository.dispose();
    await database.close();
  });

  testWidgets('connects ATProto account from settings sheet', (tester) async {
    await tester.pumpWidget(
      markerTestApp(
        database: database,
        additionalOverrides: [
          atprotoAuthRepositoryProvider.overrideWithValue(authRepository),
          atprotoOAuthBrowserProvider.overrideWithValue(browser),
        ],
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('ATProto Sync'), findsOneWidget);
    expect(find.text('Connect a Bluesky or Atmosphere account'), findsOneWidget);

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(find.text('Connect ATProto'), findsOneWidget);
    expect(find.text('Use your Bluesky or Atmosphere account to import Semble/Cosmik bookmarks.'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), ' @alice.bsky.social ');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(oauthClient.authorizedHandle, 'alice.bsky.social');
    expect(browser.authorizationUrls, [Uri.parse('https://bsky.social/oauth/authorize?request_uri=abc')]);
    expect(find.text('Import bookmarks now?'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Connected as did:plc:alice'), findsOneWidget);
  });
}

class FakeAtprotoOAuthBrowser implements AtprotoOAuthBrowser {
  final authorizationUrls = <Uri>[];

  @override
  Future<String> authenticate(Uri authorizationUrl) async {
    authorizationUrls.add(authorizationUrl);
    return 'https://marker.stormlightlabs.org/oauth/callback?code=code&state=state-1';
  }
}

class FakeAtprotoOAuthClient implements AtprotoOAuthClient {
  String? authorizedHandle;

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
    return OAuthSession(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      tokenType: 'DPoP',
      scope: 'atproto transition:generic',
      expiresAt: DateTime.utc(2026, 5, 26, 13),
      sub: 'did:plc:alice',
      $clientId: markerAtprotoOAuthClientId,
      $pdsEndpoint: 'porcini.us-east.host.bsky.network',
      $dPoPNonce: 'nonce-1',
      $publicKey: 'public-key-1',
      $privateKey: 'private-key-1',
    );
  }

  @override
  Future<OAuthSession> refresh(OAuthSession session) async => session;
}
