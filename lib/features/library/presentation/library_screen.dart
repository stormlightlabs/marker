import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/browser/application/reader_controller.dart';
import 'package:marker/features/browser/presentation/note_editor_sheet.dart';
import 'package:marker/features/library/data/library_repository.dart';
import 'package:marker/features/library/data/library_search_repository.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(librarySnapshotProvider);
    final searchResults = _query.trim().isEmpty ? null : ref.watch(librarySearchProvider(_query));

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: snapshot.when(
                data: (library) => _LibraryContent(
                  snapshot: library,
                  query: _query,
                  searchController: _searchController,
                  searchResults: searchResults,
                  onSearchChanged: (value) => setState(() => _query = value),
                  onOpenPage: (id) => context.pushNamed(AppRoute.libraryPage.routeName, pathParameters: {'pageId': id}),
                  onOpenUrl: (url) => _openInBrowser(context, ref, url),
                  onOpenAnnotation: (annotationId) => _openAnnotation(context, annotationId),
                  onOpenAnnotations: () => context.pushNamed(AppRoute.annotations.routeName),
                ),
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, stackTrace) => _LibraryError(message: error.toString()),
              ),
            ),
            const MarkerTabBar(activeRoute: AppRoute.library),
          ],
        ),
      ),
    );
  }

  void _openInBrowser(BuildContext context, WidgetRef ref, Uri url) {
    final controller = ref.read(readerControllerProvider.notifier);
    controller.setUrlText(url.toString());
    context.goNamed(AppRoute.browser.routeName);
  }

  void _openAnnotation(BuildContext context, String annotationId) {
    context.goNamed(AppRoute.annotation.routeName, pathParameters: {'annotationId': annotationId});
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.snapshot,
    required this.query,
    required this.searchController,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onOpenPage,
    required this.onOpenUrl,
    required this.onOpenAnnotation,
    required this.onOpenAnnotations,
  });

  final LibrarySnapshot snapshot;
  final String query;
  final TextEditingController searchController;
  final AsyncValue<List<LibrarySearchResult>>? searchResults;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onOpenPage;
  final ValueChanged<Uri> onOpenUrl;
  final ValueChanged<String> onOpenAnnotation;
  final VoidCallback onOpenAnnotations;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Library'),
          backgroundColor: CupertinoColors.black,
          border: null,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: CupertinoSearchTextField(
              controller: searchController,
              onChanged: onSearchChanged,
              placeholder: 'Search pages & annotations',
              backgroundColor: const Color(0xFF1C1C20),
              style: const TextStyle(color: CupertinoColors.white, letterSpacing: 0),
              placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, letterSpacing: 0),
            ),
          ),
        ),
        if (query.trim().isNotEmpty)
          ..._searchSlivers()
        else if (snapshot.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyLibrary())
        else ...[
          _LibraryPageSection(
            title: 'Bookmarks',
            pages: snapshot.bookmarkedPages,
            icon: CupertinoIcons.bookmark_fill,
            accentColor: CupertinoColors.activeBlue,
            onOpenPage: onOpenPage,
          ),
          _LibraryPageSection(
            title: 'Recently Annotated',
            pages: snapshot.recentPages,
            icon: CupertinoIcons.globe,
            accentColor: CupertinoColors.systemTeal,
            onOpenPage: onOpenPage,
          ),
          _AnnotationSection(
            annotations: snapshot.recentAnnotations,
            onOpenAnnotation: onOpenAnnotation,
            onOpenAnnotations: onOpenAnnotations,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
        ],
      ],
    );
  }

  List<Widget> _searchSlivers() {
    final results = searchResults;
    if (results == null) {
      return const [SliverToBoxAdapter(child: SizedBox.shrink())];
    }
    return results.when(
      data: (items) {
        if (items.isEmpty) {
          return const [SliverFillRemaining(hasScrollBody: false, child: _EmptySearch())];
        }
        return [
          SliverToBoxAdapter(
            child: _SectionFrame(
              title: 'Search Results',
              children: [
                for (final result in items)
                  _SearchResultRow(
                    result: result,
                    onPressed: () {
                      if (result.type == LibrarySearchResultType.annotation) {
                        onOpenAnnotation(result.id);
                      } else {
                        onOpenPage(result.id);
                      }
                    },
                  ),
              ],
            ),
          ),
        ];
      },
      loading: () => const [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: CupertinoActivityIndicator())),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(hasScrollBody: false, child: _LibraryError(message: error.toString())),
      ],
    );
  }
}

