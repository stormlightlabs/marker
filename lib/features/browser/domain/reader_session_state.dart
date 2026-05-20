import 'package:uuid/uuid.dart';

const defaultBrowserUrl = 'https://news.ycombinator.com';

class BrowserTab {
  const BrowserTab({
    required this.id,
    required this.urlText,
    this.currentUrl,
    this.title,
    this.history = const [],
    this.historyIndex = -1,
  });

  factory BrowserTab.initial({String? id}) {
    return BrowserTab(id: id ?? const Uuid().v4(), urlText: defaultBrowserUrl);
  }

  final String id;
  final String urlText;
  final Uri? currentUrl;
  final String? title;
  final List<Uri> history;
  final int historyIndex;

  bool get canGoBack => historyIndex > 0;

  bool get canGoForward => historyIndex >= 0 && historyIndex < history.length - 1;

  Uri? get backUrl => canGoBack ? history[historyIndex - 1] : null;

  Uri? get forwardUrl => canGoForward ? history[historyIndex + 1] : null;

  BrowserTab copyWith({String? urlText, Uri? currentUrl, String? title, List<Uri>? history, int? historyIndex}) {
    return BrowserTab(
      id: id,
      urlText: urlText ?? this.urlText,
      currentUrl: currentUrl ?? this.currentUrl,
      title: title ?? this.title,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }

  BrowserTab recordVisit(Uri url, {String? title}) {
    final nextHistory = historyIndex >= 0 ? history.take(historyIndex + 1).toList() : <Uri>[];
    if (nextHistory.isEmpty || nextHistory.last != url) {
      nextHistory.add(url);
    }

    return copyWith(
      urlText: url.toString(),
      currentUrl: url,
      title: title ?? this.title,
      history: List.unmodifiable(nextHistory),
      historyIndex: nextHistory.length - 1,
    );
  }

  BrowserTab moveToHistoryIndex(int index) {
    final url = history[index];
    return copyWith(urlText: url.toString(), currentUrl: url, historyIndex: index);
  }
}

class BrowserBookmark {
  const BrowserBookmark({required this.id, required this.url, this.title, required this.createdAt});

  final String id;
  final Uri url;
  final String? title;
  final DateTime createdAt;
}

class ReaderSessionState {
  const ReaderSessionState({
    required this.tabs,
    required this.activeTabId,
    this.bookmarks = const [],
    this.isLoading = false,
    this.progress = 0,
    this.lastError,
  });

  factory ReaderSessionState.initial() {
    final tab = BrowserTab.initial();
    return ReaderSessionState(tabs: [tab], activeTabId: tab.id);
  }

  final List<BrowserTab> tabs;
  final String activeTabId;
  final List<BrowserBookmark> bookmarks;
  final bool isLoading;
  final int progress;
  final String? lastError;

  BrowserTab get activeTab => tabs.firstWhere((tab) => tab.id == activeTabId);

  String get urlText => activeTab.urlText;

  Uri? get currentUrl => activeTab.currentUrl;

  String? get title => activeTab.title;

  bool get canGoBack => activeTab.canGoBack;

  bool get canGoForward => activeTab.canGoForward;

  bool get isCurrentPageBookmarked {
    final url = currentUrl ?? normalizedUrl;
    return url != null && bookmarks.any((bookmark) => bookmark.url == url);
  }

  bool get canGo => normalizedUrl != null;

  Uri? get normalizedUrl {
    final input = urlText.trim();
    if (input.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(input);
    if (parsed == null) {
      return null;
    }

    if (parsed.hasScheme) {
      return parsed.hasAuthority && parsed.host.isNotEmpty ? parsed : null;
    }

    final withScheme = Uri.tryParse('https://$input');
    return withScheme != null && withScheme.hasAuthority && withScheme.host.isNotEmpty ? withScheme : null;
  }

  ReaderSessionState copyWith({
    List<BrowserTab>? tabs,
    String? activeTabId,
    List<BrowserBookmark>? bookmarks,
    bool? isLoading,
    int? progress,
    String? lastError,
    bool clearError = false,
  }) {
    return ReaderSessionState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }

  ReaderSessionState updateActiveTab(BrowserTab Function(BrowserTab tab) update) {
    return copyWith(
      tabs: [
        for (final tab in tabs)
          if (tab.id == activeTabId) update(tab) else tab,
      ],
    );
  }
}
