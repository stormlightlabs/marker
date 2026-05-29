import 'package:flutter/cupertino.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';

enum SyncRecordState {
  localOnly('Local only', CupertinoColors.systemGrey2),
  syncPending('Sync pending', CupertinoColors.systemOrange),
  synced('Synced', CupertinoColors.activeGreen),
  needsAttention('Needs attention', CupertinoColors.systemRed);

  const SyncRecordState(this.label, this.color);

  factory SyncRecordState.fromAtproto(AtprotoLocalSyncStatus status) => switch (status) {
    AtprotoLocalSyncStatus.localOnly => SyncRecordState.localOnly,
    AtprotoLocalSyncStatus.syncPending => SyncRecordState.syncPending,
    AtprotoLocalSyncStatus.synced => SyncRecordState.synced,
    AtprotoLocalSyncStatus.needsAttention => SyncRecordState.needsAttention,
  };

  final String label;
  final Color color;
}

class SyncStateBadge extends StatelessWidget {
  const SyncStateBadge({required this.state, super.key});

  final SyncRecordState state;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: state.color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: state.color.withValues(alpha: 0.35), width: 0.5),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      child: Text(
        state.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: state.color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0),
      ),
    ),
  );
}
