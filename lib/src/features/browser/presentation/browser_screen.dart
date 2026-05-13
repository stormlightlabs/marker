import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/src/app/app_tab_bar.dart';
import 'package:marker/src/app/routes.dart';
import 'package:marker/src/features/annotations/data/annotation_repository.dart';
import 'package:marker/src/features/browser/application/link_context_controller.dart';
import 'package:marker/src/features/browser/application/native_share_controller.dart';
import 'package:marker/src/features/browser/application/reader_controller.dart';
import 'package:marker/src/features/browser/application/selection_capture_controller.dart';
import 'package:marker/src/features/browser/domain/reader_session_state.dart';
import 'package:marker/src/features/browser/presentation/annotation_sidebar_widget.dart';
import 'package:marker/src/features/browser/presentation/edge_swipe_navigator.dart';
import 'package:marker/src/features/browser/presentation/note_editor_sheet.dart';
import 'package:marker/src/features/browser/webview/browser_webview.dart';
import 'package:marker/src/features/browser/webview/reader_webview_bridge.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late final TextEditingController _urlController;
  late final WebViewController _webViewController;
  final List<Timer> _renderRetryTimers = [];
  bool _areHighlightsVisible = true;
  int _loadGeneration = 0;

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
            final generation = _loadGeneration;
            await ref
                .read(readerControllerProvider.notifier)
                .finishLoad(url: uri, canonicalUrl: canonicalUrl, title: title);
            await _renderSavedAnnotations(uri, generation: generation, retry: true);
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
    unawaited(
      _webViewController.addJavaScriptChannel(
        ReaderWebViewBridge.linkContextChannelName,
        onMessageReceived: (message) {
          ref.read(linkContextControllerProvider.notifier).handleBridgeMessage(message.message);
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromAddressBar();
    });
  }

  @override
  void dispose() {
    _cancelRenderRetries();
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
    _loadGeneration += 1;
    _cancelRenderRetries();
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

  Future<void> _openLinkInCurrentTab(LinkContext link) async {
    ref.read(readerControllerProvider.notifier).setUrlText(link.href.toString());
    final target = ref.read(readerControllerProvider.notifier).beginLoad();
    if (target != null) {
      await _loadUri(target);
    }
  }

  Future<void> _openLinkInNewTab(LinkContext link) async {
    final target = ref.read(readerControllerProvider.notifier).openInNewTab(link.href);
    await _loadUri(target);
  }

  Future<void> _copyText(String value) {
    return Clipboard.setData(ClipboardData(text: value));
  }

  Future<void> _shareUrl(BuildContext originContext, Uri url, String title) {
    final renderObject = originContext.findRenderObject();
    final origin = renderObject is RenderBox ? renderObject.localToGlobal(Offset.zero) & renderObject.size : null;
    return ref.read(nativeUrlShareProvider)(url: url, title: title, sharePositionOrigin: origin);
  }

  void _toggleBookmark() {
    unawaited(ref.read(readerControllerProvider.notifier).toggleBookmark());
  }

  void _dismissSelection() {
    ref.read(selectionCaptureControllerProvider.notifier).clear();
    unawaited(ref.read(readerWebViewBridgeProvider).clearSelection(_webViewController));
  }

  Future<void> _renderSavedAnnotations(Uri sourceUrl, {int? generation, bool retry = false}) async {
    if (!_areHighlightsVisible) {
      await ref.read(readerWebViewBridgeProvider).renderAnnotations(_webViewController, const []);
      return;
    }
    final annotations = await ref.read(annotationsForPageProvider(sourceUrl).future);
    if (!mounted || (generation != null && generation != _loadGeneration)) {
      return;
    }
    await ref
        .read(readerWebViewBridgeProvider)
        .renderAnnotations(
          _webViewController,
          annotations.map((annotation) => annotation.toRenderPayload()).toList(growable: false),
        );
    if (retry && annotations.isNotEmpty) {
      _scheduleRenderRetries(sourceUrl, generation ?? _loadGeneration);
    }
  }

  void _scheduleRenderRetries(Uri sourceUrl, int generation) {
    _cancelRenderRetries();
    for (final delay in const [Duration(milliseconds: 300), Duration(milliseconds: 1200)]) {
      _renderRetryTimers.add(
        Timer(delay, () {
          if (!mounted || generation != _loadGeneration || !_areHighlightsVisible) {
            return;
          }
          unawaited(_renderSavedAnnotations(sourceUrl, generation: generation));
        }),
      );
    }
  }

  void _cancelRenderRetries() {
    for (final timer in _renderRetryTimers) {
      timer.cancel();
    }
    _renderRetryTimers.clear();
  }

  Future<void> _toggleRenderedHighlights(Uri? sourceUrl) async {
    setState(() => _areHighlightsVisible = !_areHighlightsVisible);
    if (_areHighlightsVisible && sourceUrl != null) {
      await _renderSavedAnnotations(sourceUrl);
      return;
    }
    await ref.read(readerWebViewBridgeProvider).renderAnnotations(_webViewController, const []);
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
      builder: (sheetContext) => NoteEditorSheet(quote: capture.exact),
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

  Future<void> _editSidebarAnnotation(PageAnnotation annotation) async {
    final note = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) {
        return NoteEditorSheet(
          quote: annotation.exact ?? 'Untitled annotation',
          initialText: annotation.note ?? '',
          title: annotation.note == null ? 'Add Note' : 'Edit Note',
        );
      },
    );
    if (note == null) {
      return;
    }

    await ref
        .read(annotationRepositoryProvider)
        .updateMarkdownBody(annotationId: annotation.annotation.id, value: note);
    final sourceUrl = Uri.tryParse(annotation.target.sourceUrl);
    if (sourceUrl != null) {
      ref.invalidate(annotationsForPageProvider(sourceUrl));
      await _renderSavedAnnotations(sourceUrl);
    }
  }

  Future<void> _jumpToSidebarAnnotation(PageAnnotation annotation) {
    return ref.read(readerWebViewBridgeProvider).scrollToAnnotation(_webViewController, annotation.annotation.id);
  }

  Future<void> _deleteSidebarAnnotation(PageAnnotation annotation) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Delete Annotation?'),
          content: const Text('This removes the saved annotation and its note from this device.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(annotationRepositoryProvider).deleteAnnotation(annotation.annotation.id);
    await ref.read(readerWebViewBridgeProvider).deleteRenderedAnnotation(_webViewController, annotation.annotation.id);
    final sourceUrl = Uri.tryParse(annotation.target.sourceUrl);
    if (sourceUrl != null) {
      ref.invalidate(annotationsForPageProvider(sourceUrl));
      await _renderSavedAnnotations(sourceUrl);
    }
  }

  Future<void> _showLinkContextMenu(LinkContext link) async {
    ref.read(linkContextControllerProvider.notifier).clear();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          title: Text(link.title),
          message: Text(link.href.toString()),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_openLinkInCurrentTab(link));
              },
              child: const _ActionSheetRow(
                icon: CupertinoIcons.arrow_right_circle,
                title: 'Open',
                subtitle: 'Open in the current tab',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_openLinkInNewTab(link));
              },
              child: const _ActionSheetRow(
                icon: CupertinoIcons.plus_square,
                title: 'Open in New Tab',
                subtitle: 'Switch to a new browser tab',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_copyText(link.href.toString()));
              },
              child: const _ActionSheetRow(
                icon: CupertinoIcons.doc_on_doc,
                title: 'Copy Link',
                subtitle: 'Copy URL to clipboard',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(ref.read(readerControllerProvider.notifier).bookmarkUrl(link.href, title: link.text));
              },
              child: const _ActionSheetRow(
                icon: CupertinoIcons.bookmark,
                title: 'Add Bookmark',
                subtitle: 'Save link to Library',
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

  Future<void> _showBrowserMenu(BuildContext context, ReaderSessionState session) async {
    final currentUrl = session.currentUrl ?? session.normalizedUrl;
    final hasAnnotations = currentUrl == null
        ? false
        : (await ref.read(annotationsForPageProvider(currentUrl).future)).isNotEmpty;
    if (!context.mounted) {
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Browser Menu'),
          message: currentUrl == null ? null : Text(currentUrl.toString()),
          actions: [
            if (currentUrl != null) ...[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_loadUri(currentUrl));
                },
                child: const _ActionSheetRow(
                  icon: CupertinoIcons.refresh,
                  title: 'Reload',
                  subtitle: 'Reload this page',
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_copyText(currentUrl.toString()));
                },
                child: const _ActionSheetRow(
                  icon: CupertinoIcons.doc_on_doc,
                  title: 'Copy URL',
                  subtitle: 'Copy page URL',
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_shareUrl(sheetContext, currentUrl, session.title ?? currentUrl.host));
                },
                child: const _ActionSheetRow(
                  icon: CupertinoIcons.share,
                  title: 'Share',
                  subtitle: 'Open the native share sheet',
                ),
              ),
            ],
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _toggleBookmark();
              },
              child: _ActionSheetRow(
                icon: session.isCurrentPageBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                title: session.isCurrentPageBookmarked ? 'Unbookmark' : 'Bookmark',
                subtitle: session.isCurrentPageBookmarked ? 'Remove page from Library' : 'Save page to Library',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_newTab());
              },
              child: const _ActionSheetRow(
                icon: CupertinoIcons.plus_square,
                title: 'New Tab',
                subtitle: defaultBrowserUrl,
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _showTabs(context, session);
              },
              child: _ActionSheetRow(
                icon: CupertinoIcons.square_on_square,
                title: 'Show Tabs',
                subtitle: '${session.tabs.length} open',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.pushNamed(AppRoute.history.routeName);
              },
              child: const _ActionSheetRow(
                icon: CupertinoIcons.clock,
                title: 'History',
                subtitle: 'View recent page visits',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.pushNamed(AppRoute.settings.routeName);
              },
              child: const _ActionSheetRow(
                icon: CupertinoIcons.settings,
                title: 'Settings',
                subtitle: 'Open app settings',
              ),
            ),
            if (hasAnnotations)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(annotationSidebarOpenProvider.notifier).open();
                },
                child: const _ActionSheetRow(
                  icon: CupertinoIcons.text_bubble,
                  title: 'Open Annotations',
                  subtitle: 'Show annotations for this page',
                ),
              ),
            if (currentUrl != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_toggleRenderedHighlights(currentUrl));
                },
                child: _ActionSheetRow(
                  icon: _areHighlightsVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  title: _areHighlightsVisible ? 'Hide Highlights' : 'Show Highlights',
                  subtitle: _areHighlightsVisible ? 'Temporarily hide page highlights' : 'Render saved highlights',
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
    ref.listen(linkContextControllerProvider.select((state) => state.link), (previous, next) {
      if (next != null && ref.read(selectionCaptureControllerProvider).capture == null) {
        unawaited(_showLinkContextMenu(next));
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
              onMenuPressed: () => unawaited(_showBrowserMenu(context, session)),
              onSubmitted: (_) => _loadFromAddressBar(),
              onGoPressed: _loadFromAddressBar,
            ),
            if (session.isLoading) _ReaderProgressBar(progress: session.progress) else const SizedBox(height: 2),
            Expanded(
              child: EdgeSwipeNavigator(
                canGoBack: session.canGoBack,
                canGoForward: session.canGoForward,
                onBack: _goBack,
                onForward: _goForward,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: CupertinoColors.black,
                        child: webViewBuilder(context, _webViewController),
                      ),
                    ),
                    Positioned.fill(
                      child: AnnotationSidebarWidget(
                        sourceUrl: session.currentUrl,
                        onEdit: _editSidebarAnnotation,
                        onJump: _jumpToSidebarAnnotation,
                        onDelete: _deleteSidebarAnnotation,
                      ),
                    ),
                    if (session.isLoading) const Positioned(top: 12, right: 12, child: _ReaderLoadingBadge()),
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
    required this.onMenuPressed,
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
  final VoidCallback onMenuPressed;
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
                child: const Text('Go', style: TextStyle(fontSize: 15)),
              ),
              _BrowserIconButton(
                icon: CupertinoIcons.ellipsis_circle,
                label: 'Browser Menu',
                isEnabled: true,
                onPressed: onMenuPressed,
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

class _ReaderLoadingBadge extends StatelessWidget {
  const _ReaderLoadingBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE61C1C20),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 7),
            SizedBox(width: 8),
            Text('Loading', style: TextStyle(color: CupertinoColors.white, fontSize: 12, letterSpacing: 0)),
          ],
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
