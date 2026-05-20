import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/browser/ad_block/ad_block_rules.dart';
import 'package:marker/features/browser/webview/browser_webview.dart';

void main() {
  group('InAppBrowserWebViewController settings', () {
    test('disable the iOS input accessory bar', () {
      final controller = InAppBrowserWebViewController();

      expect(controller.settings.disableInputAccessoryView, isTrue);
    });

    test('omit content blocker rules with WebKit-incompatible regex disjunctions', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'''
/ads\.example\.com\/banner/
@@||ps.w.org^$image,domain=wordpress.org
''');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'ads\.example\.com\/banner');
    });

    test('keep escaped pipe characters in native content blocker rules', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'/literal\|pipe/');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'literal\|pipe');
    });

    test('omit content blocker rules with WebKit-incompatible shorthand character classes', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'''
/ads\.example\.com\/banner/
/(https?:\/\/)\w{30,}\.me\/\w{30,}\./
''');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'ads\.example\.com\/banner');
    });

    test('omit content blocker rules with WebKit-incompatible brace repetitions', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'''
/ads\.example\.com\/banner/
/(https?:\/\/)104\.154\..{100,}/
''');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'ads\.example\.com\/banner');
    });

    test('keep escaped braces as literal native content blocker characters', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'/literal\{brace\}/');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'literal\{brace\}');
    });

    test('omit generated EasyList separator patterns that require unsupported native regex syntax', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'''
/ads\.example\.com\/banner/
||tracker.example^
''');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'ads\.example\.com\/banner');
    });

    test('allow WebKit-supported ranges and quantifiers', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'/banner-[0-9]+\.js/');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'banner-[0-9]+\.js');
    });

    test('omit other native regex syntax outside the documented WebKit subset', () async {
      final controller = InAppBrowserWebViewController();
      final rules = EasyListParser().parse(r'''
/ads\.example\.com\/banner/
/(?:ads|tracker)\.example/
/foo^bar/
/foo$bar/
/café/
/tracker\p{L}/
''');

      await controller.setAdBlockRules(rules);

      final contentBlockers = controller.settings.contentBlockers!;
      expect(contentBlockers, hasLength(1));
      expect(contentBlockers.single.trigger.urlFilter, r'ads\.example\.com\/banner');
    });
  });
}
