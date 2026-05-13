import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  Future<void> inject(WebViewController controller) async {
    return controller.runJavaScript(await loadBootstrapScript());
  }

  Future<void> clearSelection(WebViewController controller) {
    return controller.runJavaScript('window.MarkerReader && window.MarkerReader.clearSelection();');
  }

  Future<int> renderAnnotations(WebViewController controller, List<Map<String, Object?>> annotations) async {
    await inject(controller);
    final result = await controller.runJavaScriptReturningResult(
      'window.MarkerReader && window.MarkerReader.renderAnnotations(${jsonEncode(annotations)}) || 0;',
    );
    return int.tryParse(result.toString().replaceAll('"', '').trim()) ?? 0;
  }

  Future<void> deleteRenderedAnnotation(WebViewController controller, String annotationId) {
    return controller.runJavaScript(
      'window.MarkerReader && window.MarkerReader.deleteRenderedAnnotation(${jsonEncode(annotationId)});',
    );
  }

  Future<void> scrollToAnnotation(WebViewController controller, String annotationId) {
    return controller.runJavaScript(
      'window.MarkerReader && window.MarkerReader.scrollToAnnotation(${jsonEncode(annotationId)});',
    );
  }

  Future<Uri?> readCanonicalUrl(WebViewController controller) async {
    final Object result;
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
