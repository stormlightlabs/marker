import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';

typedef AnnotationSidebarAction = Future<void> Function(PageAnnotation annotation);

final annotationSidebarOpenProvider = NotifierProvider<AnnotationSidebarOpenController, bool>(
  AnnotationSidebarOpenController.new,
);

class AnnotationSidebarOpenController extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;

  void close() => state = false;
}

enum AnnotationSidebarFilter {
  all('All'),
  highlights('Highlights'),
  notes('Notes'),
  underlines('Underlines');

  const AnnotationSidebarFilter(this.label);

  final String label;

  bool matches(PageAnnotation annotation) => switch (this) {
    AnnotationSidebarFilter.all => true,
    AnnotationSidebarFilter.highlights =>
      annotation.annotation.motivation == 'highlighting' && annotation.visualStyle == AnnotationVisualStyle.highlight,
    AnnotationSidebarFilter.notes => annotation.note != null || annotation.annotation.motivation == 'commenting',
    AnnotationSidebarFilter.underlines => annotation.visualStyle == AnnotationVisualStyle.underline,
  };
}

class AnnotationSidebarWidget extends ConsumerStatefulWidget {
  const AnnotationSidebarWidget({
    required this.sourceUrl,
    required this.onEdit,
    required this.onJump,
    required this.onDelete,
    super.key,
  });

  final Uri? sourceUrl;
  final AnnotationSidebarAction onEdit;
  final AnnotationSidebarAction onJump;
  final AnnotationSidebarAction onDelete;

  @override
  ConsumerState<AnnotationSidebarWidget> createState() => _AnnotationSidebarWidgetState();
}

class _AnnotationSidebarWidgetState extends ConsumerState<AnnotationSidebarWidget> {
  String? _focusedAnnotationId;
  AnnotationSidebarFilter _filter = AnnotationSidebarFilter.all;

  @override
  Widget build(BuildContext context) {
    final sourceUrl = widget.sourceUrl;
    if (sourceUrl == null) {
      return const SizedBox.shrink();
    }

    final annotations = ref.watch(annotationsForPageProvider(sourceUrl));

    return annotations.maybeWhen(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final isOpen = ref.watch(annotationSidebarOpenProvider);
        final visibleItems = items.where((annotation) => _filter.matches(annotation)).toList(growable: false);

        return LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth * 0.78;

            return Stack(
              children: [
                if (!isOpen)
                  Positioned(
                    right: 0,
                    top: constraints.maxHeight * 0.32,
                    child: _SidebarToggle(
                      count: items.length,
                      onPressed: ref.read(annotationSidebarOpenProvider.notifier).open,
                    ),
                  ),
                if (isOpen)
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: ref.read(annotationSidebarOpenProvider.notifier).close,
                            child: const ColoredBox(color: Color(0x73000000)),
                          ),
                        ),
                        const SizedBox(width: 0),
                      ],
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  top: 0,
                  bottom: 0,
                  right: isOpen ? 0 : -panelWidth,
                  width: panelWidth,
                  child: _SidebarPanel(
                    sourceUrl: sourceUrl,
                    allItems: items,
                    visibleItems: visibleItems,
                    filter: _filter,
                    focusedAnnotationId: _focusedAnnotationId,
                    onClose: ref.read(annotationSidebarOpenProvider.notifier).close,
                    onFilterChanged: (nextFilter) => setState(() => _filter = nextFilter),
                    onEdit: widget.onEdit,
                    onJump: (annotation) async {
                      setState(() => _focusedAnnotationId = annotation.annotation.id);
                      await widget.onJump(annotation);
                    },
                    onDelete: widget.onDelete,
                  ),
                ),
              ],
            );
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  const _SidebarToggle({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open annotations',
      child: GestureDetector(
        key: const ValueKey('annotation-sidebar-toggle'),
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                right: 0,
                top: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xF21C1C20),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                    boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(-4, 0))],
                  ),
                  child: SizedBox(
                    width: 30,
                    height: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_TogglePip(), SizedBox(height: 4), _TogglePip(), SizedBox(height: 4), _TogglePip()],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: CupertinoColors.activeBlue, shape: BoxShape.circle),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TogglePip extends StatelessWidget {
  const _TogglePip();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: CupertinoColors.white, shape: BoxShape.circle),
      child: SizedBox(width: 4, height: 4),
    );
  }
}

class _SidebarPanel extends StatelessWidget {
  const _SidebarPanel({
    required this.sourceUrl,
    required this.allItems,
    required this.visibleItems,
    required this.filter,
    required this.focusedAnnotationId,
    required this.onClose,
    required this.onFilterChanged,
    required this.onEdit,
    required this.onJump,
    required this.onDelete,
  });

