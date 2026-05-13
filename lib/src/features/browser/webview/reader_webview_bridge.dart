import 'package:webview_flutter/webview_flutter.dart';

class ReaderWebViewBridge {
  const ReaderWebViewBridge();

  static const String selectionChannelName = 'MarkerSelection';

  String get bootstrapScript => '''
(function () {
  if (window.__markerReaderInstalled === true) {
    return;
  }
  window.__markerReaderInstalled = true;
  window.MarkerReader = {
    version: 1,
    installedAt: new Date().toISOString(),
    clearSelection: function () {
      var selection = window.getSelection && window.getSelection();
      if (selection) {
        selection.removeAllRanges();
      }
    }
  };
  document.documentElement.dataset.markerReader = 'installed';
})();
''';

  Future<void> inject(WebViewController controller) {
    return controller.runJavaScript(bootstrapScript);
  }

  Future<Uri?> readCanonicalUrl(WebViewController controller) async {
    final result = await controller.runJavaScriptReturningResult('''
(function () {
  var canonical = document.querySelector('link[rel="canonical" i]');
  return canonical && canonical.href ? canonical.href : '';
})();
''');
    final raw = result.toString().replaceAll('"', '').trim();
    if (raw.isEmpty || raw == 'null') {
      return null;
    }
    final uri = Uri.tryParse(raw);
    return uri != null && uri.hasScheme && uri.hasAuthority ? uri : null;
  }
}
