import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/atproto/data/atproto_deletion_sync_service.dart';
import 'package:marker/features/atproto/data/margin_note_sync_service.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/data/semble_bookmark_push_service.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

final atprotoBookmarkImportControllerProvider =
    NotifierProvider<AtprotoBookmarkImportController, AtprotoBookmarkImportState>(AtprotoBookmarkImportController.new);

class AtprotoBookmarkImportController extends Notifier<AtprotoBookmarkImportState> {
  @override
  AtprotoBookmarkImportState build() => const AtprotoBookmarkImportIdle();

  Future<AtprotoBookmarkSyncResult?> importBookmarks(String accountDid) => syncBookmarks(accountDid);

  Future<AtprotoBookmarkSyncResult?> syncBookmarks(String accountDid) async {
    final syncAnnotations = await ref.read(settingsRepositoryProvider).isAnnotationSyncEnabled();
    final totalRequests = syncAnnotations ? 8 : 6;
    state = AtprotoBookmarkImportRunning(
      SembleBookmarkPullProgress(
        completedRequests: 0,
        totalRequests: totalRequests,
        description: 'Publishing deleted records',
      ),
    );
    try {
      await ref.read(atprotoDeletionSyncServiceProvider).pushLocalDeletes(accountDid);
      state = AtprotoBookmarkImportRunning(
        SembleBookmarkPullProgress(
          completedRequests: 1,
          totalRequests: totalRequests,
          description: 'Publishing local bookmark changes',
        ),
      );
      final pushResult = await ref.read(sembleBookmarkPushServiceProvider).pushPending(accountDid);
      MarginNoteSyncResult? marginPushResult;
      if (syncAnnotations) {
        state = AtprotoBookmarkImportRunning(
          SembleBookmarkPullProgress(
            completedRequests: 2,
            totalRequests: totalRequests,
            description: 'Publishing local annotation changes',
          ),
        );
        marginPushResult = await ref.read(marginNoteSyncServiceProvider).pushPending(accountDid);
      }
      final pullOffset = syncAnnotations ? 3 : 2;
      state = AtprotoBookmarkImportRunning(
        SembleBookmarkPullProgress(
          completedRequests: pullOffset,
          totalRequests: totalRequests,
          description: 'Fetching remote bookmark changes',
        ),
      );
      final pullResult = await ref
          .read(sembleBookmarkPullServiceProvider)
          .pull(
            accountDid,
            onProgress: (progress) => state = AtprotoBookmarkImportRunning(
              SembleBookmarkPullProgress(
                completedRequests: progress.completedRequests + pullOffset,
                totalRequests: totalRequests,
                description: progress.description,
              ),
            ),
          );
      MarginNoteSyncResult? marginPullResult;
      if (syncAnnotations) {
        state = AtprotoBookmarkImportRunning(
          SembleBookmarkPullProgress(
            completedRequests: totalRequests - 1,
            totalRequests: totalRequests,
            description: 'Fetching remote annotation changes',
          ),
        );
        marginPullResult = await ref.read(marginNoteSyncServiceProvider).pull(accountDid);
      }
      final result = AtprotoBookmarkSyncResult(
        push: pushResult,
        pull: pullResult,
        marginPush: marginPushResult,
        marginPull: marginPullResult,
      );
      state = AtprotoBookmarkImportSucceeded(result);
      return result;
    } on Object {
      state = const AtprotoBookmarkImportFailed('Could not sync bookmarks. Check your connection and try again.');
      return null;
    }
  }

  void reset() => state = const AtprotoBookmarkImportIdle();
}

sealed class AtprotoBookmarkImportState {
  const AtprotoBookmarkImportState();

  bool get isImporting => this is AtprotoBookmarkImportRunning;
}

final class AtprotoBookmarkImportIdle extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportIdle();
}

final class AtprotoBookmarkImportRunning extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportRunning(this.progress);

  final SembleBookmarkPullProgress progress;
}

final class AtprotoBookmarkImportSucceeded extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportSucceeded(this.result);

  final AtprotoBookmarkSyncResult result;
}

final class AtprotoBookmarkImportFailed extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportFailed(this.message);

  final String message;
}

