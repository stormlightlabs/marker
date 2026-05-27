import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/features/atproto/application/atproto_login_controller.dart';
import 'package:marker/features/atproto/application/bookmark_import_controller.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/data/semble_bookmark_pull_service.dart';
import 'package:marker/features/atproto/domain/atproto_account_session.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adBlockEnabled = ref.watch(adBlockEnabledProvider).value ?? true;
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
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Column(
                        children: [
                          _SettingsSwitchRow(
                            icon: CupertinoIcons.shield_lefthalf_fill,
                            title: 'Ad Blocker',
                            subtitle: 'Block EasyList ads while browsing',
                            value: adBlockEnabled,
                            onChanged: (value) {
                              ref.read(adBlockEnabledProvider.notifier).setEnabled(value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _SettingsLinkRow(
                            icon: CupertinoIcons.clock,
                            title: 'Browser History',
                            subtitle: 'Recent page visits and clear history',
                            onPressed: () => context.pushNamed(AppRoute.history.routeName),
                          ),
                          const SizedBox(height: 22),
                          const _SettingsSectionLabel('Sync'),
                          const SizedBox(height: 8),
                          _AtprotoAccountRow(state: atprotoAuthState),
                          const SizedBox(height: 22),
                          const _SettingsSectionLabel('Advanced'),
                          const SizedBox(height: 8),
                          _SettingsLinkRow(
                            icon: CupertinoIcons.doc_text_search,
                            title: 'Logs',
                            subtitle: 'View, filter, and download diagnostic logs',
                            onPressed: () => context.pushNamed(AppRoute.logs.routeName),
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

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: CupertinoColors.systemGrey,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
  );
}

class _SettingsLinkRow extends StatelessWidget {
  const _SettingsLinkRow({required this.icon, required this.title, required this.subtitle, required this.onPressed});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _SettingsRowFrame(
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.activeBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: _SettingsRowText(title: title, subtitle: subtitle),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey, size: 17),
          ],
        ),
      ),
    ),
  );
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _SettingsRowFrame(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.activeBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _SettingsRowText(title: title, subtitle: subtitle),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}

class _SettingsRowText extends StatelessWidget {
  const _SettingsRowText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: CupertinoColors.white, fontSize: 16, letterSpacing: 0)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, letterSpacing: 0)),
    ],
  );
}

class _SettingsRowFrame extends StatelessWidget {
  const _SettingsRowFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF151519),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
    ),
    child: child,
  );
}

final _atprotoAuthStateProvider = StreamProvider<AtprotoAuthState>((ref) {
  return ref.watch(atprotoAuthRepositoryProvider).watchAuthState();
});

final _atprotoSyncStatesProvider = FutureProvider.family<List<AtprotoSyncStateData>, String>((ref, accountDid) {
  return ref.watch(atprotoSyncRepositoryProvider).syncStatesForAccount(accountDid);
});

class _AtprotoAccountRow extends ConsumerWidget {
  const _AtprotoAccountRow({required this.state});

  final AtprotoAuthState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state case AtprotoAuthConnected(:final account)) {
      return _ConnectedAtprotoAccountCard(account: account);
    }

    return _SettingsRowFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            const Icon(CupertinoIcons.cloud, color: CupertinoColors.activeBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: _SettingsRowText(title: 'ATProto Sync', subtitle: _subtitle),
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

class _ConnectedAtprotoAccountCard extends ConsumerWidget {
  const _ConnectedAtprotoAccountCard({required this.account});

  final AtprotoAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStates = ref.watch(_atprotoSyncStatesProvider(account.did)).value ?? const <AtprotoSyncStateData>[];
    final importState = ref.watch(atprotoBookmarkImportControllerProvider);
    final lastImport = _latestSuccessfulSync(syncStates);
    final lastError = _latestError(syncStates);
    final isImporting = importState.isImporting;

    return _SettingsRowFrame(
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
                  child: _SettingsRowText(title: 'ATProto Sync', subtitle: 'Connected as ${_accountLabel(account)}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Bookmark sync writes Semble/Cosmik bookmark records to your ATProto repo. Browser history stays local. Annotation sync is separate and off by default.',
              style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
            _AtprotoDetailRow(label: 'Account DID', value: account.did),
            if (account.handle?.trim().isNotEmpty == true)
              _AtprotoDetailRow(label: 'Handle', value: '@${account.handle!.trim()}'),
            if (account.pdsEndpoint?.trim().isNotEmpty == true)
              _AtprotoDetailRow(label: 'PDS endpoint', value: account.pdsEndpoint!.trim()),
            _AtprotoDetailRow(label: 'Last bookmark import', value: _formatDateTime(lastImport)),
            if (lastError != null) _AtprotoDetailRow(label: 'Last error', value: lastError, isError: true),
            const SizedBox(height: 12),
            _AtprotoDiagnosticsSection(syncStates: syncStates, formatDateTime: _formatDateTime),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    color: const Color(0xFF2A2A30),
                    disabledColor: const Color(0xFF2A2A30),
                    onPressed: isImporting ? null : () => _importBookmarks(context, ref),
                    child: isImporting
                        ? const FittedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoActivityIndicator(color: CupertinoColors.white),
                                SizedBox(width: 8),
                                Text('Importing bookmarks...'),
                              ],
                            ),
                          )
                        : const Text('Import bookmarks'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    color: CupertinoColors.systemRed,
                    onPressed: () => _confirmDisconnect(context, ref),
                    child: const Text('Disconnect'),
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

  Future<void> _importBookmarks(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(atprotoBookmarkImportControllerProvider.notifier).importBookmarks(account.did);
    ref.invalidate(_atprotoSyncStatesProvider(account.did));
    if (!context.mounted) return;
    if (result == null) {
      final state = ref.read(atprotoBookmarkImportControllerProvider);
      final message = state is AtprotoBookmarkImportFailed
          ? state.message
          : 'Could not import bookmarks. Check your connection and try again.';
      await _showImportFailureDialog(context, message);
      return;
    }
    await _showImportResultDialog(context, result);
  }

  Future<void> _showImportResultDialog(BuildContext context, SembleBookmarkPullResult result) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Bookmark import complete'),
        content: Text(sembleBookmarkPullSummary(result)),
        actions: [
          if (sembleBookmarkPullHasIssues(result))
            CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('View sync issues')),
          CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showImportFailureDialog(BuildContext context, String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Import failed'),
        content: Text(message),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK'))],
      ),
    );
  }
}

