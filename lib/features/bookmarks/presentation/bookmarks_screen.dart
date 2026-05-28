import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/features/bookmarks/data/bookmark_manager_repository.dart';
import 'package:marker/features/browser/application/reader_controller.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({this.folderId, super.key});

  final String? folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contents = ref.watch(bookmarkFolderContentsProvider(folderId));
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: contents.when(
                data: (data) => _BookmarksContent(folderId: folderId, contents: data),
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, stackTrace) => _BookmarkError(message: error.toString()),
              ),
            ),
            if (folderId == null) const MarkerTabBar(activeRoute: AppRoute.bookmarks),
          ],
        ),
      ),
    );
  }
}

class BookmarkDetailScreen extends ConsumerWidget {
  const BookmarkDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookmarkDetailProvider(id));
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: const Text('Bookmark'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pushNamed(AppRoute.bookmarkEdit.routeName, pathParameters: {'id': id}),
          child: const Icon(CupertinoIcons.pencil, size: 22),
        ),
      ),
      child: SafeArea(
        child: detail.when(
          data: (item) {
            if (item == null) {
              return const _BookmarkEmpty(title: 'Bookmark Not Found');
            }
            if (item.isFolder) {
              return _FolderDetail(folder: item.folder!);
            }
            return _BookmarkDetail(bookmark: item.bookmark!);
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => _BookmarkError(message: error.toString()),
        ),
      ),
    );
  }
}

class BookmarkEditScreen extends ConsumerStatefulWidget {
  const BookmarkEditScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<BookmarkEditScreen> createState() => _BookmarkEditScreenState();
}

class _BookmarkEditScreenState extends ConsumerState<BookmarkEditScreen> {
  late final TextEditingController _titleController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(bookmarkDetailProvider(widget.id));
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: const Text('Edit Bookmark'),
        trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: _save, child: const Text('Done')),
      ),
      child: SafeArea(
        child: detail.when(
          data: (item) {
            if (item == null) {
              return const _BookmarkEmpty(title: 'Bookmark Not Found');
            }
            if (!_initialized) {
              _titleController.text = item.folder?.title ?? item.bookmark?.displayTitle ?? '';
              _initialized = true;
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoTextField(
                controller: _titleController,
                autofocus: true,
                placeholder: 'Title',
                style: const TextStyle(color: CupertinoColors.white, letterSpacing: 0),
                placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, letterSpacing: 0),
                decoration: BoxDecoration(color: const Color(0xFF151519), borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => _BookmarkError(message: error.toString()),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final repository = ref.read(bookmarkManagerRepositoryProvider);
    final detail = await ref.read(bookmarkDetailProvider(widget.id).future);
    if (detail == null) {
      return;
    }
    if (detail.isFolder) {
      await repository.updateFolder(id: widget.id, title: _titleController.text);
    } else {
      await repository.updateBookmark(id: widget.id, title: _titleController.text);
    }
    ref.invalidate(bookmarkDetailProvider(widget.id));
    ref.invalidate(bookmarkFolderContentsProvider(detail.folder?.parentId ?? detail.bookmark?.folderId));
    if (mounted) {
      context.pop();
    }
  }
}

class BookmarksExportScreen extends ConsumerWidget {
  const BookmarksExportScreen({required this.selectedIds, super.key});

  final List<String>? selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exported = ref.watch(bookmarksExportProvider(selectedIds));
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: const Text('Export Bookmarks'),
        trailing: exported.maybeWhen(
          data: (html) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Clipboard.setData(ClipboardData(text: html)),
            child: const Icon(CupertinoIcons.doc_on_doc, size: 22),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ),
      child: SafeArea(
        child: exported.when(
          data: (html) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              html,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 13, letterSpacing: 0, height: 1.25),
            ),
          ),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => _BookmarkError(message: error.toString()),
        ),
      ),
    );
  }
}

class _BookmarksContent extends ConsumerStatefulWidget {
  const _BookmarksContent({required this.folderId, required this.contents});

  final String? folderId;
  final BookmarkFolderContents contents;

  @override
  ConsumerState<_BookmarksContent> createState() => _BookmarksContentState();
}

