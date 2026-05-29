import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/app/app_transitions.dart';

void main() {
  testWidgets('MarkerTransitionPage creates a page route with iOS transition timing', (tester) async {
    await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
    const page = MarkerTransitionPage<void>(key: ValueKey('page'), child: SizedBox.shrink());
    final route = page.createRoute(tester.element(find.byType(SizedBox)));
    final pageRoute = route as PageRoute<void>;

    expect(pageRoute.transitionDuration, const Duration(milliseconds: 260));
    expect(pageRoute.reverseTransitionDuration, const Duration(milliseconds: 210));
  });
}
