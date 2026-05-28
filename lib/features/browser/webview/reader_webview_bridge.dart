import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/features/browser/webview/browser_webview.dart';

final readerWebViewBridgeProvider = Provider<ReaderWebViewBridge>(
  (ref) => ReaderWebViewBridge(logger: ref.watch(appLoggerProvider)),
);

class ReaderWebViewBridge {
  ReaderWebViewBridge({AssetBundle? assetBundle, AppLogger? logger})
    : _assetBundle = assetBundle ?? rootBundle,
      _logger = logger;

  static const String selectionChannelName = 'MarkerSelection';
  static const String linkContextChannelName = 'MarkerLinkContext';
  static const String bootstrapScriptAsset = 'assets/js/reader.js';

  final AssetBundle _assetBundle;
  final AppLogger? _logger;
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
      _logger?.debug('Ignoring failed canonical URL lookup', error: error);
      return null;
    }
    final raw = result.toString().replaceAll('"', '').trim();
    if (raw.isEmpty || raw == 'null') {
      return null;
    }
    final uri = Uri.tryParse(raw);
    return uri != null && uri.hasScheme && uri.hasAuthority ? uri : null;
  }

  Future<String?> readMetaDescription(BrowserWebViewController controller) async {
    final Object? result;
    try {
      result = await controller.runJavaScriptReturningResult('''
(function () {
  try {
    var description = document.querySelector('meta[name="description" i], meta[property="og:description" i]');
    var content = description && description.getAttribute('content') ? description.getAttribute('content') : '';
    return content || '';
  } catch (error) {
    console.debug('Marker ignored meta description lookup failure', error);
    return '';
  }
})();
''');
    } on Object catch (error) {
      _logger?.debug('Ignoring failed meta description lookup', error: error);
      return null;
    }
    final raw = result.toString().replaceAll('"', '').trim();
    return raw.isEmpty || raw == 'null' ? null : raw;
  }

  Future<Uri?> readFaviconUrl(BrowserWebViewController controller, Uri pageUrl) async {
    final Object? result;
    try {
      result = await controller.runJavaScriptReturningResult('''
(function () {
  try {
    var candidates = Array.prototype.slice.call(document.querySelectorAll(
      'link[rel~="icon" i], link[rel="shortcut icon" i], link[rel="apple-touch-icon" i]'
    ));
    candidates.sort(function (left, right) {
      var leftRel = (left.getAttribute('rel') || '').toLowerCase();
      var rightRel = (right.getAttribute('rel') || '').toLowerCase();
      var leftType = (left.getAttribute('type') || '').toLowerCase();
      var rightType = (right.getAttribute('type') || '').toLowerCase();
      var leftHref = (left.getAttribute('href') || '').toLowerCase();
      var rightHref = (right.getAttribute('href') || '').toLowerCase();
      var leftIsSvg = leftType === 'image/svg+xml' || leftHref.indexOf('.svg') !== -1;
      var rightIsSvg = rightType === 'image/svg+xml' || rightHref.indexOf('.svg') !== -1;
      if (leftIsSvg && !rightIsSvg) {
        return -1;
      }
      if (rightIsSvg && !leftIsSvg) {
        return 1;
      }
      if (leftRel.indexOf('apple-touch-icon') !== -1 && rightRel.indexOf('apple-touch-icon') === -1) {
        return -1;
      }
      if (rightRel.indexOf('apple-touch-icon') !== -1 && leftRel.indexOf('apple-touch-icon') === -1) {
        return 1;
      }
      return 0;
    });
    for (var index = 0; index < candidates.length; index += 1) {
      if (candidates[index].href) {
        return candidates[index].href;
      }
    }
    return '';
  } catch (error) {
    console.debug('Marker ignored favicon URL lookup failure', error);
    return '';
  }
})();
''');
    } on Object catch (error) {
      _logger?.debug('Ignoring failed favicon URL lookup', error: error);
      return null;
    }
    final raw = result.toString().replaceAll('"', '').trim();
    if (raw.isEmpty || raw == 'null') {
      return pageUrl.hasScheme && pageUrl.hasAuthority
          ? Uri(
              scheme: pageUrl.scheme,
              host: pageUrl.host,
              port: pageUrl.hasPort ? pageUrl.port : null,
              path: '/favicon.ico',
            )
          : null;
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
