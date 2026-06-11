import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show AlwaysStoppedAnimation, LinearProgressIndicator;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/shared/utils/atproto_utils.dart';
import 'package:marker/core/widgets/funnotation.dart';
import 'package:marker/features/atproto/application/atproto_login_controller.dart';
import 'package:marker/features/atproto/application/bookmark_import_controller.dart';
import 'package:marker/features/atproto/data/annotation_sync_opt_in_service.dart';
import 'package:marker/features/atproto/data/atproto_actor_search_repository.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/domain/atproto_account_session.dart';
import 'package:marker/features/settings/data/settings_repository.dart';
import 'package:marker/shared/widgets/settings_rows.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adBlockEnabled = ref.watch(adBlockEnabledProvider).value ?? true;
    final funEnabled = ref.watch(funEnabledProvider).value ?? true;
    final atprotoAuthState =
        ref.watch(_atprotoAuthStateProvider).value ?? ref.watch(atprotoAuthRepositoryProvider).state;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const CupertinoSliverNavigationBar(
                    largeTitle: Text('Settings'),
                    backgroundColor: CupertinoColors.black,
                    border: null,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      child: Column(
                        children: [
                          SettingsSwitchRow(
                            icon: CupertinoIcons.shield_lefthalf_fill,
                            title: 'Ad Blocker',
                            subtitle: 'Block EasyList ads while browsing',
                            value: adBlockEnabled,
                            onChanged: (value) {
                              ref.read(adBlockEnabledProvider.notifier).setEnabled(value);
                            },
                          ),
                          const SizedBox(height: 12),
                          SettingsSwitchRow(
                            icon: funEnabled ? CupertinoIcons.scribble : CupertinoIcons.wand_rays,
                            title: 'Fun',
                            titleWidget: const Funnotation(
                              color: CupertinoColors.systemGreen,
                              padding: 8,
                              child: Text(
                                'Fun',
                                style: TextStyle(color: CupertinoColors.white, fontSize: 16, letterSpacing: 0),
                              ),
                            ),
                            subtitle: 'Use playful titles and hand-drawn scribbles',
                            value: funEnabled,
                            onChanged: (value) {
                              ref.read(funEnabledProvider.notifier).setEnabled(value);
                            },
                          ),
                          const SizedBox(height: 12),
                          SettingsLinkRow(
                            icon: CupertinoIcons.clock,
                            title: 'Browser History',
                            subtitle: 'Recent page visits and clear history',
                            onPressed: () => context.pushNamed(AppRoute.history.routeName),
                          ),
                          const SizedBox(height: 22),
                          SettingsSectionHeader(
                            label: 'Sync',
                            trailing: _AtprotoInfoLink(
                              onPressed: () => _openExternalUrl('https://atmosphereaccount.com/'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SyncSettingsSummaryRow(state: atprotoAuthState),
                          const SizedBox(height: 22),
                          const SettingsSectionLabel('Advanced'),
                          const SizedBox(height: 8),
                          SettingsLinkRow(
                            icon: CupertinoIcons.doc_text_search,
                            title: 'Logs',
                            subtitle: 'View, filter, and download diagnostic logs',
                            onPressed: () => context.pushNamed(AppRoute.logs.routeName),
                          ),
                          const SizedBox(height: 12),
                          SettingsLinkRow(
                            icon: CupertinoIcons.info_circle,
                            title: 'About',
                            subtitle: 'Stormlight Labs',
                            onPressed: () => context.pushNamed(AppRoute.about.routeName),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const MarkerTabBar(activeRoute: AppRoute.settings),
          ],
        ),
      ),
    );
  }
}

Future<void> _openExternalUrl(String value) async {
  await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
}

class _AtprotoInfoLink extends StatelessWidget {
  const _AtprotoInfoLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size(24, 24),
    onPressed: onPressed,
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.at_circle, size: 15),
        SizedBox(width: 4),
        Text('What is AT Proto?', style: TextStyle(fontSize: 12, letterSpacing: 0)),
      ],
    ),
  );
}

final _atprotoAuthStateProvider = StreamProvider<AtprotoAuthState>((ref) {
  return ref.watch(atprotoAuthRepositoryProvider).watchAuthState();
});

final _atprotoSyncStatesProvider = FutureProvider.family<List<AtprotoSyncStateData>, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).syncStatesForAccount(accountDid);
});

final _atprotoSyncedRecordCountsProvider = FutureProvider.family<Map<String, int>, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).syncedRecordCountsForAccount(accountDid);
});

final _atprotoDeletedRecordCountsProvider = FutureProvider.family<Map<String, int>, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).deletedRecordCountsForAccount(accountDid);
});

final _atprotoPendingOutboxProvider = FutureProvider.family<List<AtprotoSyncOutboxData>, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).pendingOutbox(accountDid: accountDid);
});

final _atprotoSelectionDiagnosticsProvider = FutureProvider.family<Map<String, int>, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).selectionDiagnosticsForAccount(accountDid);
});

final _atprotoAutoSelectBookmarksProvider = FutureProvider.family<bool, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).autoSelectBookmarksEnabled(accountDid);
});

