import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

class BrowserActionSheetRow extends StatelessWidget {
  const BrowserActionSheetRow({required this.icon, required this.title, required this.subtitle, super.key});

  factory BrowserActionSheetRow.create(IconData icon, String title, String subtitle) {
    return BrowserActionSheetRow(icon: icon, title: title, subtitle: subtitle);
  }

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: CupertinoColors.activeBlue),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    ],
  );
}

class BrowserAddressBar extends StatelessWidget {
  const BrowserAddressBar({
    required this.controller,
    required this.focusNode,
    required this.canGoBack,
    required this.canGoForward,
    required this.isBookmarked,
    required this.isLoading,
    required this.isTypingAddress,
    required this.tabCount,
    required this.onBackPressed,
    required this.onForwardPressed,
    required this.onRefreshPressed,
    required this.onStopLoadingPressed,
    required this.onClearAddressPressed,
    required this.onBookmarkPressed,
    required this.onTabsPressed,
    required this.onMenuPressed,
    required this.onChanged,
    required this.onSubmitted,
    required this.onGoPressed,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canGoBack;
  final bool canGoForward;
  final bool isBookmarked;
  final bool isLoading;
  final bool isTypingAddress;
  final int tabCount;
  final VoidCallback onBackPressed;
  final VoidCallback onForwardPressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onStopLoadingPressed;
  final VoidCallback onClearAddressPressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onTabsPressed;
  final VoidCallback onMenuPressed;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onGoPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            BrowserIconButton.create(CupertinoIcons.back, 'Back', canGoBack, onBackPressed),
            BrowserIconButton.create(CupertinoIcons.forward, 'Forward', canGoForward, onForwardPressed),
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                autocorrect: false,
                clearButtonMode: OverlayVisibilityMode.never,
                keyboardType: TextInputType.url,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                placeholder: 'Enter URL',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemGrey, size: 13),
                ),
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 30),
                    onPressed: isTypingAddress
                        ? onClearAddressPressed
                        : isLoading
                        ? onStopLoadingPressed
                        : onRefreshPressed,
                    child: Icon(
                      isTypingAddress
                          ? CupertinoIcons.xmark_circle_fill
                          : isLoading
                          ? CupertinoIcons.xmark
                          : CupertinoIcons.refresh,
                      color: isTypingAddress ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                      size: 17,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLoading ? CupertinoColors.activeBlue : const Color(0xFF33333A),
                    width: isLoading ? 1.5 : 0.5,
                  ),
                ),
                style: const TextStyle(color: CupertinoColors.label, fontSize: 15, letterSpacing: 0),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 10),
              minimumSize: const Size(34, 34),
              onPressed: onGoPressed,
              child: const Icon(CupertinoIcons.arrow_right, size: 21),
            ),
            BrowserIconButton.create(Icons.more_vert, 'Browser Menu', true, onMenuPressed),
          ],
        ),
      ],
    ),
  );
}

class BrowserBottomActionBar extends StatelessWidget {
  const BrowserBottomActionBar({
    required this.isBookmarked,
    required this.tabCount,
    required this.onBookmarkPressed,
    required this.onTabsPressed,
    super.key,
  });

  final bool isBookmarked;
  final int tabCount;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onTabsPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('browser-bottom-action-bar'),
    decoration: const BoxDecoration(
      color: Color(0xFF0F0F13),
      border: Border(top: BorderSide(color: Color(0xFF2A2A30), width: 0.5)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      child: Row(
        children: [
          if (isBookmarked)
            BrowserChromeChip.create(CupertinoIcons.bookmark_fill, 'Saved', onBookmarkPressed)
          else
            BrowserChromeChip.create(CupertinoIcons.bookmark, 'Save', onBookmarkPressed),
          const Spacer(),
          BrowserChromeChip.create(CupertinoIcons.square_on_square, 'Tabs $tabCount', onTabsPressed),
        ],
      ),
    ),
  );
}

class BrowserIconButton extends StatelessWidget {
  const BrowserIconButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  factory BrowserIconButton.create(IconData icon, String label, bool isEnabled, VoidCallback onPressed) {
    return BrowserIconButton(icon: icon, label: label, isEnabled: isEnabled, onPressed: onPressed);
  }

  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: isEnabled,
    label: label,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(34, 34),
      onPressed: isEnabled ? onPressed : null,
      child: Icon(icon, color: isEnabled ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray, size: 22),
    ),
  );
}

class BrowserChromeChip extends StatelessWidget {
  const BrowserChromeChip({required this.icon, required this.label, required this.onPressed, super.key});

  factory BrowserChromeChip.create(IconData icon, String label, VoidCallback onPressed) {
    return BrowserChromeChip(icon: icon, label: label, onPressed: onPressed);
  }

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: const Size(0, 30),
      color: const Color(0xFF1C1C20),
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: CupertinoColors.activeBlue),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.white, letterSpacing: 0)),
        ],
      ),
    ),
  );
}

class BrowserProgressBar extends StatelessWidget {
  const BrowserProgressBar({required this.progress, super.key});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0, 100);
    return SizedBox(
      key: const ValueKey('reader-progress-bar'),
      height: 3,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clampedProgress == 0 ? 0.08 : clampedProgress / 100,
          child: const ColoredBox(color: CupertinoColors.activeBlue),
        ),
      ),
    );
  }
}

class BrowserErrorBanner extends StatelessWidget {
  const BrowserErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.systemRed.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(message, style: const TextStyle(color: CupertinoColors.white, fontSize: 13, letterSpacing: 0)),
    ),
  );
}