class _BookmarksContentState extends ConsumerState<_BookmarksContent> {
  final Set<String> _expandedFolderIds = <String>{};
  final Set<String> _selectedKeys = <String>{};
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final contents = widget.contents;
    final folderId = widget.folderId;
    if (folderId != null && contents.folder == null) {
      return const _BookmarkEmpty(title: 'Folder Not Found');
    }
    final funEnabled = ref.watch(funEnabledProvider).value ?? true;
    return Column(
      children: [
        _BookmarkHeader(
          title: contents.folder?.title ?? 'Bookmarks',
          funEnabled: funEnabled,
          canPop: folderId != null,
          isEditing: _isEditing,
          onBackPressed: () => context.pop(),
          onCreateFolder: () => _createFolder(context, ref),
          onExport: () => context.pushNamed(AppRoute.bookmarksExport.routeName),
          onInfo: contents.folder == null
              ? null
              : () => context.pushNamed(AppRoute.bookmarkDetail.routeName, pathParameters: {'id': contents.folder!.id}),
          onEdit: () => setState(() {
            _isEditing = !_isEditing;
            _selectedKeys.clear();
          }),
        ),
        Expanded(
          child: contents.isEmpty
              ? const _BookmarkEmpty(title: 'No Bookmarks')
              : ReorderableList(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
                  proxyDecorator: (child, index, animation) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18)],
                    ),
                    child: child,
                  ),
                  itemCount: contents.items.length,
                  onReorderItem: (oldIndex, newIndex) => _reorder(ref, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final item = contents.items[index];
                    return _BookmarkItemBlock(
                      key: ValueKey(item.key),
                      index: index,
                      item: item,
                      isEditing: _isEditing,
                      isSelected: _selectedKeys.contains(item.key),
                      isExpanded: item.type == BookmarkEntryType.folder && _expandedFolderIds.contains(item.id),
                      onPressed: () => _pressItem(context, ref, item),
                      onLongPress: () => _longPressItem(context, item),
                      onInfoPressed: item.type == BookmarkEntryType.folder
                          ? () => context.pushNamed(AppRoute.bookmarkDetail.routeName, pathParameters: {'id': item.id})
                          : null,
                      onDroppedOnFolder: (dragged) => _moveEntryToFolder(ref, dragged, item.id),
                    );
                  },
                ),
        ),
        if (_isEditing)
          _BookmarkEditBar(
            selectedCount: _selectedKeys.length,
            onMove: _selectedKeys.isEmpty ? null : () => _moveSelected(context, ref),
            onDelete: _selectedKeys.isEmpty ? null : () => _deleteSelected(context, ref),
          ),
      ],
    );
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('New Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: controller, autofocus: true, placeholder: 'Title'),
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null) {
      return;
    }

    await ref.read(bookmarkManagerRepositoryProvider).createFolder(title: title, parentId: widget.folderId);
    ref.invalidate(bookmarkFolderContentsProvider(widget.folderId));
  }

  Future<void> _reorder(WidgetRef ref, int oldIndex, int newIndex) async {
    final items = widget.contents.items.toList();
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    await ref
        .read(bookmarkManagerRepositoryProvider)
        .reorderEntries(folderId: widget.folderId, entries: items.map((item) => item.ref).toList(growable: false));
    ref.invalidate(bookmarkFolderContentsProvider(widget.folderId));
  }

  void _pressItem(BuildContext context, WidgetRef ref, BookmarkListItem item) {
    if (_isEditing) {
      setState(() {
        if (!_selectedKeys.add(item.key)) {
          _selectedKeys.remove(item.key);
        }
      });
      return;
    }
    if (item.type == BookmarkEntryType.folder) {
      context.pushNamed(AppRoute.bookmarksFolder.routeName, pathParameters: {'id': item.id});
      return;
    }
    _openBookmark(context, ref, item.bookmark!.url);
  }

  void _longPressItem(BuildContext context, BookmarkListItem item) {
    if (_isEditing) {
      _pressItem(context, ref, item);
      return;
    }
    if (item.type == BookmarkEntryType.folder) {
      setState(() {
        if (!_expandedFolderIds.add(item.id)) {
          _expandedFolderIds.remove(item.id);
        }
      });
      return;
    }
    context.pushNamed(AppRoute.bookmarkDetail.routeName, pathParameters: {'id': item.id});
  }

  Future<void> _moveEntryToFolder(WidgetRef ref, BookmarkEntryRef entry, String folderId) async {
    if (entry.type == BookmarkEntryType.folder && entry.id == folderId) {
      return;
    }
    await ref.read(bookmarkManagerRepositoryProvider).moveEntry(entry, folderId: folderId);
    ref.invalidate(bookmarkFolderContentsProvider(widget.folderId));
    ref.invalidate(bookmarkFolderContentsProvider(folderId));
  }

  Future<void> _moveSelected(BuildContext context, WidgetRef ref) async {
    final targetFolderId = await _chooseFolder(context, ref);
    if (!mounted) {
      return;
    }
    await ref.read(bookmarkManagerRepositoryProvider).moveEntries(_selectedRefs(), folderId: targetFolderId);
    setState(() {
      _selectedKeys.clear();
      _isEditing = false;
    });
    ref.invalidate(bookmarkFolderContentsProvider(widget.folderId));
    ref.invalidate(bookmarkFolderContentsProvider(targetFolderId));
  }

  Future<void> _deleteSelected(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${_selectedKeys.length} selected item(s)?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(bookmarkManagerRepositoryProvider).deleteEntries(_selectedRefs());
    setState(() {
      _selectedKeys.clear();
      _isEditing = false;
    });
    ref.invalidate(bookmarkFolderContentsProvider(widget.folderId));
  }

  Future<String?> _chooseFolder(BuildContext context, WidgetRef ref) async {
    final folders = await ref.read(bookmarkManagerRepositoryProvider).loadFolders();
    if (!context.mounted) {
      return null;
    }
    return showCupertinoModalPopup<String?>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Move To'),
        actions: [
          CupertinoActionSheetAction(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('Bookmarks')),
          for (final folder in folders)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(folder.id),
              child: Text(folder.title),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(widget.folderId),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  List<BookmarkEntryRef> _selectedRefs() {
    return _selectedKeys.map(BookmarkEntryRef.fromKey).toList(growable: false);
  }

  void _openBookmark(BuildContext context, WidgetRef ref, Uri url) {
    ref.read(readerControllerProvider.notifier).openBookmark(url);
    context.goNamed(AppRoute.browser.routeName);
  }
}

class _BookmarkHeader extends StatelessWidget {
  const _BookmarkHeader({
    required this.title,
    required this.funEnabled,
    required this.canPop,
    required this.isEditing,
    required this.onBackPressed,
    required this.onCreateFolder,
    required this.onExport,
    required this.onEdit,
    this.onInfo,
  });

  final String title;
  final bool funEnabled;
  final bool canPop;
  final bool isEditing;
  final VoidCallback onBackPressed;
  final VoidCallback onCreateFolder;
  final VoidCallback onExport;
  final VoidCallback onEdit;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Row(
      children: [
        if (canPop)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onBackPressed,
            child: const Icon(CupertinoIcons.chevron_back, size: 24),
          ),
        Expanded(
          child: _BookmarkTitle(text: title, funEnabled: funEnabled),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onCreateFolder,
          child: const Icon(CupertinoIcons.folder_badge_plus, size: 22),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onExport,
          child: const Icon(CupertinoIcons.square_arrow_up, size: 22),
        ),
        if (onInfo != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onInfo,
            child: const Icon(CupertinoIcons.info_circle, size: 22),
          ),
        CupertinoButton(padding: EdgeInsets.zero, onPressed: onEdit, child: Text(isEditing ? 'Done' : 'Edit')),
      ],
    ),
  );
}

