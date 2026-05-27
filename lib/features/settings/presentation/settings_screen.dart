import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/features/atproto/application/atproto_login_controller.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
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

class _AtprotoAccountRow extends ConsumerWidget {
  const _AtprotoAccountRow({required this.state});

  final AtprotoAuthState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            if (state case AtprotoAuthConnected(:final account))
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => ref.read(atprotoAuthRepositoryProvider).disconnect(account.did),
                child: const Text('Disconnect'),
              )
            else
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
    AtprotoAuthConnected(:final account) => 'Connected as ${account.handle ?? account.did}',
    AtprotoAuthFailure(:final message) => message,
    AtprotoAuthDisconnected() => 'Connect a Bluesky or Atmosphere account',
  };

  Future<void> _showConnectSheet(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => const _AtprotoConnectSheet(),
    );
  }
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
    await _showImportPrompt(context);
  }

  Future<void> _showImportPrompt(BuildContext context) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Import bookmarks now?'),
        content: const Text('Marker can pull Semble/Cosmik bookmarks and collections from your ATProto repo.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Not now')),
          CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Import bookmarks')),
        ],
      ),
    );
  }
}
