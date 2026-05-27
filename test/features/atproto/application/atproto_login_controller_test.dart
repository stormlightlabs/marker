import 'package:drift/native.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/features/atproto/application/atproto_login_controller.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_session_store.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:poptart/poptart.dart';

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late MemoryAtprotoSessionStore sessionStore;
  late FakeAtprotoOAuthClient oauthClient;
  late AtprotoAuthRepository authRepository;
  late FakeAtprotoOAuthBrowser browser;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 26, 12));
    sessionStore = MemoryAtprotoSessionStore();
    oauthClient = FakeAtprotoOAuthClient();
    authRepository = AtprotoAuthRepository(
      syncRepository: syncRepository,
      sessionStore: sessionStore,
      oauthClient: oauthClient,
      now: () => DateTime.utc(2026, 5, 26, 12),
    );
    browser = FakeAtprotoOAuthBrowser();
    container = ProviderContainer(
      overrides: [
        atprotoAuthRepositoryProvider.overrideWithValue(authRepository),
        atprotoOAuthBrowserProvider.overrideWithValue(browser),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    authRepository.dispose();
    await database.close();
  });

  test('completes browser OAuth and trims optional handle', () async {
    final states = _recordLoginStates(container);

    final account = await container
        .read(atprotoLoginControllerProvider.notifier)
        .connect(handle: ' @alice.bsky.social ');

    expect(account?.did, 'did:plc:alice');
    expect(oauthClient.authorizedHandle, 'alice.bsky.social');
    expect(browser.authorizationUrls, [Uri.parse('https://bsky.social/oauth/authorize?request_uri=abc')]);
    expect(container.read(atprotoLoginControllerProvider), isA<AtprotoLoginConnected>());
    expect(states.map((state) => state.runtimeType), [
      AtprotoLoginIdle,
      AtprotoLoginStartingOAuth,
      AtprotoLoginWaitingForCallback,
      AtprotoLoginCompletingOAuth,
      AtprotoLoginConnected,
    ]);
  });

  test('logs OAuth start failures and shows configuration-specific copy', () async {
    final logDirectory = await Directory.systemTemp.createTemp('marker-atproto-login-logs');
    final logger = await AppLogger.initialize(directory: logDirectory);
    final localContainer = ProviderContainer(
      overrides: [
        atprotoAuthRepositoryProvider.overrideWithValue(authRepository),
        atprotoOAuthBrowserProvider.overrideWithValue(browser),
        appLoggerProvider.overrideWithValue(logger),
      ],
    );
    oauthClient.authorizeError = StateError('client metadata was not accepted');

    final account = await localContainer.read(atprotoLoginControllerProvider.notifier).connect(handle: 'alice.bsky.social');

    expect(account, isNull);
    final state = localContainer.read(atprotoLoginControllerProvider);
    expect(state, isA<AtprotoLoginFailed>());
    expect((state as AtprotoLoginFailed).message, 'Could not load Marker sign-in configuration. Try again later.');
    final logContents = await File('${logDirectory.path}/marker.log').readAsString();
    expect(logContents, contains('Failed to start ATProto OAuth sign in'));

    localContainer.dispose();
    await logger.close();
    await logDirectory.delete(recursive: true);
  });

  test('reports browser cancellation and keeps the sheet retryable', () async {
    browser.error = PlatformException(code: 'CANCELED', message: 'User canceled login');

    final account = await container.read(atprotoLoginControllerProvider.notifier).connect();

    expect(account, isNull);
    final state = container.read(atprotoLoginControllerProvider);
    expect(state, isA<AtprotoLoginFailed>());
    expect((state as AtprotoLoginFailed).message, 'Sign in was canceled.');
  });

  test('reports interrupted pending OAuth context as expired sign in', () async {
    browser.onAuthenticate = () async => sessionStore.clearPendingOAuthContext();

    final account = await container.read(atprotoLoginControllerProvider.notifier).connect();

    expect(account, isNull);
    final state = container.read(atprotoLoginControllerProvider);
    expect(state, isA<AtprotoLoginFailed>());
    expect((state as AtprotoLoginFailed).message, 'Sign in expired. Start again.');
  });

  test('reports token exchange failure with retry copy', () async {
    oauthClient.callbackError = StateError('token exchange failed');

    final account = await container.read(atprotoLoginControllerProvider.notifier).connect();

    expect(account, isNull);
    final state = container.read(atprotoLoginControllerProvider);
    expect(state, isA<AtprotoLoginFailed>());
    expect((state as AtprotoLoginFailed).message, 'Could not finish sign in. Try again.');
  });

  test('rejects handles with spaces before starting OAuth', () async {
    final account = await container.read(atprotoLoginControllerProvider.notifier).connect(handle: 'alice bsky social');

    expect(account, isNull);
    expect(oauthClient.authorizedHandle, isNull);
    final state = container.read(atprotoLoginControllerProvider);
    expect(state, isA<AtprotoLoginFailed>());
    expect((state as AtprotoLoginFailed).message, 'Enter a handle like alice.bsky.social, or leave it blank.');
  });
}

List<AtprotoLoginState> _recordLoginStates(ProviderContainer container) {
  final states = <AtprotoLoginState>[];
  container.listen<AtprotoLoginState>(
    atprotoLoginControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );
  return states;
}

class FakeAtprotoOAuthBrowser implements AtprotoOAuthBrowser {
  final authorizationUrls = <Uri>[];
  PlatformException? error;
  Future<void> Function()? onAuthenticate;

  @override
  Future<String> authenticate(Uri authorizationUrl) async {
    authorizationUrls.add(authorizationUrl);
    await onAuthenticate?.call();
    final error = this.error;
    if (error != null) throw error;
    return 'https://marker.stormlightlabs.org/oauth/callback?code=code&state=state-1';
  }
}

class FakeAtprotoOAuthClient implements AtprotoOAuthClient {
  String? authorizedHandle;
  Object? authorizeError;
  Object? callbackError;

  @override
  Future<(Uri, OAuthContext)> authorize({String? handle}) async {
    final authorizeError = this.authorizeError;
    if (authorizeError != null) throw authorizeError;
    authorizedHandle = handle;
    return (
      Uri.parse('https://bsky.social/oauth/authorize?request_uri=abc'),
      const OAuthContext(codeVerifier: 'verifier-1', state: 'state-1', dpopNonce: 'nonce-1'),
    );
  }

  @override
  Future<OAuthSession> callback({required String callbackUrl, required OAuthContext context}) async {
    final callbackError = this.callbackError;
    if (callbackError != null) throw callbackError;
    return fakeSession();
  }

  @override
  Future<OAuthSession> refresh(OAuthSession session) async => fakeSession(accessToken: 'access-token-2');
}

OAuthSession fakeSession({String accessToken = 'access-token-1'}) => OAuthSession(
  accessToken: accessToken,
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
