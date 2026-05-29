import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/browser/presentation/browser_screen.dart';

void main() {
  testWidgets('allows the route to pop when browser history cannot go back', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: BrowserRouteBackHandler(canGoBack: false, onBack: () async {}, child: const SizedBox.shrink()),
      ),
    );

    final popScope = tester.widget<PopScope<Object?>>(find.byWidgetPredicate((widget) => widget is PopScope));
    expect(popScope.canPop, isTrue);
  });

  testWidgets('handles Android back with browser history before popping the route', (tester) async {
    var backCount = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: BrowserRouteBackHandler(
          canGoBack: true,
          onBack: () async => backCount += 1,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    final popScope = tester.widget<PopScope<Object?>>(find.byWidgetPredicate((widget) => widget is PopScope));
    expect(popScope.canPop, isFalse);

    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pump();
    expect(backCount, 1);
  });
}
