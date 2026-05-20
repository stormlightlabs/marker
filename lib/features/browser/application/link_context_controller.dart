import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final linkContextControllerProvider = NotifierProvider<LinkContextController, LinkContextState>(
  LinkContextController.new,
);

class LinkContextController extends Notifier<LinkContextState> {
  @override
  LinkContextState build() {
    return const LinkContextState.empty();
  }

  void handleBridgeMessage(String message) {
    final event = LinkContextEvent.tryParse(message);
    if (event == null) {
      return;
    }
    state = LinkContextState(link: event.link);
  }

  void clear() {
    state = const LinkContextState.empty();
  }
}

class LinkContextState {
  const LinkContextState({this.link});

  const LinkContextState.empty() : link = null;

  final LinkContext? link;
}

class LinkContextEvent {
  const LinkContextEvent({required this.link});

  final LinkContext link;

  static LinkContextEvent? tryParse(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, Object?> || decoded['type'] != 'link-long-pressed') {
        return null;
      }

      final payload = decoded['payload'];
      if (payload is! Map<String, Object?>) {
        return null;
      }

      final link = LinkContext.tryParse(payload);
      return link == null ? null : LinkContextEvent(link: link);
    } on FormatException catch (error) {
      debugPrint('Ignoring malformed link bridge message: $error');
      return null;
    } on TypeError catch (error) {
      debugPrint('Ignoring invalid link bridge message: $error');
      return null;
    }
  }
}

class LinkContext {
  const LinkContext({required this.href, required this.pageUrl, this.text, this.pageTitle});

  final Uri href;
  final Uri pageUrl;
  final String? text;
  final String? pageTitle;

  String get title => text ?? href.host;

  static LinkContext? tryParse(Map<String, Object?> payload) {
    final hrefText = _nonEmpty(payload['href']);
    final pageUrlText = _nonEmpty(payload['pageUrl']);
    final href = hrefText == null ? null : Uri.tryParse(hrefText);
    final pageUrl = pageUrlText == null ? null : Uri.tryParse(pageUrlText);

    if (href == null || pageUrl == null || !href.hasScheme || !href.hasAuthority) {
      return null;
    }

    return LinkContext(
      href: href,
      pageUrl: pageUrl,
      text: _nonEmpty(payload['text']),
      pageTitle: _nonEmpty(payload['pageTitle']),
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
