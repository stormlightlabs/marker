import 'package:flutter/cupertino.dart';
import 'package:marker/core/widgets/funnotation.dart';
import 'package:marker/features/browser/application/selection_capture_controller.dart';

class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({
    required this.capture,
    required this.onHighlightPressed,
    required this.onNotePressed,
    required this.onUnderlinePressed,
    required this.onRemovePressed,
    super.key,
  });

  final SelectionCapture capture;
  final VoidCallback onHighlightPressed;
  final VoidCallback onNotePressed;
  final VoidCallback onUnderlinePressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF21A1A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF33333A), width: 0.5),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                capture.exact,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: CupertinoColors.systemGrey2, fontSize: 12, letterSpacing: 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnnotationToolbarButton(
                    icon: CupertinoIcons.pencil,
                    label: 'Highlight',
                    color: CupertinoColors.systemYellow,
                    onPressed: onHighlightPressed,
                  ),
                  const _ToolbarDivider(),
                  _AnnotationToolbarButton(
                    icon: CupertinoIcons.chat_bubble_text,
                    label: 'Note',
                    color: CupertinoColors.white,
                    onPressed: onNotePressed,
                  ),
                  const _ToolbarDivider(),
                  _AnnotationToolbarButton(
                    icon: CupertinoIcons.underline,
                    label: 'Underline',
                    color: CupertinoColors.systemTeal,
                    onPressed: onUnderlinePressed,
                  ),
                  const _ToolbarDivider(),
                  _AnnotationToolbarButton(
                    icon: CupertinoIcons.trash,
                    label: 'Remove',
                    color: CupertinoColors.systemRed,
                    onPressed: onRemovePressed,
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

class _AnnotationToolbarButton extends StatelessWidget {
  const _AnnotationToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      minimumSize: const Size(62, 54),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Funnotation(
            kind: label == 'Remove' ? FunnotationKind.box : FunnotationKind.underline,
            color: color,
            strokeWidth: 1.2,
            padding: 2,
            child: Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 11, letterSpacing: 0)),
          ),
        ],
      ),
    ),
  );
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 42,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF33333A))),
      ),
    ),
  );
}