  final Uri sourceUrl;
  final List<PageAnnotation> allItems;
  final List<PageAnnotation> visibleItems;
  final AnnotationSidebarFilter filter;
  final String? focusedAnnotationId;
  final VoidCallback onClose;
  final ValueChanged<AnnotationSidebarFilter> onFilterChanged;
  final AnnotationSidebarAction onEdit;
  final AnnotationSidebarAction onJump;
  final AnnotationSidebarAction onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C20),
        boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(-8, 0))],
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Annotations',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(30, 30),
                        onPressed: onClose,
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.systemGrey,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(color: const Color(0xFF2C2C30), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemGrey, size: 12),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _displayUrl(sourceUrl),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 11, letterSpacing: 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final candidate in AnnotationSidebarFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: _FilterPill(
                        filter: candidate,
                        count: _countFor(candidate),
                        isSelected: filter == candidate,
                        onPressed: () => onFilterChanged(candidate),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 3),
              child: Text(
                'ON THIS PAGE',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            Expanded(
              child: visibleItems.isEmpty
                  ? const _EmptyFilter()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        final annotation = visibleItems[index];
                        return _AnnotationCard(
                          annotation: annotation,
                          isFocused: annotation.annotation.id == focusedAnnotationId,
                          onPressed: () => onJump(annotation),
                          onEdit: () => onEdit(annotation),
                          onJump: () => onJump(annotation),
                          onDelete: () => onDelete(annotation),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int _countFor(AnnotationSidebarFilter candidate) {
    return allItems.where((annotation) {
      return switch (candidate) {
        AnnotationSidebarFilter.all => true,
        AnnotationSidebarFilter.highlights =>
          annotation.annotation.motivation == 'highlighting' &&
              annotation.visualStyle == AnnotationVisualStyle.highlight,
        AnnotationSidebarFilter.notes => annotation.note != null || annotation.annotation.motivation == 'commenting',
        AnnotationSidebarFilter.underlines => annotation.visualStyle == AnnotationVisualStyle.underline,
      };
    }).length;
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.filter, required this.count, required this.isSelected, required this.onPressed});

  final AnnotationSidebarFilter filter;
  final int count;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      minimumSize: const Size(0, 26),
      color: isSelected ? CupertinoColors.white : const Color(0xFF2C2C30),
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Text(
        filter == AnnotationSidebarFilter.all ? '${filter.label} ($count)' : filter.label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1C1C20) : CupertinoColors.systemGrey,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _AnnotationCard extends StatelessWidget {
  const _AnnotationCard({
    required this.annotation,
    required this.isFocused,
    required this.onPressed,
    required this.onEdit,
    required this.onJump,
    required this.onDelete,
  });

  final PageAnnotation annotation;
  final bool isFocused;
  final VoidCallback onPressed;
  final VoidCallback onEdit;
  final VoidCallback onJump;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(annotation);
    final note = annotation.note;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isFocused ? const Color(0xFF36363C) : const Color(0xFF2C2C30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isFocused ? accent : const Color(0x00000000), width: 1),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                  ),
                  child: const SizedBox(width: 3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${annotation.exact ?? 'Untitled annotation'}"',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 12,
                          height: 1.3,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TypeTag(annotation: annotation),
                        const Spacer(),
                        _CardAction(icon: CupertinoIcons.pencil, label: 'Edit', onPressed: onEdit),
                        _CardAction(icon: CupertinoIcons.arrow_down_right, label: 'Jump', onPressed: onJump),
                        _CardAction(icon: CupertinoIcons.trash, label: 'Delete', onPressed: onDelete),
                      ],
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

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.annotation});

  final PageAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final isNote = annotation.note != null || annotation.annotation.motivation == 'commenting';
    final isUnderline = annotation.visualStyle == AnnotationVisualStyle.underline;
    final label = isNote ? 'Note' : (isUnderline ? 'Underline' : 'Highlight');
    final color = isNote ? CupertinoColors.activeBlue : _accentColor(annotation);

    return DecoratedBox(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: const EdgeInsets.only(left: 8),
        minimumSize: const Size(32, 32),
        onPressed: onPressed,
        child: Icon(icon, color: CupertinoColors.systemGrey, size: 16),
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No annotations match this filter.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, letterSpacing: 0),
        ),
      ),
    );
  }
}

Color _accentColor(PageAnnotation annotation) {
  final parsed = int.tryParse(annotation.colorHex.replaceFirst('#', ''), radix: 16);
  if (parsed == null) {
    return annotation.visualStyle == AnnotationVisualStyle.underline
        ? CupertinoColors.systemTeal
        : CupertinoColors.systemYellow;
  }
  return Color(0xFF000000 | parsed);
}

String _displayUrl(Uri uri) {
  final path = uri.path == '/' ? '' : uri.path;
  return '${uri.host}$path';
}