class _AtprotoDiagnosticsSection extends StatelessWidget {
  const _AtprotoDiagnosticsSection({required this.syncStates, required this.formatDateTime});

  final List<AtprotoSyncStateData> syncStates;
  final String Function(DateTime? value) formatDateTime;

  static const _trackedCollections = <String, String>{
    sembleCardCollection: 'Cards / bookmarks',
    sembleCollectionCollection: 'Collections / folders',
    sembleCollectionLinkCollection: 'Collection links',
  };

  @override
  Widget build(BuildContext context) {
    final statesByCollection = {for (final state in syncStates) state.collection: state};
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync diagnostics',
              style: TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Protocol state only. Tokens, keys, OAuth context, and refresh material are never shown.',
              style: TextStyle(color: CupertinoColors.systemGrey2, fontSize: 11, height: 1.25),
            ),
            const SizedBox(height: 8),
            for (final entry in _trackedCollections.entries) ...[
              _AtprotoDiagnosticCollectionRow(
                collectionLabel: entry.value,
                collection: entry.key,
                syncState: statesByCollection[entry.key],
                formatDateTime: formatDateTime,
              ),
              if (entry.key != _trackedCollections.keys.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AtprotoDiagnosticCollectionRow extends StatelessWidget {
  const _AtprotoDiagnosticCollectionRow({
    required this.collectionLabel,
    required this.collection,
    required this.syncState,
    required this.formatDateTime,
  });

  final String collectionLabel;
  final String collection;
  final AtprotoSyncStateData? syncState;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final lastError = syncState?.lastError?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(collectionLabel, style: const TextStyle(color: CupertinoColors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Text(collection, style: const TextStyle(color: CupertinoColors.systemGrey2, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          'Last successful sync: ${formatDateTime(syncState?.lastSuccessfulSyncAt)}',
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

class _AtprotoConnectSheet extends ConsumerStatefulWidget {
  const _AtprotoConnectSheet();

  @override
  ConsumerState<_AtprotoConnectSheet> createState() => _AtprotoConnectSheetState();
}

class _AtprotoConnectSheetState extends ConsumerState<_AtprotoConnectSheet> {
  late final TextEditingController _handleController;

  @override
  void initState() {
    super.initState();
    _handleController = TextEditingController();
  }

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(atprotoLoginControllerProvider);
    final isBusy = loginState.isBusy;
    final errorMessage = loginState is AtprotoLoginFailed ? loginState.message : null;

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
                    'Use your Bluesky or Atmosphere account to import Semble/Cosmik bookmarks.',
                    style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bookmark sync publishes bookmark records to your ATProto repo. Browser history stays local.',
                    style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 6),
                  const Text(
                    'Optional. Leave blank to choose an account in the browser.',
                    style: TextStyle(color: CupertinoColors.systemGrey2, fontSize: 12),
                  ),
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
    );
  }

  void _cancel() {
    ref.read(atprotoLoginControllerProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  Future<void> _continue() async {
    final account = await ref.read(atprotoLoginControllerProvider.notifier).connect(handle: _handleController.text);
    if (!mounted || account == null) return;
    Navigator.of(context).pop();
    await _showImportPrompt(context, account.did);
  }

  Future<void> _showImportPrompt(BuildContext context, String accountDid) async => await showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Import bookmarks now?'),
      content: const Text('Marker can pull Semble/Cosmik bookmarks and collections from your ATProto repo.'),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Not now')),
        CupertinoDialogAction(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            final result = await ref.read(atprotoBookmarkImportControllerProvider.notifier).importBookmarks(accountDid);
            if (!context.mounted) return;
            if (result == null) {
              await _showImportFailure(context);
              return;
            }
            await _showImportResult(context, result);
          },
          child: const Text('Import bookmarks'),
        ),
      ],
    ),
  );

  Future<void> _showImportFailure(BuildContext context) async => showCupertinoDialog<void>(
    context: context,
    builder: (failureContext) => CupertinoAlertDialog(
      title: const Text('Import failed'),
      content: const Text('Could not import bookmarks. Check your connection and try again.'),
      actions: [CupertinoDialogAction(onPressed: () => Navigator.of(failureContext).pop(), child: const Text('OK'))],
    ),
  );

  Future<void> _showImportResult(BuildContext context, SembleBookmarkPullResult result) async => showCupertinoDialog<void>(
    context: context,
    builder: (resultContext) => CupertinoAlertDialog(
      title: const Text('Bookmark import complete'),
      content: Text(sembleBookmarkPullSummary(result)),
      actions: [
        if (sembleBookmarkPullHasIssues(result))
          CupertinoDialogAction(onPressed: () => Navigator.of(resultContext).pop(), child: const Text('View sync issues')),
        CupertinoDialogAction(onPressed: () => Navigator.of(resultContext).pop(), child: const Text('OK')),
      ],
    ),
  );
}
