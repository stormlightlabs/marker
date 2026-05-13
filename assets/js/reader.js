(function () {
  if (window.MarkerReader && window.MarkerReader.version >= 2) {
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
      return String(value).replace(/[^a-zA-Z0-9_-]/g, '\\$&');
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
        pageTitle: document.title || '',
      },
    });
  }

  function textNodesUnder(root) {
    var nodes = [];
    if (!root) {
      return nodes;
    }

    if (root.nodeType === Node.TEXT_NODE) {
      return acceptsTextNode(root) ? [root] : nodes;
    }

    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        return acceptsTextNode(node) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
      },
    });
    var current;
    while ((current = walker.nextNode())) {
      nodes.push(current);
    }
    return nodes;
  }

  function acceptsTextNode(node) {
    if (!node.nodeValue || !node.nodeValue.length) {
      return false;
    }
    var parent = node.parentElement;
    if (!parent || parent.closest('[data-marker-annotation-id]')) {
      return false;
    }
    if (parent.closest('script, style, noscript, template, [hidden], [aria-hidden="true"]')) {
      return false;
    }
    if (!isElementTextVisible(parent)) {
      return false;
    }
    return true;
  }

  function isElementTextVisible(element) {
    var current = element;
    while (current && current.nodeType === Node.ELEMENT_NODE && current !== document.documentElement) {
      if (window.getComputedStyle) {
        var style = window.getComputedStyle(current);
        if (style && (style.display === 'none' || style.visibility === 'hidden' || style.visibility === 'collapse')) {
          return false;
        }
      }
      current = current.parentElement;
    }
    return true;
  }

  function normalizeForSearch(value) {
    return String(value || '').replace(/\s+/g, ' ').trim();
  }

  function normalizedDocumentTextIndex() {
    var nodes = textNodesUnder(document.body || document.documentElement);
    var text = '';
    var map = [];
    var lastWasWhitespace = false;

    nodes.forEach(function (node) {
      var value = node.nodeValue || '';
      for (var i = 0; i < value.length; i += 1) {
        var character = value.charAt(i);
        if (/\s/.test(character)) {
          if (!lastWasWhitespace) {
            text += ' ';
            map.push({ node: node, offset: i });
            lastWasWhitespace = true;
          }
        } else {
          text += character;
          map.push({ node: node, offset: i });
          lastWasWhitespace = false;
        }
      }
    });

    return { text: text, map: map };
  }

  function rangeFromTextIndex(index, start, end) {
    if (!index || !index.map.length || start < 0 || end <= start || end > index.map.length) {
      return null;
    }

    var startPoint = index.map[start];
    var endPoint = index.map[end - 1];
    if (!startPoint || !endPoint) {
      return null;
    }

    var range = document.createRange();
    range.setStart(startPoint.node, startPoint.offset);
    range.setEnd(endPoint.node, endPoint.offset + 1);
    return range.collapsed ? null : range;
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
    return nodes
      .map(function (node) {
        return node.nodeValue;
      })
      .join('');
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

    var index = normalizedDocumentTextIndex();
    var text = index.text;
    var exact = normalizeForSearch(quote.exact);
    var prefix = normalizeForSearch(quote.prefix);
    var suffix = normalizeForSearch(quote.suffix);
    var bestIndex = -1;
    var bestScore = -1;
    var matchIndex = exact ? text.indexOf(exact) : -1;

    while (matchIndex !== -1) {
      var score = 0;
      var before = normalizeForSearch(text.slice(Math.max(0, matchIndex - prefix.length - 8), matchIndex));
      var after = normalizeForSearch(text.slice(matchIndex + exact.length, matchIndex + exact.length + suffix.length + 8));
      if (!prefix || before.endsWith(prefix)) {
        score += 2;
      }
      if (!suffix || after.startsWith(suffix)) {
        score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        bestIndex = matchIndex;
      }
      matchIndex = text.indexOf(exact, matchIndex + Math.max(1, exact.length));
    }

    return bestIndex === -1 ? null : rangeFromTextIndex(index, bestIndex, bestIndex + exact.length);
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
    return (
      rangeFromQuoteSelector(annotation) || rangeFromPositionSelector(annotation) || rangeFromCssSelector(annotation)
    );
  }

  function removeRenderedAnnotation(annotationId) {
    var selector = '[data-marker-annotation-id="' + String(annotationId).replace(/"/g, '\\"') + '"]';
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

  function annotationElement(annotation) {
    var span = document.createElement('mark');
    span.setAttribute('data-marker-annotation-id', annotation.id);
    span.setAttribute('data-marker-annotation-style', annotation.style || 'highlight');
    span.style.setProperty('border-radius', '2px', 'important');
    span.style.setProperty('box-decoration-break', 'clone', 'important');
    span.style.setProperty('-webkit-box-decoration-break', 'clone', 'important');
    span.style.setProperty('color', 'inherit', 'important');
    span.style.setProperty('padding', '0 1px', 'important');
    if (annotation.style === 'underline') {
      span.style.setProperty('background-color', 'transparent', 'important');
      span.style.setProperty('text-decoration-line', 'underline', 'important');
      span.style.setProperty('text-decoration-thickness', '0.16em', 'important');
      span.style.setProperty('text-decoration-color', annotation.color || '#64D2FF', 'important');
      span.style.setProperty('text-underline-offset', '0.18em', 'important');
    } else {
      span.style.setProperty('background-color', annotation.color || '#FFCC00', 'important');
    }
    return span;
  }

  function rangeIntersectsTextNode(range, node) {
    if (typeof range.intersectsNode === 'function') {
      return range.intersectsNode(node);
    }
    var nodeRange = document.createRange();
    try {
      nodeRange.selectNodeContents(node);
      return (
        range.compareBoundaryPoints(Range.END_TO_START, nodeRange) > 0 &&
        range.compareBoundaryPoints(Range.START_TO_END, nodeRange) < 0
      );
    } finally {
      nodeRange.detach && nodeRange.detach();
    }
  }

  function wrapTextNodePortion(node, start, end, annotation) {
    if (!node.parentNode || start < 0 || end <= start || end > node.nodeValue.length) {
      return false;
    }

    var target = node;
    if (end < target.nodeValue.length) {
      target.splitText(end);
    }
    if (start > 0) {
      target = target.splitText(start);
    }

    var wrapper = annotationElement(annotation);
    target.parentNode.insertBefore(wrapper, target);
    wrapper.appendChild(target);
    return true;
  }

  function wrapRangeTextNodes(range, annotation) {
    var root = range.commonAncestorContainer;
    var nodes = textNodesUnder(root).filter(function (node) {
      return rangeIntersectsTextNode(range, node);
    });
    var rendered = false;

    nodes.forEach(function (node) {
      var start = node === range.startContainer ? range.startOffset : 0;
      var end = node === range.endContainer ? range.endOffset : node.nodeValue.length;
      if (wrapTextNodePortion(node, start, end, annotation)) {
        rendered = true;
      }
    });

    return rendered;
  }

  function renderAnnotation(annotation) {
    var range = rangeForAnnotation(annotation);
    if (!range) {
      return false;
    }

    try {
      return wrapRangeTextNodes(range, annotation);
    } catch (error) {
      console.debug('Marker failed to render annotation', annotation.id, error);
      return false;
    }
  }

  function scrollToAnnotation(annotationId) {
    var node = document.querySelector(
      '[data-marker-annotation-id="' + String(annotationId).replace(/"/g, '\\"') + '"]',
    );
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
        pageTitle: document.title || '',
      },
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
    version: 2,
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
    scrollToAnnotation: scrollToAnnotation,
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
