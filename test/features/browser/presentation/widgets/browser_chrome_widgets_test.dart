import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/browser/presentation/widgets/browser_chrome_widgets.dart';

void main() {
  testWidgets('BrowserActionSheetRow renders icon title and subtitle', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: BrowserActionSheetRow(icon: CupertinoIcons.share, title: 'Share', subtitle: 'Open native sheet'),
      ),
    );

    expect(find.byIcon(CupertinoIcons.share), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Open native sheet'), findsOneWidget);
  });

  testWidgets('BrowserIconButton disables callback when disabled', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: BrowserIconButton(icon: CupertinoIcons.back, label: 'Back', isEnabled: false, onPressed: () => taps += 1),
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.back));
    expect(taps, 0);
  });

  testWidgets('BrowserBottomActionBar reflects bookmark state and tab count callbacks', (tester) async {
    var bookmarkTaps = 0;
    var tabTaps = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: BrowserBottomActionBar(
          isBookmarked: true,
          tabCount: 3,
          onBookmarkPressed: () => bookmarkTaps += 1,
          onTabsPressed: () => tabTaps += 1,
        ),
      ),
    );

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Tabs 3'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await tester.tap(find.text('Tabs 3'));
    expect(bookmarkTaps, 1);
    expect(tabTaps, 1);
  });

  testWidgets('BrowserAddressBar wires text field actions and loading suffix', (tester) async {
    final controller = TextEditingController(text: 'https://example.com');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    var changed = '';
    var submitted = '';
    var stopTaps = 0;
    var goTaps = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: BrowserAddressBar(
          controller: controller,
          focusNode: focusNode,
          canGoBack: true,
          canGoForward: false,
          isBookmarked: false,
          isLoading: true,
          isTypingAddress: false,
          tabCount: 1,
          onBackPressed: () {},
          onForwardPressed: () {},
          onRefreshPressed: () {},
          onStopLoadingPressed: () => stopTaps += 1,
          onClearAddressPressed: () {},
          onBookmarkPressed: () {},
          onTabsPressed: () {},
          onMenuPressed: () {},
          onChanged: (value) => changed = value,
          onSubmitted: (value) => submitted = value,
          onGoPressed: () => goTaps += 1,
        ),
      ),
    );

    await tester.enterText(find.byType(CupertinoTextField), 'marker.test');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.tap(find.byIcon(CupertinoIcons.arrow_right));

    expect(changed, 'marker.test');
    expect(submitted, 'marker.test');
    expect(stopTaps, 1);
    expect(goTaps, 1);
  });

  testWidgets('BrowserProgressBar clamps progress and error banner shows message', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Column(
          children: [
            BrowserProgressBar(progress: 250),
            BrowserErrorBanner(message: 'Network failed'),
          ],
        ),
      ),
    );

    final bar = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(bar.widthFactor, 1);
    expect(find.text('Network failed'), findsOneWidget);
  });
}
