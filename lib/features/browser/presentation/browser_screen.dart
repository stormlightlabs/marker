import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/browser/ad_block/ad_block_providers.dart';
import 'package:marker/features/browser/application/link_context_controller.dart';
import 'package:marker/features/browser/application/native_share_controller.dart';
import 'package:marker/features/browser/application/reader_controller.dart';
import 'package:marker/features/browser/application/selection_capture_controller.dart';
import 'package:marker/features/browser/data/browser_history_search_repository.dart';
import 'package:marker/features/browser/data/favicon_cache.dart';
import 'package:marker/features/browser/domain/reader_session_state.dart';
import 'package:marker/features/browser/presentation/annotation_sidebar_widget.dart';
import 'package:marker/features/browser/presentation/edge_swipe_navigator.dart';
import 'package:marker/features/browser/presentation/note_editor_sheet.dart';
import 'package:marker/features/browser/presentation/widgets/annotation_toolbar.dart';
import 'package:marker/features/browser/presentation/widgets/history_overlay.dart';
import 'package:marker/features/browser/webview/browser_webview.dart';
import 'package:marker/features/browser/webview/reader_webview_bridge.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late final TextEditingController _urlController;
  late final FocusNode _addressFocusNode;
  late final BrowserWebViewController _webViewController;
  final List<Timer> _renderRetryTimers = [];
  bool _areHighlightsVisible = true;
  String _addressSearchQuery = '';
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    final initialUrl = ref.read(readerControllerProvider).urlText;
    _urlController = TextEditingController(text: initialUrl);
    _addressFocusNode = FocusNode()..addListener(_handleAddressFocusChanged);
    _webViewController = ref.read(browserWebViewControllerFactoryProvider)();
    unawaited(_webViewController.setJavaScriptModeUnrestricted());
    unawaited(
      _webViewController.setNavigationDelegate(
        BrowserNavigationDelegate(
          onProgress: (progress) {
            ref.read(readerControllerProvider.notifier).updateProgress(progress);
          },
          onPageFinished: (url) async {
            final bridge = ref.read(readerWebViewBridgeProvider);
            await bridge.inject(_webViewController);
            final canonicalUrl = await bridge.readCanonicalUrl(_webViewController);
            final description = await bridge.readMetaDescription(_webViewController);
            final title = await _webViewController.getTitle();
            final loadedUrl = await _webViewController.currentUrl();
            final uri = Uri.tryParse(loadedUrl ?? url);
            if (uri == null) {
              ref.read(readerControllerProvider.notifier).failLoad('The loaded page did not report a valid URL.');
              return;
            }
            final faviconUrl = await bridge.readFaviconUrl(_webViewController, uri);
            final faviconFilePath = await ref.read(faviconCacheProvider).cacheFavicon(faviconUrl);
            final generation = _loadGeneration;
            await _injectAdBlockCosmetics(uri);
            await ref
                .read(readerControllerProvider.notifier)
                .finishLoad(
                  url: uri,
                  canonicalUrl: canonicalUrl,
                  title: title,
                  description: description,
                  faviconUrl: faviconUrl,
                  faviconFilePath: faviconFilePath,
                );
            await _renderSavedAnnotations(uri, generation: generation, retry: true);
          },
          onWebResourceError: (description) {
            ref.read(readerControllerProvider.notifier).failLoad(description);
          },
        ),
      ),
    );
    unawaited(
      _webViewController.addJavaScriptChannel(
        ReaderWebViewBridge.selectionChannelName,
        onMessageReceived: (message) {
          ref.read(selectionCaptureControllerProvider.notifier).handleBridgeMessage(message);
        },
      ),
    );
    unawaited(
      _webViewController.addJavaScriptChannel(
        ReaderWebViewBridge.linkContextChannelName,
        onMessageReceived: (message) {
          ref.read(linkContextControllerProvider.notifier).handleBridgeMessage(message);
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_configureAdBlocking(reload: false).then((_) => _loadFromAddressBar()));
    });
  }

  @override
  void dispose() {
    _cancelRenderRetries();
    _addressFocusNode
      ..removeListener(_handleAddressFocusChanged)
      ..dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadFromAddressBar() async {
    ref.read(readerControllerProvider.notifier).setUrlText(_urlController.text);
    final target = ref.read(readerControllerProvider.notifier).beginLoad();
    if (target == null) {
      return;
    }
    _addressFocusNode.unfocus();
    setState(() {
      _addressSearchQuery = '';
    });
    await _loadUri(target);
  }

  Future<void> _reloadCurrentPage() async {
    _addressFocusNode.unfocus();
    await _webViewController.reload();
  }

  Future<void> _stopLoadingCurrentPage() async {
    await _webViewController.stopLoading();
    ref.read(readerControllerProvider.notifier).stopLoad();
  }

  Future<void> _loadUri(Uri target) {
    _loadGeneration += 1;
    _cancelRenderRetries();
    ref.read(selectionCaptureControllerProvider.notifier).clear();
    return _webViewController.loadRequest(target);
  }

  Future<void> _configureAdBlocking({required bool reload}) async {
    final enabled = ref.read(adBlockEnabledProvider).value ?? true;
    final rules = enabled ? ref.read(compiledAdBlockRulesProvider).value : null;
    await _webViewController.setAdBlockRules(rules);
    if (reload) {
      await _webViewController.reload();
    }
  }

  Future<void> _injectAdBlockCosmetics(Uri pageUrl) async {
    final enabled = ref.read(adBlockEnabledProvider).value ?? true;
    final rules = ref.read(compiledAdBlockRulesProvider).value;
    if (!enabled || rules == null) {
      return;
    }
    await ref.read(adBlockRuntimeProvider).injectCosmeticFilters(_webViewController, pageUrl: pageUrl, rules: rules);
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

  void _handleAddressFocusChanged() {
    if (_addressFocusNode.hasFocus) {
      _urlController.selection = TextSelection(baseOffset: 0, extentOffset: _urlController.text.length);
      setState(() {
        _addressSearchQuery = '';
      });
      return;
    }

    final committedUrl = ref.read(readerControllerProvider).urlText;
    if (_urlController.text != committedUrl) {
      _urlController.text = committedUrl;
    }
    setState(() {
      _addressSearchQuery = '';
    });
  }

  void _handleAddressChanged(String value) {
    if (!_addressFocusNode.hasFocus) {
      return;
    }
    setState(() {
      _addressSearchQuery = value;
    });
  }

  void _clearAddressInput() {
    _urlController.clear();
    setState(() {
      _addressSearchQuery = '';
    });
  }

  Future<void> _openHistorySearchMatch(BrowserHistorySearchMatch match) async {
    _urlController.text = match.url.toString();
    await _loadFromAddressBar();
  }

  Future<void> _pasteAndGo() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      return;
    }
    _urlController.text = text;
    await _loadFromAddressBar();
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
              child: _ActionSheetRow.create(CupertinoIcons.arrow_right_circle, 'Open', 'Open in the current tab'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_openLinkInNewTab(link));
              },
              child: _ActionSheetRow.create(
                CupertinoIcons.plus_square,
                'Open in New Tab',
                'Switch to a new browser tab',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_copyText(link.href.toString()));
              },
              child: _ActionSheetRow.create(CupertinoIcons.doc_on_doc, 'Copy Link', 'Copy URL to clipboard'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(ref.read(readerControllerProvider.notifier).bookmarkUrl(link.href, title: link.text));
              },
              child: _ActionSheetRow.create(CupertinoIcons.bookmark, 'Add Bookmark', 'Save link to Library'),
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
                child: _ActionSheetRow.create(CupertinoIcons.refresh, 'Reload', 'Reload this page'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_copyText(currentUrl.toString()));
                },
                child: _ActionSheetRow.create(CupertinoIcons.doc_on_doc, 'Copy URL', 'Copy page URL'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_shareUrl(sheetContext, currentUrl, session.title ?? currentUrl.host));
                },
                child: _ActionSheetRow.create(CupertinoIcons.share, 'Share', 'Open the native share sheet'),
              ),
            ],
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _toggleBookmark();
              },
              child: _ActionSheetRow.create(
                session.isCurrentPageBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                session.isCurrentPageBookmarked ? 'Unbookmark' : 'Bookmark',
                session.isCurrentPageBookmarked ? 'Remove page from Library' : 'Save page to Library',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_newTab());
              },
              child: _ActionSheetRow.create(CupertinoIcons.plus_square, 'New Tab', defaultBrowserUrl),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _showTabs(context, session);
              },
              child: _ActionSheetRow.create(
                CupertinoIcons.square_on_square,
                'Show Tabs',
                '${session.tabs.length} open',
              ),
            ),

            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.pushNamed(AppRoute.history.routeName);
              },
              child: _ActionSheetRow.create(CupertinoIcons.clock, 'History', 'View recent page visits'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.pushNamed(AppRoute.settings.routeName);
              },
              child: _ActionSheetRow.create(CupertinoIcons.settings, 'Settings', 'Open app settings'),
            ),
            if (hasAnnotations)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(annotationSidebarOpenProvider.notifier).open();
                },
                child: _ActionSheetRow.create(
                  CupertinoIcons.text_bubble,
                  'Open Annotations',
                  'Show annotations for this page',
                ),
              ),
            if (currentUrl != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_toggleRenderedHighlights(currentUrl));
                },
                child: _areHighlightsVisible
                    ? _ActionSheetRow.create(CupertinoIcons.eye_slash, 'Hide Highlights', 'Temporarily hide highlights')
                    : _ActionSheetRow.create(CupertinoIcons.eye, 'Show Highlights', 'Show saved highlights'),
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
              child: _ActionSheetRow.create(CupertinoIcons.add, 'New Tab', defaultBrowserUrl),
            ),
            if (session.tabs.length > 1)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _closeTab(session.activeTabId);
                },
                child: _ActionSheetRow.create(
                  CupertinoIcons.xmark,
                  'Close Current Tab',
                  'Close & switch to the prev. tab',
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
                child: _ActionSheetRow.create(
                  CupertinoIcons.bookmark_fill,
                  bookmark.title ?? bookmark.url.host,
                  bookmark.url.toString(),
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
    final historyMatches = ref.watch(browserHistorySearchProvider(_addressSearchQuery));

    ref.listen(adBlockEnabledProvider, (previous, next) {
      if (next is! AsyncData<bool>) {
        return;
      }
      if (previous is! AsyncData<bool>) {
        unawaited(_configureAdBlocking(reload: false));
        return;
      }
      if (previous.value != next.value) {
        unawaited(_configureAdBlocking(reload: true));
      }
    });
    ref.listen(compiledAdBlockRulesProvider, (previous, next) {
      if (next.value == null) {
        return;
      }
      unawaited(
        _configureAdBlocking(reload: false).then((_) async {
          final currentUrl = await _webViewController.currentUrl();
          final uri = currentUrl == null ? null : Uri.tryParse(currentUrl);
          if (uri != null) {
            await _injectAdBlockCosmetics(uri);
          }
        }),
      );
    });
    ref.listen(readerControllerProvider.select((value) => value.urlText), (previous, next) {
      if (!_addressFocusNode.hasFocus && _urlController.text != next) {
        _urlController.text = next;
      }
    });
    ref.listen(linkContextControllerProvider.select((state) => state.link), (previous, next) {
      if (next != null && ref.read(selectionCaptureControllerProvider).capture == null) {
        unawaited(_showLinkContextMenu(next));
      }
    });

    final capture = selection.capture;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BrowserAddressBar(
              controller: _urlController,
              focusNode: _addressFocusNode,
              canGoBack: session.canGoBack,
              canGoForward: session.canGoForward,
              isBookmarked: session.isCurrentPageBookmarked,
              isLoading: session.isLoading,
              isTypingAddress: _addressFocusNode.hasFocus && _addressSearchQuery.isNotEmpty,
              tabCount: session.tabs.length,
              bookmarkCount: session.bookmarks.length,
              onBackPressed: _goBack,
              onForwardPressed: _goForward,
              onRefreshPressed: _reloadCurrentPage,
              onStopLoadingPressed: _stopLoadingCurrentPage,
              onClearAddressPressed: _clearAddressInput,
              onBookmarkPressed: _toggleBookmark,
              onBookmarksPressed: () => _showBookmarks(context, session),
              onTabsPressed: () => _showTabs(context, session),
              onMenuPressed: () => unawaited(_showBrowserMenu(context, session)),
              onChanged: _handleAddressChanged,
              onSubmitted: (_) => _loadFromAddressBar(),
              onGoPressed: _loadFromAddressBar,
            ),
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
                    if (capture != null)
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 16,
                        child: AnnotationToolbar(
                          capture: capture,
                          onHighlightPressed: () => unawaited(_saveHighlight(capture)),
                          onNotePressed: () => unawaited(_openNoteEditor(capture)),
                          onUnderlinePressed: () => unawaited(_saveUnderline(capture)),
                          onRemovePressed: _dismissSelection,
                        ),
                      ),
                    if (_addressFocusNode.hasFocus)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 8,
                        child: HistorySearchMatches(
                          query: _addressSearchQuery,
                          matches: historyMatches,
                          currentMatch: session.currentUrl == null
                              ? null
                              : BrowserHistorySearchMatch(
                                  url: session.currentUrl!,
                                  title: session.title ?? session.currentUrl!.host,
                                  description: null,
                                  faviconUrl: null,
                                  faviconFilePath: null,
                                  score: 0,
                                ),
                          onMatchPressed: (match) => unawaited(_openHistorySearchMatch(match)),
                          onCopyPressed: (match) => unawaited(_copyText(match.url.toString())),
                          onSharePressed: (context, match) => unawaited(_shareUrl(context, match.url, match.title)),
                          onPasteAndGoPressed: () => unawaited(_pasteAndGo()),
                        ),
                      ),
                    if (session.lastError != null)
                      Positioned(left: 12, right: 12, top: 12, child: _BrowserErrorBanner(message: session.lastError!)),
                  ],
                ),
              ),
            ),
            if (session.isLoading) _BrowserProgressBar(progress: session.progress) else const SizedBox(height: 2),
            const MarkerTabBar(activeRoute: AppRoute.browser),
          ],
        ),
      ),
    );
  }
}

