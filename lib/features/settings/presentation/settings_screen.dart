import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
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
                onPressed: () => _showConnectDialog(context, ref),
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

  Future<void> _showConnectDialog(BuildContext context, WidgetRef ref) async {
    final handleController = TextEditingController();
    final callbackController = TextEditingController();
    Uri? authUrl;
    String? error;

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => CupertinoAlertDialog(
          title: const Text('Connect ATProto'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(controller: handleController, placeholder: 'handle.bsky.social (optional)'),
              const SizedBox(height: 8),
              if (authUrl != null) ...[
                const Text('Open this URL in your browser, then paste the callback URL below.'),
                const SizedBox(height: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Clipboard.setData(ClipboardData(text: authUrl.toString())),
                  child: const Text('Copy authorization URL'),
                ),
                CupertinoTextField(controller: callbackController, placeholder: 'Callback URL'),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: CupertinoColors.systemRed)),
              ],
            ],
          ),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            if (authUrl == null)
              CupertinoDialogAction(
                onPressed: () async {
                  try {
                    final url = await ref
                        .read(atprotoAuthRepositoryProvider)
                        .startConnect(handle: handleController.text);
                    setState(() {
                      authUrl = url;
                      error = null;
                    });
                  } catch (exception) {
                    setState(() => error = exception.toString());
                  }
                },
                child: const Text('Start'),
              )
            else
              CupertinoDialogAction(
                onPressed: () async {
                  try {
                    await ref.read(atprotoAuthRepositoryProvider).completeConnect(callbackController.text);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  } catch (exception) {
                    setState(() => error = exception.toString());
                  }
                },
                child: const Text('Complete'),
              ),
          ],
        ),
      ),
    );
  }
}
