import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poptart/poptart.dart';

final atprotoSessionStoreProvider = Provider<AtprotoSessionStore>((ref) {
  return const SecureAtprotoSessionStore(FlutterSecureStorage());
});

abstract interface class AtprotoSessionStore {
  Future<void> savePendingOAuthContext(OAuthContext context);

  Future<OAuthContext?> readPendingOAuthContext();

  Future<void> clearPendingOAuthContext();

  Future<void> saveOAuthSession(String did, OAuthSession session);

  Future<OAuthSession?> readOAuthSession(String did);

  Future<void> deleteOAuthSession(String did);
}

class SecureAtprotoSessionStore implements AtprotoSessionStore {
  const SecureAtprotoSessionStore(this._storage);

  static const _pendingContextKey = 'atproto.oauth.pending_context';
  static const _sessionPrefix = 'atproto.oauth.session.';

  final FlutterSecureStorage _storage;

  @override
  Future<void> savePendingOAuthContext(OAuthContext context) {
    return _storage.write(
      key: _pendingContextKey,
      value: jsonEncode({'codeVerifier': context.codeVerifier, 'state': context.state, 'dpopNonce': context.dpopNonce}),
    );
  }

  @override
  Future<OAuthContext?> readPendingOAuthContext() async {
    final raw = await _storage.read(key: _pendingContextKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return OAuthContext(
      codeVerifier: json['codeVerifier'] as String,
      state: json['state'] as String,
      dpopNonce: json['dpopNonce'] as String,
    );
  }

  @override
  Future<void> clearPendingOAuthContext() => _storage.delete(key: _pendingContextKey);

  @override
  Future<void> saveOAuthSession(String did, OAuthSession session) {
    return _storage.write(key: _sessionKey(did), value: jsonEncode(_sessionToJson(session)));
  }

  @override
  Future<OAuthSession?> readOAuthSession(String did) async {
    final raw = await _storage.read(key: _sessionKey(did));
    if (raw == null) return null;
    return _sessionFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteOAuthSession(String did) => _storage.delete(key: _sessionKey(did));

  static String _sessionKey(String did) => '$_sessionPrefix$did';
}

class MemoryAtprotoSessionStore implements AtprotoSessionStore {
  OAuthContext? pendingContext;
  final Map<String, OAuthSession> sessions = <String, OAuthSession>{};

  @override
  Future<void> savePendingOAuthContext(OAuthContext context) async {
    pendingContext = context;
  }

  @override
  Future<OAuthContext?> readPendingOAuthContext() async => pendingContext;

  @override
  Future<void> clearPendingOAuthContext() async {
    pendingContext = null;
  }

  @override
  Future<void> saveOAuthSession(String did, OAuthSession session) async {
    sessions[did] = session;
  }

  @override
  Future<OAuthSession?> readOAuthSession(String did) async => sessions[did];

  @override
  Future<void> deleteOAuthSession(String did) async {
    sessions.remove(did);
  }
}

Map<String, dynamic> _sessionToJson(OAuthSession session) => <String, dynamic>{
  'accessToken': session.accessToken,
  'refreshToken': session.refreshToken,
  'tokenType': session.tokenType,
  'scope': session.scope,
  'expiresAt': session.expiresAt.toIso8601String(),
  'sub': session.sub,
  'clientId': session.$clientId,
  'pdsEndpoint': session.$pdsEndpoint,
  'dpopNonce': session.$dPoPNonce,
  'publicKey': session.$publicKey,
  'privateKey': session.$privateKey,
};

OAuthSession _sessionFromJson(Map<String, dynamic> json) => restoreOAuthSession(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  tokenType: json['tokenType'] as String?,
  scope: json['scope'] as String?,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  sub: json['sub'] as String?,
  clientId: json['clientId'] as String?,
  pdsEndpoint: json['pdsEndpoint'] as String?,
  dPoPNonce: json['dpopNonce'] as String?,
  publicKey: json['publicKey'] as String,
  privateKey: json['privateKey'] as String,
);

extension AtprotoOAuthSessionAccount on OAuthSession {
  String? get markerPdsEndpoint => atprotoPdsEndpoint ?? $pdsEndpoint;
}