class _ActionSheetRow extends StatelessWidget {
  const _ActionSheetRow({required this.icon, required this.title, required this.subtitle});

  factory _ActionSheetRow.create(IconData icon, String title, String subtitle) {
    return _ActionSheetRow(icon: icon, title: title, subtitle: subtitle);
  }

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
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

class _BrowserAddressBar extends StatelessWidget {
  const _BrowserAddressBar({
    required this.controller,
    required this.focusNode,
    required this.canGoBack,
    required this.canGoForward,
    required this.isBookmarked,
    required this.isLoading,
    required this.isTypingAddress,
    required this.tabCount,
    required this.bookmarkCount,
    required this.onBackPressed,
    required this.onForwardPressed,
    required this.onRefreshPressed,
    required this.onStopLoadingPressed,
    required this.onClearAddressPressed,
    required this.onBookmarkPressed,
    required this.onBookmarksPressed,
    required this.onTabsPressed,
    required this.onMenuPressed,
    required this.onChanged,
    required this.onSubmitted,
    required this.onGoPressed,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canGoBack;
  final bool canGoForward;
  final bool isBookmarked;
  final bool isLoading;
  final bool isTypingAddress;
  final int tabCount;
  final int bookmarkCount;
  final VoidCallback onBackPressed;
  final VoidCallback onForwardPressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onStopLoadingPressed;
  final VoidCallback onClearAddressPressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onBookmarksPressed;
  final VoidCallback onTabsPressed;
  final VoidCallback onMenuPressed;
  final ValueChanged<String> onChanged;
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
              _BrowserIconButton.create(CupertinoIcons.back, 'Back', canGoBack, onBackPressed),
              _BrowserIconButton.create(CupertinoIcons.forward, 'Forward', canGoForward, onForwardPressed),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  focusNode: focusNode,
                  autocorrect: false,
                  clearButtonMode: OverlayVisibilityMode.never,
                  keyboardType: TextInputType.url,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  placeholder: 'Enter URL',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemGrey, size: 13),
                  ),
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 30),
                      onPressed: isTypingAddress
                          ? onClearAddressPressed
                          : isLoading
                          ? onStopLoadingPressed
                          : onRefreshPressed,
                      child: Icon(
                        isTypingAddress
                            ? CupertinoIcons.xmark_circle_fill
                            : isLoading
                            ? CupertinoIcons.xmark
                            : CupertinoIcons.refresh,
                        color: isTypingAddress ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                        size: 17,
                      ),
                    ),
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
                child: const Icon(CupertinoIcons.arrow_right, size: 21),
              ),
              _BrowserIconButton.create(CupertinoIcons.ellipsis_circle, 'Browser Menu', true, onMenuPressed),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (isBookmarked)
                _BrowserChromeChip.create(CupertinoIcons.bookmark_fill, 'Saved', onBookmarkPressed)
              else
                _BrowserChromeChip.create(CupertinoIcons.bookmark, 'Save', onBookmarkPressed),
              const SizedBox(width: 8),
              _BrowserChromeChip.create(CupertinoIcons.book, 'Bookmarks $bookmarkCount', onBookmarksPressed),
              const Spacer(),
              _BrowserChromeChip.create(CupertinoIcons.square_on_square, 'Tabs $tabCount', onTabsPressed),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrowserIconButton extends StatelessWidget {
  const _BrowserIconButton({required this.icon, required this.label, required this.isEnabled, required this.onPressed});

  factory _BrowserIconButton.create(IconData icon, String label, bool isEnabled, VoidCallback onPressed) {
    return _BrowserIconButton(icon: icon, label: label, isEnabled: isEnabled, onPressed: onPressed);
  }

  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: isEnabled,
    label: label,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(34, 34),
      onPressed: isEnabled ? onPressed : null,
      child: Icon(icon, color: isEnabled ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray, size: 22),
    ),
  );
}

class _BrowserChromeChip extends StatelessWidget {
  const _BrowserChromeChip({required this.icon, required this.label, required this.onPressed});

  factory _BrowserChromeChip.create(IconData icon, String label, VoidCallback onPressed) {
    return _BrowserChromeChip(icon: icon, label: label, onPressed: onPressed);
  }

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
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

class _BrowserProgressBar extends StatelessWidget {
  const _BrowserProgressBar({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0, 100);
    final widthFactor = clampedProgress == 0 ? 0.08 : clampedProgress / 100;

    return SizedBox(
      key: const ValueKey('reader-progress-bar'),
      height: 3,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: const ColoredBox(color: CupertinoColors.activeBlue),
        ),
      ),
    );
  }
}

class _BrowserErrorBanner extends StatelessWidget {
  const _BrowserErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
