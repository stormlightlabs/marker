import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

class ReaderWebViewBridge {
  const ReaderWebViewBridge();

  static const String selectionChannelName = 'MarkerSelection';
  static const String linkContextChannelName = 'MarkerLinkContext';

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

  function postLinkContextMessage(message) {
    if (window.MarkerLinkContext && typeof window.MarkerLinkContext.postMessage === 'function') {
      window.MarkerLinkContext.postMessage(JSON.stringify(message));
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

  function textNodesUnder(root) {
    var nodes = [];
    if (!root) {
      return nodes;
    }
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        if (!node.nodeValue || !node.nodeValue.length) {
          return NodeFilter.FILTER_REJECT;
        }
        var parent = node.parentElement;
        if (!parent || parent.closest('[data-marker-annotation-id]')) {
          return NodeFilter.FILTER_REJECT;
        }
        var tag = parent.tagName;
        if (tag === 'SCRIPT' || tag === 'STYLE' || tag === 'NOSCRIPT') {
          return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    var current;
    while ((current = walker.nextNode())) {
      nodes.push(current);
    }
    return nodes;
  }

  function rangeFromOffsets(start, end) {
    var root = document.body || document.documentElement;
    var nodes = textNodesUnder(root);
    var offset = 0;
    var range = document.createRange();
    var started = false;

    for (var i = 0; i < nodes.length; i += 1) {
      var node = nodes[i];
      var nextOffset = offset + node.nodeValue.length;
      if (!started && start >= offset && start <= nextOffset) {
        range.setStart(node, Math.max(0, start - offset));
        started = true;
      }
      if (started && end >= offset && end <= nextOffset) {
        range.setEnd(node, Math.max(0, end - offset));
        return range;
      }
      offset = nextOffset;
    }

    return null;
  }

  function documentText() {
    var nodes = textNodesUnder(document.body || document.documentElement);
    return nodes.map(function (node) { return node.nodeValue; }).join('');
  }

  function selectorOfType(annotation, type) {
    var selectors = Array.isArray(annotation.selector) ? annotation.selector : [];
    for (var i = 0; i < selectors.length; i += 1) {
      if (selectors[i] && selectors[i].type === type) {
        return selectors[i];
      }
    }
    return null;
  }

  function rangeFromQuoteSelector(annotation) {
    var quote = selectorOfType(annotation, 'TextQuoteSelector');
    if (!quote || !quote.exact) {
      return null;
    }

    var text = documentText();
    var exact = String(quote.exact);
    var prefix = quote.prefix ? String(quote.prefix) : '';
    var suffix = quote.suffix ? String(quote.suffix) : '';
    var bestIndex = -1;
    var bestScore = -1;
    var index = text.indexOf(exact);

    while (index !== -1) {
      var score = 0;
      if (!prefix || text.slice(Math.max(0, index - prefix.length), index) === prefix) {
        score += 2;
      }
      if (!suffix || text.slice(index + exact.length, index + exact.length + suffix.length) === suffix) {
        score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
      index = text.indexOf(exact, index + Math.max(1, exact.length));
    }

    return bestIndex === -1 ? null : rangeFromOffsets(bestIndex, bestIndex + exact.length);
  }

  function rangeFromPositionSelector(annotation) {
    var position = selectorOfType(annotation, 'TextPositionSelector');
    if (!position || typeof position.start !== 'number' || typeof position.end !== 'number') {
      return null;
    }
    if (position.start < 0 || position.end <= position.start) {
      return null;
    }
    return rangeFromOffsets(position.start, position.end);
  }

  function rangeFromCssSelector(annotation) {
    var css = selectorOfType(annotation, 'CssSelector');
    if (!css || !css.value) {
      return null;
    }
    try {
      var element = document.querySelector(css.value);
      if (!element) {
        return null;
      }
      var range = document.createRange();
      range.selectNodeContents(element);
      return range.collapsed ? null : range;
    } catch (error) {
      console.debug('Marker ignored invalid CSS selector', error);
      return null;
    }
  }

  function rangeForAnnotation(annotation) {
    return rangeFromQuoteSelector(annotation) || rangeFromPositionSelector(annotation) || rangeFromCssSelector(annotation);
  }

  function removeRenderedAnnotation(annotationId) {
    var selector = '[data-marker-annotation-id="' + String(annotationId).replace(/"/g, '\\\\"') + '"]';
    var nodes = Array.prototype.slice.call(document.querySelectorAll(selector));
    nodes.forEach(function (node) {
      var parent = node.parentNode;
      if (!parent) {
        return;
      }
      while (node.firstChild) {
        parent.insertBefore(node.firstChild, node);
      }
      parent.removeChild(node);
      parent.normalize();
    });
  }

  function removeAllRenderedAnnotations() {
    var nodes = Array.prototype.slice.call(document.querySelectorAll('[data-marker-annotation-id]'));
    nodes.forEach(function (node) {
      removeRenderedAnnotation(node.getAttribute('data-marker-annotation-id'));
    });
  }

  function renderAnnotation(annotation) {
    var range = rangeForAnnotation(annotation);
    if (!range) {
      return false;
    }

    var span = document.createElement('mark');
    span.setAttribute('data-marker-annotation-id', annotation.id);
    span.setAttribute('data-marker-annotation-style', annotation.style || 'highlight');
    span.style.borderRadius = '2px';
    span.style.padding = '0 1px';
    span.style.color = 'inherit';
    if (annotation.style === 'underline') {
      span.style.background = 'transparent';
      span.style.textDecorationLine = 'underline';
      span.style.textDecorationThickness = '0.16em';
      span.style.textDecorationColor = annotation.color || '#64D2FF';
      span.style.textUnderlineOffset = '0.18em';
    } else {
      span.style.background = annotation.color || '#FFCC00';
    }

    try {
      var contents = range.extractContents();
      span.appendChild(contents);
      range.insertNode(span);
      return true;
    } catch (error) {
      console.debug('Marker failed to render annotation', annotation.id, error);
      return false;
    }
  }

  function scrollToAnnotation(annotationId) {
    var node = document.querySelector('[data-marker-annotation-id="' + String(annotationId).replace(/"/g, '\\\\"') + '"]');
    if (node) {
      node.scrollIntoView({ block: 'center', inline: 'nearest', behavior: 'smooth' });
    }
  }

  var linkPressTimer = null;
  var linkPressAnchor = null;
  var linkPressStartX = 0;
  var linkPressStartY = 0;

  function clearLinkPressTimer() {
    window.clearTimeout(linkPressTimer);
    linkPressTimer = null;
    linkPressAnchor = null;
  }

  function nearestAnchor(target) {
    return target && target.closest ? target.closest('a[href]') : null;
  }

  function postLinkLongPress(anchor) {
    if (!anchor || !anchor.href) {
      return;
    }
    postLinkContextMessage({
      type: 'link-long-pressed',
      payload: {
        href: anchor.href,
        text: (anchor.innerText || anchor.textContent || '').trim(),
        pageUrl: window.location.href,
        pageTitle: document.title || ''
      }
    });
  }

  function scheduleLinkLongPress(event) {
    var anchor = nearestAnchor(event.target);
    if (!anchor) {
      return;
    }
    var selection = window.getSelection && window.getSelection();
    if (selection && !selection.isCollapsed) {
      return;
    }

    var point = event.touches && event.touches.length > 0 ? event.touches[0] : event;
    linkPressAnchor = anchor;
    linkPressStartX = point.clientX || 0;
    linkPressStartY = point.clientY || 0;
    window.clearTimeout(linkPressTimer);
    linkPressTimer = window.setTimeout(function () {
      postLinkLongPress(linkPressAnchor);
      clearLinkPressTimer();
    }, 560);
  }

  function cancelLinkLongPressIfMoved(event) {
    if (!linkPressTimer) {
      return;
    }
    var point = event.touches && event.touches.length > 0 ? event.touches[0] : event;
    var dx = Math.abs((point.clientX || 0) - linkPressStartX);
    var dy = Math.abs((point.clientY || 0) - linkPressStartY);
    if (dx > 10 || dy > 10) {
      clearLinkPressTimer();
    }
  }

  function handleContextMenu(event) {
    var anchor = nearestAnchor(event.target);
    if (!anchor) {
      return;
    }
    event.preventDefault();
    clearLinkPressTimer();
    postLinkLongPress(anchor);
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
    },
    renderAnnotations: function (annotations) {
      removeAllRenderedAnnotations();
      if (!Array.isArray(annotations)) {
        return 0;
      }
      var rendered = 0;
      annotations.forEach(function (annotation) {
        if (annotation && annotation.id && renderAnnotation(annotation)) {
          rendered += 1;
        }
      });
      return rendered;
    },
    deleteRenderedAnnotation: removeRenderedAnnotation,
    scrollToAnnotation: scrollToAnnotation
  };
  document.addEventListener('selectionchange', scheduleCapture);
  document.addEventListener('mouseup', scheduleCapture);
  document.addEventListener('touchend', scheduleCapture);
  document.addEventListener('keyup', scheduleCapture);
  document.addEventListener('contextmenu', handleContextMenu);
  document.addEventListener('touchstart', scheduleLinkLongPress, { passive: true });
  document.addEventListener('touchmove', cancelLinkLongPressIfMoved, { passive: true });
  document.addEventListener('touchend', clearLinkPressTimer);
  document.addEventListener('mousedown', scheduleLinkLongPress);
  document.addEventListener('mousemove', cancelLinkLongPressIfMoved);
  document.addEventListener('mouseup', clearLinkPressTimer);
  document.addEventListener('scroll', clearLinkPressTimer, true);
  document.documentElement.dataset.markerReader = 'installed';
})();
''';

  Future<void> inject(WebViewController controller) {
    return controller.runJavaScript(bootstrapScript);
  }

  Future<void> clearSelection(WebViewController controller) {
    return controller.runJavaScript('window.MarkerReader && window.MarkerReader.clearSelection();');
  }

  Future<int> renderAnnotations(WebViewController controller, List<Map<String, Object?>> annotations) async {
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
