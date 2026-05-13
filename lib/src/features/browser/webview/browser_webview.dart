import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/features/browser/webview/reader_webview_bridge.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef BrowserWebViewBuilder = Widget Function(BuildContext context, WebViewController controller);

final browserWebViewBuilderProvider = Provider<BrowserWebViewBuilder>((ref) {
  return (context, controller) => WebViewWidget(controller: controller);
});

final readerWebViewBridgeProvider = Provider<ReaderWebViewBridge>((ref) {
  return const ReaderWebViewBridge();
});
