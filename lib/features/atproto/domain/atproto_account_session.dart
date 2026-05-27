import 'package:marker/core/database/app_database.dart';

sealed class AtprotoAuthState {
  const AtprotoAuthState();
}

final class AtprotoAuthDisconnected extends AtprotoAuthState {
  const AtprotoAuthDisconnected();
}

final class AtprotoAuthConnected extends AtprotoAuthState {
  const AtprotoAuthConnected(this.account);

  final AtprotoAccount account;
}

final class AtprotoAuthFailure extends AtprotoAuthState {
  const AtprotoAuthFailure(this.message);

  final String message;
}
