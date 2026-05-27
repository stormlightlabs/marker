import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/atproto/application/bookmark_import_controller.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';

void main() {
  test('imports bookmarks and exposes success state', () async {
    final service = FakeSembleBookmarkPullService(
      result: const SembleBookmarkPullResult(cardsImported: 12, collectionsImported: 3, linksImported: 18),
    );
    final container = ProviderContainer(overrides: [sembleBookmarkPullServiceProvider.overrideWithValue(service)]);
    addTearDown(container.dispose);

    final result = await container.read(atprotoBookmarkImportControllerProvider.notifier).importBookmarks('did:plc:alice');

    expect(service.accountDid, 'did:plc:alice');
    expect(result?.cardsImported, 12);
    expect(container.read(atprotoBookmarkImportControllerProvider), isA<AtprotoBookmarkImportSucceeded>());
  });

  test('reports import failure with retry copy', () async {
    final service = FakeSembleBookmarkPullService(error: StateError('network down'));
    final container = ProviderContainer(overrides: [sembleBookmarkPullServiceProvider.overrideWithValue(service)]);
    addTearDown(container.dispose);

    final result = await container.read(atprotoBookmarkImportControllerProvider.notifier).importBookmarks('did:plc:alice');

    expect(result, isNull);
    final state = container.read(atprotoBookmarkImportControllerProvider);
    expect(state, isA<AtprotoBookmarkImportFailed>());
    expect((state as AtprotoBookmarkImportFailed).message, 'Could not import bookmarks. Check your connection and try again.');
  });

  test('formats result summaries for imported, empty, and partial issue imports', () {
    expect(
      sembleBookmarkPullSummary(
        const SembleBookmarkPullResult(
          cardsImported: 12,
          collectionsImported: 3,
          linksImported: 18,
          duplicates: 4,
          conflicts: 1,
          malformed: 2,
        ),
      ),
      'Imported 12 bookmarks, 3 folders, and 18 folder links.\nSkipped 4 duplicates, 1 conflict, and 2 malformed records.',
    );
    expect(sembleBookmarkPullSummary(const SembleBookmarkPullResult()), 'No new bookmarks found.');
    expect(
      sembleBookmarkPullSummary(const SembleBookmarkPullResult(duplicates: 1)),
      'No new bookmarks found.\nSkipped 1 duplicate, 0 conflicts, and 0 malformed records.',
    );
    expect(sembleBookmarkPullHasIssues(const SembleBookmarkPullResult(conflicts: 1)), isTrue);
    expect(sembleBookmarkPullHasIssues(const SembleBookmarkPullResult(malformed: 1)), isTrue);
  });
}

class FakeSembleBookmarkPullService implements SembleBookmarkPullService {
  FakeSembleBookmarkPullService({this.result = const SembleBookmarkPullResult(), this.error});

  final SembleBookmarkPullResult result;
  final Object? error;
  String? accountDid;

  @override
  Future<SembleBookmarkPullResult> pull(String accountDid) async {
    this.accountDid = accountDid;
    final error = this.error;
    if (error != null) throw error;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
