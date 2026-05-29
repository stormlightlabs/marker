import 'package:flutter/cupertino.dart';

class MarkerTransitionPage<T> extends CupertinoPage<T> {
  const MarkerTransitionPage({required super.child, super.key});

  @override
  Route<T> createRoute(BuildContext context) => _MarkerPageRoute<T>(page: this);
}

class MarkerTabPage<T> extends Page<T> {
  const MarkerTabPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
    settings: this,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

class _MarkerPageRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  _MarkerPageRoute({required MarkerTransitionPage<T> page}) : super(settings: page) {
    assert(opaque);
  }

  static const _transitionDuration = Duration(milliseconds: 260);
  static const _reverseTransitionDuration = Duration(milliseconds: 210);

  MarkerTransitionPage<T> get _page => settings as MarkerTransitionPage<T>;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Duration get reverseTransitionDuration => _reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => CupertinoPageTransition.delegatedTransition;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  String? get title => _page.title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;
}

class MarkerAnimatedContent extends StatelessWidget {
  const MarkerAnimatedContent({required this.child, this.duration = const Duration(milliseconds: 220), super.key});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
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
