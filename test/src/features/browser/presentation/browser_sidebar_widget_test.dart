import 'package:code_forge/code_forge.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/database/app_database.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../../../helpers/harness.dart';

void main() {
  late FakeWebViewPlatform platform;
  late AppDatabase database;

  setUp(() {
    platform = FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('filters, jumps, edits, and deletes annotations', (tester) async {
    await seedSidebarAnnotations(database);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Browser'));
    await pumpRouteTransition(tester);
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    expect(find.text('Annotations'), findsOneWidget);
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Underlines'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('note quote'), findsOneWidget);
    expect(find.textContaining('highlight quote'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Jump').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      platform.controller.injectedScripts.any((script) => script.contains('scrollToAnnotation("note-annotation")')),
      isTrue,
    );

    await tester.tap(find.bySemanticsLabel('Edit').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Edit Note'), findsOneWidget);
    await tester.tap(find.byType(CodeForge));
    await tester.pump();
    tester.testTextInput.enterText('Updated sidebar note');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final editedBody = (await database.select(database.annotationBodies).get()).firstWhere(
      (body) => body.annotationId == 'note-annotation' && body.type == 'TextualBody',
    );
    expect(editedBody.value, 'Updated sidebar note');

    await tester.tap(find.bySemanticsLabel('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final deleted = await (database.select(
      database.annotations,
    )..where((annotation) => annotation.id.equals('note-annotation'))).getSingle();
    expect(deleted.deletedAt, isNotNull);
    expect(
      platform.controller.injectedScripts.any(
        (script) => script.contains('deleteRenderedAnnotation("note-annotation")'),
      ),
      isTrue,
    );
  });
}
