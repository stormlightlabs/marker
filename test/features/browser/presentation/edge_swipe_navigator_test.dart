import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/browser/presentation/edge_swipe_navigator.dart';

void main() {
  testWidgets('triggers back from the leading edge after threshold', (tester) async {
    var backCount = 0;

    await tester.pumpWidget(_EdgeSwipeHarness(canGoBack: true, onBack: () async => backCount += 1));

    final gesture = await tester.startGesture(const Offset(4, 200));
    await gesture.moveBy(const Offset(90, 4));
    await gesture.up();
    await tester.pump();

    expect(backCount, 1);
  });

  testWidgets('does not trigger unavailable or short edge swipes', (tester) async {
    var backCount = 0;

    await tester.pumpWidget(_EdgeSwipeHarness(canGoBack: false, onBack: () async => backCount += 1));

    var gesture = await tester.startGesture(const Offset(4, 200));
    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pump();
    expect(backCount, 0);

    await tester.pumpWidget(_EdgeSwipeHarness(canGoBack: true, onBack: () async => backCount += 1));
    gesture = await tester.startGesture(const Offset(4, 200));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.up();
    await tester.pump();
    expect(backCount, 0);
  });

  testWidgets('triggers forward from the trailing edge and ignores vertical drags', (tester) async {
    var forwardCount = 0;

    await tester.pumpWidget(_EdgeSwipeHarness(canGoForward: true, onForward: () async => forwardCount += 1));

    var gesture = await tester.startGesture(const Offset(796, 200));
    await gesture.moveBy(const Offset(-88, 2));
    await gesture.up();
    await tester.pump();
    expect(forwardCount, 1);

    gesture = await tester.startGesture(const Offset(796, 200));
    await gesture.moveBy(const Offset(-24, 80));
    await gesture.up();
    await tester.pump();
    expect(forwardCount, 1);
  });
}

class _EdgeSwipeHarness extends StatelessWidget {
  const _EdgeSwipeHarness({this.canGoBack = false, this.canGoForward = false, this.onBack, this.onForward});

  final bool canGoBack;
  final bool canGoForward;
  final Future<void> Function()? onBack;
  final Future<void> Function()? onForward;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: SizedBox(
        width: 400,
        height: 400,
        child: EdgeSwipeNavigator(
          canGoBack: canGoBack,
          canGoForward: canGoForward,
          onBack: onBack ?? () async {},
          onForward: onForward ?? () async {},
          child: const ColoredBox(color: CupertinoColors.black),
        ),
      ),
    );
  }
}