class _LibraryPageSection extends StatelessWidget {
  const _LibraryPageSection({
    required this.title,
    required this.pages,
    required this.icon,
    required this.accentColor,
    required this.onOpenPage,
  });

  final String title;
  final List<LibraryPageItem> pages;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<String> onOpenPage;

  @override
  Widget build(BuildContext context) => pages.isEmpty
      ? const SliverToBoxAdapter(child: SizedBox.shrink())
      : SliverToBoxAdapter(
          child: _SectionFrame(
            title: title,
            children: [
              for (final page in pages)
                _PageRow(page: page, icon: icon, accentColor: accentColor, onPressed: () => onOpenPage(page.id)),
            ],
          ),
        );
}

class _AnnotationSection extends StatelessWidget {
  const _AnnotationSection({
    required this.annotations,
    required this.onOpenAnnotation,
    required this.onOpenAnnotations,
  });

  final List<LibraryAnnotationItem> annotations;
  final ValueChanged<String> onOpenAnnotation;
  final VoidCallback onOpenAnnotations;

  @override
  Widget build(BuildContext context) => annotations.isEmpty
      ? const SliverToBoxAdapter(child: SizedBox.shrink())
      : SliverToBoxAdapter(
          child: _SectionFrame(
            title: 'Recent Annotations',
            children: [
              _AllAnnotationsRow(onPressed: onOpenAnnotations),
              for (final annotation in annotations)
                _AnnotationRow(annotation: annotation, onPressed: () => onOpenAnnotation(annotation.id)),
            ],
          ),
        );
}

class AllAnnotationsScreen extends ConsumerStatefulWidget {
  const AllAnnotationsScreen({super.key});

  @override
  ConsumerState<AllAnnotationsScreen> createState() => _AllAnnotationsScreenState();
}

class _AllAnnotationsScreenState extends ConsumerState<AllAnnotationsScreen> {
  final Set<String> _selectedIds = <String>{};
  LibraryAnnotationFilter _filter = LibraryAnnotationFilter.all;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(allAnnotationGroupsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: groups.when(
                data: (items) => _AllAnnotationsContent(
                  groups: items,
                  filter: _filter,
                  isEditing: _isEditing,
                  selectedIds: _selectedIds,
                  onFilterChanged: (value) => setState(() => _filter = value),
                  onToggleEditing: () => setState(() {
                    _isEditing = !_isEditing;
                    _selectedIds.clear();
                  }),
                  onExportAll: () => _openExport(context, null, 'markdown'),
                  onOpenPage: (id) => context.pushNamed(AppRoute.libraryPage.routeName, pathParameters: {'pageId': id}),
                  onOpenAnnotation: (annotationId) => _openAnnotation(context, annotationId),
                  onToggleSelection: _toggleSelection,
                ),
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, stackTrace) => _LibraryError(message: error.toString()),
              ),
            ),
            if (_isEditing)
              _AnnotationEditBar(
                selectedCount: _selectedIds.length,
                onEdit: _selectedIds.length == 1 ? () => _editSelectedNote(_selectedIds.single) : null,
                onExportMarkdown: _selectedIds.isEmpty ? null : () => _openExport(context, _selectedIds, 'markdown'),
                onExportJson: _selectedIds.isEmpty ? null : () => _openExport(context, _selectedIds, 'json'),
                onDelete: _selectedIds.isEmpty ? null : () => _deleteSelected(),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String annotationId) {
    setState(() {
      if (!_selectedIds.add(annotationId)) {
        _selectedIds.remove(annotationId);
      }
    });
  }

  void _openAnnotation(BuildContext context, String annotationId) {
    context.goNamed(AppRoute.annotation.routeName, pathParameters: {'annotationId': annotationId});
  }

  void _openExport(BuildContext context, Iterable<String>? selectedIds, String format) {
    context.pushNamed(
      AppRoute.annotationExport.routeName,
      queryParameters: {'format': format, if (selectedIds != null) 'selected': selectedIds.join(',')},
    );
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete $count selected annotation(s)?'),
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
    await ref.read(annotationRepositoryProvider).deleteAnnotations(_selectedIds);
    ref.invalidate(allAnnotationGroupsProvider);
    ref.invalidate(librarySnapshotProvider);
    setState(() {
      _selectedIds.clear();
      _isEditing = false;
    });
  }

  Future<void> _editSelectedNote(String annotationId) async {
    final detail = await ref.read(annotationDetailProvider(annotationId).future);
    if (detail == null || !mounted) {
      return;
    }
    final note = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => NoteEditorSheet(
        quote: detail.annotation.exact ?? 'Untitled annotation',
        initialText: detail.annotation.note ?? '',
        title: detail.annotation.note == null ? 'Add Note' : 'Edit Note',
      ),
    );
    if (note == null) {
      return;
    }
    await ref.read(annotationRepositoryProvider).updateMarkdownBody(annotationId: annotationId, value: note);
    ref.invalidate(allAnnotationGroupsProvider);
    ref.invalidate(librarySnapshotProvider);
  }
}

