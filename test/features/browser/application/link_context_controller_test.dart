import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/browser/application/link_context_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('captures valid link context bridge messages', () {
    container
        .read(linkContextControllerProvider.notifier)
        .handleBridgeMessage(
          jsonEncode({
            'type': 'link-long-pressed',
            'payload': {
              'href': 'https://example.com/article',
              'text': 'Read article',
              'pageUrl': 'https://example.com',
              'pageTitle': 'Example',
            },
          }),
        );

    final link = container.read(linkContextControllerProvider).link;

    expect(link, isNotNull);
    expect(link!.href, Uri.parse('https://example.com/article'));
    expect(link.text, 'Read article');
    expect(link.pageUrl, Uri.parse('https://example.com'));
  });

  test('ignores malformed and invalid link context messages', () {
    final controller = container.read(linkContextControllerProvider.notifier);

    controller.handleBridgeMessage('not json');
    expect(container.read(linkContextControllerProvider).link, isNull);

    controller.handleBridgeMessage(
      jsonEncode({
        'type': 'link-long-pressed',
        'payload': {'href': 'not-a-url', 'pageUrl': 'https://example.com'},
      }),
    );
    expect(container.read(linkContextControllerProvider).link, isNull);
  });
}
