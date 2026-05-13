import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/features/browser/webview/browser_webview.dart';

final readerWebViewBridgeProvider = Provider<ReaderWebViewBridge>((ref) => ReaderWebViewBridge());

class ReaderWebViewBridge {
  ReaderWebViewBridge({AssetBundle? assetBundle}) : _assetBundle = assetBundle ?? rootBundle;

  static const String selectionChannelName = 'MarkerSelection';
  static const String linkContextChannelName = 'MarkerLinkContext';
  static const String bootstrapScriptAsset = 'assets/js/reader.js';

  final AssetBundle _assetBundle;
  Future<String>? _bootstrapScript;

  Future<String> loadBootstrapScript() {
    return _bootstrapScript ??= _assetBundle.loadString(bootstrapScriptAsset);
  }

  Future<void> inject(BrowserWebViewController controller) async {
    await controller.runJavaScript(_channelCompatibilityScript);
    return controller.runJavaScript(await loadBootstrapScript());
  }

  Future<void> clearSelection(BrowserWebViewController controller) {
    return controller.runJavaScript('window.MarkerReader && window.MarkerReader.clearSelection();');
  }

  Future<int> renderAnnotations(BrowserWebViewController controller, List<Map<String, Object?>> annotations) async {
    await inject(controller);
    final result = await controller.runJavaScriptReturningResult(
      'window.MarkerReader && window.MarkerReader.renderAnnotations(${jsonEncode(annotations)}) || 0;',
    );
    return int.tryParse(result.toString().replaceAll('"', '').trim()) ?? 0;
  }

  Future<void> deleteRenderedAnnotation(BrowserWebViewController controller, String annotationId) {
    return controller.runJavaScript(
      'window.MarkerReader && window.MarkerReader.deleteRenderedAnnotation(${jsonEncode(annotationId)});',
    );
  }

  Future<void> scrollToAnnotation(BrowserWebViewController controller, String annotationId) {
    return controller.runJavaScript(
      'window.MarkerReader && window.MarkerReader.scrollToAnnotation(${jsonEncode(annotationId)});',
    );
  }

  Future<Uri?> readCanonicalUrl(BrowserWebViewController controller) async {
    final Object? result;
    try {
      result = await controller.runJavaScriptReturningResult('''
(function () {
  try {
    var canonical = document.querySelector('link[rel="canonical" i]');
    return canonical && canonical.href ? canonical.href : '';
  } catch (error) {
    console.debug('Marker ignored canonical URL lookup failure', error);
    return '';
  }
})();
''');
    } on Object catch (error) {
      debugPrint('Ignoring failed canonical URL lookup: $error');
      return null;
    }
    final raw = result.toString().replaceAll('"', '').trim();
    if (raw.isEmpty || raw == 'null') {
      return null;
    }
    final uri = Uri.tryParse(raw);
    return uri != null && uri.hasScheme && uri.hasAuthority ? uri : null;
  }
}

const String _channelCompatibilityScript = '''
(function () {
  function installChannel(name) {
    if (window[name] && typeof window[name].postMessage === 'function') {
      return;
    }
    window[name] = {
      postMessage: function (message) {
        if (window.flutter_inappwebview && typeof window.flutter_inappwebview.callHandler === 'function') {
          window.flutter_inappwebview.callHandler(name, message);
        }
      },
    };
  }
  installChannel('MarkerSelection');
  installChannel('MarkerLinkContext');
})();
''';
