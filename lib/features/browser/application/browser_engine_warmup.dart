import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/features/browser/ad_block/ad_block_providers.dart';

final browserEngineWarmupProvider = Provider<BrowserEngineWarmup>((ref) {
  final warmup = BrowserEngineWarmup(
    logger: ref.watch(appLoggerProvider),
    preloadAdBlockRules: () async {
      await ref.read(compiledAdBlockRulesProvider.future);
    },
    headlessWebView: ref.watch(browserHeadlessWebViewProvider),
  );
  ref.onDispose(() => unawaited(warmup.dispose()));
  return warmup;
});

final browserHeadlessWebViewProvider = Provider<BrowserHeadlessWebView>((ref) => InAppHeadlessBrowserWebView());

abstract interface class BrowserHeadlessWebView {
  Future<void> run(Uri initialUrl);
  Future<void> dispose();
}

class BrowserEngineWarmup {
  BrowserEngineWarmup({
    required AppLogger logger,
    required Future<void> Function() preloadAdBlockRules,
    required BrowserHeadlessWebView headlessWebView,
  }) : _logger = logger,
       _preloadAdBlockRules = preloadAdBlockRules,
       _headlessWebView = headlessWebView;

  final AppLogger _logger;
  final Future<void> Function() _preloadAdBlockRules;
  final BrowserHeadlessWebView _headlessWebView;
  Future<void>? _warmup;

  Future<void> warmUp() {
    final existing = _warmup;
    if (existing != null) {
      return existing;
    }
    final started = _runWarmup();
    _warmup = started;
    return started;
  }

  Future<void> dispose() => _headlessWebView.dispose();

  Future<void> _runWarmup() async => await Future.wait<void>([_warmAdBlockRules(), _warmHeadlessWebView()]);

  Future<void> _warmAdBlockRules() async {
    try {
      await _preloadAdBlockRules();
      _logger.debug('Browser ad block rules warmed');
    } on Object catch (error, stackTrace) {
      _logger.warning('Browser ad block warmup failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _warmHeadlessWebView() async {
    try {
      await _headlessWebView.run(Uri.parse('about:blank'));
      _logger.debug('Headless browser WebView warmed');
    } on Object catch (error, stackTrace) {
      _logger.warning('Headless browser WebView warmup failed', error: error, stackTrace: stackTrace);
    }
  }
}

class InAppHeadlessBrowserWebView implements BrowserHeadlessWebView {
  inapp.HeadlessInAppWebView? _webView;

  @override
  Future<void> run(Uri initialUrl) async {
    if (_webView?.isRunning() == true || inapp.InAppWebViewPlatform.instance == null) {
      return;
    }
    final webView = inapp.HeadlessInAppWebView(
      initialUrlRequest: inapp.URLRequest(url: inapp.WebUri.uri(initialUrl)),
      initialSettings: inapp.InAppWebViewSettings(javaScriptEnabled: true),
    );
    _webView = webView;
    await webView.run();
  }

  @override
  Future<void> dispose() async {
    final webView = _webView;
    _webView = null;
    if (webView?.isRunning() != true) {
      return;
    }
    await webView?.dispose();
  }
}
