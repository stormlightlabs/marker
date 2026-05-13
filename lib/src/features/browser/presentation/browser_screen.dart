import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/app/app_tab_bar.dart';
import 'package:marker/src/app/routes.dart';
import 'package:marker/src/features/annotations/data/annotation_repository.dart';
import 'package:marker/src/features/browser/application/reader_controller.dart';
import 'package:marker/src/features/browser/application/selection_capture_controller.dart';
import 'package:marker/src/features/browser/domain/reader_session_state.dart';
import 'package:marker/src/features/browser/webview/browser_webview.dart';
import 'package:marker/src/features/browser/webview/reader_webview_bridge.dart';
import 'package:marker/src/features/browser/presentation/note_editor_sheet.dart';
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
            await _renderSavedAnnotations(uri);
          },
          onWebResourceError: (error) {
            ref.read(readerControllerProvider.notifier).failLoad(error.description);
          },
        ),
      );
    unawaited(
      _webViewController.addJavaScriptChannel(
        ReaderWebViewBridge.selectionChannelName,
        onMessageReceived: (message) {
          ref.read(selectionCaptureControllerProvider.notifier).handleBridgeMessage(message.message);
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
    await _loadUri(target);
  }

  Future<void> _loadUri(Uri target) {
    ref.read(selectionCaptureControllerProvider.notifier).clear();
    return _webViewController.loadRequest(target);
  }

  Future<void> _goBack() async {
    final target = ref.read(readerControllerProvider.notifier).goBack();
    if (target != null) {
      await _loadUri(target);
    }
  }

  Future<void> _goForward() async {
    final target = ref.read(readerControllerProvider.notifier).goForward();
    if (target != null) {
      await _loadUri(target);
    }
  }

  Future<void> _newTab() async {
    final target = ref.read(readerControllerProvider.notifier).newTab();
    await _loadUri(target);
  }

  Future<void> _switchTab(String tabId) async {
    final target = ref.read(readerControllerProvider.notifier).switchTab(tabId);
    if (target != null) {
      await _loadUri(target);
    }
  }

  Future<void> _closeTab(String tabId) async {
    final target = ref.read(readerControllerProvider.notifier).closeTab(tabId);
    if (target != null) {
      await _loadUri(target);
    }
  }

  Future<void> _openBookmark(Uri url) async {
    final target = ref.read(readerControllerProvider.notifier).openBookmark(url);
    if (target != null) {
      await _loadUri(target);
    }
  }

  void _toggleBookmark() {
    unawaited(ref.read(readerControllerProvider.notifier).toggleBookmark());
  }

  void _dismissSelection() {
    ref.read(selectionCaptureControllerProvider.notifier).clear();
    unawaited(ref.read(readerWebViewBridgeProvider).clearSelection(_webViewController));
  }

  Future<void> _renderSavedAnnotations(Uri sourceUrl) async {
    final annotations = await ref.read(annotationsForPageProvider(sourceUrl).future);
    await ref
        .read(readerWebViewBridgeProvider)
        .renderAnnotations(
          _webViewController,
          annotations.map((annotation) => annotation.toRenderPayload()).toList(growable: false),
        );
  }

  Future<void> _saveHighlight(SelectionCapture capture) async {
    await _saveAnnotation(
      capture,
      motivation: 'highlighting',
      bodies: [AnnotationBodyInput.style(style: AnnotationVisualStyle.highlight, colorHex: '#FFCC00')],
    );
  }

  Future<void> _saveUnderline(SelectionCapture capture) async {
    await _saveAnnotation(
      capture,
      motivation: 'highlighting',
      bodies: [AnnotationBodyInput.style(style: AnnotationVisualStyle.underline, colorHex: '#64D2FF')],
    );
  }

  Future<void> _openNoteEditor(SelectionCapture capture) async {
    final note = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => NoteEditorSheet(capture: capture),
    );
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }

    await _saveAnnotation(
      capture,
      motivation: 'commenting',
      bodies: [
        AnnotationBodyInput.markdownNote(trimmed),
        AnnotationBodyInput.style(style: AnnotationVisualStyle.highlight, colorHex: '#FFCC00'),
      ],
    );
  }

  Future<void> _saveAnnotation(
    SelectionCapture capture, {
    required String motivation,
    required List<AnnotationBodyInput> bodies,
  }) async {
    await ref
        .read(annotationRepositoryProvider)
        .createAnnotation(
          sourceUrl: capture.sourceUrl,
          exact: capture.exact,
          prefix: capture.prefix,
          suffix: capture.suffix,
          motivation: motivation,
          textPositionStart: capture.textPositionStart,
          textPositionEnd: capture.textPositionEnd,
          pageTitle: capture.pageTitle,
          cssSelector: capture.cssSelector,
          bodies: bodies,
        );
    ref.invalidate(annotationsForPageProvider(capture.sourceUrl));
    await _renderSavedAnnotations(capture.sourceUrl);
    _dismissSelection();
  }

  void _showTabs(BuildContext context, ReaderSessionState session) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Tabs'),
          actions: [
            for (final tab in session.tabs)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _switchTab(tab.id);
                },
                child: _ActionSheetRow(
                  icon: tab.id == session.activeTabId ? CupertinoIcons.check_mark : CupertinoIcons.globe,
                  title: tab.title ?? tab.currentUrl?.host ?? tab.urlText,
                  subtitle: tab.currentUrl?.toString() ?? tab.urlText,
                ),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _newTab();
              },
              child: const _ActionSheetRow(icon: CupertinoIcons.add, title: 'New Tab', subtitle: defaultBrowserUrl),
            ),
            if (session.tabs.length > 1)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _closeTab(session.activeTabId);
                },
                child: const _ActionSheetRow(
                  icon: CupertinoIcons.xmark,
                  title: 'Close Current Tab',
                  subtitle: 'Switches to the previous tab',
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _showBookmarks(BuildContext context, ReaderSessionState session) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Bookmarks'),
          message: session.bookmarks.isEmpty ? const Text('No bookmarks yet.') : null,
          actions: [
            for (final bookmark in session.bookmarks)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _openBookmark(bookmark.url);
                },
                child: _ActionSheetRow(
                  icon: CupertinoIcons.bookmark_fill,
                  title: bookmark.title ?? bookmark.url.host,
                  subtitle: bookmark.url.toString(),
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(readerControllerProvider);
    final selection = ref.watch(selectionCaptureControllerProvider);
    final webViewBuilder = ref.watch(browserWebViewBuilderProvider);

    ref.listen(readerControllerProvider.select((value) => value.urlText), (previous, next) {
      if (_urlController.text != next) {
        _urlController.text = next;
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BrowserAddressBar(
              controller: _urlController,
              canGoBack: session.canGoBack,
              canGoForward: session.canGoForward,
              isBookmarked: session.isCurrentPageBookmarked,
              isLoading: session.isLoading,
              tabCount: session.tabs.length,
              bookmarkCount: session.bookmarks.length,
              onBackPressed: _goBack,
              onForwardPressed: _goForward,
              onBookmarkPressed: _toggleBookmark,
              onBookmarksPressed: () => _showBookmarks(context, session),
              onTabsPressed: () => _showTabs(context, session),
              onSubmitted: (_) => _loadFromAddressBar(),
              onGoPressed: _loadFromAddressBar,
            ),
            if (session.isLoading) _ReaderProgressBar(progress: session.progress) else const SizedBox(height: 2),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: CupertinoColors.black, child: webViewBuilder(context, _webViewController)),
                  ),
                  if (selection.capture != null)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 16,
                      child: AnnotationToolbar(
                        capture: selection.capture!,
                        onHighlightPressed: () => unawaited(_saveHighlight(selection.capture!)),
                        onNotePressed: () => unawaited(_openNoteEditor(selection.capture!)),
                        onUnderlinePressed: () => unawaited(_saveUnderline(selection.capture!)),
                        onRemovePressed: _dismissSelection,
                      ),
                    ),
                  if (session.lastError != null)
                    Positioned(left: 12, right: 12, top: 12, child: _ReaderErrorBanner(message: session.lastError!)),
                ],
              ),
            ),
            const MarkerTabBar(activeRoute: AppRoute.browser),
          ],
        ),
      ),
    );
  }
}