final _atprotoAutoSelectAnnotationsProvider = FutureProvider.family<bool, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).autoSelectAnnotationsEnabled(accountDid);
});

final _atprotoLatestMirrorSyncProvider = FutureProvider.family<DateTime?, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).latestMirrorSyncAtForAccount(accountDid);
});

final _annotationSyncEnabledProvider = FutureProvider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).isAnnotationSyncEnabled();
});

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atprotoAuthState =
        ref.watch(_atprotoAuthStateProvider).value ?? ref.watch(atprotoAuthRepositoryProvider).state;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: Text('Sync'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AtprotoAccountRow(state: atprotoAuthState),
              const SizedBox(height: 12),
              SettingsLinkRow(
                icon: CupertinoIcons.at_circle,
                title: 'What is ATProto / the Atmosphere?',
                subtitle: 'Learn how Marker sync works with open social web accounts',
                onPressed: () => _openExternalUrl('https://atmosphereaccount.com/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncSettingsSummaryRow extends StatelessWidget {
  const _SyncSettingsSummaryRow({required this.state});

  final AtprotoAuthState state;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (state) {
      AtprotoAuthConnected(:final account) => 'Connected as ${_ConnectedAtprotoAccountCard._accountLabel(account)}',
      AtprotoAuthFailure(:final message) => message,
      AtprotoAuthDisconnected() => 'Connect an account and choose what syncs',
    };
    return SettingsLinkRow(
      icon: CupertinoIcons.cloud,
      title: 'Sync',
      subtitle: subtitle,
      onPressed: () => context.pushNamed(AppRoute.sync.routeName),
    );
  }
}

class _AtprotoAccountRow extends ConsumerWidget {
  const _AtprotoAccountRow({required this.state});

  final AtprotoAuthState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state case AtprotoAuthConnected(:final account)) {
      return Column(
        children: [
          _ConnectedAtprotoAccountCard(account: account),
          const SizedBox(height: 12),
          _AtprotoSyncOptionsCard(accountDid: account.did),
        ],
      );
    }

    return SettingsRowFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            const Icon(CupertinoIcons.cloud, color: CupertinoColors.activeBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: SettingsRowText(title: 'Sync', subtitle: _subtitle),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showConnectSheet(context),
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle => switch (state) {
    AtprotoAuthFailure(:final message) => message,
    AtprotoAuthDisconnected() => 'Connect a Bluesky or Atmosphere account',
    AtprotoAuthConnected() => 'Connected',
  };

  Future<void> _showConnectSheet(BuildContext context) async {
    await showCupertinoModalPopup<void>(context: context, builder: (sheetContext) => const _AtprotoConnectSheet());
  }
}

class _AnnotationSyncOptInRow extends StatelessWidget {
  const _AnnotationSyncOptInRow({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
    decoration: BoxDecoration(color: const Color(0xFF151519), borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        const Expanded(
          child: SettingsRowText(
            title: 'Annotation sync',
            subtitle: 'Sync highlights, notes, tags, and annotation collections with Margin.',
          ),
        ),
        CupertinoSwitch(value: enabled, onChanged: onChanged),
      ],
    ),
  );
}

class _ConnectedAtprotoAccountCard extends ConsumerWidget {
  const _ConnectedAtprotoAccountCard({required this.account});

  final AtprotoAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStates = ref.watch(_atprotoSyncStatesProvider(account.did)).value ?? const <AtprotoSyncStateData>[];
    final syncedRecordCounts =
        ref.watch(_atprotoSyncedRecordCountsProvider(account.did)).value ?? const <String, int>{};

    final deletedRecordCounts =
        ref.watch(_atprotoDeletedRecordCountsProvider(account.did)).value ?? const <String, int>{};

    final pendingOutbox =
        ref.watch(_atprotoPendingOutboxProvider(account.did)).value ?? const <AtprotoSyncOutboxData>[];
    final selectionDiagnostics =
        ref.watch(_atprotoSelectionDiagnosticsProvider(account.did)).value ?? const <String, int>{};
    final lastPush = ref.watch(_atprotoLatestMirrorSyncProvider(account.did)).value;
    final importState = ref.watch(atprotoBookmarkImportControllerProvider);
    final lastImport = _latestSuccessfulSync(syncStates);
    final lastError = _latestError(syncStates);
    final isImporting = importState.isImporting;

    return SettingsRowFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(CupertinoIcons.cloud, color: CupertinoColors.activeBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SettingsRowText(title: 'Sync', subtitle: 'Connected as ${_accountLabel(account)}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Marker only syncs items you choose to keep synced, plus future items covered by your defaults. Browser history stays local.',
              style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
            _ExpandableSettingsSection(
              title: 'Account info',
              initiallyExpanded: false,
              child: Column(
                children: [
                  _AtprotoDetailRow(label: 'Account DID', value: account.did),
                  if (account.handle?.trim().isNotEmpty == true)
                    _AtprotoDetailRow(label: 'Handle', value: '@${account.handle!.trim()}'),
                  if (account.pdsEndpoint?.trim().isNotEmpty == true)
                    _AtprotoDetailRow(label: 'PDS endpoint', value: account.pdsEndpoint!.trim()),
                  _AtprotoDetailRow(label: 'Last bookmark import', value: _formatDateTime(lastImport)),
                  if (lastError != null) _AtprotoDetailRow(label: 'Last error', value: lastError, isError: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _AtprotoDiagnosticsSection(
              syncStates: syncStates,
              syncedRecordCounts: syncedRecordCounts,
              deletedRecordCounts: deletedRecordCounts,
              pendingOutbox: pendingOutbox,
              selectionDiagnostics: selectionDiagnostics,
              lastPush: lastPush,
              formatDateTime: _formatDateTime,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    color: const Color(0xFF2A2A30),
                    disabledColor: const Color(0xFF2A2A30),
                    onPressed: isImporting ? null : () => _showImportSheet(context),
                    child: Text(isImporting ? 'Syncing...' : 'Sync now'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    color: CupertinoColors.systemRed,
                    onPressed: () => _confirmDisconnect(context, ref),
                    child: const Text('Disconnect', style: TextStyle(color: CupertinoColors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _accountLabel(AtprotoAccount account) {
    final handle = account.handle?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return account.did;
  }

  static DateTime? _latestSuccessfulSync(List<AtprotoSyncStateData> states) {
    DateTime? latest;
    for (final state in states) {
      final syncedAt = state.lastSuccessfulSyncAt;
      if (syncedAt == null) continue;
      if (latest == null || syncedAt.isAfter(latest)) latest = syncedAt;
    }
    return latest;
  }

  static String? _latestError(List<AtprotoSyncStateData> states) {
    for (final state in states) {
      final error = state.lastError?.trim();
      if (error != null && error.isNotEmpty) return error;
    }
    return null;
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return 'Never';
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final shouldDisconnect = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Disconnect ATProto?'),
        content: const Text('Marker will remove the saved sign-in session. Imported bookmarks stay on this device.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (shouldDisconnect != true) return;
    await ref.read(atprotoAuthRepositoryProvider).disconnect(account.did);
  }

  Future<void> _showImportSheet(BuildContext context) async {
    final importAsLocalOnly = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Import remote records'),
        content: const Text(
          'Keep imported records linked to this account for future sync, or import them as local-only so future edits stay private.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Local-only'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep linked'),
          ),
        ],
      ),
    );
    if (importAsLocalOnly == null || !context.mounted) return;
    await showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: false,
      builder: (sheetContext) => _AtprotoImportSheet(accountDid: account.did, importAsLocalOnly: importAsLocalOnly),
    );
  }
}

class _ExpandableSettingsSection extends StatefulWidget {
  const _ExpandableSettingsSection({required this.title, required this.child, this.initiallyExpanded = false});

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSettingsSection> createState() => _ExpandableSettingsSectionState();
}

class _ExpandableSettingsSectionState extends State<_ExpandableSettingsSection> {
  late var _isExpanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF0F0F13),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                color: CupertinoColors.systemGrey2,
                size: 16,
              ),
            ],
          ),
        ),
        if (_isExpanded) Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10), child: widget.child),
      ],
    ),
  );
}

