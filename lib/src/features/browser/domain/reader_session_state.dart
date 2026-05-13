class ReaderSessionState {
  const ReaderSessionState({
    required this.urlText,
    this.currentUrl,
    this.title,
    this.isLoading = false,
    this.progress = 0,
    this.lastError,
  });

  factory ReaderSessionState.initial() {
    return const ReaderSessionState(urlText: 'https://news.ycombinator.com');
  }

  final String urlText;
  final Uri? currentUrl;
  final String? title;
  final bool isLoading;
  final int progress;
  final String? lastError;

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
    String? urlText,
    Uri? currentUrl,
    String? title,
    bool? isLoading,
    int? progress,
    String? lastError,
    bool clearError = false,
  }) {
    return ReaderSessionState(
      urlText: urlText ?? this.urlText,
      currentUrl: currentUrl ?? this.currentUrl,
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}