class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({
    required this.capture,
    required this.onHighlightPressed,
    required this.onNotePressed,
    required this.onUnderlinePressed,
    required this.onRemovePressed,
    super.key,
  });

  final SelectionCapture capture;
  final VoidCallback onHighlightPressed;
  final VoidCallback onNotePressed;
  final VoidCallback onUnderlinePressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF21A1A1F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF33333A), width: 0.5),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Text(
                  capture.exact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CupertinoColors.systemGrey2, fontSize: 12, letterSpacing: 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AnnotationToolbarButton(
                      icon: CupertinoIcons.pencil,
                      label: 'Highlight',
                      color: CupertinoColors.systemYellow,
                      onPressed: onHighlightPressed,
                    ),
                    const _ToolbarDivider(),
                    _AnnotationToolbarButton(
                      icon: CupertinoIcons.chat_bubble_text,
                      label: 'Note',
                      color: CupertinoColors.white,
                      onPressed: onNotePressed,
                    ),
                    const _ToolbarDivider(),
                    _AnnotationToolbarButton(
                      icon: CupertinoIcons.underline,
                      label: 'Underline',
                      color: CupertinoColors.systemTeal,
                      onPressed: onUnderlinePressed,
                    ),
                    const _ToolbarDivider(),
                    _AnnotationToolbarButton(
                      icon: CupertinoIcons.trash,
                      label: 'Remove',
                      color: CupertinoColors.systemRed,
                      onPressed: onRemovePressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotationToolbarButton extends StatelessWidget {
  const _AnnotationToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        minimumSize: const Size(62, 54),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 11, letterSpacing: 0)),
          ],
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF33333A))),
        ),
      ),
    );
  }
}

