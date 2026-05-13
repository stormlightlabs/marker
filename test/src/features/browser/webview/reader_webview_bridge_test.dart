import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/features/browser/webview/reader_webview_bridge.dart';

void main() {
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
