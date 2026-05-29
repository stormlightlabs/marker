import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/application/atproto_login_controller.dart';
import 'package:marker/features/atproto/data/atproto_actor_search_repository.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_session_store.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/data/semble_bookmark_push_service.dart';
import 'package:poptart/poptart.dart';

import '../../../helpers/harness.dart';

const fakeContext = OAuthContext(codeVerifier: 'verifier-1', state: 'state-1', dpopNonce: 'nonce-1');

void main() {
  late AppDatabase database;
  late AtprotoSyncRepository syncRepository;
  late MemoryAtprotoSessionStore sessionStore;
  late AtprotoAuthRepository authRepository;
  late FakeAtprotoOAuthClient oauthClient;
  late FakeAtprotoOAuthBrowser browser;
  late FakeSembleBookmarkPullService bookmarkPullService;
  late FakeSembleBookmarkPushService bookmarkPushService;
  late FakeAtprotoActorSearchRepository actorSearchRepository;

  setUp(() {
    FakeWebViewPlatform();
    database = AppDatabase(NativeDatabase.memory());
    syncRepository = AtprotoSyncRepository(database, now: () => DateTime.utc(2026, 5, 26, 12));
    sessionStore = MemoryAtprotoSessionStore();
    oauthClient = FakeAtprotoOAuthClient();
    browser = FakeAtprotoOAuthBrowser();
    bookmarkPullService = FakeSembleBookmarkPullService();
    bookmarkPushService = FakeSembleBookmarkPushService();
    actorSearchRepository = FakeAtprotoActorSearchRepository();
    authRepository = AtprotoAuthRepository(
      syncRepository: syncRepository,
      sessionStore: sessionStore,
      oauthClient: oauthClient,
      now: () => DateTime.utc(2026, 5, 26, 12),
    );
  });

  tearDown(() async {
    authRepository.dispose();
    await database.close();
  });

  Future<void> seedConnectedAccount() async {
    await syncRepository.upsertAccount(
      did: 'did:plc:alice',
      handle: 'alice.bsky.social',
      pdsEndpoint: 'https://pds.example',
      authMethod: 'oauth',
    );
    await sessionStore.saveOAuthSession(
      'did:plc:alice',
      await oauthClient.callback(callbackUrl: '', context: fakeContext),
    );
    await authRepository.restore();
  }

  testWidgets('connects ATProto account from settings sheet', (tester) async {
    await tester.pumpWidget(
      markerTestApp(
        database: database,
        additionalOverrides: [
          atprotoAuthRepositoryProvider.overrideWithValue(authRepository),
          atprotoOAuthBrowserProvider.overrideWithValue(browser),
          atprotoActorSearchRepositoryProvider.overrideWithValue(actorSearchRepository),
        ],
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);

    expect(find.text('ATProto Sync'), findsOneWidget);
    expect(find.text('Connect a Bluesky or Atmosphere account'), findsOneWidget);

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(find.text('Connect ATProto'), findsOneWidget);
    expect(find.text('Use your Bluesky or Atmosphere account to import Semble/Cosmik bookmarks.'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), ' @alice.bsky.social ');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(actorSearchRepository.queries, ['alice.bsky.social']);
    await tester.tap(find.text('@alice.bsky.social'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(oauthClient.authorizedHandle, 'alice.bsky.social');
    expect(browser.authorizationUrls, [Uri.parse('https://bsky.social/oauth/authorize?request_uri=abc')]);
    expect(find.text('Import bookmarks now?'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Connected as did:plc:alice'), findsOneWidget);
  });

  testWidgets('shows connected account details and confirms disconnect without deleting local data', (tester) async {
    final now = DateTime.utc(2026, 5, 26, 12);
    await syncRepository.upsertAccount(
      did: 'did:plc:alice',
      handle: 'alice.bsky.social',
      pdsEndpoint: 'https://pds.example',
      authMethod: 'oauth',
    );
    await syncRepository.saveCursor(
      accountDid: 'did:plc:alice',
      collection: SembleSyncCollection.card.value,
      lastSuccessfulSyncAt: now,
      lastError: 'rate limited',
    );
    await syncRepository.saveCursor(
      accountDid: 'did:plc:alice',
      collection: SembleSyncCollection.collectionLinkRemoval.value,
      lastSuccessfulSyncAt: now,
    );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'deleted-bookmark',
      collection: SembleSyncCollection.card.value,
      rkey: 'deleted-card',
      uri: 'at://did:plc:alice/${SembleSyncCollection.card.value}/deleted-card',
      deletedAt: now,
    );
    await syncRepository.createMirror(
      accountDid: 'did:plc:alice',
      localTable: AtprotoSyncLocalTable.bookmarkFolders.value,
      localId: 'synced-folder',
      collection: SembleSyncCollection.collection.value,
      rkey: 'synced-folder',
      uri: 'at://did:plc:alice/${SembleSyncCollection.collection.value}/synced-folder',
      lastSyncedAt: now,
    );
    final pushOutbox = await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.create.value,
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'pending-create',
      collection: SembleSyncCollection.card.value,
    );
    await syncRepository.markOutboxAttempt(id: pushOutbox.id, attemptCount: 1, lastError: 'push failed');
    final deleteOutbox = await syncRepository.enqueueOutbox(
      accountDid: 'did:plc:alice',
      operation: AtprotoSyncOperation.delete.value,
      localTable: AtprotoSyncLocalTable.bookmarks.value,
      localId: 'pending-delete',
      collection: SembleSyncCollection.card.value,
    );
    await syncRepository.markOutboxAttempt(id: deleteOutbox.id, attemptCount: 1, lastError: 'delete failed');
    await sessionStore.saveOAuthSession(
      'did:plc:alice',
      await oauthClient.callback(callbackUrl: '', context: fakeContext),
    );
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'local-bookmark',
            url: 'https://example.com/saved',
            title: const Value('Saved locally'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await authRepository.restore();

    await tester.pumpWidget(
      markerTestApp(
        database: database,
        additionalOverrides: [atprotoAuthRepositoryProvider.overrideWithValue(authRepository)],
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);
    await tester.pumpAndSettle();

    expect(find.text('Connected as @alice.bsky.social'), findsOneWidget);
    expect(find.text('Account info'), findsOneWidget);
    expect(find.text('Account DID'), findsNothing);
    await tester.tap(find.text('Account info'));
    await tester.pumpAndSettle();
    expect(find.text('Account DID'), findsOneWidget);
    expect(find.text('did:plc:alice'), findsOneWidget);
    expect(find.text('Handle'), findsOneWidget);
    expect(find.text('@alice.bsky.social'), findsOneWidget);
    expect(find.text('PDS endpoint'), findsOneWidget);
    expect(find.text('https://pds.example'), findsOneWidget);
    expect(find.text('Last bookmark import'), findsOneWidget);
    expect(find.text('Last error'), findsWidgets);
    expect(find.text('rate limited'), findsWidgets);
    expect(find.text('Sync diagnostics'), findsOneWidget);
    expect(find.text('Cards / bookmarks'), findsNothing);
    await tester.ensureVisible(find.text('Sync diagnostics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sync diagnostics'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Cards / bookmarks'), findsOneWidget);
    expect(find.text(SembleSyncCollection.card.value), findsOneWidget);
    final cardCollectionText = tester.widget<Text>(find.text(SembleSyncCollection.card.value));
    expect(cardCollectionText.style?.fontFamily, 'JetBrainsMono_700');
    expect(cardCollectionText.style?.fontWeight, FontWeight.w700);
    expect(find.text('Collections / folders'), findsOneWidget);
    expect(find.text(SembleSyncCollection.collection.value), findsOneWidget);
    expect(find.text('Collection links'), findsOneWidget);
    expect(find.text(SembleSyncCollection.collectionLink.value), findsOneWidget);
    expect(find.text('Collection link removals'), findsOneWidget);
    expect(find.text(SembleSyncCollection.collectionLinkRemoval.value), findsOneWidget);
    expect(find.text('Margin notes / annotations'), findsOneWidget);
    expect(find.text(MarginSyncCollection.note.value), findsOneWidget);
    expect(find.text('Margin annotation collections'), findsOneWidget);
    expect(find.text(MarginSyncCollection.collection.value), findsOneWidget);
    expect(find.text('Margin annotation collection items'), findsOneWidget);
    expect(find.text(MarginSyncCollection.collectionItem.value), findsOneWidget);
    expect(find.text('Push sync'), findsOneWidget);
    expect(find.text('Local changes pending: 1'), findsOneWidget);
    expect(find.textContaining('Last push:'), findsOneWidget);
    expect(find.text('Last push error: push failed'), findsOneWidget);
    expect(find.text('Outbox'), findsOneWidget);
    expect(find.text('Pending creates: 1'), findsOneWidget);
    expect(find.text('Pending updates: 0'), findsOneWidget);
    expect(find.text('Pending deletes: 1'), findsWidgets);
    expect(find.text('Failed attempts: 2'), findsOneWidget);
    expect(find.textContaining('Oldest pending change:'), findsOneWidget);
    expect(find.text('Delete sync'), findsOneWidget);
    expect(find.text('Failed delete attempts: 1'), findsOneWidget);
    expect(find.text('Confirmed remote deletes: 1'), findsOneWidget);
    expect(find.textContaining('Last successful sync:'), findsWidgets);
    expect(find.text('Last error: rate limited'), findsOneWidget);
    expect(find.text('Last error: None'), findsNWidgets(6));
    expect(find.text('Records synced: 0'), findsNWidgets(6));
    expect(find.text('Records synced: 1'), findsOneWidget);
    expect(find.text('Records deleted: 0'), findsNWidgets(6));
    expect(find.text('Records deleted: 1'), findsOneWidget);
    expect(find.textContaining('access-token'), findsNothing);
    expect(find.textContaining('refresh-token'), findsNothing);
    expect(find.textContaining('private-key'), findsNothing);

    await tester.ensureVisible(find.text('Disconnect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect ATProto?'), findsOneWidget);
    await tester.tap(find.text('Disconnect').last);
    await tester.pumpAndSettle();

    expect(sessionStore.sessions, isEmpty);
    expect((await syncRepository.accounts()).single.did, 'did:plc:alice');
    expect((await database.select(database.bookmarks).get()).single.id, 'local-bookmark');
    expect(find.text('Connect a Bluesky or Atmosphere account'), findsOneWidget);
  });

  testWidgets('imports bookmarks from the connected settings card and shows result summary', (tester) async {
    final importCompleter = Completer<SembleBookmarkPullResult>();
    bookmarkPullService.pendingResult = importCompleter.future;
    bookmarkPushService.result = const SembleBookmarkPushResult(pushed: 2, created: 1, updated: 1);
    await seedConnectedAccount();

    await tester.pumpWidget(
      markerTestApp(
        database: database,
        additionalOverrides: [
          atprotoAuthRepositoryProvider.overrideWithValue(authRepository),
          sembleBookmarkPullServiceProvider.overrideWithValue(bookmarkPullService),
          sembleBookmarkPushServiceProvider.overrideWithValue(bookmarkPushService),
        ],
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoButton, 'Sync'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Syncing...'), findsOneWidget);
    expect(find.textContaining('requests complete'), findsOneWidget);
    expect(find.textContaining('Fetching'), findsOneWidget);
    importCompleter.complete(
      const SembleBookmarkPullResult(
        cardsImported: 2,
        collectionsImported: 1,
        linksImported: 3,
        duplicates: 1,
        conflicts: 1,
        malformed: 0,
        deleted: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(bookmarkPullService.accountDid, 'did:plc:alice');
    expect(find.text('Bookmark sync complete'), findsOneWidget);
    expect(
      find.text(
        'Published 2 bookmark changes (1 new, 1 updated).\nImported 2 bookmarks, 1 folder, and 3 folder links.\nApplied 2 remote deletes.\nSkipped 1 duplicate, 1 conflict, and 0 malformed records.',
      ),
      findsOneWidget,
    );
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('shows import failure state from the connected settings card', (tester) async {
    bookmarkPullService.error = StateError('offline');
    await seedConnectedAccount();

    await tester.pumpWidget(
      markerTestApp(
        database: database,
        additionalOverrides: [
          atprotoAuthRepositoryProvider.overrideWithValue(authRepository),
          sembleBookmarkPullServiceProvider.overrideWithValue(bookmarkPullService),
          sembleBookmarkPushServiceProvider.overrideWithValue(bookmarkPushService),
        ],
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpRouteTransition(tester);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoButton, 'Sync'));
    await tester.pumpAndSettle();

    expect(find.text('Sync failed'), findsOneWidget);
    expect(find.text('Could not sync bookmarks. Check your connection and try again.'), findsOneWidget);
  });
}

class FakeAtprotoActorSearchRepository implements AtprotoActorSearchRepository {
  final queries = <String>[];
  var suggestions = const <AtprotoActorSuggestion>[
    AtprotoActorSuggestion(did: 'did:plc:alice', handle: 'alice.bsky.social', displayName: 'Alice'),
  ];

  @override
  Future<List<AtprotoActorSuggestion>> searchTypeahead(String query, {int limit = 8}) async {
    queries.add(query);
    return suggestions;
  }
}

class FakeSembleBookmarkPushService implements SembleBookmarkPushService {
  SembleBookmarkPushResult result = const SembleBookmarkPushResult();
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
  SembleBookmarkPullResult result = const SembleBookmarkPullResult();
  Future<SembleBookmarkPullResult>? pendingResult;
  Object? error;
  String? accountDid;

  @override
  Future<SembleBookmarkPullResult> pull(String accountDid, {SembleBookmarkPullProgressListener? onProgress}) async {
    this.accountDid = accountDid;
    onProgress?.call(
      const SembleBookmarkPullProgress(completedRequests: 1, totalRequests: 4, description: 'Fetching cards'),
    );
    final error = this.error;
    if (error != null) throw error;
    final pendingResult = this.pendingResult;
    if (pendingResult != null) return pendingResult;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAtprotoOAuthBrowser implements AtprotoOAuthBrowser {
  final authorizationUrls = <Uri>[];

  @override
  Future<String> authenticate(Uri authorizationUrl) async {
    authorizationUrls.add(authorizationUrl);
    return 'https://marker.stormlightlabs.org/oauth/callback?code=code&state=state-1';
  }
}

class FakeAtprotoOAuthClient implements AtprotoOAuthClient {
  String? authorizedHandle;

  @override
  Future<(Uri, OAuthContext)> authorize({String? handle}) async {
    authorizedHandle = handle;
    return (Uri.parse('https://bsky.social/oauth/authorize?request_uri=abc'), fakeContext);
  }

  @override
  Future<OAuthSession> callback({required String callbackUrl, required OAuthContext context}) async => OAuthSession(
    accessToken: 'access-token-1',
    refreshToken: 'refresh-token-1',
    tokenType: 'DPoP',
    scope: 'atproto transition:generic',
    expiresAt: DateTime.utc(2026, 5, 26, 13),
    sub: 'did:plc:alice',
    $clientId: markerAtprotoOAuthClientId,
    $pdsEndpoint: 'porcini.us-east.host.bsky.network',
    $dPoPNonce: 'nonce-1',
    $publicKey: 'public-key-1',
    $privateKey: 'private-key-1',
  );

  @override
  Future<OAuthSession> refresh(OAuthSession session) async => session;
}
