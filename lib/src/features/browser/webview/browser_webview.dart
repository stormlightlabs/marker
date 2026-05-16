import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/features/browser/ad_block/ad_block_rules.dart';

typedef BrowserWebViewBuilder = Widget Function(BuildContext context, BrowserWebViewController controller);
typedef BrowserWebViewControllerFactory = BrowserWebViewController Function();
typedef BrowserJavaScriptMessageHandler = void Function(String message);

final browserWebViewControllerFactoryProvider = Provider<BrowserWebViewControllerFactory>((ref) {
  return InAppBrowserWebViewController.new;
});

final browserWebViewBuilderProvider = Provider<BrowserWebViewBuilder>((ref) {
  return (context, controller) => InAppBrowserWebView(controller: controller);
});

class BrowserNavigationDelegate {
  const BrowserNavigationDelegate({
    required this.onProgress,
    required this.onPageFinished,
    required this.onWebResourceError,
  });

  final void Function(int progress) onProgress;
  final Future<void> Function(String url) onPageFinished;
  final void Function(String description) onWebResourceError;
}

abstract class BrowserWebViewController {
  Future<void> setJavaScriptModeUnrestricted();
  Future<void> setNavigationDelegate(BrowserNavigationDelegate delegate);
  Future<void> addJavaScriptChannel(String name, {required BrowserJavaScriptMessageHandler onMessageReceived});
  Future<void> loadRequest(Uri uri);
  Future<void> reload();
  Future<void> runJavaScript(String javaScript);
  Future<Object?> runJavaScriptReturningResult(String javaScript);
  Future<String?> getTitle();
  Future<String?> currentUrl();
  Future<void> setAdBlockRules(CompiledAdBlockRules? rules);
}

class InAppBrowserWebView extends StatelessWidget {
  const InAppBrowserWebView({required this.controller, super.key});

  final BrowserWebViewController controller;

  @override
  Widget build(BuildContext context) {
    final inAppController = controller as InAppBrowserWebViewController;
    return inapp.InAppWebView(
      initialSettings: inAppController.settings,
      onWebViewCreated: inAppController.attach,
      onProgressChanged: (controller, progress) => inAppController.handleProgress(progress),
      onLoadStop: (controller, url) => inAppController.handleLoadStop(url),
      onReceivedError: (controller, request, error) => inAppController.handleReceivedError(request, error),
      shouldOverrideUrlLoading: (controller, navigationAction) =>
          inAppController.handleNavigationRequest(navigationAction),
      shouldInterceptRequest: (controller, request) => inAppController.handleInterceptRequest(request),
    );
  }
}

class InAppBrowserWebViewController implements BrowserWebViewController {
  inapp.InAppWebViewController? _controller;
  BrowserNavigationDelegate? _delegate;
  Uri? _pendingLoad;
  Uri? _currentTopUrl;
  CompiledAdBlockRules? _adBlockRules;
  final _channels = <String, BrowserJavaScriptMessageHandler>{};

  inapp.InAppWebViewSettings get settings => inapp.InAppWebViewSettings(
    javaScriptEnabled: true,
    disableInputAccessoryView: true,
    useShouldOverrideUrlLoading: true,
    useShouldInterceptRequest: true,
    contentBlockers: _contentBlockersFor(_adBlockRules),
  );

  void attach(inapp.InAppWebViewController controller) {
    _controller = controller;
    for (final entry in _channels.entries) {
      _installJavaScriptHandler(entry.key, entry.value);
    }
    unawaited(_applySettings());
    final pendingLoad = _pendingLoad;
    if (pendingLoad != null) {
      _pendingLoad = null;
      unawaited(loadRequest(pendingLoad));
    }
  }

  void handleProgress(int progress) {
    _delegate?.onProgress(progress);
  }

  Future<void> handleLoadStop(inapp.WebUri? url) async {
    final text = url?.toString() ?? await currentUrl();
    if (text == null) {
      return;
    }
    _currentTopUrl = Uri.tryParse(text);
    await _delegate?.onPageFinished(text);
  }

  void handleReceivedError(inapp.WebResourceRequest request, inapp.WebResourceError error) {
    if (request.isForMainFrame == false) {
      return;
    }
    _delegate?.onWebResourceError(error.description);
  }

  Future<inapp.NavigationActionPolicy?> handleNavigationRequest(inapp.NavigationAction navigationAction) async {
    return inapp.NavigationActionPolicy.ALLOW;
  }

