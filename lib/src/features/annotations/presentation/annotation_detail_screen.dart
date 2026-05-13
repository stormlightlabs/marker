import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/app/app_transitions.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/src/app/routes.dart';
import 'package:marker/src/features/annotations/data/annotation_repository.dart';
import 'package:marker/src/features/browser/application/reader_controller.dart';
import 'package:marker/src/features/browser/presentation/note_editor_sheet.dart';
import 'package:marker/src/features/library/data/library_repository.dart';

class AnnotationDetailScreen extends ConsumerStatefulWidget {
  const AnnotationDetailScreen({required this.annotationId, super.key});

  final String annotationId;

  @override
  ConsumerState<AnnotationDetailScreen> createState() => _AnnotationDetailScreenState();
}

class _AnnotationDetailScreenState extends ConsumerState<AnnotationDetailScreen> {
  Future<void> _openEditor(AnnotationDetail detail) async {
    final note = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) {
        return NoteEditorSheet(
          quote: detail.annotation.exact ?? 'Untitled annotation',
          initialText: detail.annotation.note ?? '',
          title: detail.annotation.note == null ? 'Add Note' : 'Edit Note',
        );
      },
    );

    if (note == null) {
      return;
    }

    await ref.read(annotationRepositoryProvider).updateMarkdownBody(annotationId: widget.annotationId, value: note);
    ref.invalidate(annotationDetailProvider(widget.annotationId));
    ref.invalidate(librarySnapshotProvider);
  }

  Future<void> _deleteAnnotation(AnnotationDetail detail) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Delete Annotation?'),
          content: const Text('This removes the saved annotation and its note from this device.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(annotationRepositoryProvider).deleteAnnotation(widget.annotationId);
    ref.invalidate(annotationDetailProvider(widget.annotationId));
    ref.invalidate(annotationsForPageProvider(detail.sourceUrl));
    ref.invalidate(librarySnapshotProvider);
    if (mounted) {
      context.goNamed(AppRoute.library.routeName);
    }
  }

  void _openSource(AnnotationDetail detail) {
    ref.read(readerControllerProvider.notifier).setUrlText(detail.sourceUrl.toString());
    context.goNamed(AppRoute.browser.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(annotationDetailProvider(widget.annotationId));

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: const Text('Annotation'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.goNamed(AppRoute.library.routeName),
          child: const Text('Back'),
        ),
        trailing: detail.maybeWhen(
          data: (value) => value == null
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _openEditor(value),
                  child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0)),
                ),
          orElse: () => null,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: MarkerAnimatedContent(
          child: detail.when(
            data: (value) {
              if (value == null) {
                return const _MissingAnnotation(key: ValueKey('missing-annotation'));
              }
              return _AnnotationReadView(
                key: ValueKey('annotation-${value.annotation.annotation.id}'),
                detail: value,
                onOpenSource: () => _openSource(value),
                onDelete: () => _deleteAnnotation(value),
              );
            },
            loading: () => const Center(key: ValueKey('annotation-loading'), child: CupertinoActivityIndicator()),
            error: (error, stackTrace) =>
                _AnnotationError(key: const ValueKey('annotation-error'), message: error.toString()),
          ),
        ),
      ),
    );
  }
}

class _AnnotationReadView extends StatelessWidget {
  const _AnnotationReadView({required this.detail, required this.onOpenSource, required this.onDelete, super.key});

  final AnnotationDetail detail;
  final VoidCallback onOpenSource;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final note = detail.annotation.note;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _MotivationTag(annotation: detail.annotation),
        const SizedBox(height: 12),
        _QuoteBlock(text: detail.annotation.exact ?? 'Untitled annotation', color: _accentColor(detail.annotation)),
        const SizedBox(height: 14),
        if (note == null)
          const Text(
            'No note attached. Tap Edit to add one.',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, letterSpacing: 0),
          )
        else
          _NoteBlock(note: note),
        const SizedBox(height: 22),
        const _SectionLabel('Source'),
        _GroupedRows(
          rows: [
            _MetaRow(label: 'Page', value: detail.pageTitle),
            _MetaRow(label: 'URL', value: _displayUrl(detail.sourceUrl)),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionLabel('Timestamps'),
        _GroupedRows(
          rows: [
            _MetaRow(label: 'Created', value: _formatTimestamp(detail.annotation.annotation.createdAt)),
            _MetaRow(label: 'Modified', value: _formatTimestamp(detail.annotation.annotation.modifiedAt)),
          ],
        ),
        const SizedBox(height: 18),
        _GroupedRows(
          rows: [
            _ActionRow(
              icon: CupertinoIcons.globe,
              label: 'Open source page',
              color: CupertinoColors.activeBlue,
              onPressed: onOpenSource,
            ),
            _ActionRow(
              icon: CupertinoIcons.trash,
              label: 'Delete annotation',
              color: CupertinoColors.systemRed,
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _MotivationTag extends StatelessWidget {
  const _MotivationTag({required this.annotation});

  final PageAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final isNote = annotation.note != null || annotation.annotation.motivation == 'commenting';
    final isUnderline = annotation.visualStyle == AnnotationVisualStyle.underline;
    final label = isNote ? 'Note' : (isUnderline ? 'Underline' : 'Highlight');
    final icon = isNote
        ? CupertinoIcons.chat_bubble_text
        : (isUnderline ? CupertinoIcons.underline : CupertinoIcons.pencil);
    final color = isNote ? CupertinoColors.activeBlue : _accentColor(annotation);

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151519),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Text(
          '"$text"',
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            height: 1.35,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: MarkdownBody(
          data: note,
          selectable: false,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: CupertinoColors.white, fontSize: 15, height: 1.35, letterSpacing: 0),
            strong: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700, letterSpacing: 0),
            em: const TextStyle(color: CupertinoColors.systemGrey2, fontStyle: FontStyle.italic, letterSpacing: 0),
            code: const TextStyle(color: Color(0xFFA5D6FF), fontSize: 13, fontFamily: 'Menlo', letterSpacing: 0),
          ),
        ),
      ),
    );
  }
}

class _GroupedRows extends StatelessWidget {
  const _GroupedRows({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xFF151519), borderRadius: BorderRadius.circular(8)),
      child: Column(children: rows),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14, letterSpacing: 0)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 14, letterSpacing: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.color, required this.onPressed});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 9),
            Text(label, style: TextStyle(color: color, fontSize: 15, letterSpacing: 0)),
            const Spacer(),
            if (color != CupertinoColors.systemRed)
              const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey2, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MissingAnnotation extends StatelessWidget {
  const _MissingAnnotation({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Annotation not found.', style: TextStyle(color: CupertinoColors.systemGrey, letterSpacing: 0)),
    );
  }
}

class _AnnotationError extends StatelessWidget {
  const _AnnotationError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 14, letterSpacing: 0),
          textAlign: TextAlign.center,
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

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final month = _monthNames[local.month - 1];
  final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day}, ${local.year}, $hour:$minute $period';
}

const _monthNames = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
