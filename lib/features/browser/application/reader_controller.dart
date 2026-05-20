import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/browser/data/bookmark_repository.dart';
import 'package:marker/features/browser/domain/reader_session_state.dart';

final readerControllerProvider = NotifierProvider<ReaderController, ReaderSessionState>(ReaderController.new);

class ReaderController extends Notifier<ReaderSessionState> {
  @override
  ReaderSessionState build() {
    unawaited(_hydrateBookmarks());
    return ReaderSessionState.initial();
  }

  void setUrlText(String value) {
    state = state.updateActiveTab((tab) => tab.copyWith(urlText: value)).copyWith(clearError: true);
  }

  Uri? beginLoad() {
    final target = state.normalizedUrl;
    if (target == null) {
      state = state.copyWith(lastError: 'Enter a valid URL.');
      return null;
    }

    state = state.copyWith(
      tabs: state.updateActiveTab((tab) => tab.copyWith(urlText: target.toString(), currentUrl: target)).tabs,
      isLoading: true,
      progress: 0,
      clearError: true,
    );
    return target;
  }

  void updateProgress(int progress) {
    state = state.copyWith(progress: progress.clamp(0, 100), isLoading: progress < 100);
  }

  Future<void> finishLoad({required Uri url, Uri? canonicalUrl, String? title}) async {
    state = state
        .updateActiveTab((tab) => tab.recordVisit(url, title: title))
        .copyWith(isLoading: false, progress: 100, clearError: true);

    await ref.read(annotationRepositoryProvider).recordPageVisit(url: url, canonicalUrl: canonicalUrl, title: title);
  }

  void failLoad(String description) {
    state = state.copyWith(isLoading: false, lastError: description);
  }

  Uri? goBack() {
    final activeTab = state.activeTab;
    final target = activeTab.backUrl;
    if (target == null) {
      return null;
    }

    state = state
        .updateActiveTab((tab) => tab.moveToHistoryIndex(tab.historyIndex - 1))
        .copyWith(isLoading: true, progress: 0, clearError: true);
    return target;
  }

  Uri? goForward() {
    final activeTab = state.activeTab;
    final target = activeTab.forwardUrl;
    if (target == null) {
      return null;
    }

    state = state
        .updateActiveTab((tab) => tab.moveToHistoryIndex(tab.historyIndex + 1))
        .copyWith(isLoading: true, progress: 0, clearError: true);
    return target;
  }

  Uri newTab() {
    final tab = BrowserTab.initial();
    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: tab.id,
      isLoading: true,
      progress: 0,
      clearError: true,
    );
    return Uri.parse(defaultBrowserUrl);
  }

  Uri openInNewTab(Uri url) {
    final tab = BrowserTab.initial().copyWith(urlText: url.toString(), currentUrl: url);
    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: tab.id,
      isLoading: true,
      progress: 0,
      clearError: true,
    );
    return url;
  }

  Uri? switchTab(String tabId) {
    if (tabId == state.activeTabId || state.tabs.every((tab) => tab.id != tabId)) {
      return null;
    }

    final tab = state.tabs.firstWhere((candidate) => candidate.id == tabId);
    state = state.copyWith(activeTabId: tabId, isLoading: true, progress: 0, clearError: true);
    return tab.currentUrl ?? _normalizeUrl(tab.urlText);
  }

  Uri? closeTab(String tabId) {
    if (state.tabs.length == 1 || state.tabs.every((tab) => tab.id != tabId)) {
      return null;
    }

    final closingActiveTab = state.activeTabId == tabId;
    final remainingTabs = state.tabs.where((tab) => tab.id != tabId).toList(growable: false);
    final nextActiveTab = closingActiveTab ? remainingTabs.last : state.activeTab;
    state = state.copyWith(
      tabs: remainingTabs,
      activeTabId: nextActiveTab.id,
      isLoading: closingActiveTab,
      progress: closingActiveTab ? 0 : state.progress,
      clearError: true,
    );

    return closingActiveTab ? nextActiveTab.currentUrl ?? _normalizeUrl(nextActiveTab.urlText) : null;
  }

  Future<void> toggleBookmark() async {
    final url = state.currentUrl ?? state.normalizedUrl;
    if (url == null) {
      return;
    }

    if (state.bookmarks.any((bookmark) => bookmark.url == url)) {
      final bookmarks = await ref.read(bookmarkRepositoryProvider).removeBookmark(url);
      state = state.copyWith(bookmarks: bookmarks);
      return;
    }

    final bookmarks = await ref.read(bookmarkRepositoryProvider).addBookmark(url: url, title: state.title);
    state = state.copyWith(bookmarks: bookmarks);
  }

  Future<void> bookmarkUrl(Uri url, {String? title}) async {
    final bookmarks = await ref.read(bookmarkRepositoryProvider).addBookmark(url: url, title: title);
    state = state.copyWith(bookmarks: bookmarks);
  }

  Uri? openBookmark(Uri url) {
    setUrlText(url.toString());
    return beginLoad();
  }

  Uri? _normalizeUrl(String value) {
    return ReaderSessionState(
      tabs: [BrowserTab(id: 'normalizer', urlText: value)],
      activeTabId: 'normalizer',
    ).normalizedUrl;
  }

  Future<void> _hydrateBookmarks() async {
    final bookmarks = await ref.read(bookmarkRepositoryProvider).getBookmarks();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(bookmarks: bookmarks);
  }
}
