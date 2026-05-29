import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';

void main() {
  testWidgets('shows primary tabs in order', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Align(
          alignment: Alignment.bottomCenter,
          child: MarkerTabBar(activeRoute: AppRoute.library),
        ),
      ),
    );

    final libraryCenter = tester.getCenter(find.text('Library')).dx;
    final settingsCenter = tester.getCenter(find.text('Settings')).dx;
    expect(libraryCenter, lessThan(settingsCenter));
    expect(find.text('Bookmarks'), findsNothing);
    expect(find.text('Annotations'), findsNothing);
  });
}
