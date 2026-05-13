import 'package:flutter/cupertino.dart';

enum EdgeSwipeDirection { back, forward }

class EdgeSwipeNavigator extends StatefulWidget {
  const EdgeSwipeNavigator({
    required this.child,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    this.edgeWidth = 28,
    this.distanceThreshold = 72,
    this.velocityThreshold = 700,
    super.key,
  });

  final Widget child;
  final bool canGoBack;
  final bool canGoForward;
  final Future<void> Function() onBack;
  final Future<void> Function() onForward;
  final double edgeWidth;
  final double distanceThreshold;
  final double velocityThreshold;

  @override
  State<EdgeSwipeNavigator> createState() => _EdgeSwipeNavigatorState();
}

class _EdgeSwipeNavigatorState extends State<EdgeSwipeNavigator> {
  EdgeSwipeDirection? _activeDirection;
  double _dragDistance = 0;
  bool _cancelledByVerticalDrag = false;

  double get _progress => (_dragDistance.abs() / widget.distanceThreshold).clamp(0, 1);

  void _start(EdgeSwipeDirection direction) {
    setState(() {
      _activeDirection = direction;
      _dragDistance = 0;
      _cancelledByVerticalDrag = false;
    });
  }

  void _update(DragUpdateDetails details) {
    if (_activeDirection == null || _cancelledByVerticalDrag) {
      return;
    }

    final delta = details.delta;
    if (delta.dy.abs() > delta.dx.abs() * 1.2) {
      setState(() {
        _cancelledByVerticalDrag = true;
        _dragDistance = 0;
      });
      return;
    }

    setState(() {
      _dragDistance += delta.dx;
    });
  }

  void _end(DragEndDetails details) {
    final direction = _activeDirection;
    if (direction == null) {
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final shouldNavigate = !_cancelledByVerticalDrag && _meetsThreshold(direction, velocity);
    setState(() {
      _activeDirection = null;
      _dragDistance = 0;
      _cancelledByVerticalDrag = false;
    });

    if (!shouldNavigate) {
      return;
    }
    if (direction == EdgeSwipeDirection.back) {
      widget.onBack();
    } else {
      widget.onForward();
    }
  }

  bool _meetsThreshold(EdgeSwipeDirection direction, double velocity) {
    return switch (direction) {
      EdgeSwipeDirection.back => _dragDistance > widget.distanceThreshold || velocity > widget.velocityThreshold,
      EdgeSwipeDirection.forward => _dragDistance < -widget.distanceThreshold || velocity < -widget.velocityThreshold,
    };
  }

  void _cancel() {
    if (_activeDirection == null) {
      return;
    }
    setState(() {
      _activeDirection = null;
      _dragDistance = 0;
      _cancelledByVerticalDrag = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.canGoBack)
          _EdgeGestureBand(
            alignment: Alignment.centerLeft,
            width: widget.edgeWidth,
            onStart: () => _start(EdgeSwipeDirection.back),
            onUpdate: _update,
            onEnd: _end,
            onCancel: _cancel,
          ),
        if (widget.canGoForward)
          _EdgeGestureBand(
            alignment: Alignment.centerRight,
            width: widget.edgeWidth,
            onStart: () => _start(EdgeSwipeDirection.forward),
            onUpdate: _update,
            onEnd: _end,
            onCancel: _cancel,
          ),
        if (_activeDirection != null && !_cancelledByVerticalDrag)
          _EdgeSwipeAffordance(direction: _activeDirection!, progress: _progress),
      ],
    );
  }
}

class _EdgeGestureBand extends StatelessWidget {
  const _EdgeGestureBand({
    required this.alignment,
    required this.width,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final Alignment alignment;
  final double width;
  final VoidCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => onStart(),
          onHorizontalDragUpdate: onUpdate,
          onHorizontalDragEnd: onEnd,
          onHorizontalDragCancel: onCancel,
        ),
      ),
    );
  }
}

class _EdgeSwipeAffordance extends StatelessWidget {
  const _EdgeSwipeAffordance({required this.direction, required this.progress});

  final EdgeSwipeDirection direction;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final isBack = direction == EdgeSwipeDirection.back;
    return Align(
      alignment: isBack ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(left: isBack ? 12 : 0, right: isBack ? 0 : 12),
        child: Opacity(
          opacity: 0.25 + (progress * 0.75),
          child: Transform.translate(
            offset: Offset(isBack ? progress * 18 : -progress * 18, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xE61C1C20),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(
                  isBack ? CupertinoIcons.chevron_back : CupertinoIcons.chevron_forward,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