  Future<inapp.WebResourceResponse?> handleInterceptRequest(inapp.WebResourceRequest request) async {
    final rules = _adBlockRules;
    if (rules == null) {
      return null;
    }
    final url = Uri.tryParse(request.url.toString());
    if (url == null || !url.hasScheme) {
      return null;
    }
    final type = _resourceTypeForRequest(request);
    final shouldBlock = rules.shouldBlockRequest(url, topUrl: _currentTopUrl, resourceType: type);
    if (!shouldBlock) {
      return null;
    }
    return inapp.WebResourceResponse(
      contentType: 'text/plain',
      data: Uint8List(0),
      statusCode: 200,
      reasonPhrase: 'OK',
      headers: const {'Access-Control-Allow-Origin': '*'},
    );
  }

  @override
  Future<void> setJavaScriptModeUnrestricted() async {}

  @override
  Future<void> setNavigationDelegate(BrowserNavigationDelegate delegate) async {
    _delegate = delegate;
  }

  @override
  Future<void> addJavaScriptChannel(String name, {required BrowserJavaScriptMessageHandler onMessageReceived}) async {
    _channels[name] = onMessageReceived;
    _installJavaScriptHandler(name, onMessageReceived);
  }

  @override
  Future<void> loadRequest(Uri uri) async {
    _currentTopUrl = uri;
    final controller = _controller;
    if (controller == null) {
      _pendingLoad = uri;
      return;
    }
    await controller.loadUrl(urlRequest: inapp.URLRequest(url: inapp.WebUri.uri(uri)));
  }

  @override
  Future<void> reload() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.reload();
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.evaluateJavascript(source: javaScript);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String javaScript) async {
    final controller = _controller;
    if (controller == null) {
      return null;
    }
    return controller.evaluateJavascript(source: javaScript);
  }

  @override
  Future<String?> getTitle() {
    final controller = _controller;
    if (controller == null) {
      return Future<String?>.value(null);
    }
    return controller.getTitle();
  }

  @override
  Future<String?> currentUrl() async {
    final controller = _controller;
    if (controller == null) {
      return _currentTopUrl?.toString();
    }
    final url = await controller.getUrl();
    return url?.toString() ?? _currentTopUrl?.toString();
  }

  @override
  Future<void> setAdBlockRules(CompiledAdBlockRules? rules) async {
    _adBlockRules = rules;
    await _applySettings();
  }

  Future<void> _applySettings() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.setSettings(settings: settings);
  }

  void _installJavaScriptHandler(String name, BrowserJavaScriptMessageHandler handler) {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (controller.hasJavaScriptHandler(handlerName: name)) {
      controller.removeJavaScriptHandler(handlerName: name);
    }
    controller.addJavaScriptHandler(
      handlerName: name,
      callback: (arguments) {
        if (arguments.isEmpty) {
          return null;
        }
        handler(arguments.first?.toString() ?? '');
        return null;
      },
    );
  }
}

List<inapp.ContentBlocker> _contentBlockersFor(CompiledAdBlockRules? rules) {
  if (rules == null) {
    return const [];
  }
  final blockers = <inapp.ContentBlocker>[];
  for (final rule in rules.networkRules) {
    if (!_isWebKitContentBlockerRuleSupported(rule)) {
      continue;
    }
    blockers.add(
      inapp.ContentBlocker(
        trigger: inapp.ContentBlockerTrigger(
          urlFilter: rule.urlFilter,
          resourceType: rule.resourceTypes.map(_contentBlockerResourceType).toList(growable: false),
          loadType: rule.loadTypes.map(_contentBlockerLoadType).toList(growable: false),
          ifTopUrl: rule.ifTopUrl,
          unlessTopUrl: rule.unlessTopUrl,
        ),
        action: inapp.ContentBlockerAction(
          type: rule.isException
              ? inapp.ContentBlockerActionType.IGNORE_PREVIOUS_RULES
              : inapp.ContentBlockerActionType.BLOCK,
        ),
      ),
    );
  }
  return blockers;
}

bool _isWebKitContentBlockerRuleSupported(AdBlockNetworkRule rule) {
  return _isWebKitContentBlockerPatternSupported(rule.urlFilter) &&
      rule.ifTopUrl.every(_isWebKitContentBlockerPatternSupported) &&
      rule.unlessTopUrl.every(_isWebKitContentBlockerPatternSupported);
}

