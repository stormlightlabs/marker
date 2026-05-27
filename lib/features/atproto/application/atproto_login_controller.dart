import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';

const markerAtprotoOAuthCallbackScheme = 'https';
const markerAtprotoOAuthCallbackHost = 'marker.stormlightlabs.org';
const markerAtprotoOAuthCallbackPath = '/oauth/callback';

final atprotoOAuthBrowserProvider = Provider<AtprotoOAuthBrowser>((ref) => const FlutterWebAtprotoOAuthBrowser());

final atprotoLoginControllerProvider = NotifierProvider<AtprotoLoginController, AtprotoLoginState>(
  AtprotoLoginController.new,
);

abstract interface class AtprotoOAuthBrowser {
  Future<String> authenticate(Uri authorizationUrl);
}

class FlutterWebAtprotoOAuthBrowser implements AtprotoOAuthBrowser {
  const FlutterWebAtprotoOAuthBrowser();

  @override
  Future<String> authenticate(Uri authorizationUrl) {
    return FlutterWebAuth2.authenticate(
      url: authorizationUrl.toString(),
      callbackUrlScheme: markerAtprotoOAuthCallbackScheme,
      options: const FlutterWebAuth2Options(
        httpsHost: markerAtprotoOAuthCallbackHost,
        httpsPath: markerAtprotoOAuthCallbackPath,
      ),
    );
  }
}

class AtprotoLoginController extends Notifier<AtprotoLoginState> {
  @override
  AtprotoLoginState build() => const AtprotoLoginIdle();

  Future<AtprotoAccount?> connect({String? handle}) async {
    final normalizedHandle = _normalizeHandle(handle);
    if (normalizedHandle == _invalidHandleSentinel) {
      state = const AtprotoLoginFailed('Enter a handle like alice.bsky.social, or leave it blank.');
      return null;
    }

    final repository = ref.read(atprotoAuthRepositoryProvider);
    final browser = ref.read(atprotoOAuthBrowserProvider);

    Uri authorizationUrl;
    try {
      state = const AtprotoLoginStartingOAuth();
      authorizationUrl = await repository.startConnect(handle: normalizedHandle);
    } on Object {
      state = const AtprotoLoginFailed('Could not start sign in. Check your connection and try again.');
      return null;
    }

    String callbackUrl;
    try {
      state = const AtprotoLoginWaitingForCallback();
      callbackUrl = await browser.authenticate(authorizationUrl);
    } on PlatformException catch (error) {
      state = AtprotoLoginFailed(_browserFailureMessage(error));
      return null;
    } on Object {
      state = const AtprotoLoginFailed('Could not finish sign in. Try again.');
      return null;
    }

    try {
      state = const AtprotoLoginCompletingOAuth();
      final account = await repository.completeConnect(callbackUrl);
      state = AtprotoLoginConnected(account);
      return account;
    } on Object catch (error) {
      state = AtprotoLoginFailed(_completionFailureMessage(error));
      return null;
    }
  }

  void reset() {
    state = const AtprotoLoginIdle();
  }

  static const _invalidHandleSentinel = '__marker_invalid_atproto_handle__';

  static String? _normalizeHandle(String? handle) {
    final trimmed = handle?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    if (withoutAt.isEmpty || withoutAt.contains(RegExp(r'\s')) || withoutAt.contains('://')) {
      return _invalidHandleSentinel;
    }
    return withoutAt;
  }

  static String _browserFailureMessage(PlatformException error) {
    if (error.code == 'CANCELED') {
      return 'Sign in was canceled.';
    }
    return 'Could not finish sign in. Try again.';
  }

  static String _completionFailureMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (error is StateError && message.contains('interrupted')) {
      return 'Sign in expired. Start again.';
    }
    if (message.contains('state mismatch') || message.contains('invalid state')) {
      return 'Sign in could not be verified. Start again.';
    }
    if (message.contains('secure') || message.contains('keychain') || message.contains('keystore')) {
      return 'Marker could not save the session securely on this device.';
    }
    return 'Could not finish sign in. Try again.';
  }
}

sealed class AtprotoLoginState {
  const AtprotoLoginState();

  bool get isBusy => switch (this) {
    AtprotoLoginStartingOAuth() || AtprotoLoginWaitingForCallback() || AtprotoLoginCompletingOAuth() => true,
    _ => false,
  };
}

final class AtprotoLoginIdle extends AtprotoLoginState {
  const AtprotoLoginIdle();
}

final class AtprotoLoginStartingOAuth extends AtprotoLoginState {
  const AtprotoLoginStartingOAuth();
}

final class AtprotoLoginWaitingForCallback extends AtprotoLoginState {
  const AtprotoLoginWaitingForCallback();
}

final class AtprotoLoginCompletingOAuth extends AtprotoLoginState {
  const AtprotoLoginCompletingOAuth();
}

final class AtprotoLoginConnected extends AtprotoLoginState {
  const AtprotoLoginConnected(this.account);

  final AtprotoAccount account;
}

final class AtprotoLoginFailed extends AtprotoLoginState {
  const AtprotoLoginFailed(this.message);

  final String message;
}
