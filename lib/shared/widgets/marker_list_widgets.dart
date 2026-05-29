import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:marker/core/widgets/funnotation.dart';

class MarkerGroupFrame extends StatelessWidget {
  const MarkerGroupFrame({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151519),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
      ),
      child: Column(children: children),
    ),
  );
}

class MarkerSectionFrame extends StatelessWidget {
  const MarkerSectionFrame({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Funnotation(
            color: CupertinoColors.systemYellow,
            strokeWidth: 1.4,
            padding: 2,
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF151519),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class MarkerRowButton extends StatelessWidget {
  const MarkerRowButton({
    required this.onPressed,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.titleWidget,
    this.trailing = const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey2, size: 17),
    this.backgroundColor,
    this.onLongPress,
    super.key,
  });

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? titleWidget;
  final Widget? trailing;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    onLongPress: onLongPress,
    child: Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(bottom: BorderSide(color: Color(0xFF26262C), width: 0.5)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                titleWidget ??
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, letterSpacing: 0),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    ),
  );
}

class MarkerIconTile extends StatelessWidget {
  const MarkerIconTile({required this.icon, required this.color, this.child, this.opacity = 0.2, super.key});

  final IconData icon;
  final Color color;
  final Widget? child;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: child ?? Icon(icon, color: color, size: 19),
  );
}

class MarkerFaviconFrame extends StatelessWidget {
  const MarkerFaviconFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: const Color(0xFF24242A), borderRadius: BorderRadius.circular(8)),
    child: child,
  );
}

class MarkerDomainPlaceholder extends StatelessWidget {
  const MarkerDomainPlaceholder({required this.host, required this.icon, required this.color, super.key});

  final String host;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = markerDomainInitial(host);
    return MarkerIconTile(
      icon: icon,
      color: color,
      child: initial == null
          ? Icon(icon, color: color, size: 19)
          : Text(
              initial,
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0),
            ),
    );
  }
}

class MarkerFileFavicon extends StatelessWidget {
  const MarkerFileFavicon({
    required this.filePath,
    required this.fallbackHost,
    required this.fallbackIcon,
    required this.fallbackColor,
    super.key,
  });

  final String? filePath;
  final String fallbackHost;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final path = filePath;
    if (path == null) {
      return MarkerDomainPlaceholder(host: fallbackHost, icon: fallbackIcon, color: fallbackColor);
    }
    return MarkerFaviconFrame(
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            MarkerDomainPlaceholder(host: fallbackHost, icon: fallbackIcon, color: fallbackColor),
      ),
    );
  }
}

String? markerDomainInitial(String host) {
  final normalizedHost = host.trim();
  if (normalizedHost.isEmpty) {
    return null;
  }
  final domain = normalizedHost.startsWith('www.') ? normalizedHost.substring(4) : normalizedHost;
  return domain.substring(0, 1).toUpperCase();
}