class _ActionSheetRow extends StatelessWidget {
  const _ActionSheetRow({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CupertinoColors.activeBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrowserAddressBar extends StatelessWidget {
  const _BrowserAddressBar({
    required this.controller,
    required this.canGoBack,
    required this.canGoForward,
    required this.isBookmarked,
    required this.isLoading,
    required this.tabCount,
    required this.bookmarkCount,
    required this.onBackPressed,
    required this.onForwardPressed,
    required this.onBookmarkPressed,
    required this.onBookmarksPressed,
    required this.onTabsPressed,
    required this.onSubmitted,
    required this.onGoPressed,
  });

  final TextEditingController controller;
  final bool canGoBack;
  final bool canGoForward;
  final bool isBookmarked;
  final bool isLoading;
  final int tabCount;
  final int bookmarkCount;
  final VoidCallback onBackPressed;
  final VoidCallback onForwardPressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onBookmarksPressed;
  final VoidCallback onTabsPressed;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onGoPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _BrowserIconButton(
                icon: CupertinoIcons.back,
                label: 'Back',
                isEnabled: canGoBack,
                onPressed: onBackPressed,
              ),
              _BrowserIconButton(
                icon: CupertinoIcons.forward,
                label: 'Forward',
                isEnabled: canGoForward,
                onPressed: onForwardPressed,
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
                    color: const Color(0xFF1C1C20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLoading ? CupertinoColors.activeBlue : const Color(0xFF33333A),
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
          const SizedBox(height: 6),
          Row(
            children: [
              _BrowserChromeChip(
                icon: isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                label: isBookmarked ? 'Saved' : 'Save',
                onPressed: onBookmarkPressed,
              ),
              const SizedBox(width: 8),
              _BrowserChromeChip(
                icon: CupertinoIcons.book,
                label: 'Bookmarks $bookmarkCount',
                onPressed: onBookmarksPressed,
              ),
              const Spacer(),
              _BrowserChromeChip(
                icon: CupertinoIcons.square_on_square,
                label: 'Tabs $tabCount',
                onPressed: onTabsPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrowserIconButton extends StatelessWidget {
  const _BrowserIconButton({required this.icon, required this.label, required this.isEnabled, required this.onPressed});

  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(34, 34),
        onPressed: isEnabled ? onPressed : null,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _BrowserChromeChip extends StatelessWidget {
  const _BrowserChromeChip({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 30),
        color: const Color(0xFF1C1C20),
        borderRadius: BorderRadius.circular(8),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: CupertinoColors.activeBlue),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.white, letterSpacing: 0)),
          ],
        ),
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
