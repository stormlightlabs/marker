import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/data/semble_bookmark_push_service.dart';

final atprotoBookmarkImportControllerProvider =
    NotifierProvider<AtprotoBookmarkImportController, AtprotoBookmarkImportState>(AtprotoBookmarkImportController.new);

class AtprotoBookmarkImportController extends Notifier<AtprotoBookmarkImportState> {
  @override
  AtprotoBookmarkImportState build() => const AtprotoBookmarkImportIdle();

  Future<AtprotoBookmarkSyncResult?> importBookmarks(String accountDid) => syncBookmarks(accountDid);

  Future<AtprotoBookmarkSyncResult?> syncBookmarks(String accountDid) async {
    state = const AtprotoBookmarkImportRunning(
      SembleBookmarkPullProgress(completedRequests: 0, totalRequests: 5, description: 'Publishing local changes'),
    );
    try {
      final pushResult = await ref.read(sembleBookmarkPushServiceProvider).pushPending(accountDid);
      state = const AtprotoBookmarkImportRunning(
        SembleBookmarkPullProgress(completedRequests: 1, totalRequests: 5, description: 'Fetching remote changes'),
      );
      final pullResult = await ref
          .read(sembleBookmarkPullServiceProvider)
          .pull(accountDid, onProgress: (progress) => state = AtprotoBookmarkImportRunning(progress.offsetBy(1)));
      final result = AtprotoBookmarkSyncResult(push: pushResult, pull: pullResult);
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
  const AtprotoBookmarkSyncResult({required this.push, required this.pull});

  final SembleBookmarkPushResult push;
  final SembleBookmarkPullResult pull;
}

String atprotoBookmarkSyncSummary(AtprotoBookmarkSyncResult result) {
  final push = result.push;
  final pull = result.pull;
  if (push.pushed == 0 && push.failed == 0 && push.deferred == 0) {
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

  final pullSummary = sembleBookmarkPullSummary(pull);
  if (pullSummary != 'No new bookmarks found.') {
    lines.add(pullSummary);
  }
  return lines.isEmpty ? 'Bookmarks are up to date.' : lines.join('\n');
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