void _invalidateAtprotoSyncUi(WidgetRef ref, String accountDid) {
  ref.invalidate(_atprotoSyncStatesProvider(accountDid));
  ref.invalidate(_atprotoPendingOutboxProvider(accountDid));
  ref.invalidate(_atprotoSelectionDiagnosticsProvider(accountDid));
  ref.invalidate(_atprotoSyncedRecordCountsProvider(accountDid));
  ref.invalidate(_atprotoLatestMirrorSyncProvider(accountDid));
}

class _AtprotoSyncOptionsCard extends ConsumerWidget {
  const _AtprotoSyncOptionsCard({required this.accountDid});

  final String accountDid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationSyncEnabled = ref.watch(_annotationSyncEnabledProvider).value ?? false;
    final autoSelectBookmarks = ref.watch(_atprotoAutoSelectBookmarksProvider(accountDid)).value ?? false;
    final autoSelectAnnotations = ref.watch(_atprotoAutoSelectAnnotationsProvider(accountDid)).value ?? false;

    return SettingsRowFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
        child: _AtprotoSelectionControls(
          accountDid: accountDid,
          annotationSyncEnabled: annotationSyncEnabled,
          autoSelectBookmarks: autoSelectBookmarks,
          autoSelectAnnotations: autoSelectAnnotations,
        ),
      ),
    );
  }
}

class _AtprotoSelectionControls extends ConsumerWidget {
  const _AtprotoSelectionControls({
    required this.accountDid,
    required this.annotationSyncEnabled,
    required this.autoSelectBookmarks,
    required this.autoSelectAnnotations,
  });

