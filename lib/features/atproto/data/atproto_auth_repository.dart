import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_session_store.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/domain/atproto_account_session.dart';
import 'package:poptart/poptart.dart';

const markerAtprotoOAuthClientId = String.fromEnvironment(
  'MARKER_ATPROTO_CLIENT_ID',
  defaultValue: 'https://marker.stormlightlabs.org/client-metadata.json',
);
const markerAtprotoOAuthService = String.fromEnvironment('MARKER_ATPROTO_OAUTH_SERVICE', defaultValue: 'bsky.social');

final atprotoOAuthClientProvider = Provider<AtprotoOAuthClient>((ref) {
  return PoptartAtprotoOAuthClient(clientId: markerAtprotoOAuthClientId, service: markerAtprotoOAuthService);
});

final atprotoAuthRepositoryProvider = Provider<AtprotoAuthRepository>((ref) {
  final repository = AtprotoAuthRepository(
    syncRepository: ref.watch(atprotoSyncRepositoryProvider),
    sessionStore: ref.watch(atprotoSessionStoreProvider),
    oauthClient: ref.watch(atprotoOAuthClientProvider),
  );
  ref.onDispose(repository.dispose);
  unawaited(
    repository.restore().catchError((Object error) {
      repository.emitFailure('Failed to restore ATProto session: $error');
      return null;
    }),
  );
  return repository;
});

abstract interface class AtprotoOAuthClient {
  Future<(Uri, OAuthContext)> authorize({String? handle});

  Future<OAuthSession> callback({required String callbackUrl, required OAuthContext context});

  Future<OAuthSession> refresh(OAuthSession session);
}

class PoptartAtprotoOAuthClient implements AtprotoOAuthClient {
  PoptartAtprotoOAuthClient({required this.clientId, required this.service});

  final String clientId;
  final String service;
  OAuthClient? _client;

  Future<OAuthClient> _loadClient() async {
    final existing = _client;
    if (existing != null) return existing;
    final metadata = await getClientMetadata(clientId);
    return _client = OAuthClient(metadata, service: service);
  }

  @override
  Future<(Uri, OAuthContext)> authorize({String? handle}) async {
    final client = await _loadClient();
    return client.authorize(handle?.trim().isEmpty == true ? null : handle?.trim());
  }

  @override
  Future<OAuthSession> callback({required String callbackUrl, required OAuthContext context}) async {
    final client = await _loadClient();
    return client.callback(callbackUrl, context);
  }

  @override
  Future<OAuthSession> refresh(OAuthSession session) async {
    final client = await _loadClient();
    return client.refresh(session);
  }
}

class AtprotoAuthRepository {
  AtprotoAuthRepository({
    required AtprotoSyncRepository syncRepository,
    required AtprotoSessionStore sessionStore,
    required AtprotoOAuthClient oauthClient,
    PoptartClient Function(OAuthSession session)? clientFactory,
    DateTime Function()? now,
  }) : _syncRepository = syncRepository,
       _sessionStore = sessionStore,
       _oauthClient = oauthClient,
       _clientFactory = clientFactory ?? PoptartClient.fromOAuthSession,
       _now = now ?? (() => DateTime.now().toUtc());

  final AtprotoSyncRepository _syncRepository;
  final AtprotoSessionStore _sessionStore;
  final AtprotoOAuthClient _oauthClient;
  final PoptartClient Function(OAuthSession session) _clientFactory;
  final DateTime Function() _now;
  final StreamController<AtprotoAuthState> _stateController = StreamController<AtprotoAuthState>.broadcast();
  final Map<String, OAuthSession> _sessions = <String, OAuthSession>{};
  final Map<String, PoptartClient> _clients = <String, PoptartClient>{};

  AtprotoAuthState _state = const AtprotoAuthDisconnected();

  AtprotoAuthState get state => _state;

  Stream<AtprotoAuthState> watchAuthState() async* {
    yield _state;
    yield* _stateController.stream;
  }

  Future<Uri> startConnect({String? handle}) async {
    final (authUrl, context) = await _oauthClient.authorize(handle: handle);
    await _sessionStore.savePendingOAuthContext(context);
    return authUrl;
  }

  Future<AtprotoAccount> completeConnect(String callbackUrl) async {
    final context = await _sessionStore.readPendingOAuthContext();
    if (context == null) {
      throw StateError('OAuth session was interrupted. Start account connection again.');
    }

    final session = await _oauthClient.callback(callbackUrl: callbackUrl, context: context);
    await _sessionStore.clearPendingOAuthContext();
    return _saveConnectedSession(session);
  }

  Future<AtprotoAccount?> restore() async {
    final accounts = await _syncRepository.accounts();
    for (final account in accounts) {
      final session = await _sessionStore.readOAuthSession(account.did);
      if (session == null) continue;
      _cacheSession(session);
      _emit(AtprotoAuthConnected(account));
      return account;
    }
    _emit(const AtprotoAuthDisconnected());
    return null;
  }

  Future<AtprotoAccount> refreshIfNeeded(String did, {Duration skew = const Duration(minutes: 2)}) async {
    final session = await _sessionForDid(did);
    if (session.expiresAt.isAfter(_now().add(skew))) {
      final account = await _syncRepository.accountByDid(did);
      if (account == null) throw StateError('No ATProto account metadata for $did.');
      return account;
    }
    final refreshed = await _oauthClient.refresh(session);
    return _saveConnectedSession(refreshed);
  }

  Future<void> persistClientSession(String did) async {
    final client = _clients[did];
    final session = client?.oAuthSession ?? _sessions[did];
    if (session != null) {
      await _sessionStore.saveOAuthSession(did, session);
    }
  }

  Future<void> disconnect(String did) async {
    await _sessionStore.deleteOAuthSession(did);
    _sessions.remove(did);
    _clients.remove(did);
    _emit(const AtprotoAuthDisconnected());
  }

  Future<PoptartClient> requireClient(String did) async {
    await refreshIfNeeded(did);
    final existing = _clients[did];
    if (existing != null) return existing;
    final session = await _sessionForDid(did);
    return _clients[did] = _clientFactory(session);
  }

  void emitFailure(String message) {
    _emit(AtprotoAuthFailure(message));
  }

  void dispose() {
    unawaited(_stateController.close());
  }

  Future<AtprotoAccount> _saveConnectedSession(OAuthSession session) async {
    final did = session.sub;
    await _sessionStore.saveOAuthSession(did, session);
    _cacheSession(session);
    final account = await _syncRepository.upsertAccount(
      did: did,
      pdsEndpoint: session.markerPdsEndpoint,
      authMethod: 'oauth',
    );
    _emit(AtprotoAuthConnected(account));
    return account;
  }

  Future<OAuthSession> _sessionForDid(String did) async {
    final cached = _sessions[did];
    if (cached != null) return cached;
    final stored = await _sessionStore.readOAuthSession(did);
    if (stored == null) throw StateError('No ATProto OAuth session for $did.');
    _cacheSession(stored);
    return stored;
  }

  void _cacheSession(OAuthSession session) {
    _sessions[session.sub] = session;
    _clients[session.sub] = _clientFactory(session);
  }

  void _emit(AtprotoAuthState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
