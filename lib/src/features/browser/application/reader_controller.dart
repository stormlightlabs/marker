import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/features/annotations/data/annotation_repository.dart';
import 'package:marker/src/features/browser/domain/reader_session_state.dart';

final readerControllerProvider = NotifierProvider<ReaderController, ReaderSessionState>(ReaderController.new);

class ReaderController extends Notifier<ReaderSessionState> {
  @override
  ReaderSessionState build() => ReaderSessionState.initial();

  void setUrlText(String value) {
    state = state.copyWith(urlText: value, clearError: true);
  }

  Uri? beginLoad() {
    final target = state.normalizedUrl;
    if (target == null) {
      state = state.copyWith(lastError: 'Enter a valid URL.');
      return null;
    }

    state = state.copyWith(
      urlText: target.toString(),
      currentUrl: target,
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
    state = state.copyWith(
      urlText: url.toString(),
      currentUrl: url,
      title: title,
      isLoading: false,
      progress: 100,
      clearError: true,
    );

    await ref.read(annotationRepositoryProvider).recordPageVisit(url: url, canonicalUrl: canonicalUrl, title: title);
  }

  void failLoad(String description) {
    state = state.copyWith(isLoading: false, lastError: description);
  }
}