class _BookmarkTitle extends StatelessWidget {
  const _BookmarkTitle({required this.text, required this.funEnabled});

  final String text;
  final bool funEnabled;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: funEnabled
        ? GoogleFonts.slacksideOne(
            color: CupertinoColors.white,
            fontSize: 40,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          )
        : const TextStyle(color: CupertinoColors.white, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0),
  );
}

class _BookmarkItemBlock extends ConsumerWidget {
  const _BookmarkItemBlock({
    required super.key,
    required this.index,
    required this.item,
    required this.isEditing,
    required this.isSelected,
    required this.isExpanded,
    required this.onPressed,
    required this.onLongPress,
    required this.onDroppedOnFolder,
    this.onInfoPressed,
  });

  final int index;
  final BookmarkListItem item;
  final bool isEditing;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final VoidCallback? onInfoPressed;
  final ValueChanged<BookmarkEntryRef> onDroppedOnFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = _BookmarkRow(
      item: item,
      index: index,
      isEditing: isEditing,
      isSelected: isSelected,
      isExpanded: isExpanded,
      onPressed: onPressed,
      onLongPress: onLongPress,
      onInfoPressed: onInfoPressed,
    );

    return Column(
      key: key,
      children: [
        if (item.type == BookmarkEntryType.folder)
          DragTarget<BookmarkEntryRef>(
            onWillAcceptWithDetails: (details) => details.data.key != item.key,
            onAcceptWithDetails: (details) => onDroppedOnFolder(details.data),
            builder: (context, candidateData, rejectedData) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: candidateData.isEmpty ? null : Border.all(color: CupertinoColors.activeBlue, width: 1.5),
              ),
              child: row,
            ),
          )
        else
          row,
        if (item.type == BookmarkEntryType.folder && isExpanded) _ExpandedFolderContents(folderId: item.id, depth: 1),
      ],
    );
  }
}

class _ExpandedFolderContents extends ConsumerWidget {
  const _ExpandedFolderContents({required this.folderId, required this.depth});

