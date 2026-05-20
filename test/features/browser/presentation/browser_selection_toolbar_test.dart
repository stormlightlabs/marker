import 'package:code_forge/code_forge.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';

import '../../../helpers/harness.dart';

void main() {
  late FakeWebViewPlatform platform;
  late AppDatabase database;

  setUp(() {
    platform = FakeWebViewPlatform();
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('shows annotation toolbar for captured selections', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    platform.controller.sendSelectionMessage(
      '{"type":"selection-captured","payload":{"exact":"selected text","prefix":"before ","suffix":" after","sourceUrl":"https://news.ycombinator.com","pageTitle":"Hacker News","textPositionStart":7,"textPositionEnd":20,"cssSelector":"p:nth-of-type(1)"}}',
    );
    await tester.pump();

    expect(find.text('selected text'), findsOneWidget);
    expect(find.text('Highlight'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Underline'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.widgetWithText(CupertinoButton, 'Highlight'));
    await tester.pumpAndSettle();

    expect(find.text('selected text'), findsNothing);
    expect(platform.controller.injectedScripts.last, contains('clearSelection'));
    expect(platform.controller.injectedScripts.any((script) => script.contains('"exact":"selected text"')), isTrue);

    final annotations = await database.select(database.annotations).get();
    final bodies = await database.select(database.annotationBodies).get();
    expect(annotations.single.motivation, 'highlighting');
    expect(bodies.single.type, 'StyleHint');
  });

  testWidgets('opens note editor and saves markdown note annotations', (tester) async {
    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);

    platform.controller.sendSelectionMessage(
      '{"type":"selection-captured","payload":{"exact":"note text","prefix":"before ","suffix":" after","sourceUrl":"https://news.ycombinator.com","pageTitle":"Hacker News","textPositionStart":7,"textPositionEnd":16,"cssSelector":"p:nth-of-type(1)"}}',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(CupertinoButton, 'Note'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Add Note'), findsOneWidget);

    await tester.tap(find.byType(CodeForge));
    await tester.pump();
    tester.testTextInput.enterText('**Markdown** note');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final annotations = await database.select(database.annotations).get();
    final bodies = await database.select(database.annotationBodies).get();
    expect(annotations.single.motivation, 'commenting');
    expect(bodies.firstWhere((body) => body.type == 'TextualBody').format, 'text/markdown');
    expect(bodies.firstWhere((body) => body.type == 'TextualBody').value, '**Markdown** note');
  });
}