class _AllAnnotationsContent extends StatelessWidget {
  const _AllAnnotationsContent({
    required this.groups,
    required this.filter,
    required this.isEditing,
    required this.selectedIds,
    required this.onFilterChanged,
    required this.onToggleEditing,
    required this.onExportAll,
    required this.onOpenPage,
    required this.onOpenAnnotation,
    required this.onToggleSelection,
  });

  final List<LibraryAnnotationGroup> groups;
  final LibraryAnnotationFilter filter;
  final bool isEditing;
  final Set<String> selectedIds;
  final ValueChanged<LibraryAnnotationFilter> onFilterChanged;
  final VoidCallback onToggleEditing;
  final VoidCallback onExportAll;
  final ValueChanged<String> onOpenPage;
  final ValueChanged<String> onOpenAnnotation;
  final ValueChanged<String> onToggleSelection;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      CupertinoSliverNavigationBar(
        largeTitle: const Text('Annotations'),
        backgroundColor: CupertinoColors.black,
        border: null,
        previousPageTitle: 'Library',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onExportAll,
              child: const Icon(CupertinoIcons.square_arrow_up, size: 21),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onToggleEditing,
              child: Text(isEditing ? 'Done' : 'Edit'),
            ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: _AnnotationFilterBar(filter: filter, onChanged: onFilterChanged),
      ),
      if (groups.isEmpty)
        const SliverFillRemaining(hasScrollBody: false, child: _EmptyAnnotations())
      else ...[
        for (final group in groups)
          if (group.annotations.any(filter.matches))
            SliverToBoxAdapter(
              child: _LibraryGroupFrame(
                children: [
                  _AnnotationPageRow(group: group, onPressed: () => onOpenPage(group.id)),
                  for (final annotation in group.annotations.where(filter.matches))
                    _AnnotationRow(
                      annotation: annotation,
                      isEditing: isEditing,
                      isSelected: selectedIds.contains(annotation.id),
                      onPressed: () => isEditing ? onToggleSelection(annotation.id) : onOpenAnnotation(annotation.id),
                    ),
                ],
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    ],
  );
}

class _LibraryGroupFrame extends StatelessWidget {
  const _LibraryGroupFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151519),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
      ),
      child: Column(children: children),
    ),
  );
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF151519),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _PageRow extends StatelessWidget {
  const _PageRow({required this.page, required this.icon, required this.accentColor, required this.onPressed});

  final LibraryPageItem page;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final annotationText = page.annotationCount == 1 ? '1 annotation' : '${page.annotationCount} annotations';
    final preview = page.annotationPreview;
    final bookmarkFolderPath = page.bookmarkFolderPath;

    return _LibraryRowButton(
      onPressed: onPressed,
      leading: _PageFavicon(page: page, fallbackIcon: icon, fallbackColor: accentColor),
      title: _titleWithBookmarkFolder(page.title, bookmarkFolderPath),
      subtitle: preview == null
          ? '${page.subtitle} · $annotationText'
          : '${page.subtitle} · $annotationText · "$preview"',
    );
  }
}