  final String accountDid;
  final bool annotationSyncEnabled;
  final bool autoSelectBookmarks;
  final bool autoSelectAnnotations;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SyncOptionsHeader(),
      const SizedBox(height: 8),
      _AnnotationSyncOptInRow(
        enabled: annotationSyncEnabled,
        onChanged: (enabled) async {
          if (enabled) {
            final confirmed = await _confirmEnableAnnotationSync(context);
            if (!confirmed) return;
          }
          await ref.read(annotationSyncOptInServiceProvider).setEnabled(enabled);
          ref.invalidate(_annotationSyncEnabledProvider);
          _invalidateAtprotoSyncUi(ref, accountDid);
        },
      ),
      const SizedBox(height: 8),
      _SyncSelectionSwitchRow(
        title: 'Sync local new bookmarks',
        subtitle: 'Automatically select new bookmarks, folders, and memberships for this account.',
        value: autoSelectBookmarks,
        onChanged: (value) async {
          await ref.read(atprotoSyncRepositoryProvider).setAutoSelectBookmarksEnabled(accountDid, value);
          ref.invalidate(_atprotoAutoSelectBookmarksProvider(accountDid));
        },
      ),
      const SizedBox(height: 8),
      const _UnderlineSyncInfoBlock(),
      const SizedBox(height: 8),
      _SyncSelectionSwitchRow(
        title: 'Sync local new annotations',
        subtitle: 'Automatically select new annotations and curated annotation collections for this account.',
        value: autoSelectAnnotations,
        onChanged: (value) async {
          await ref.read(atprotoSyncRepositoryProvider).setAutoSelectAnnotationsEnabled(accountDid, value);
          ref.invalidate(_atprotoAutoSelectAnnotationsProvider(accountDid));
        },
      ),
    ],
  );
}

Future<bool> _confirmEnableAnnotationSync(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Sync annotations?'),
      content: const Text(
        'Marker will import and publish Margin note records in your ATProto repo. Synced records can include page URLs, selected text, notes, and highlight colors.',
      ),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Enable annotation sync'),
        ),
      ],
    ),
  );
  return result == true;
}

class _SyncOptionsHeader extends StatelessWidget {
  const _SyncOptionsHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What syncs',
          style: TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 3),
        Text(
          'Choose what Marker is allowed to keep synced. Existing local items stay private until selected.',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 11, height: 1.35),
        ),
      ],
    ),
  );
}

class _SyncOptionBlock extends StatelessWidget {
  const _SyncOptionBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
    decoration: BoxDecoration(color: const Color(0xFF151519), borderRadius: BorderRadius.circular(14)),
    child: child,
  );
}

class _UnderlineSyncInfoBlock extends StatelessWidget {
  const _UnderlineSyncInfoBlock();

