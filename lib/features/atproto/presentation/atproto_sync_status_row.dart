import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show AlwaysStoppedAnimation, LinearProgressIndicator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/shared/utils/datetime_utils.dart';
import 'package:marker/features/atproto/application/bookmark_import_controller.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/domain/atproto_account_session.dart';

final _atprotoAuthStateProvider = StreamProvider<AtprotoAuthState>((ref) {
  return ref.watch(atprotoAuthRepositoryProvider).watchAuthState();
});

final _latestAtprotoSyncProvider = FutureProvider.family<DateTime?, String>((ref, accountDid) async {
  final repository = ref.watch(atprotoSyncRepositoryProvider);
  final states = await repository.syncStatesForAccount(accountDid);
  final latestMirror = await repository.latestMirrorSyncAtForAccount(accountDid);
  DateTime? latest = latestMirror;
  for (final state in states) {
    final syncedAt = state.lastSuccessfulSyncAt;
    if (syncedAt == null) continue;
    if (latest == null || syncedAt.isAfter(latest)) latest = syncedAt;
  }
  return latest;
});

class AtprotoSyncStatusRow extends ConsumerWidget {
  const AtprotoSyncStatusRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_atprotoAuthStateProvider).value ?? ref.watch(atprotoAuthRepositoryProvider).state;
    if (state is! AtprotoAuthConnected) return const SizedBox.shrink();
    final account = state.account;
    final lastSync = ref.watch(_latestAtprotoSyncProvider(account.did)).value;
    final syncState = ref.watch(atprotoBookmarkImportControllerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFF151519), borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          child: Row(
            children: [
              const Icon(CupertinoIcons.cloud, color: CupertinoColors.activeBlue, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Last sync: ${formatDateTime(lastSync)}',
                  style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, letterSpacing: 0),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                minimumSize: const Size(0, 28),
                color: const Color(0xFF2A2A30),
                onPressed: syncState.isImporting ? null : () => _showSyncSheet(context, ref, account),
                child: Text(syncState.isImporting ? 'Syncing…' : 'Sync now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSyncSheet(BuildContext context, WidgetRef ref, AtprotoAccount account) async {
    await showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: false,
      builder: (sheetContext) => _AtprotoSyncSheet(accountDid: account.did),
    );
  }
}

class _AtprotoSyncSheet extends ConsumerStatefulWidget {
  const _AtprotoSyncSheet({required this.accountDid});

  final String accountDid;

  @override
  ConsumerState<_AtprotoSyncSheet> createState() => _AtprotoSyncSheetState();
}

class _AtprotoSyncSheetState extends ConsumerState<_AtprotoSyncSheet> {
  AtprotoBookmarkSyncResult? _result;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_sync);
  }

  Future<void> _sync() async {
    final result = await ref.read(atprotoBookmarkImportControllerProvider.notifier).syncBookmarks(widget.accountDid);
    if (!mounted) return;
    ref.invalidate(_latestAtprotoSyncProvider(widget.accountDid));
    final state = ref.read(atprotoBookmarkImportControllerProvider);
    setState(() {
      _result = result;
      _failureMessage = result == null && state is AtprotoBookmarkImportFailed
          ? state.message
          : (result == null ? 'Could not sync. Check your connection and try again.' : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(atprotoBookmarkImportControllerProvider);
    final progress = importState is AtprotoBookmarkImportRunning
        ? importState.progress
        : const SembleBookmarkPullProgress(completedRequests: 0, totalRequests: 6, description: 'Starting sync');
    final isRunning = _result == null && _failureMessage == null;
    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF151519)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _failureMessage != null ? 'Sync failed' : (_result == null ? 'Syncing ATProto' : 'Sync complete'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (isRunning) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.fraction.clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: const Color(0xFF2A2A30),
                      valueColor: const AlwaysStoppedAnimation<Color>(CupertinoColors.activeBlue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    progress.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.white, fontSize: 14),
                  ),
                ] else if (_failureMessage != null) ...[
                  Text(
                    _failureMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 14),
                  ),
                ] else ...[
                  Text(
                    atprotoBookmarkSyncSummary(_result!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14, height: 1.35),
                  ),
                ],
                const SizedBox(height: 18),
                CupertinoButton.filled(
                  onPressed: isRunning ? null : () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
