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

  function postSelectionMessage(message) {
    if (window.MarkerSelection && typeof window.MarkerSelection.postMessage === 'function') {
      window.MarkerSelection.postMessage(JSON.stringify(message));
    }
  }

  function cssPathFor(node) {
    function escapeCssIdentifier(value) {
      if (window.CSS && typeof window.CSS.escape === 'function') {
        return window.CSS.escape(value);
      }
      return String(value).replace(/[^a-zA-Z0-9_-]/g, '\\\\\$&');
    }

    var element = node && node.nodeType === Node.ELEMENT_NODE ? node : node && node.parentElement;
    if (!element || !document.documentElement.contains(element)) {
      return '';
    }

    var parts = [];
    while (element && element.nodeType === Node.ELEMENT_NODE && element !== document.documentElement) {
      var part = element.localName;
      if (element.id) {
        parts.unshift(part + '#' + escapeCssIdentifier(element.id));
        break;
      }

      var sibling = element;
      var index = 1;
      while ((sibling = sibling.previousElementSibling) !== null) {
        if (sibling.localName === element.localName) {
          index += 1;
        }
      }
      parts.unshift(part + ':nth-of-type(' + index + ')');
      element = element.parentElement;
    }
    return parts.join(' > ');
  }

  function textBeforeRange(range) {
    var before = range.cloneRange();
    before.selectNodeContents(document.body || document.documentElement);
    before.setEnd(range.startContainer, range.startOffset);
    return before.toString();
  }

  function textAfterRange(range) {
    var after = range.cloneRange();
    after.selectNodeContents(document.body || document.documentElement);
    after.setStart(range.endContainer, range.endOffset);
    return after.toString();
  }

  function captureSelection() {
    var selection = window.getSelection && window.getSelection();
    if (!selection || selection.rangeCount === 0 || selection.isCollapsed) {
      postSelectionMessage({ type: 'selection-cleared' });
      return;
    }

    var exact = selection.toString().trim();
    if (!exact) {
      postSelectionMessage({ type: 'selection-cleared' });
      return;
    }

    var range = selection.getRangeAt(0);
    var beforeText = textBeforeRange(range);
    var afterText = textAfterRange(range);
    var start = beforeText.length;
    var end = start + exact.length;

    postSelectionMessage({
      type: 'selection-captured',
      payload: {
        exact: exact,
        prefix: beforeText.slice(-120),
        suffix: afterText.slice(0, 120),
        textPositionStart: start,
        textPositionEnd: end,
        cssSelector: cssPathFor(range.commonAncestorContainer),
        sourceUrl: window.location.href,
        pageTitle: document.title || ''
      }
    });
  }

  var captureTimer = null;
  function scheduleCapture() {
    window.clearTimeout(captureTimer);
    captureTimer = window.setTimeout(captureSelection, 80);
  }

  window.MarkerReader = {
    version: 1,
    installedAt: new Date().toISOString(),
    clearSelection: function () {
      var selection = window.getSelection && window.getSelection();
      if (selection) {
        selection.removeAllRanges();
      }
      postSelectionMessage({ type: 'selection-cleared' });
    }
  };
  document.addEventListener('selectionchange', scheduleCapture);
  document.addEventListener('mouseup', scheduleCapture);
  document.addEventListener('touchend', scheduleCapture);
  document.addEventListener('keyup', scheduleCapture);
  document.documentElement.dataset.markerReader = 'installed';
})();
''';

  Future<void> inject(WebViewController controller) {
    return controller.runJavaScript(bootstrapScript);
  }

  Future<void> clearSelection(WebViewController controller) {
    return controller.runJavaScript('window.MarkerReader && window.MarkerReader.clearSelection();');
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
