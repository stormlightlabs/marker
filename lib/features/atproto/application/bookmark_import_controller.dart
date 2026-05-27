import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';

final atprotoBookmarkImportControllerProvider =
    NotifierProvider<AtprotoBookmarkImportController, AtprotoBookmarkImportState>(
      AtprotoBookmarkImportController.new,
    );

class AtprotoBookmarkImportController extends Notifier<AtprotoBookmarkImportState> {
  @override
  AtprotoBookmarkImportState build() => const AtprotoBookmarkImportIdle();

  Future<SembleBookmarkPullResult?> importBookmarks(String accountDid) async {
    state = const AtprotoBookmarkImportRunning();
    try {
      final result = await ref.read(sembleBookmarkPullServiceProvider).pull(accountDid);
      state = AtprotoBookmarkImportSucceeded(result);
      return result;
    } on Object {
      state = const AtprotoBookmarkImportFailed('Could not import bookmarks. Check your connection and try again.');
      return null;
    }
  }

  void reset() {
    state = const AtprotoBookmarkImportIdle();
  }
}

sealed class AtprotoBookmarkImportState {
  const AtprotoBookmarkImportState();

  bool get isImporting => this is AtprotoBookmarkImportRunning;
}

final class AtprotoBookmarkImportIdle extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportIdle();
}

final class AtprotoBookmarkImportRunning extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportRunning();
}

final class AtprotoBookmarkImportSucceeded extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportSucceeded(this.result);

  final SembleBookmarkPullResult result;
}

final class AtprotoBookmarkImportFailed extends AtprotoBookmarkImportState {
  const AtprotoBookmarkImportFailed(this.message);

  final String message;
}

String sembleBookmarkPullSummary(SembleBookmarkPullResult result) {
  final importedTotal = result.cardsImported + result.collectionsImported + result.linksImported;
  final skippedTotal = result.duplicates + result.conflicts + result.malformed;
  if (importedTotal == 0 && skippedTotal == 0) {
    return 'No new bookmarks found.';
  }

  final lines = <String>[];
  if (importedTotal == 0) {
    lines.add('No new bookmarks found.');
  } else {
    lines.add(
      'Imported ${result.cardsImported} ${_plural(result.cardsImported, 'bookmark')}, '
      '${result.collectionsImported} ${_plural(result.collectionsImported, 'folder')}, and '
      '${result.linksImported} ${_plural(result.linksImported, 'folder link')}.',
    );
  }

  if (skippedTotal > 0) {
    lines.add(
      'Skipped ${result.duplicates} ${_plural(result.duplicates, 'duplicate')}, '
      '${result.conflicts} ${_plural(result.conflicts, 'conflict')}, and '
      '${result.malformed} malformed ${_plural(result.malformed, 'record')}.',
    );
  }
  return lines.join('\n');
}

bool sembleBookmarkPullHasIssues(SembleBookmarkPullResult result) => result.conflicts > 0 || result.malformed > 0;

String _plural(int count, String singular) => count == 1 ? singular : '${singular}s';