class AtprotoBookmarkSyncResult {
  const AtprotoBookmarkSyncResult({required this.push, required this.pull, this.marginPush, this.marginPull});

  final SembleBookmarkPushResult push;
  final SembleBookmarkPullResult pull;
  final MarginNoteSyncResult? marginPush;
  final MarginNoteSyncResult? marginPull;
}

String atprotoBookmarkSyncSummary(AtprotoBookmarkSyncResult result) {
  final push = result.push;
  final pull = result.pull;
  final marginPush = result.marginPush;
  final marginPull = result.marginPull;
  if (push.pushed == 0 &&
      push.failed == 0 &&
      push.deferred == 0 &&
      (marginPush == null || (marginPush.pushed == 0 && marginPush.failed == 0 && marginPush.deferred == 0)) &&
      (marginPull == null || _marginPullChangedCount(marginPull) == 0)) {
    final pullSummary = sembleBookmarkPullSummary(pull);
    return pullSummary == 'No new bookmarks found.' ? 'Bookmarks are up to date.' : pullSummary;
  }

  final lines = <String>[];
  if (push.pushed > 0) {
    lines.add(
      'Published ${push.pushed} bookmark ${plural(push.pushed, 'change')} '
      '(${push.created} new, ${push.updated} updated).',
    );
  }
  if (push.failed > 0 || push.deferred > 0) {
    lines.add('Could not publish ${push.failed} ${plural(push.failed, 'change')}; ${push.deferred} waiting to retry.');
  }
  if (marginPush != null && marginPush.pushed > 0) {
    lines.add('Published ${marginPush.pushed} annotation ${plural(marginPush.pushed, 'change')}.');
  }
  if (marginPush != null && (marginPush.failed > 0 || marginPush.deferred > 0)) {
    lines.add(
      'Could not publish ${marginPush.failed} annotation ${plural(marginPush.failed, 'change')}; '
      '${marginPush.deferred} waiting to retry.',
    );
  }
  if (marginPull != null && _marginPullChangedCount(marginPull) > 0) {
    lines.add(
      'Synced ${marginPull.imported} new, ${marginPull.updated} updated, '
      '${marginPull.deleted} deleted, and ${marginPull.duplicates} duplicate annotation '
      '${plural(_marginPullChangedCount(marginPull), 'record')}.',
    );
  }

  final pullSummary = sembleBookmarkPullSummary(pull);
  if (pullSummary != 'No new bookmarks found.') {
    lines.add(pullSummary);
  }
  return lines.isEmpty ? 'Bookmarks are up to date.' : lines.join('\n');
}

int _marginPullChangedCount(MarginNoteSyncResult result) {
  return result.imported + result.updated + result.duplicates + result.conflicts + result.malformed + result.deleted;
}

String sembleBookmarkPullSummary(SembleBookmarkPullResult result) {
  final importedTotal = result.cardsImported + result.collectionsImported + result.linksImported;
  final skippedTotal = result.duplicates + result.conflicts + result.malformed;
  final changedTotal = importedTotal + result.deleted;
  if (changedTotal == 0 && skippedTotal == 0) {
    return 'No new bookmarks found.';
  }

  final lines = <String>[];
  if (importedTotal == 0) {
    lines.add('No new bookmarks found.');
  } else {
    lines.add(
      'Imported ${result.cardsImported} ${plural(result.cardsImported, 'bookmark')}, '
      '${result.collectionsImported} ${plural(result.collectionsImported, 'folder')}, and '
      '${result.linksImported} ${plural(result.linksImported, 'folder link')}.',
    );
  }

  if (result.deleted > 0) {
    lines.add('Applied ${result.deleted} remote ${plural(result.deleted, 'delete')}.');
  }

  if (skippedTotal > 0) {
    lines.add(
      'Skipped ${result.duplicates} ${plural(result.duplicates, 'duplicate')}, '
      '${result.conflicts} ${plural(result.conflicts, 'conflict')}, and '
      '${result.malformed} malformed ${plural(result.malformed, 'record')}.',
    );
  }
  return lines.join('\n');
}

bool sembleBookmarkPullHasIssues(SembleBookmarkPullResult result) => result.conflicts > 0 || result.malformed > 0;
