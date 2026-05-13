import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/features/browser/domain/reader_session_state.dart';

void main() {
  group('ReaderSessionState.normalizedUrl', () {
    test('keeps valid absolute URLs', () {
      const state = ReaderSessionState(urlText: 'https://example.com/path');

      expect(state.normalizedUrl, Uri.parse('https://example.com/path'));
      expect(state.canGo, isTrue);
    });

    test('adds https to host-only input', () {
      const state = ReaderSessionState(urlText: 'inkandswitch.com/local-first');

      expect(state.normalizedUrl, Uri.parse('https://inkandswitch.com/local-first'));
    });

    test('rejects empty and schemeless non-host input', () {
      expect(const ReaderSessionState(urlText: '').normalizedUrl, isNull);
      expect(const ReaderSessionState(urlText: 'https:///nope').normalizedUrl, isNull);
    });
  });
}
