import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/features/browser/application/reader_controller.dart';
import 'package:marker/features/settings/data/browser_history_repository.dart';

class BrowserHistoryScreen extends ConsumerWidget {
  const BrowserHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(browserHistoryProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('History'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _confirmClear(context, ref),
          child: const Text('Clear'),
        ),
      ),
      child: SafeArea(
        child: history.when(
          data: (items) => items.isEmpty
              ? const Center(
                  child: Text(
                    'No browser history',
                    style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15, letterSpacing: 0),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _HistoryRow(item: item, onPressed: () => _openHistoryItem(context, ref, item.url));
                  },
                ),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              error.toString(),
              style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13, letterSpacing: 0),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final shouldClear = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Clear History?'),
          content: const Text('This removes browser visit history from this device. Saved pages and annotations stay.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }
    await ref.read(browserHistoryRepositoryProvider).clearHistory();
    ref.invalidate(browserHistoryProvider);
  }

  void _openHistoryItem(BuildContext context, WidgetRef ref, Uri url) {
    ref.read(readerControllerProvider.notifier).setUrlText(url.toString());
    context.goNamed(AppRoute.browser.routeName);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.onPressed});

  final BrowserHistoryItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF151519),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Row(
            children: [
              const Icon(CupertinoIcons.globe, color: CupertinoColors.systemTeal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: CupertinoColors.white, fontSize: 15, letterSpacing: 0),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, letterSpacing: 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
