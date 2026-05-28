import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/settings/data/settings_repository.dart';
import 'package:rough_notation/rough_notation.dart';

enum FunnotationKind { underline, box, circle, highlight }

class Funnotation extends ConsumerWidget {
  const Funnotation({
    required this.child,
    required this.kind,
    this.color = CupertinoColors.activeBlue,
    this.strokeWidth = 2,
    this.padding = 3,
    this.iterations = 2,
    super.key,
  });

  final Widget child;
  final FunnotationKind kind;
  final Color color;
  final double strokeWidth;
  final double padding;
  final int iterations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funEnabled = ref.watch(funEnabledProvider).value ?? true;
    if (!funEnabled) {
      return child;
    }

    return switch (kind) {
      FunnotationKind.underline => RoughUnderlineAnnotation(
        color: color,
        strokeWidth: strokeWidth,
        padding: padding,
        iterations: iterations,
        child: child,
      ),
      FunnotationKind.box => RoughBoxAnnotation(
        color: color,
        strokeWidth: strokeWidth,
        padding: padding,
        iterations: iterations,
        child: child,
      ),
      FunnotationKind.circle => RoughCircleAnnotation(
        color: color,
        strokeWidth: strokeWidth,
        padding: padding,
        iterations: iterations,
        child: child,
      ),
      FunnotationKind.highlight => RoughHighlightAnnotation(
        color: color,
        padding: padding,
        iterations: iterations,
        child: child,
      ),
    };
  }
}