class _AllAnnotationsRow extends StatelessWidget {
  const _AllAnnotationsRow({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _LibraryRowButton(
    onPressed: onPressed,
    leading: const _LibraryIcon(icon: CupertinoIcons.book, color: CupertinoColors.systemPurple),
    title: 'All Annotations',
    subtitle: 'Browse every highlight and note',
  );
}

class _AnnotationPageRow extends StatelessWidget {
  const _AnnotationPageRow({required this.group, required this.onPressed});

  final LibraryAnnotationGroup group;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final annotationCount = group.annotations.length;
    final annotationText = annotationCount == 1 ? '1 annotation' : '$annotationCount annotations';
    final bookmarkFolderPath = group.bookmarkFolderPath;

    return _LibraryRowButton(
      onPressed: onPressed,
      leading: _AnnotationGroupFavicon(group: group),
      title: _titleWithBookmarkFolder(group.title, bookmarkFolderPath),
      subtitle: '${group.subtitle} · $annotationText',
    );
  }
}

class _AnnotationRow extends StatelessWidget {
  const _AnnotationRow({
    required this.annotation,
    required this.onPressed,
    this.isEditing = false,
    this.isSelected = false,
  });

  final LibraryAnnotationItem annotation;
  final VoidCallback onPressed;
  final bool isEditing;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => _LibraryRowButton(
    onPressed: onPressed,
    leading: isEditing
        ? _SelectionDot(isSelected: isSelected)
        : _LibraryIcon(
            icon: annotation.isNote ? CupertinoIcons.chat_bubble_text : CupertinoIcons.pencil,
            color: annotation.isNote ? CupertinoColors.activeBlue : CupertinoColors.systemYellow,
          ),
    title: annotation.excerpt,
    subtitle: '${annotation.typeLabel} · ${annotation.pageTitle}',
  );
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.result, required this.onPressed});

  final LibrarySearchResult result;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isAnnotation = result.type == LibrarySearchResultType.annotation;
    return _LibraryRowButton(
      onPressed: onPressed,
      leading: _LibraryIcon(
        icon: isAnnotation ? CupertinoIcons.pencil : CupertinoIcons.doc_text,
        color: isAnnotation ? CupertinoColors.systemYellow : CupertinoColors.activeBlue,
      ),
      title: result.title,
      subtitle: result.subtitle,
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: isSelected ? CupertinoColors.activeBlue : const Color(0xFF24242A),
      shape: BoxShape.circle,
      border: Border.all(color: isSelected ? CupertinoColors.activeBlue : const Color(0xFF3A3A42), width: 1),
    ),
    child: isSelected ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.white, size: 16) : null,
  );
}

class _AnnotationGroupFavicon extends StatelessWidget {
  const _AnnotationGroupFavicon({required this.group});

  final LibraryAnnotationGroup group;

  @override
  Widget build(BuildContext context) {
    final faviconFilePath = group.faviconFilePath;
    if (faviconFilePath != null) {
      return _FaviconFrame(
        child: Image.file(
          File(faviconFilePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _DomainPlaceholder(host: group.subtitle, icon: CupertinoIcons.globe, color: CupertinoColors.systemTeal),
        ),
      );
    }

    final faviconUrl = group.faviconUrl;
    if (faviconUrl == null) {
      return _DomainPlaceholder(host: group.subtitle, icon: CupertinoIcons.globe, color: CupertinoColors.systemTeal);
    }

    return _FaviconFrame(
      child: Image.network(
        faviconUrl.toString(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _DomainPlaceholder(host: group.subtitle, icon: CupertinoIcons.globe, color: CupertinoColors.systemTeal),
      ),
    );
  }
}

class _LibraryRowButton extends StatelessWidget {
  const _LibraryRowButton({
    required this.onPressed,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onPressed;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF26262C), width: 0.5)),
      ),
      child: Row(
        children: [
          leading,
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

class _LibraryIcon extends StatelessWidget {
  const _LibraryIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
    alignment: Alignment.center,
    child: Icon(icon, color: color, size: 19),
  );
}

class _PageFavicon extends StatelessWidget {
  const _PageFavicon({required this.page, required this.fallbackIcon, required this.fallbackColor});

  final LibraryPageItem page;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final faviconFilePath = page.faviconFilePath;
    if (faviconFilePath != null) {
      return _FaviconFrame(
        child: Image.file(
          File(faviconFilePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _DomainPlaceholder(host: page.subtitle, icon: fallbackIcon, color: fallbackColor),
        ),
      );
    }

    final faviconUrl = page.faviconUrl;
    if (faviconUrl == null) {
      return _DomainPlaceholder(host: page.subtitle, icon: fallbackIcon, color: fallbackColor);
    }

    return _FaviconFrame(
      child: Image.network(
        faviconUrl.toString(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _DomainPlaceholder(host: page.subtitle, icon: fallbackIcon, color: fallbackColor),
      ),
    );
  }
}

class _FaviconFrame extends StatelessWidget {
  const _FaviconFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: const Color(0xFF24242A), borderRadius: BorderRadius.circular(8)),
    child: child,
  );
}

class _DomainPlaceholder extends StatelessWidget {
  const _DomainPlaceholder({required this.host, required this.icon, required this.color});

