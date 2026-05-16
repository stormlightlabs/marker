import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/src/app/app_tab_bar.dart';
import 'package:marker/src/app/routes.dart';
import 'package:marker/src/features/bookmarks/data/bookmark_manager_repository.dart';
import 'package:marker/src/features/browser/application/reader_controller.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({this.folderId, super.key});

  final String? folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contents = ref.watch(bookmarkFolderContentsProvider(folderId));
    final isRoot = folderId == null;
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
            if (isRoot) const MarkerTabBar(activeRoute: AppRoute.bookmarks),
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

class _BookmarksContent extends ConsumerWidget {
  const _BookmarksContent({required this.folderId, required this.contents});

  final String? folderId;
  final BookmarkFolderContents contents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (folderId != null && contents.folder == null) {
      return const _BookmarkEmpty(title: 'Folder Not Found');
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(contents.folder?.title ?? 'Bookmarks'),
          backgroundColor: CupertinoColors.black,
          border: null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _createFolder(context, ref),
                child: const Icon(CupertinoIcons.folder_badge_plus, size: 22),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pushNamed(AppRoute.bookmarksExport.routeName),
                child: const Icon(CupertinoIcons.square_arrow_up, size: 22),
              ),
            ],
          ),
        ),
        if (contents.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _BookmarkEmpty(title: 'No Bookmarks'))
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF151519),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
                ),
                child: Column(
                  children: [
                    for (final folder in contents.folders)
                      _BookmarkRow(
                        icon: CupertinoIcons.folder_fill,
                        color: CupertinoColors.systemYellow,
                        title: folder.title,
                        subtitle: 'Folder',
                        onPressed: () =>
                            context.pushNamed(AppRoute.bookmarkDetail.routeName, pathParameters: {'id': folder.id}),
                      ),
                    for (final bookmark in contents.bookmarks)
                      _BookmarkRow(
                        icon: CupertinoIcons.bookmark_fill,
                        color: CupertinoColors.activeBlue,
                        title: bookmark.displayTitle,
                        subtitle: bookmark.url.toString(),
                        onPressed: () => _openBookmark(context, ref, bookmark.url),
                      ),
                  ],
                ),
              ),
            ),
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

    await ref.read(bookmarkManagerRepositoryProvider).createFolder(title: title, parentId: folderId);
    ref.invalidate(bookmarkFolderContentsProvider(folderId));
  }

  void _openBookmark(BuildContext context, WidgetRef ref, Uri url) {
    ref.read(readerControllerProvider.notifier).openBookmark(url);
    context.goNamed(AppRoute.browser.routeName);
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
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF26262C), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
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
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, letterSpacing: 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey2, size: 17),
        ],
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