  @override
  Widget build(BuildContext context) => const _SyncOptionBlock(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(CupertinoIcons.info_circle, color: CupertinoColors.systemGrey2, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Underlines stay underlined in Marker. Margin does not have a separate underline style yet, so underlines sync to Margin as highlights.',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 11, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _SyncSelectionSwitchRow extends StatelessWidget {
  const _SyncSelectionSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _SyncOptionBlock(
    child: Row(
      children: [
        Expanded(
          child: SettingsRowText(title: title, subtitle: subtitle),
        ),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class _AtprotoDiagnosticsSection extends StatelessWidget {
  const _AtprotoDiagnosticsSection({
    required this.syncStates,
    required this.syncedRecordCounts,
    required this.deletedRecordCounts,
    required this.pendingOutbox,
    required this.selectionDiagnostics,
    required this.lastPush,
    required this.formatDateTime,
  });

  final List<AtprotoSyncStateData> syncStates;
  final Map<String, int> syncedRecordCounts;
  final Map<String, int> deletedRecordCounts;
  final List<AtprotoSyncOutboxData> pendingOutbox;
  final Map<String, int> selectionDiagnostics;
  final DateTime? lastPush;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final statesByCollection = {for (final state in syncStates) state.collection: state};
    final pendingPushes = pendingOutbox
        .where(
          (item) =>
              item.operation == AtprotoSyncOperation.create.value ||
              item.operation == AtprotoSyncOperation.update.value,
        )
        .toList();

    final pendingDeletes = pendingOutbox.where((item) => item.operation == AtprotoSyncOperation.delete.value).toList();
    final failedDeletes = pendingDeletes.where((item) => item.lastError?.trim().isNotEmpty == true).length;
    final confirmedDeletes = deletedRecordCounts.values.fold<int>(0, (total, count) => total + count);
    return _ExpandableSettingsSection(
      title: 'Sync diagnostics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _AtprotoPushSyncStatus(pendingPushes: pendingPushes, lastPush: lastPush, formatDateTime: formatDateTime),
          const SizedBox(height: 8),
          _AtprotoOutboxStatus(pendingOutbox: pendingOutbox, formatDateTime: formatDateTime),
          const SizedBox(height: 8),
          _AtprotoDeleteSyncStatus(
            pendingDeleteCount: pendingDeletes.length,
            failedDeleteCount: failedDeletes,
            confirmedDeleteCount: confirmedDeletes,
          ),
          const SizedBox(height: 8),
          _AtprotoSelectionDiagnosticsStatus(selectionDiagnostics: selectionDiagnostics),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: const Color(0xFF2A2A30),
            onPressed: () => Clipboard.setData(
              ClipboardData(
                text: _diagnosticsExportJson(
                  syncStates: syncStates,
                  syncedRecordCounts: syncedRecordCounts,
                  deletedRecordCounts: deletedRecordCounts,
                  pendingOutbox: pendingOutbox,
                  selectionDiagnostics: selectionDiagnostics,
                  lastPush: lastPush,
                ),
              ),
            ),
            child: const Text('Copy diagnostics'),
          ),
          const SizedBox(height: 8),
          for (final entry in AtprotoSyncCollections.trackedCollections.entries) ...[
            _AtprotoDiagnosticCollectionRow(
              collectionLabel: entry.value,
              collection: entry.key,
              syncState: statesByCollection[entry.key],
              syncedRecordCount: syncedRecordCounts[entry.key] ?? 0,
              deletedRecordCount: deletedRecordCounts[entry.key] ?? 0,
              formatDateTime: formatDateTime,
            ),
            if (entry.key != AtprotoSyncCollections.trackedCollections.keys.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

String _diagnosticsExportJson({
  required List<AtprotoSyncStateData> syncStates,
  required Map<String, int> syncedRecordCounts,
  required Map<String, int> deletedRecordCounts,
  required List<AtprotoSyncOutboxData> pendingOutbox,
  required Map<String, int> selectionDiagnostics,
  required DateTime? lastPush,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'lastPush': lastPush?.toUtc().toIso8601String(),
    'syncStates': [
      for (final state in syncStates)
        {
          'collection': state.collection,
          'cursor': state.cursor,
          'lastSuccessfulSyncAt': state.lastSuccessfulSyncAt?.toUtc().toIso8601String(),
          'lastError': state.lastError,
        },
    ],
    'syncedRecordCounts': syncedRecordCounts,
    'deletedRecordCounts': deletedRecordCounts,
    'selectionDiagnostics': selectionDiagnostics,
    'outbox': [
      for (final item in pendingOutbox)
        {
          'operation': item.operation,
          'localTable': item.localTable,
          'collection': item.collection,
          'createdAt': item.createdAt.toUtc().toIso8601String(),
          'updatedAt': item.updatedAt.toUtc().toIso8601String(),
          'attemptCount': item.attemptCount,
          'lastError': item.lastError,
        },
    ],
  });
}

class _AtprotoSelectionDiagnosticsStatus extends StatelessWidget {
  const _AtprotoSelectionDiagnosticsStatus({required this.selectionDiagnostics});

  final Map<String, int> selectionDiagnostics;

  @override
  Widget build(BuildContext context) {
    final selected = selectionDiagnostics.entries
        .where((entry) => entry.key.startsWith('selected:'))
        .fold<int>(0, (total, entry) => total + entry.value);
    final unselected = selectionDiagnostics.entries
        .where((entry) => entry.key.startsWith('unselected:'))
        .fold<int>(0, (total, entry) => total + entry.value);
    final blocked = selectionDiagnostics.entries
        .where((entry) => entry.key.startsWith('dependencyBlocked:'))
        .fold<int>(0, (total, entry) => total + entry.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selection', style: TextStyle(color: CupertinoColors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Text('Selected records: $selected', style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11)),
        Text(
          'Unselected local records: $unselected',
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
        ),
        Text(
          'Dependency-blocked selections: $blocked',
          style: TextStyle(
            color: blocked == 0 ? CupertinoColors.systemGrey : CupertinoColors.systemOrange,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _AtprotoPushSyncStatus extends StatelessWidget {
  const _AtprotoPushSyncStatus({required this.pendingPushes, required this.lastPush, required this.formatDateTime});

  final List<AtprotoSyncOutboxData> pendingPushes;
  final DateTime? lastPush;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final failed = pendingPushes.where((item) => item.lastError?.trim().isNotEmpty == true).toList();
    final lastError = failed.isEmpty ? null : failed.first.lastError!.trim();
    final nextRetry = _nextRetryAt(pendingPushes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Push sync', style: TextStyle(color: CupertinoColors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          'Local changes pending: ${pendingPushes.length}',
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
        ),
        Text(
          'Last push: ${formatDateTime(lastPush)}',
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
        ),
        Text(
          lastError == null ? 'Last push error: None' : 'Last push error: $lastError',
          style: TextStyle(
            color: lastError == null ? CupertinoColors.systemGrey : CupertinoColors.systemRed,
            fontSize: 11,
          ),
        ),
        if (nextRetry != null)
          Text(
            'Retrying after: ${formatDateTime(nextRetry)}',
            style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
          ),
      ],
    );
  }
}

class _AtprotoOutboxStatus extends StatelessWidget {
  const _AtprotoOutboxStatus({required this.pendingOutbox, required this.formatDateTime});

  final List<AtprotoSyncOutboxData> pendingOutbox;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final creates = pendingOutbox.where((item) => item.operation == AtprotoSyncOperation.create.value).length;
    final updates = pendingOutbox.where((item) => item.operation == AtprotoSyncOperation.update.value).length;
    final deletes = pendingOutbox.where((item) => item.operation == AtprotoSyncOperation.delete.value).length;
    final failed = pendingOutbox.where((item) => item.lastError?.trim().isNotEmpty == true).length;
    final oldest = pendingOutbox.isEmpty
        ? null
        : pendingOutbox.map((item) => item.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final nextRetry = _nextRetryAt(pendingOutbox);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Outbox', style: TextStyle(color: CupertinoColors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Text('Pending creates: $creates', style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11)),
        Text('Pending updates: $updates', style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11)),
        Text('Pending deletes: $deletes', style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11)),
        Text(
          'Failed attempts: $failed',
          style: TextStyle(color: failed == 0 ? CupertinoColors.systemGrey : CupertinoColors.systemRed, fontSize: 11),
        ),
        Text(
          'Oldest pending change: ${formatDateTime(oldest)}',
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
        ),
        if (nextRetry != null)
          Text(
            'Next retry: ${formatDateTime(nextRetry)}',
            style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
          ),
      ],
    );
  }
}

DateTime? _nextRetryAt(List<AtprotoSyncOutboxData> outbox) {
  DateTime? next;
  for (final item in outbox) {
    if (item.attemptCount <= 0) continue;
    final retryAt = item.updatedAt.add(Duration(minutes: 1 << (item.attemptCount - 1).clamp(0, 5)));
    if (next == null || retryAt.isBefore(next)) next = retryAt;
  }
  return next;
}

class _AtprotoDeleteSyncStatus extends StatelessWidget {
  const _AtprotoDeleteSyncStatus({
    required this.pendingDeleteCount,
    required this.failedDeleteCount,
    required this.confirmedDeleteCount,
  });

  final int pendingDeleteCount;
  final int failedDeleteCount;
  final int confirmedDeleteCount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Delete sync', style: TextStyle(color: CupertinoColors.white, fontSize: 12)),
      const SizedBox(height: 2),
      Text(
        'Pending deletes: $pendingDeleteCount',
        style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
      ),
      Text(
        'Failed delete attempts: $failedDeleteCount',
        style: TextStyle(
          color: failedDeleteCount == 0 ? CupertinoColors.systemGrey : CupertinoColors.systemRed,
          fontSize: 11,
        ),
      ),
      Text(
        'Confirmed remote deletes: $confirmedDeleteCount',
        style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
      ),
    ],
  );
}

class _AtprotoDiagnosticCollectionRow extends StatelessWidget {
  const _AtprotoDiagnosticCollectionRow({
    required this.collectionLabel,
    required this.collection,
    required this.syncState,
    required this.syncedRecordCount,
    required this.deletedRecordCount,
    required this.formatDateTime,
  });

  final String collectionLabel;
  final String collection;
  final AtprotoSyncStateData? syncState;
  final int syncedRecordCount;
  final int deletedRecordCount;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final lastError = syncState?.lastError?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(collectionLabel, style: const TextStyle(color: CupertinoColors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          collection,
          style: GoogleFonts.jetBrainsMono(
            color: CupertinoColors.systemGrey2,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Last successful sync: ${formatDateTime(syncState?.lastSuccessfulSyncAt)}',
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
        ),
        Text(
          'Records synced: $syncedRecordCount',
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
        ),
        Text(
          'Records deleted: $deletedRecordCount',
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11),
        ),
        Text(
          lastError == null || lastError.isEmpty ? 'Last error: None' : 'Last error: $lastError',
          style: TextStyle(
            color: lastError == null || lastError.isEmpty ? CupertinoColors.systemGrey : CupertinoColors.systemRed,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _AtprotoDetailRow extends StatelessWidget {
  const _AtprotoDetailRow({required this.label, required this.value, this.isError = false});

  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 126,
          child: Text(label, style: const TextStyle(color: CupertinoColors.systemGrey2, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: isError ? CupertinoColors.systemRed : CupertinoColors.white, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _AtprotoImportSheet extends ConsumerStatefulWidget {
  const _AtprotoImportSheet({required this.accountDid, required this.importAsLocalOnly});

  final String accountDid;
  final bool importAsLocalOnly;

  @override
  ConsumerState<_AtprotoImportSheet> createState() => _AtprotoImportSheetState();
}

class _AtprotoImportSheetState extends ConsumerState<_AtprotoImportSheet> {
  AtprotoBookmarkSyncResult? _result;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_startImport);
  }

  Future<void> _startImport() async {
    final notifier = ref.read(atprotoBookmarkImportControllerProvider.notifier);
    final result = await notifier.syncBookmarks(widget.accountDid, importAsLocalOnly: widget.importAsLocalOnly);
    if (!mounted) return;
    ref
      ..invalidate(_atprotoSyncStatesProvider(widget.accountDid))
      ..invalidate(_atprotoSyncedRecordCountsProvider(widget.accountDid))
      ..invalidate(_atprotoDeletedRecordCountsProvider(widget.accountDid))
      ..invalidate(_atprotoPendingOutboxProvider(widget.accountDid))
      ..invalidate(_atprotoSelectionDiagnosticsProvider(widget.accountDid))
      ..invalidate(_atprotoLatestMirrorSyncProvider(widget.accountDid));
    final state = ref.read(atprotoBookmarkImportControllerProvider);
    setState(() {
      _result = result;
      _failureMessage = _importFailMsg(result: result, state: state);
    });
  }

  String? _importFailMsg({required AtprotoBookmarkSyncResult? result, required AtprotoBookmarkImportState state}) {
    if (result != null) {
      return null;
    }
    if (state is AtprotoBookmarkImportFailed) {
      return state.message;
    }
    if (state is AtprotoBookmarkImportCanceled) {
      return 'Sync canceled.';
    }
    return 'Could not sync bookmarks. Check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(atprotoBookmarkImportControllerProvider);
    final progress = importState is AtprotoBookmarkImportRunning
        ? importState.progress
        : const SembleBookmarkPullProgress(completedRequests: 0, totalRequests: 5, description: 'Starting sync');

    final presentationState = _AtprotoImportPresentationState(
      result: _result,
      failureMessage: _failureMessage,
      isCanceled: importState is AtprotoBookmarkImportCanceled,
    );

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
                  presentationState.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (presentationState.isRunning) ...[
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
                    '${progress.completedRequests} of ${progress.totalRequests} requests complete',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    progress.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.white, fontSize: 14),
                  ),
                ] else if (presentationState.failureMessage != null) ...[
                  Text(
                    presentationState.failureMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 14),
                  ),
                ] else ...[
                  Text(
                    atprotoBookmarkSyncSummary(presentationState.result!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14, height: 1.35),
                  ),
                ],
                const SizedBox(height: 18),
                CupertinoButton.filled(
                  onPressed: presentationState.isRunning
                      ? () => ref.read(atprotoBookmarkImportControllerProvider.notifier).cancelSync()
                      : () => Navigator.of(context).pop(),
                  child: Text(presentationState.isRunning ? 'Cancel sync' : 'Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AtprotoImportPresentationState {
  const _AtprotoImportPresentationState({required this.result, required this.failureMessage, required this.isCanceled});

  final AtprotoBookmarkSyncResult? result;
  final String? failureMessage;
  final bool isCanceled;

  bool get isRunning => result == null && failureMessage == null && !isCanceled;

  String get title {
    if (isCanceled) return 'Sync canceled';
    if (failureMessage != null) return 'Sync failed';
    if (result != null) return 'ATProto sync complete';
    return 'Syncing ATProto';
  }
}

class _AtprotoConnectSheet extends ConsumerStatefulWidget {
  const _AtprotoConnectSheet();

  @override
  ConsumerState<_AtprotoConnectSheet> createState() => _AtprotoConnectSheetState();
}

class _AtprotoConnectSheetState extends ConsumerState<_AtprotoConnectSheet> {
  late final TextEditingController _handleController;
  Timer? _typeaheadDebounce;
  var _typeaheadGeneration = 0;
  var _suggestions = const <AtprotoActorSuggestion>[];
  var _isSearchingHandles = false;
  var _ignoreNextHandleChange = false;
  String? _selectedHandle;
  String? _handleValidationMessage;

  @override
  void initState() {
    super.initState();
    _handleController = TextEditingController()..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _typeaheadDebounce?.cancel();
    _handleController
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(atprotoLoginControllerProvider);
    final isBusy = loginState.isBusy;
    final errorMessage = loginState is AtprotoLoginFailed ? loginState.message : null;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final suggestions = _suggestions.isEmpty
        ? null
        : _AtprotoHandleSuggestions(suggestions: _suggestions, onSelected: isBusy ? null : _selectSuggestion);

    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF151519)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Connect ATProto',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Use your Bluesky or Atmosphere account to import Semble bookmarks.',
                      style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connecting an account does not publish local data. Select bookmarks or annotations for sync when you are ready. Browser history stays local.',
                      style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    if (keyboardOpen && suggestions != null) ...[suggestions, const SizedBox(height: 8)],
                    CupertinoTextField(
                      controller: _handleController,
                      enabled: !isBusy,
                      placeholder: 'alice.bsky.social',
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.url,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    ),
                    if (!keyboardOpen && suggestions != null) ...[const SizedBox(height: 8), suggestions],
                    const SizedBox(height: 6),
                    Text(
                      _isSearchingHandles
                          ? 'Looking up handles…'
                          : 'Optional. Pick a suggested handle, or leave blank to choose in the browser.',
                      style: const TextStyle(color: CupertinoColors.systemGrey2, fontSize: 12),
                    ),
                    if (_handleValidationMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _handleValidationMessage!,
                        style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13),
                      ),
                    ],
                    if (loginState is AtprotoLoginWaitingForCallback) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Waiting for sign in to finish in the browser…',
                        style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMessage, style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13)),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFF2A2A30),
                            disabledColor: const Color(0xFF2A2A30),
                            onPressed: isBusy ? null : _cancel,
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: isBusy ? null : _continue,
                            child: isBusy
                                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                : const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleChanged() {
    if (_ignoreNextHandleChange) {
      _ignoreNextHandleChange = false;
      return;
    }
    final normalized = normalizeHandle(_handleController.text);
    _typeaheadDebounce?.cancel();
    _typeaheadGeneration += 1;

    if (_selectedHandle != null && _selectedHandle != normalized) {
      _selectedHandle = null;
    }

    if (normalized == null || normalized == invalidHandleSentinel) {
      if (_suggestions.isNotEmpty || _isSearchingHandles || _handleValidationMessage != null) {
        setState(() {
          _suggestions = const <AtprotoActorSuggestion>[];
          _isSearchingHandles = false;
          _handleValidationMessage = null;
        });
      }
      return;
    }

    final generation = _typeaheadGeneration;
    _typeaheadDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_loadHandleSuggestions(normalized, generation));
    });
  }

  Future<void> _loadHandleSuggestions(String query, int generation) async {
    setState(() {
      _isSearchingHandles = true;
      _handleValidationMessage = null;
    });

    try {
      final suggestions = await ref.read(atprotoActorSearchRepositoryProvider).searchTypeahead(query);
      if (!mounted || generation != _typeaheadGeneration) return;
      setState(() {
        _suggestions = suggestions;
        _isSearchingHandles = false;
      });
    } on Object catch (error, stackTrace) {
      ref.read(appLoggerProvider).warning('Failed to search ATProto handles', error: error, stackTrace: stackTrace);
      if (!mounted || generation != _typeaheadGeneration) return;
      setState(() {
        _suggestions = const <AtprotoActorSuggestion>[];
        _isSearchingHandles = false;
        _handleValidationMessage = 'Could not look up handles. Check your connection and try again.';
      });
    }
  }

  void _selectSuggestion(AtprotoActorSuggestion suggestion) {
    _typeaheadDebounce?.cancel();
    _typeaheadGeneration += 1;
    _selectedHandle = suggestion.handle;
    _ignoreNextHandleChange = true;
    _handleController.value = TextEditingValue(
      text: suggestion.handle,
      selection: TextSelection.collapsed(offset: suggestion.handle.length),
    );
    setState(() {
      _suggestions = const <AtprotoActorSuggestion>[];
      _isSearchingHandles = false;
      _handleValidationMessage = null;
    });
  }

  String? _validatedHandleForSubmit() {
    final normalized = normalizeHandle(_handleController.text);
    if (normalized == null) {
      setState(() => _handleValidationMessage = null);
      return null;
    }
    if (normalized == invalidHandleSentinel) {
      setState(() => _handleValidationMessage = 'Enter a handle like alice.bsky.social, or leave it blank.');
      return invalidHandleSentinel;
    }
    String? exactSuggestionHandle;
    for (final suggestion in _suggestions) {
      if (suggestion.handle == normalized) {
        exactSuggestionHandle = suggestion.handle;
        break;
      }
    }
    final validatedHandle = _selectedHandle == normalized ? normalized : exactSuggestionHandle;
    if (validatedHandle == null) {
      setState(() => _handleValidationMessage = 'Choose a handle from the suggestions so Marker can verify it.');
      return invalidHandleSentinel;
    }
    setState(() => _handleValidationMessage = null);
    return validatedHandle;
  }

  void _cancel() {
    ref.read(atprotoLoginControllerProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  Future<void> _continue() async {
    final handle = _validatedHandleForSubmit();
    if (handle == invalidHandleSentinel) return;
    final navigator = Navigator.of(context);
    final promptContext = navigator.context;
    final account = await ref.read(atprotoLoginControllerProvider.notifier).connect(handle: handle);
    if (!navigator.mounted || !promptContext.mounted || account == null) return;
    navigator.pop();
    await _showImportPrompt(promptContext, account.did);
  }

  Future<void> _showImportPrompt(BuildContext context, String accountDid) async => await showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Import bookmarks now?'),
      content: const Text('Marker can pull Semble bookmarks and collections from your ATProto repo.'),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Not now')),
        CupertinoDialogAction(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await showCupertinoModalPopup<void>(
              context: context,
              barrierDismissible: false,
              builder: (sheetContext) => _AtprotoImportSheet(accountDid: accountDid, importAsLocalOnly: false),
            );
          },
          child: const Text('Import bookmarks'),
        ),
      ],
    ),
  );
}

