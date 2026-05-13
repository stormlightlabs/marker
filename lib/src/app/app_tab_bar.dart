import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/src/app/routes.dart';

class MarkerTabBar extends StatelessWidget {
  const MarkerTabBar({required this.activeRoute, super.key});

  final AppRoute activeRoute;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF111114),
        border: Border(top: BorderSide(color: Color(0xFF2A2A30), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              Expanded(
                child: _TabBarItem(
                  icon: CupertinoIcons.collections,
                  label: 'Library',
                  isActive: activeRoute == AppRoute.library,
                  onPressed: () => context.goNamed(AppRoute.library.routeName),
                ),
              ),
              Expanded(
                child: _TabBarItem(
                  icon: CupertinoIcons.globe,
                  label: 'Browser',
                  isActive: activeRoute == AppRoute.browser,
                  onPressed: () => context.goNamed(AppRoute.browser.routeName),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({required this.icon, required this.label, required this.isActive, required this.onPressed});

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isActive ? null : onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 11, letterSpacing: 0)),
          ],
        ),
      ),
    );
  }
}
