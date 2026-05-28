import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/shared/utils/text_utils.dart';

void main() {
  group('normalize', () {
    test('trims text and maps blanks to null', () {
      expect(normalize('  marker  '), 'marker');
      expect(normalize('   '), isNull);
      expect(normalize(null), isNull);
    });
  });

  group('stable text hashes', () {
    test('keeps FNV-1a 64-bit output stable for cache keys', () {
      expect(stableFnv1a64Hash(''), '-340d631b7bdddcdb');
      expect(stableFnv1a64Hash('Marker'), '-29ba75c1107c2ba9');
      expect(stableFnv1a64Hash('https://example.com/favicon.ico'), '-1ffbc7e4e09eee79');
    });

    test('keeps Jenkins output stable for sync fingerprints', () {
      expect(stableJenkinsOneAtATimeHash(''), '0');
      expect(stableJenkinsOneAtATimeHash('Marker'), '81e5f00');
      expect(stableJenkinsOneAtATimeHash('https://example.com/favicon.ico'), '1fa51b02');
    });
  });
}
