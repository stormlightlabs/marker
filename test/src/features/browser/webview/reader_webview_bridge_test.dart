import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/features/browser/webview/reader_webview_bridge.dart';

import '../../../../helpers/harness.dart';

void main() {
  test('reader script uses resilient web-page anchoring', () async {
    final script = await File(ReaderWebViewBridge.bootstrapScriptAsset).readAsString();

    expect(script, contains('version: 2'));
    expect(script, contains('normalizedDocumentTextIndex'));
    expect(script, contains('normalizeForSearch'));
    expect(script, contains('wrapTextNodePortion'));
    expect(script, contains("setProperty('background-color'"));
  });

  test('loads and caches the reader script asset', () async {
    final bundle = _CountingAssetBundle();
    final bridge = ReaderWebViewBridge(assetBundle: bundle);

    final first = await bridge.loadBootstrapScript();
    final second = await bridge.loadBootstrapScript();

    expect(first, contains('window.__markerReaderInstalled'));
    expect(second, same(first));
    expect(bundle.loadCount, 1);
    expect(bundle.loadedKeys, [ReaderWebViewBridge.bootstrapScriptAsset]);
  });

  test('installs the reader runtime before rendering annotations', () async {
    final platform = FakeWebViewPlatform();
    final bridge = testReaderBridge();
    final controller = platform.controller;

    final rendered = await bridge.renderAnnotations(controller, [
      {
        'id': 'annotation',
        'selector': [
          {'type': 'TextQuoteSelector', 'exact': 'selected text'},
        ],
      },
    ]);

    expect(rendered, 1);
    expect(platform.controller.injectedScripts, hasLength(3));
    expect(platform.controller.injectedScripts.first, contains('installChannel'));
    expect(platform.controller.injectedScripts[1], contains('window.__markerReaderInstalled'));
    expect(platform.controller.injectedScripts.last, contains('renderAnnotations'));
    expect(platform.controller.injectedScripts.last, contains('"id":"annotation"'));
  });

  test('returns null when the page rejects canonical URL lookup', () async {
    final platform = FakeWebViewPlatform();
    final bridge = testReaderBridge();
    final controller = platform.controller;
    platform.controller.throwOnCanonicalUrlRead = true;

    final canonicalUrl = await bridge.readCanonicalUrl(controller);

    expect(canonicalUrl, isNull);
    expect(platform.controller.injectedScripts.single, contains('link[rel="canonical"'));
  });
}

class _CountingAssetBundle extends CachingAssetBundle {
  int loadCount = 0;
  final loadedKeys = <String>[];

  @override
  Future<ByteData> load(String key) {
    loadCount += 1;
    loadedKeys.add(key);
    final bytes = Uint8List.fromList(utf8.encode('window.__markerReaderInstalled = true;'));
    return SynchronousFuture<ByteData>(ByteData.view(bytes.buffer));
  }
}