  final String host;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = _domainInitial(host);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: initial == null
          ? Icon(icon, color: color, size: 19)
          : Text(
              initial,
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0),
            ),
    );
  }
}

String? _domainInitial(String host) {
  final normalizedHost = host.trim();
  if (normalizedHost.isEmpty) {
    return null;
  }
  final domain = normalizedHost.startsWith('www.') ? normalizedHost.substring(4) : normalizedHost;
  return domain.substring(0, 1).toUpperCase();
}

String _titleWithBookmarkFolder(String title, String? bookmarkFolderPath) {
  return bookmarkFolderPath == null ? title : '$title · $bookmarkFolderPath';
}

enum LibraryAnnotationFilter {
  all('All'),
  highlights('Highlights'),
  notes('Notes'),
  underlines('Underlines');

  const LibraryAnnotationFilter(this.label);

  final String label;

  bool matches(LibraryAnnotationItem annotation) => switch (this) {
    LibraryAnnotationFilter.all => true,
    LibraryAnnotationFilter.highlights =>
      !annotation.isNote && annotation.visualStyle == AnnotationVisualStyle.highlight,
    LibraryAnnotationFilter.notes => annotation.isNote,
    LibraryAnnotationFilter.underlines => annotation.visualStyle == AnnotationVisualStyle.underline,
  };
}

class LibraryPageDetailScreen extends ConsumerStatefulWidget {
  const LibraryPageDetailScreen({required this.pageId, super.key});

  final String pageId;

  @override
  ConsumerState<LibraryPageDetailScreen> createState() => _LibraryPageDetailScreenState();
}

class _LibraryPageDetailScreenState extends ConsumerState<LibraryPageDetailScreen> {
  final Set<String> _selectedIds = <String>{};
  late final TextEditingController _searchController = TextEditingController();
  LibraryAnnotationFilter _filter = LibraryAnnotationFilter.all;
  bool _isEditing = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(libraryPageDetailProvider(widget.pageId));
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: const Text('Page'),
        trailing: detail.maybeWhen(
          data: (value) => value == null
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() {
                    _isEditing = !_isEditing;
                    _selectedIds.clear();
                  }),
                  child: Text(_isEditing ? 'Done' : 'Edit'),
                ),
          orElse: () => null,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: detail.when(
                data: (value) => value == null
                    ? const _EmptyAnnotations()
                    : _PageDetailContent(
                        detail: value,
                        query: _query,
                        searchController: _searchController,
                        filter: _filter,
                        isEditing: _isEditing,
                        selectedIds: _selectedIds,
                        onSearchChanged: (value) => setState(() => _query = value),
                        onFilterChanged: (value) => setState(() => _filter = value),
                        onOpenSource: () => _openInBrowser(value.url),
                        onOpenAnnotation: (id) =>
                            context.goNamed(AppRoute.annotation.routeName, pathParameters: {'annotationId': id}),
                        onToggleSelection: _toggleSelection,
                        onExportAll: () => _openExport(null, 'markdown'),
                      ),
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, stackTrace) => _LibraryError(message: error.toString()),
              ),
            ),
            if (_isEditing)
              _AnnotationEditBar(
                selectedCount: _selectedIds.length,
                onEdit: _selectedIds.length == 1 ? () => _editSelectedNote(_selectedIds.single) : null,
                onExportMarkdown: _selectedIds.isEmpty ? null : () => _openExport(_selectedIds, 'markdown'),
                onExportJson: _selectedIds.isEmpty ? null : () => _openExport(_selectedIds, 'json'),
                onDelete: _selectedIds.isEmpty ? null : _deleteSelected,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String annotationId) {
    setState(() {
      if (!_selectedIds.add(annotationId)) {
        _selectedIds.remove(annotationId);
      }
    });
  }

  void _openInBrowser(Uri url) {
    ref.read(readerControllerProvider.notifier).setUrlText(url.toString());
    context.goNamed(AppRoute.browser.routeName);
  }

  void _openExport(Iterable<String>? selectedIds, String format) {
    context.pushNamed(
      AppRoute.annotationExport.routeName,
      queryParameters: {'format': format, if (selectedIds != null) 'selected': selectedIds.join(',')},
    );
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${_selectedIds.length} selected annotation(s)?'),
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
    await ref.read(annotationRepositoryProvider).deleteAnnotations(_selectedIds);
    ref.invalidate(libraryPageDetailProvider(widget.pageId));
    ref.invalidate(allAnnotationGroupsProvider);
    ref.invalidate(librarySnapshotProvider);
    setState(() {
      _selectedIds.clear();
      _isEditing = false;
    });
  }

  Future<void> _editSelectedNote(String annotationId) async {
    final detail = await ref.read(annotationDetailProvider(annotationId).future);
    if (detail == null || !mounted) {
      return;
    }
    final note = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => NoteEditorSheet(
        quote: detail.annotation.exact ?? 'Untitled annotation',
        initialText: detail.annotation.note ?? '',
        title: detail.annotation.note == null ? 'Add Note' : 'Edit Note',
      ),
    );
    if (note == null) {
      return;
    }
    await ref.read(annotationRepositoryProvider).updateMarkdownBody(annotationId: annotationId, value: note);
    ref.invalidate(libraryPageDetailProvider(widget.pageId));
    ref.invalidate(allAnnotationGroupsProvider);
    ref.invalidate(librarySnapshotProvider);
  }
}

