import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/features/browser/application/selection_capture_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('captures valid selection bridge messages', () {
    container
        .read(selectionCaptureControllerProvider.notifier)
        .handleBridgeMessage(
          jsonEncode({
            'type': 'selection-captured',
            'payload': {
              'exact': 'local-first software',
              'prefix': 'The case for ',
              'suffix': ' is strong.',
              'sourceUrl': 'https://example.com/article',
              'pageTitle': 'Example Article',
              'textPositionStart': 13,
              'textPositionEnd': 33,
              'cssSelector': 'article > p:nth-of-type(1)',
            },
          }),
        );

    final capture = container.read(selectionCaptureControllerProvider).capture;

    expect(capture, isNotNull);
    expect(capture!.exact, 'local-first software');
    expect(capture.sourceUrl, Uri.parse('https://example.com/article'));
    expect(capture.toW3cTargetJson()['selector'], hasLength(3));
  });

  test('clears invalid, collapsed, and malformed bridge messages', () {
    final controller = container.read(selectionCaptureControllerProvider.notifier);
    controller.handleBridgeMessage(
      jsonEncode({
        'type': 'selection-captured',
        'payload': {
          'exact': 'selected',
          'sourceUrl': 'https://example.com',
          'textPositionStart': 1,
          'textPositionEnd': 9,
        },
      }),
    );
    expect(container.read(selectionCaptureControllerProvider).hasSelection, isTrue);

    controller.handleBridgeMessage(jsonEncode({'type': 'selection-cleared'}));
    expect(container.read(selectionCaptureControllerProvider).hasSelection, isFalse);

    controller.handleBridgeMessage('not json');
    expect(container.read(selectionCaptureControllerProvider).hasSelection, isFalse);
  });
}
