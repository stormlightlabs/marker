import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/shared/widgets/settings_rows.dart';

void main() {
  testWidgets('SettingsLinkRow renders labels and invokes callback', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: SettingsLinkRow(
          icon: CupertinoIcons.clock,
          title: 'Browser History',
          subtitle: 'Recent page visits',
          onPressed: () => pressed = true,
        ),
      ),
    );

    expect(find.text('Browser History'), findsOneWidget);
    expect(find.text('Recent page visits'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.clock), findsOneWidget);

    await tester.tap(find.text('Browser History'));
    expect(pressed, isTrue);
  });

  testWidgets('SettingsSwitchRow renders custom title widget and toggles', (tester) async {
    bool? changedValue;

    await tester.pumpWidget(
      CupertinoApp(
        home: SettingsSwitchRow(
          icon: CupertinoIcons.shield,
          title: 'Fallback title',
          titleWidget: const Text('Custom title'),
          subtitle: 'Blocks ads',
          value: false,
          onChanged: (value) => changedValue = value,
        ),
      ),
    );

    expect(find.text('Custom title'), findsOneWidget);
    expect(find.text('Fallback title'), findsNothing);
    expect(find.text('Blocks ads'), findsOneWidget);

    await tester.tap(find.byType(CupertinoSwitch));
    expect(changedValue, isTrue);
  });

  testWidgets('SettingsSectionHeader includes optional trailing widget', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: SettingsSectionHeader(label: 'Sync', trailing: Text('Help')),
      ),
    );

    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
  });
}