class _PageDetailContent extends StatelessWidget {
  const _PageDetailContent({
    required this.detail,
    required this.query,
    required this.searchController,
    required this.filter,
    required this.isEditing,
    required this.selectedIds,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onOpenSource,
    required this.onOpenAnnotation,
    required this.onToggleSelection,
    required this.onExportAll,
  });

  final LibraryPageDetail detail;
  final String query;
  final TextEditingController searchController;
  final LibraryAnnotationFilter filter;
  final bool isEditing;
  final Set<String> selectedIds;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LibraryAnnotationFilter> onFilterChanged;
  final VoidCallback onOpenSource;
  final ValueChanged<String> onOpenAnnotation;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onExportAll;

  @override
  Widget build(BuildContext context) {
    final queryText = query.trim().toLowerCase();
    final annotations = detail.annotations
        .where((annotation) {
          if (!filter.matches(annotation)) {
            return false;
          }
          if (queryText.isEmpty) {
            return true;
          }
          return annotation.excerpt.toLowerCase().contains(queryText) ||
              annotation.pageTitle.toLowerCase().contains(queryText) ||
              annotation.typeLabel.toLowerCase().contains(queryText);
        })
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageDetailFavicon(detail: detail),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.title,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail.url.toString(),
                    style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, letterSpacing: 0),
                  ),
                  if (detail.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      detail.description!,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey2,
                        fontSize: 14,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _GroupedRows(
          children: [
            _PlainActionRow(icon: CupertinoIcons.globe, label: 'Open source page', onPressed: onOpenSource),
            _PlainActionRow(icon: CupertinoIcons.square_arrow_up, label: 'Export annotations', onPressed: onExportAll),
          ],
        ),
        const SizedBox(height: 14),
        CupertinoSearchTextField(
          controller: searchController,
          onChanged: onSearchChanged,
          placeholder: 'Search this page',
          backgroundColor: const Color(0xFF1C1C20),
          style: const TextStyle(color: CupertinoColors.white, letterSpacing: 0),
          placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, letterSpacing: 0),
        ),
        _AnnotationFilterBar(filter: filter, onChanged: onFilterChanged),
        if (annotations.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 52), child: _EmptyAnnotations())
        else
          _LibraryGroupFrame(
            children: [
              for (final annotation in annotations)
                _AnnotationRow(
                  annotation: annotation,
                  isEditing: isEditing,
                  isSelected: selectedIds.contains(annotation.id),
                  onPressed: () => isEditing ? onToggleSelection(annotation.id) : onOpenAnnotation(annotation.id),
                ),
            ],
          ),
      ],
    );
  }
}

