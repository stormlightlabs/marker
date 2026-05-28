import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/features/browser/application/browser_engine_warmup.dart';

void main() {
  test('warms ad block rules and about blank once', () async {
    var adBlockWarmups = 0;
    final headlessWebView = FakeHeadlessWebView();
    final warmup = BrowserEngineWarmup(
      logger: AppLogger.console(),
      preloadAdBlockRules: () async {
        adBlockWarmups += 1;
      },
      headlessWebView: headlessWebView,
    );

    await warmup.warmUp();
    await warmup.warmUp();

    expect(adBlockWarmups, 1);
    expect(headlessWebView.runUrls, [Uri.parse('about:blank')]);
  });

  test('does not let warmup failures escape startup', () async {
    final headlessWebView = FakeHeadlessWebView()..runError = StateError('webview unavailable');
    final warmup = BrowserEngineWarmup(
      logger: AppLogger.console(),
      preloadAdBlockRules: () => throw StateError('rules unavailable'),
      headlessWebView: headlessWebView,
    );

    await expectLater(warmup.warmUp(), completes);

    expect(headlessWebView.runUrls, [Uri.parse('about:blank')]);
  });

  test('disposes the warmed headless WebView', () async {
    final headlessWebView = FakeHeadlessWebView();
    final warmup = BrowserEngineWarmup(
      logger: AppLogger.console(),
      preloadAdBlockRules: () async {},
      headlessWebView: headlessWebView,
    );

    await warmup.dispose();

    expect(headlessWebView.disposeCount, 1);
  });
}

class FakeHeadlessWebView implements BrowserHeadlessWebView {
  final runUrls = <Uri>[];
  var disposeCount = 0;
  Object? runError;

  @override
  Future<void> run(Uri initialUrl) async {
    runUrls.add(initialUrl);
    final error = runError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}
