import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/browser/domain/reader_session_state.dart';

void main() {
  group('ReaderSessionState.normalizedUrl', () {
    test('keeps valid absolute URLs', () {
      final state = _stateForUrl('https://example.com/path');

      expect(state.normalizedUrl, Uri.parse('https://example.com/path'));
      expect(state.canGo, isTrue);
    });

    test('adds https to host-only input', () {
      final state = _stateForUrl('inkandswitch.com/local-first');

      expect(state.normalizedUrl, Uri.parse('https://inkandswitch.com/local-first'));
    });

    test('rejects empty and schemeless non-host input', () {
      expect(_stateForUrl('').normalizedUrl, isNull);
      expect(_stateForUrl('https:///nope').normalizedUrl, isNull);
    });
  });
}

ReaderSessionState _stateForUrl(String urlText) {
  const tab = BrowserTab(id: 'tab-1', urlText: '');
  return ReaderSessionState(
    tabs: [tab.copyWith(urlText: urlText)],
    activeTabId: tab.id,
  );
}