bool _isWebKitContentBlockerPatternSupported(String pattern) {
  if (pattern.codeUnits.any((codeUnit) => codeUnit > 0x7F)) {
    return false;
  }

  var escaped = false;
  var inCharacterClass = false;
  var characterClassStart = -1;
  for (var index = 0; index < pattern.length; index += 1) {
    final char = pattern[index];
    if (escaped) {
      if (_isUnsupportedRegexEscape(char)) {
        return false;
      }
      escaped = false;
      continue;
    }
    if (char == r'\') {
      escaped = true;
      continue;
    }
    if (char == '|') {
      return false;
    }
    if (!inCharacterClass && (char == '{' || char == '}')) {
      return false;
    }
    if (char == '[') {
      if (inCharacterClass) {
        return false;
      }
      inCharacterClass = true;
      characterClassStart = index;
      continue;
    }
    if (char == ']') {
      if (!inCharacterClass || !_isSupportedCharacterClass(pattern.substring(characterClassStart + 1, index))) {
        return false;
      }
      inCharacterClass = false;
      continue;
    }
    if (!inCharacterClass && char == '?' && _isUnsupportedQuestionMarkUse(pattern, index)) {
      return false;
    }
    if (!inCharacterClass && char == '^' && index != 0) {
      return false;
    }
    if (!inCharacterClass && char == r'$' && index != pattern.length - 1) {
      return false;
    }
  }
  return !escaped && !inCharacterClass;
}

bool _isUnsupportedRegexEscape(String char) {
  return _isAsciiAlphaNumeric(char);
}

bool _isSupportedCharacterClass(String content) {
  if (content.isEmpty || content.startsWith('^') || content.contains('|')) {
    return false;
  }
  var escaped = false;
  for (final codeUnit in content.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    if (escaped) {
      if (_isUnsupportedRegexEscape(char)) {
        return false;
      }
      escaped = false;
      continue;
    }
    if (char == r'\') {
      escaped = true;
      continue;
    }
  }
  return !escaped;
}

bool _isUnsupportedQuestionMarkUse(String pattern, int index) => index > 0 && pattern[index - 1] == '(';

bool _isAsciiAlphaNumeric(String char) {
  final codeUnit = char.codeUnitAt(0);
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A);
}

inapp.ContentBlockerTriggerResourceType _contentBlockerResourceType(AdBlockResourceType type) => switch (type) {
  AdBlockResourceType.document => inapp.ContentBlockerTriggerResourceType.DOCUMENT,
  AdBlockResourceType.font => inapp.ContentBlockerTriggerResourceType.FONT,
  AdBlockResourceType.image => inapp.ContentBlockerTriggerResourceType.IMAGE,
  AdBlockResourceType.media => inapp.ContentBlockerTriggerResourceType.MEDIA,
  AdBlockResourceType.raw => inapp.ContentBlockerTriggerResourceType.RAW,
  AdBlockResourceType.script => inapp.ContentBlockerTriggerResourceType.SCRIPT,
  AdBlockResourceType.styleSheet => inapp.ContentBlockerTriggerResourceType.STYLE_SHEET,
};

inapp.ContentBlockerTriggerLoadType _contentBlockerLoadType(AdBlockLoadType type) => switch (type) {
  AdBlockLoadType.firstParty => inapp.ContentBlockerTriggerLoadType.FIRST_PARTY,
  AdBlockLoadType.thirdParty => inapp.ContentBlockerTriggerLoadType.THIRD_PARTY,
};

AdBlockResourceType? _resourceTypeForRequest(inapp.WebResourceRequest request) {
  final path = request.url.path.toLowerCase();
  if (path.endsWith('.js')) {
    return AdBlockResourceType.script;
  }
  if (path.endsWith('.css')) {
    return AdBlockResourceType.styleSheet;
  }
  if (path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      path.endsWith('.avif') ||
      path.endsWith('.svg')) {
    return AdBlockResourceType.image;
  }
  if (path.endsWith('.woff') || path.endsWith('.woff2') || path.endsWith('.ttf') || path.endsWith('.otf')) {
    return AdBlockResourceType.font;
  }
  if (path.endsWith('.mp4') || path.endsWith('.webm') || path.endsWith('.mp3') || path.endsWith('.m3u8')) {
    return AdBlockResourceType.media;
  }
  return AdBlockResourceType.raw;
}
