import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/settings/data/settings_repository.dart';
import 'package:rough_notation/rough_notation.dart';

class Funnotation extends ConsumerWidget {
  const Funnotation({
    required this.child,
    this.color = CupertinoColors.activeBlue,
    this.strokeWidth = 2,
    this.padding = 3,
    this.iterations = 2,
    super.key,
  });

  final Widget child;
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

    return RoughUnderlineAnnotation(
      color: color,
      strokeWidth: strokeWidth,
      padding: padding,
      iterations: iterations,
      child: child,
    );
  }
}