  final String folderId;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contents = ref.watch(bookmarkFolderContentsProvider(folderId));
    return contents.maybeWhen(
      data: (data) => Column(
        children: data.items
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(left: 18.0 * depth),
                child: _BookmarkRow(
                  item: item,
                  index: 0,
                  isEditing: false,
                  isSelected: false,
                  isExpanded: false,
                  onPressed: () {
                    if (item.type == BookmarkEntryType.folder) {
                      context.pushNamed(AppRoute.bookmarksFolder.routeName, pathParameters: {'id': item.id});
                    } else {
                      ref.read(readerControllerProvider.notifier).openBookmark(item.bookmark!.url);
                      context.goNamed(AppRoute.browser.routeName);
                    }
                  },
                  onLongPress: () =>
                      context.pushNamed(AppRoute.bookmarkDetail.routeName, pathParameters: {'id': item.id}),
                  onInfoPressed: item.type == BookmarkEntryType.folder
                      ? () => context.pushNamed(AppRoute.bookmarkDetail.routeName, pathParameters: {'id': item.id})
                      : null,
                  showDragControls: false,
                ),
              ),
            )
            .toList(growable: false),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _FolderDetail extends StatelessWidget {
  const _FolderDetail({required this.folder});

  final BookmarkFolderItem folder;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _DetailRow(label: 'Title', value: folder.title),
      _DetailRow(label: 'Created', value: folder.createdAt.toLocal().toString()),
      CupertinoButton.filled(
        onPressed: () => context.pushNamed(AppRoute.bookmarksFolder.routeName, pathParameters: {'id': folder.id}),
        child: const Text('Open Folder'),
      ),
    ],
  );
}

class _BookmarkDetail extends StatelessWidget {
  const _BookmarkDetail({required this.bookmark});

  final BookmarkItem bookmark;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _DetailRow(label: 'Title', value: bookmark.displayTitle),
      _DetailRow(label: 'URL', value: bookmark.url.toString()),
      _DetailRow(label: 'Created', value: bookmark.createdAt.toLocal().toString()),
    ],
  );
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({
    required this.item,
    required this.index,
    required this.isEditing,
    required this.isSelected,
    required this.isExpanded,
    required this.onPressed,
    required this.onLongPress,
    this.onInfoPressed,
    this.showDragControls = true,
  });

  final BookmarkListItem item;
  final int index;
  final bool isEditing;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final VoidCallback? onInfoPressed;
  final bool showDragControls;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    onLongPress: onLongPress,
    child: Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1D2A3A) : const Color(0xFF151519),
        border: const Border(bottom: BorderSide(color: Color(0xFF26262C), width: 0.5)),
      ),
      child: Row(
        children: [
          if (isEditing) ...[
            Icon(
              isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
              color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
              size: 22,
            ),
            const SizedBox(width: 10),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _rowColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(_rowIcon, color: _rowColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
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
                  item.type == BookmarkEntryType.folder && isExpanded ? 'Expanded folder' : item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, letterSpacing: 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onInfoPressed != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(34),
              onPressed: onInfoPressed,
              child: const Icon(CupertinoIcons.info_circle, color: CupertinoColors.systemGrey2, size: 21),
            ),
          if (showDragControls) ...[
            LongPressDraggable<BookmarkEntryRef>(
              data: item.ref,
              feedback: _DragFeedback(title: item.title),
              childWhenDragging: const Icon(CupertinoIcons.arrow_right_arrow_left, color: CupertinoColors.systemGrey3),
              child: const Icon(CupertinoIcons.arrow_right_arrow_left, color: CupertinoColors.systemGrey2, size: 20),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(CupertinoIcons.line_horizontal_3, color: CupertinoColors.systemGrey2, size: 20),
              ),
            ),
          ] else
            const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey2, size: 17),
        ],
      ),
    ),
  );

  IconData get _rowIcon =>
      item.type == BookmarkEntryType.folder ? CupertinoIcons.folder_fill : CupertinoIcons.bookmark_fill;

  Color get _rowColor =>
      item.type == BookmarkEntryType.folder ? CupertinoColors.systemYellow : CupertinoColors.activeBlue;
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Text(
        title,
        style: const TextStyle(color: CupertinoColors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _BookmarkEditBar extends StatelessWidget {
  const _BookmarkEditBar({required this.selectedCount, required this.onMove, required this.onDelete});

  final int selectedCount;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFF111114),
      border: Border(top: BorderSide(color: Color(0xFF2A2A30), width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '$selectedCount selected',
                  style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14, letterSpacing: 0),
                ),
              ),
            ),
            CupertinoButton(onPressed: onMove, child: const Text('Move')),
            CupertinoButton(
              onPressed: onDelete,
              child: Text(
                'Delete',
                style: TextStyle(color: onDelete == null ? CupertinoColors.systemGrey : CupertinoColors.systemRed),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: CupertinoColors.white, fontSize: 16, letterSpacing: 0)),
      ],
    ),
  );
}

class _BookmarkEmpty extends StatelessWidget {
  const _BookmarkEmpty({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(title, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 16, letterSpacing: 0)),
  );
}

class _BookmarkError extends StatelessWidget {
  const _BookmarkError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
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
