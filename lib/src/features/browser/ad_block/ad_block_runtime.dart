import 'dart:convert';

import 'package:marker/src/features/browser/ad_block/ad_block_rules.dart';
import 'package:marker/src/features/browser/webview/browser_webview.dart';

class AdBlockRuntime {
  const AdBlockRuntime();

  Future<void> injectCosmeticFilters(
    BrowserWebViewController controller, {
    required Uri pageUrl,
    required CompiledAdBlockRules rules,
  }) async {
    final selectors = rules.cosmeticSelectorsFor(pageUrl);
    if (selectors.isEmpty) {
      await controller.runJavaScript(_clearScript);
      return;
    }
    await controller.runJavaScript('window.MarkerAdBlock && window.MarkerAdBlock.stop();');
    await controller.runJavaScript(_runtimeScript(jsonEncode(selectors)));
  }
}

const String _clearScript = '''
(function () {
  if (window.MarkerAdBlock && typeof window.MarkerAdBlock.stop === 'function') {
    window.MarkerAdBlock.stop();
  }
})();
''';

String _runtimeScript(String selectorsJson) {
  return '''
(function () {
  var selectors = $selectorsJson;
  var observer = null;

  function hideOne(selector) {
    try {
      var nodes = document.querySelectorAll(selector);
      for (var i = 0; i < nodes.length; i += 1) {
        nodes[i].style.setProperty('display', 'none', 'important');
        nodes[i].setAttribute('data-marker-ad-block-hidden', 'true');
      }
    } catch (error) {
      console.debug('Marker ignored invalid ad-block cosmetic selector', selector, error);
    }
  }

  function applyCosmeticRules() {
    for (var i = 0; i < selectors.length; i += 1) {
      hideOne(selectors[i]);
    }
  }

  if (window.MarkerAdBlock && typeof window.MarkerAdBlock.stop === 'function') {
    window.MarkerAdBlock.stop();
  }

  window.MarkerAdBlock = {
    stop: function () {
      if (observer) {
        observer.disconnect();
        observer = null;
      }
    },
  };

  applyCosmeticRules();
  observer = new MutationObserver(function () {
    applyCosmeticRules();
  });
  observer.observe(document.documentElement || document, { childList: true, subtree: true });
})();
''';
}