class AnnotationExportScreen extends ConsumerWidget {
  const AnnotationExportScreen({required this.selectedIds, required this.format, super.key});

  final List<String>? selectedIds;
  final String format;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exported = FutureProvider.autoDispose<String>((providerRef) {
      final repository = providerRef.watch(annotationRepositoryProvider);
      return format == 'json'
          ? repository.exportAnnotationsJson(annotationIds: selectedIds)
          : repository.exportAnnotationsMarkdown(annotationIds: selectedIds);
    });
    final value = ref.watch(exported);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: Text(format == 'json' ? 'Export JSON' : 'Export Markdown'),
        trailing: value.maybeWhen(
          data: (text) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            child: const Icon(CupertinoIcons.doc_on_doc, size: 22),
          ),
          orElse: () => null,
        ),
      ),
      child: SafeArea(
        child: value.when(
          data: (text) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              text,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 13, height: 1.25, letterSpacing: 0),
            ),
          ),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => _LibraryError(message: error.toString()),
        ),
      ),
    );
  }
}

class _AnnotationFilterBar extends StatelessWidget {
  const _AnnotationFilterBar({required this.filter, required this.onChanged});

  final LibraryAnnotationFilter filter;
  final ValueChanged<LibraryAnnotationFilter> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Row(
      children: [
        for (final candidate in LibraryAnnotationFilter.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              color: filter == candidate ? CupertinoColors.activeBlue : const Color(0xFF1C1C20),
              borderRadius: BorderRadius.circular(8),
              onPressed: () => onChanged(candidate),
              child: Text(candidate.label, style: const TextStyle(fontSize: 13, letterSpacing: 0)),
            ),
          ),
      ],
    ),
  );
}

class _AnnotationEditBar extends StatelessWidget {
  const _AnnotationEditBar({
    required this.selectedCount,
    required this.onEdit,
    required this.onExportMarkdown,
    required this.onExportJson,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback? onEdit;
  final VoidCallback? onExportMarkdown;
  final VoidCallback? onExportJson;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFF111115),
      border: Border(top: BorderSide(color: Color(0xFF2A2A30), width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$selectedCount selected',
                style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, letterSpacing: 0),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: onEdit,
              child: const Text('Edit'),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: onExportMarkdown,
              child: const Text('Markdown'),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: onExportJson,
              child: const Text('JSON'),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: onDelete,
              child: const Text('Delete', style: TextStyle(color: CupertinoColors.systemRed)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PageDetailFavicon extends StatelessWidget {
  const _PageDetailFavicon({required this.detail});

  final LibraryPageDetail detail;

  @override
  Widget build(BuildContext context) => _PageFavicon(
    page: LibraryPageItem(
      id: detail.id,
      url: detail.url,
      title: detail.title,
      subtitle: detail.subtitle,
      faviconUrl: detail.faviconUrl,
      faviconFilePath: detail.faviconFilePath,
      bookmarkFolderPath: detail.bookmarkFolderPath,
      annotationPreview: null,
      annotationCount: detail.annotations.length,
      timestamp: DateTime.now(),
    ),
    fallbackIcon: CupertinoIcons.globe,
    fallbackColor: CupertinoColors.systemTeal,
  );
}

class _GroupedRows extends StatelessWidget {
  const _GroupedRows({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF151519),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
    ),
    child: Column(children: children),
  );
}

class _PlainActionRow extends StatelessWidget {
  const _PlainActionRow({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF26262C), width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.activeBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 15, letterSpacing: 0)),
          ),
          const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey2, size: 17),
        ],
      ),
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 42),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.search, size: 42, color: CupertinoColors.systemGrey),
        SizedBox(height: 14),
        Text(
          'No Matches',
          style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 42),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.book, size: 42, color: CupertinoColors.systemGrey),
        SizedBox(height: 14),
        Text(
          'No Saved Pages',
          style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Open a webpage in the browser tab to start reading and annotating.',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15, letterSpacing: 0, height: 1.25),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _EmptyAnnotations extends StatelessWidget {
  const _EmptyAnnotations();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 42),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.pencil, size: 42, color: CupertinoColors.systemGrey),
        SizedBox(height: 14),
        Text(
          'No Annotations',
          style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Annotations you add in the browser will appear here grouped by page.',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15, letterSpacing: 0, height: 1.25),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message});

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
