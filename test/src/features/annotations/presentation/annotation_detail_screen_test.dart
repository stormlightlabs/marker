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

  testWidgets('supports editing and deleting notes', (tester) async {
    await seedLibrary(database);

    await tester.pumpWidget(markerTestApp(database: database));

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('highlighting'));
    await tester.pumpAndSettle();

    expect(find.text('Annotation'), findsOneWidget);
    expect(find.text('"important quote"'), findsOneWidget);
    expect(find.text('No note attached. Tap Edit to add one.'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Add Note'), findsOneWidget);

    await tester.tap(find.byType(CodeForge));
    await tester.pump();
    tester.testTextInput.enterText('Updated note');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Updated note'), findsOneWidget);
    final editedBodies = await database.select(database.annotationBodies).get();
    expect(editedBodies.where((body) => body.type == 'TextualBody').single.value, 'Updated note');

    await tester.tap(find.text('Delete annotation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsWidgets);
    final deleted = await (database.select(
      database.annotations,
    )..where((annotation) => annotation.id.equals('annotation'))).getSingle();
    expect(deleted.deletedAt, isNotNull);
  });
}
