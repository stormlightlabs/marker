import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';

void main() {
  testWidgets('places Library in the center tab slot', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Align(
          alignment: Alignment.bottomCenter,
          child: MarkerTabBar(activeRoute: AppRoute.library),
        ),
      ),
    );

    final libraryCenter = tester.getCenter(find.text('Library')).dx;
    final screenCenter = tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
    expect(libraryCenter, closeTo(screenCenter, 1));
    expect(tester.getCenter(find.text('Feeds')).dx, lessThan(libraryCenter));
    expect(tester.getCenter(find.text('Bookmarks')).dx, greaterThan(libraryCenter));
  });
}
