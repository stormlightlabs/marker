import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/features/browser/application/reader_controller.dart';
import 'package:marker/src/features/browser/webview/browser_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late final TextEditingController _urlController;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    final initialUrl = ref.read(readerControllerProvider).urlText;
    _urlController = TextEditingController(text: initialUrl);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            ref.read(readerControllerProvider.notifier).updateProgress(progress);
          },
          onPageFinished: (url) async {
            final bridge = ref.read(readerWebViewBridgeProvider);
            await bridge.inject(_webViewController);
            final canonicalUrl = await bridge.readCanonicalUrl(_webViewController);
            final title = await _webViewController.getTitle();
            final loadedUrl = await _webViewController.currentUrl();
            final uri = Uri.tryParse(loadedUrl ?? url);
            if (uri == null) {
              ref.read(readerControllerProvider.notifier).failLoad('The loaded page did not report a valid URL.');
              return;
            }
            await ref
                .read(readerControllerProvider.notifier)
                .finishLoad(url: uri, canonicalUrl: canonicalUrl, title: title);
          },
          onWebResourceError: (error) {
            ref.read(readerControllerProvider.notifier).failLoad(error.description);
          },
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromAddressBar();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadFromAddressBar() async {
    ref.read(readerControllerProvider.notifier).setUrlText(_urlController.text);
    final target = ref.read(readerControllerProvider.notifier).beginLoad();
    if (target == null) {
      return;
    }
    await _webViewController.loadRequest(target);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(readerControllerProvider);
    final webViewBuilder = ref.watch(browserWebViewBuilderProvider);

    ref.listen(readerControllerProvider.select((value) => value.urlText), (previous, next) {
      if (_urlController.text != next) {
        _urlController.text = next;
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BrowserAddressBar(
              controller: _urlController,
              isLoading: session.isLoading,
              onSubmitted: (_) => _loadFromAddressBar(),
              onGoPressed: _loadFromAddressBar,
            ),
            if (session.isLoading) _ReaderProgressBar(progress: session.progress) else const SizedBox(height: 2),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: CupertinoColors.white, child: webViewBuilder(context, _webViewController)),
                  ),
                  if (session.lastError != null)
                    Positioned(left: 12, right: 12, top: 12, child: _ReaderErrorBanner(message: session.lastError!)),
                ],
              ),
            ),
            const _BrowserTabBar(),
          ],
        ),
      ),
    );
  }
}

class _BrowserAddressBar extends StatelessWidget {
  const _BrowserAddressBar({
    required this.controller,
    required this.isLoading,
    required this.onSubmitted,
    required this.onGoPressed,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onGoPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
      child: Row(
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: Center(child: Icon(CupertinoIcons.back, size: 22, color: CupertinoColors.inactiveGray)),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              autocorrect: false,
              clearButtonMode: OverlayVisibilityMode.editing,
              keyboardType: TextInputType.url,
              onSubmitted: onSubmitted,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              placeholder: 'Enter URL',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemGrey, size: 13),
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLoading ? CupertinoColors.activeBlue : CupertinoColors.separator,
                  width: isLoading ? 1.5 : 0.5,
                ),
              ),
              style: const TextStyle(color: CupertinoColors.label, fontSize: 15, letterSpacing: 0),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 10),
            minimumSize: const Size(34, 34),
            onPressed: onGoPressed,
            child: Text(isLoading ? '...' : 'Go', style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _ReaderProgressBar extends StatelessWidget {
  const _ReaderProgressBar({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0, 100) / 100,
          child: const ColoredBox(color: CupertinoColors.activeBlue),
        ),
      ),
    );
  }
}

class _ReaderErrorBanner extends StatelessWidget {
  const _ReaderErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(message, style: const TextStyle(color: CupertinoColors.white, fontSize: 13, letterSpacing: 0)),
      ),
    );
  }
}

class _BrowserTabBar extends StatelessWidget {
  const _BrowserTabBar();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border(top: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              Expanded(
                child: _TabBarItem(icon: CupertinoIcons.collections, label: 'Library', isActive: false),
              ),
              Expanded(
                child: _TabBarItem(icon: CupertinoIcons.globe, label: 'Browser', isActive: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({required this.icon, required this.label, required this.isActive});

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 11, letterSpacing: 0)),
      ],
    );
  }
}