class _AtprotoActorAvatar extends StatelessWidget {
  const _AtprotoActorAvatar({required this.suggestion});

  final AtprotoActorSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final avatar = suggestion.avatar;
    return ClipOval(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF34343B)),
        child: SizedBox.square(
          dimension: 36,
          child: avatar == null || avatar.isEmpty
              ? const Icon(CupertinoIcons.person_fill, size: 18, color: CupertinoColors.systemGrey2)
              : Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(CupertinoIcons.person_fill, size: 18, color: CupertinoColors.systemGrey2),
                ),
        ),
      ),
    );
  }
}

class _AtprotoHandleSuggestions extends StatelessWidget {
  const _AtprotoHandleSuggestions({required this.suggestions, required this.onSelected});

  final List<AtprotoActorSuggestion> suggestions;
  final ValueChanged<AtprotoActorSuggestion>? onSelected;

  static const double _rowHeight = 58.0;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF202026),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF33333A)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _rowHeight * 3),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => Container(height: 0.5, color: const Color(0xFF33333A)),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return SizedBox(
              height: _rowHeight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onSelected == null ? null : () => onSelected!(suggestion),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _AtprotoActorAvatar(suggestion: suggestion),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${suggestion.handle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (suggestion.displayName?.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                suggestion.displayName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: CupertinoColors.systemGrey2, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
