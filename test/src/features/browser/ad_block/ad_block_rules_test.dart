import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/features/browser/ad_block/ad_block_rules.dart';

void main() {
  group('EasyListParser', () {
    test('parses network rules, comments, and exceptions', () {
      final rules = EasyListParser().parse('''
! comment
||ads.example.com^
@@||ads.example.com/allowed.js\$script
/banner-[0-9]+\\.js/
''');

      expect(rules.stats.totalLines, 4);
      expect(rules.stats.commentLines, 1);
      expect(rules.networkRules, hasLength(3));
      expect(rules.stats.exceptionRules, 1);
      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://ads.example.com/ad.js'),
          topUrl: Uri.parse('https://news.example'),
          resourceType: AdBlockResourceType.script,
        ),
        isTrue,
      );
      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://ads.example.com/allowed.js'),
          topUrl: Uri.parse('https://news.example'),
          resourceType: AdBlockResourceType.script,
        ),
        isFalse,
      );
      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://cdn.example/banner-42.js'),
          topUrl: Uri.parse('https://news.example'),
          resourceType: AdBlockResourceType.script,
        ),
        isTrue,
      );
    });

    test('honors important rules over exceptions', () {
      final rules = EasyListParser().parse('''
@@||ads.example.com^
||ads.example.com^\$important
''');

      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://ads.example.com/ad.js'),
          topUrl: Uri.parse('https://news.example'),
          resourceType: AdBlockResourceType.script,
        ),
        isTrue,
      );
    });

    test('parses domain, party, and resource type constraints', () {
      final rules = EasyListParser().parse('||tracker.example^\$script,third-party,domain=site.example|~safe.example');

      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://tracker.example/tag.js'),
          topUrl: Uri.parse('https://site.example/article'),
          resourceType: AdBlockResourceType.script,
        ),
        isTrue,
      );
      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://tracker.example/tag.css'),
          topUrl: Uri.parse('https://site.example/article'),
          resourceType: AdBlockResourceType.styleSheet,
        ),
        isFalse,
      );
      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://tracker.example/tag.js'),
          topUrl: Uri.parse('https://safe.example/article'),
          resourceType: AdBlockResourceType.script,
        ),
        isFalse,
      );
      expect(
        rules.shouldBlockRequest(
          Uri.parse('https://site.example/tag.js'),
          topUrl: Uri.parse('https://site.example/article'),
          resourceType: AdBlockResourceType.script,
        ),
        isFalse,
      );
    });

    test('parses cosmetic rules and exceptions by page host', () {
      final rules = EasyListParser().parse('''
##.generic-ad
example.com##.ad
example.com#@#.ad
example.com,~sub.example.com##.sponsored
''');

      expect(rules.stats.cosmeticRules, 4);
      expect(rules.cosmeticSelectorsFor(Uri.parse('https://example.com')), ['.generic-ad', '.sponsored']);
      expect(rules.cosmeticSelectorsFor(Uri.parse('https://sub.example.com')), ['.generic-ad']);
      expect(rules.cosmeticSelectorsFor(Uri.parse('https://other.example')), ['.generic-ad']);
    });

    test('counts unsupported filters without failing compilation', () {
      final rules = EasyListParser().parse('''
example.com##+js(abort-on-property-read, ad)
||example.com^\$redirect=noopjs
##
''');

      expect(rules.stats.unsupportedRules, 2);
      expect(rules.stats.invalidRules, 1);
      expect(rules.networkRules, isEmpty);
      expect(rules.cosmeticRules, isEmpty);
    });
  });
}
