import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/shared/widgets/marker_list_widgets.dart';

void main() {
  test('markerDomainInitial trims hosts and strips www prefix', () {
    expect(markerDomainInitial(' example.com '), 'E');
    expect(markerDomainInitial('www.marker.test'), 'M');
    expect(markerDomainInitial('   '), isNull);
  });

  testWidgets('MarkerRowButton renders title, subtitle, leading, trailing and handles taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: MarkerRowButton(
          onPressed: () => taps += 1,
          leading: const MarkerIconTile(icon: CupertinoIcons.doc_text, color: CupertinoColors.activeBlue),
          title: 'Article title',
          subtitle: 'example.com · 2 annotations',
        ),
      ),
    );

    expect(find.text('Article title'), findsOneWidget);
    expect(find.text('example.com · 2 annotations'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.doc_text), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);

    await tester.tap(find.text('Article title'));
    expect(taps, 1);
  });

  testWidgets('MarkerGroupFrame displays children inside the shared frame', (tester) async {
    await tester.pumpWidget(const CupertinoApp(home: MarkerGroupFrame(children: [Text('Child row')])));

    expect(find.text('Child row'), findsOneWidget);
  });

  testWidgets('MarkerFileFavicon falls back to domain placeholder without a file', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: MarkerFileFavicon(
          filePath: null,
          fallbackHost: 'www.example.com',
          fallbackIcon: CupertinoIcons.globe,
          fallbackColor: CupertinoColors.systemTeal,
        ),
      ),
    );

    expect(find.text('E'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.globe), findsNothing);
  });
}
