import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/atproto/application/bookmark_import_controller.dart';
import 'package:marker/features/atproto/data/atproto_deletion_sync_service.dart';
import 'package:marker/features/atproto/data/margin_note_sync_service.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/data/semble_bookmark_push_service.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

void main() {
  test('syncs bookmarks and exposes success state', () async {
    final deletionService = FakeAtprotoDeletionSyncService();
    final pushService = FakeSembleBookmarkPushService();
    final service = FakeSembleBookmarkPullService(
      result: const SembleBookmarkPullResult(cardsImported: 12, collectionsImported: 3, linksImported: 18),
    );
    final container = ProviderContainer(
      overrides: [
        atprotoDeletionSyncServiceProvider.overrideWithValue(deletionService),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        sembleBookmarkPullServiceProvider.overrideWithValue(service),
        sembleBookmarkPushServiceProvider.overrideWithValue(pushService),
      ],
    );
    addTearDown(container.dispose);
    final result = await container
        .read(atprotoBookmarkImportControllerProvider.notifier)
        .syncBookmarks('did:plc:alice');

    expect(deletionService.accountDid, 'did:plc:alice');
    expect(pushService.accountDid, 'did:plc:alice');
    expect(service.accountDid, 'did:plc:alice');
    expect(result?.pull.cardsImported, 12);
    expect(container.read(atprotoBookmarkImportControllerProvider), isA<AtprotoBookmarkImportSucceeded>());
  });

  test('reports sync failure with retry copy', () async {
    final service = FakeSembleBookmarkPullService(error: StateError('network down'));
    final container = ProviderContainer(
      overrides: [
        atprotoDeletionSyncServiceProvider.overrideWithValue(FakeAtprotoDeletionSyncService()),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        sembleBookmarkPullServiceProvider.overrideWithValue(service),
        sembleBookmarkPushServiceProvider.overrideWithValue(FakeSembleBookmarkPushService()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(atprotoBookmarkImportControllerProvider.notifier)
        .syncBookmarks('did:plc:alice');

    expect(result, isNull);
    final state = container.read(atprotoBookmarkImportControllerProvider);
    expect(state, isA<AtprotoBookmarkImportFailed>());
    expect(
      (state as AtprotoBookmarkImportFailed).message,
      'Could not sync bookmarks. Check your connection and try again.',
    );
  });

  test('syncs Margin records when annotation sync is enabled', () async {
    final marginService = FakeMarginNoteSyncService();
    final container = ProviderContainer(
      overrides: [
        atprotoDeletionSyncServiceProvider.overrideWithValue(FakeAtprotoDeletionSyncService()),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository(annotationSyncEnabled: true)),
        sembleBookmarkPullServiceProvider.overrideWithValue(FakeSembleBookmarkPullService()),
        sembleBookmarkPushServiceProvider.overrideWithValue(FakeSembleBookmarkPushService()),
        marginNoteSyncServiceProvider.overrideWithValue(marginService),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(atprotoBookmarkImportControllerProvider.notifier)
        .syncBookmarks('did:plc:alice');

    expect(marginService.pushedAccountDid, 'did:plc:alice');
    expect(marginService.pulledAccountDid, 'did:plc:alice');
    expect(result?.marginPush?.pushed, 1);
    expect(result?.marginPull?.imported, 1);
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
      sembleBookmarkPullSummary(const SembleBookmarkPullResult(deleted: 2)),
      'No new bookmarks found.\nApplied 2 remote deletes.',
    );
    expect(
      sembleBookmarkPullSummary(const SembleBookmarkPullResult(duplicates: 1)),
      'No new bookmarks found.\nSkipped 1 duplicate, 0 conflicts, and 0 malformed records.',
    );
    expect(sembleBookmarkPullHasIssues(const SembleBookmarkPullResult(conflicts: 1)), isTrue);
    expect(sembleBookmarkPullHasIssues(const SembleBookmarkPullResult(malformed: 1)), isTrue);
  });

  test('formats combined push and pull summaries', () {
    expect(
      atprotoBookmarkSyncSummary(
        const AtprotoBookmarkSyncResult(
          push: SembleBookmarkPushResult(pushed: 2, created: 1, updated: 1),
          pull: SembleBookmarkPullResult(deleted: 1),
        ),
      ),
      'Published 2 bookmark changes (1 new, 1 updated).\nNo new bookmarks found.\nApplied 1 remote delete.',
    );
    expect(
      atprotoBookmarkSyncSummary(
        const AtprotoBookmarkSyncResult(push: SembleBookmarkPushResult(), pull: SembleBookmarkPullResult()),
      ),
      'Bookmarks are up to date.',
    );
  });
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({this.annotationSyncEnabled = false});

  final bool annotationSyncEnabled;

  @override
  Future<bool> isAnnotationSyncEnabled() async => annotationSyncEnabled;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAtprotoDeletionSyncService implements AtprotoDeletionSyncService {
  String? accountDid;

  @override
  Future<void> pushLocalDeletes(String accountDid) async {
    this.accountDid = accountDid;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMarginNoteSyncService implements MarginNoteSyncService {
  String? pushedAccountDid;
  String? pulledAccountDid;

  @override
  Future<MarginNoteSyncResult> pushPending(String accountDid, {int limit = 100}) async {
    pushedAccountDid = accountDid;
    return const MarginNoteSyncResult(pushed: 1);
  }

  @override
  Future<MarginNoteSyncResult> pull(String accountDid, {bool importAsLocalOnly = false}) async {
    pulledAccountDid = accountDid;
    return const MarginNoteSyncResult(imported: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSembleBookmarkPushService implements SembleBookmarkPushService {
  FakeSembleBookmarkPushService({this.result = const SembleBookmarkPushResult()});

  final SembleBookmarkPushResult result;
  String? accountDid;

  @override
  Future<SembleBookmarkPushResult> pushPending(String accountDid, {int limit = 100}) async {
    this.accountDid = accountDid;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSembleBookmarkPullService implements SembleBookmarkPullService {
  FakeSembleBookmarkPullService({this.result = const SembleBookmarkPullResult(), this.error});

  final SembleBookmarkPullResult result;
  final Object? error;
  String? accountDid;

  @override
  Future<SembleBookmarkPullResult> pull(
    String accountDid, {
    SembleBookmarkPullProgressListener? onProgress,
    bool importAsLocalOnly = false,
  }) async {
    this.accountDid = accountDid;
    onProgress?.call(
      const SembleBookmarkPullProgress(completedRequests: 1, totalRequests: 4, description: 'Fetching cards'),
    );
    final error = this.error;
    if (error != null) throw error;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
