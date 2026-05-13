import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class MarkerTransitionPage<T> extends CustomTransitionPage<T> {
  const MarkerTransitionPage({required super.child, super.key})
    : super(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 210),
        transitionsBuilder: _buildTransition,
      );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final offset = Tween<Offset>(begin: const Offset(0.035, 0), end: Offset.zero).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: offset, child: child),
    );
  }
}

class MarkerAnimatedContent extends StatelessWidget {
  const MarkerAnimatedContent({required this.child, this.duration = const Duration(milliseconds: 220), super.key});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}
