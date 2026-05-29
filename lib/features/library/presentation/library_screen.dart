import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/core/logging/app_logger.dart';
import 'package:marker/core/widgets/funnotation.dart';
import 'package:marker/features/annotations/data/annotation_repository.dart';
import 'package:marker/features/atproto/application/bookmark_import_controller.dart';
import 'package:marker/features/atproto/data/atproto_auth_repository.dart';
import 'package:marker/features/atproto/data/atproto_sync_constants.dart';
import 'package:marker/features/atproto/data/atproto_sync_repository.dart';
import 'package:marker/features/atproto/domain/atproto_account_session.dart';
import 'package:marker/features/atproto/presentation/sync_state_badge.dart';
import 'package:marker/features/browser/application/reader_controller.dart';
import 'package:marker/features/browser/presentation/note_editor_sheet.dart';
import 'package:marker/features/library/data/library_refresh.dart';
import 'package:marker/features/library/data/library_repository.dart';
import 'package:marker/features/library/data/library_search_repository.dart';
import 'package:marker/shared/widgets/marker_list_widgets.dart';

final _annotationSyncStatusProvider = FutureProvider.autoDispose
    .family<AtprotoLocalSyncStatus, ({String accountDid, String annotationId})>((ref, args) async {
      final statuses = await ref
          .watch(atprotoSyncRepositoryProvider)
          .localSyncStatuses(
            accountDid: args.accountDid,
            localTable: AtprotoSyncLocalTable.annotations.value,
            collection: MarginSyncCollection.note.value,
            localIds: [args.annotationId],
          );
      return statuses[args.annotationId] ?? AtprotoLocalSyncStatus.localOnly;
    });

enum LibraryAnnotationFilter {
  all('All'),
  highlights('Highlights'),
  notes('Notes'),
  underlines('Underlines');

  const LibraryAnnotationFilter(this.label);

  final String label;

  LibraryAnnotationQueryFilter get queryFilter => switch (this) {
    LibraryAnnotationFilter.all => LibraryAnnotationQueryFilter.all,
    LibraryAnnotationFilter.highlights => LibraryAnnotationQueryFilter.highlights,
    LibraryAnnotationFilter.notes => LibraryAnnotationQueryFilter.notes,
    LibraryAnnotationFilter.underlines => LibraryAnnotationQueryFilter.underlines,
  };

  bool matches(LibraryAnnotationItem annotation) => switch (this) {
    LibraryAnnotationFilter.all => true,
    LibraryAnnotationFilter.highlights =>
      !annotation.isNote && annotation.visualStyle == AnnotationVisualStyle.highlight,
    LibraryAnnotationFilter.notes => annotation.isNote,
    LibraryAnnotationFilter.underlines => annotation.visualStyle == AnnotationVisualStyle.underline,
  };
}

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
                  onRefresh: _refreshLibrary,
                  onOpenPage: (id) => context.pushNamed(AppRoute.libraryPage.routeName, pathParameters: {'pageId': id}),
                  onOpenUrl: (url) => _openInBrowser(context, ref, url),
                  onOpenAnnotation: (annotationId) => _openAnnotation(context, annotationId),
                  onOpenBookmarks: () => context.pushNamed(AppRoute.bookmarks.routeName),
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

  Future<void> _refreshLibrary() async {
    invalidateLibraryWidgetData(ref);
    await ref.read(librarySnapshotProvider.future);
    if (_query.trim().isNotEmpty) {
      await ref.read(librarySearchProvider(_query).future);
    }
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

class _LibraryContent extends ConsumerWidget {
  const _LibraryContent({
    required this.snapshot,
    required this.query,
    required this.searchController,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onOpenPage,
    required this.onOpenUrl,
    required this.onOpenAnnotation,
    required this.onOpenBookmarks,
    required this.onOpenAnnotations,
  });

  final LibrarySnapshot snapshot;
  final String query;
  final TextEditingController searchController;
  final AsyncValue<List<LibrarySearchResult>>? searchResults;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onOpenPage;
  final ValueChanged<Uri> onOpenUrl;
  final ValueChanged<String> onOpenAnnotation;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenAnnotations;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      CupertinoSliverNavigationBar(
        largeTitle: Row(
          children: [
            const Expanded(child: Text('Library')),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(34),
              onPressed: () => _showLibraryMenu(context, ref),
              child: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
            ),
          ],
        ),
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      CupertinoSliverRefreshControl(onRefresh: onRefresh),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: CupertinoSearchTextField(
            controller: searchController,
            onChanged: onSearchChanged,
            placeholder: 'Search bookmarks & annotations',
            backgroundColor: const Color(0xFF1C1C20),
            style: const TextStyle(color: CupertinoColors.white, letterSpacing: 0),
            placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, letterSpacing: 0),
          ),
        ),
      ),
      if (query.trim().isNotEmpty) ..._searchSlivers() else ..._librarySlivers(),
    ],
  );

  Future<void> _showLibraryMenu(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(atprotoAuthRepositoryProvider).state;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Library'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              if (authState case AtprotoAuthConnected(:final account)) {
                await ref.read(atprotoBookmarkImportControllerProvider.notifier).syncBookmarks(account.did);
                return;
              }
              if (context.mounted) await context.pushNamed(AppRoute.sync.routeName);
            },
            child: Text(authState is AtprotoAuthConnected ? 'Sync now' : 'Connect sync account'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await context.pushNamed(AppRoute.sync.routeName);
            },
            child: const Text('Sync settings'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  List<Widget> _librarySlivers() {
    if (snapshot.isEmpty) {
      return const [SliverFillRemaining(hasScrollBody: false, child: _EmptyLibrary())];
    }
    return [
      _LibraryPageSection(
        title: 'Bookmarks',
        pages: snapshot.bookmarkedPages,
        icon: CupertinoIcons.bookmark_fill,
        accentColor: CupertinoColors.activeBlue,
        onOpenPage: onOpenPage,
        onShowAll: onOpenBookmarks,
      ),
      _AnnotationSection(
        annotations: snapshot.recentAnnotations,
        onOpenAnnotation: onOpenAnnotation,
        onOpenAnnotations: onOpenAnnotations,
      ),
      _LibraryPageSection(
        title: 'Recently Annotated',
        pages: snapshot.recentPages,
        icon: CupertinoIcons.globe,
        accentColor: CupertinoColors.systemTeal,
        onOpenPage: onOpenPage,
        onShowAll: snapshot.recentPages.length > _librarySectionPreviewLimit ? onOpenAnnotations : null,
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
    ];
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
            child: MarkerSectionFrame(
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

const int _librarySectionPreviewLimit = 5;

class _LibraryPageSection extends StatelessWidget {
  const _LibraryPageSection({
    required this.title,
    required this.pages,
    required this.icon,
    required this.accentColor,
    required this.onOpenPage,
    required this.onShowAll,
  });

  final String title;
  final List<LibraryPageItem> pages;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<String> onOpenPage;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) => pages.isEmpty
      ? const SliverToBoxAdapter(child: SizedBox.shrink())
      : SliverToBoxAdapter(
          child: MarkerSectionFrame(
            title: title,
            children: [
              for (final page in pages.take(_librarySectionPreviewLimit))
                _PageRow(page: page, icon: icon, accentColor: accentColor, onPressed: () => onOpenPage(page.id)),
              if (onShowAll != null) _ShowAllRow(onPressed: onShowAll!),
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
          child: MarkerSectionFrame(
            title: 'Recent Annotations',
            children: [
              for (final annotation in annotations.take(_librarySectionPreviewLimit))
                _AnnotationRow(annotation: annotation, onPressed: () => onOpenAnnotation(annotation.id)),
              _ShowAllRow(onPressed: onOpenAnnotations),
            ],
          ),
        );
}

class AllAnnotationsScreen extends ConsumerStatefulWidget {
  const AllAnnotationsScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  ConsumerState<AllAnnotationsScreen> createState() => _AllAnnotationsScreenState();
}

class _AllAnnotationsScreenState extends ConsumerState<AllAnnotationsScreen> {
  final Set<String> _selectedIds = <String>{};
  List<LibraryAnnotationGroup> _groups = const [];
  LibraryAnnotationCursor? _nextCursor;
  LibraryAnnotationFilter _filter = LibraryAnnotationFilter.all;
  Object? _error;
  Object? _loadMoreError;
  bool _isEditing = false;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_reloadAnnotations);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: _buildBody(context)),
            if (_isEditing)
              _AnnotationEditBar(
                selectedCount: _selectedIds.length,
                onEdit: _selectedIds.length == 1 ? () => _editSelectedNote(_selectedIds.single) : null,
                onExportMarkdown: _selectedIds.isEmpty ? null : () => _openExport(context, _selectedIds, 'markdown'),
                onExportJson: _selectedIds.isEmpty ? null : () => _openExport(context, _selectedIds, 'json'),
                onSync: _selectedIds.isEmpty ? null : () => _syncSelected(context),
                onDelete: _selectedIds.isEmpty ? null : () => _deleteSelected(),
              )
            else
              const MarkerTabBar(activeRoute: AppRoute.annotations),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoadingInitial) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final error = _error;
    if (error != null) {
      return _LibraryError(message: error.toString());
    }
    return _AllAnnotationsContent(
      embedded: widget.embedded,
      groups: _groups,
      filter: _filter,
      isEditing: _isEditing,
      selectedIds: _selectedIds,
      hasMore: _hasMore,
      isLoadingMore: _isLoadingMore,
      loadMoreError: _loadMoreError?.toString(),
      onFilterChanged: _changeFilter,
      onToggleEditing: () => setState(() {
        _isEditing = !_isEditing;
        _selectedIds.clear();
      }),
      onExportAll: () => _openExport(context, null, 'markdown'),
      onOpenPage: (id) => context.pushNamed(AppRoute.libraryPage.routeName, pathParameters: {'pageId': id}),
      onOpenAnnotation: (annotationId) => _openAnnotation(context, annotationId),
      onToggleSelection: _toggleSelection,
      onShowMore: _loadMoreAnnotations,
    );
  }

  Future<void> _reloadAnnotations() async {
    if (!mounted) {
      return;
    }
    final repository = ref.read(libraryRepositoryProvider);
    final logger = ref.read(appLoggerProvider);
    final generation = ++_requestGeneration;
    setState(() {
      _isLoadingInitial = true;
      _isLoadingMore = false;
      _error = null;
      _loadMoreError = null;
      _nextCursor = null;
      _hasMore = false;
    });

    try {
      final page = await repository.loadAnnotationGroupsPage(limit: _annotationsPageSize, filter: _filter.queryFilter);
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _groups = page.groups;
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _isLoadingInitial = false;
      });
      unawaited(_refreshLoadedFavicons(page.groups));
    } on Object catch (error, stackTrace) {
      logger.error('Failed to load annotation page.', error: error, stackTrace: stackTrace);
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _error = error;
        _groups = const [];
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _loadMoreAnnotations() async {
    final cursor = _nextCursor;
    if (_isLoadingMore || !_hasMore || cursor == null) {
      return;
    }
    final repository = ref.read(libraryRepositoryProvider);
    final logger = ref.read(appLoggerProvider);
    final generation = _requestGeneration;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final page = await repository.loadAnnotationGroupsPage(
        limit: _annotationsPageSize,
        filter: _filter.queryFilter,
        cursor: cursor,
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _groups = _mergeAnnotationGroups(_groups, page.groups);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
      unawaited(_refreshLoadedFavicons(page.groups));
    } on Object catch (error, stackTrace) {
      logger.error('Failed to load more annotations.', error: error, stackTrace: stackTrace);
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _loadMoreError = error;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshLoadedFavicons(List<LibraryAnnotationGroup> groups) async {
    final repository = ref.read(libraryRepositoryProvider);
    final logger = ref.read(appLoggerProvider);
    try {
      await repository.refreshMissingFaviconsForPageIds(groups.map((group) => group.id));
    } on Object catch (error, stackTrace) {
      logger.debug('Failed to refresh annotation page favicons.', error: error, stackTrace: stackTrace);
    }
  }

  void _changeFilter(LibraryAnnotationFilter value) {
    if (_filter == value) {
      return;
    }
    setState(() {
      _filter = value;
      _selectedIds.clear();
    });
    unawaited(_reloadAnnotations());
  }

  List<LibraryAnnotationGroup> _mergeAnnotationGroups(
    List<LibraryAnnotationGroup> existing,
    List<LibraryAnnotationGroup> incoming,
  ) {
    final merged = existing.toList(growable: true);
    for (final group in incoming) {
      final index = merged.indexWhere((candidate) => candidate.url == group.url);
      if (index == -1) {
        merged.add(group);
        continue;
      }
      final current = merged[index];
      final annotationsById = <String, LibraryAnnotationItem>{
        for (final annotation in current.annotations) annotation.id: annotation,
        for (final annotation in group.annotations) annotation.id: annotation,
      };
      final annotations = annotationsById.values.toList(growable: false)..sort(_compareAnnotationsBySource);
      merged[index] = LibraryAnnotationGroup(
        id: current.id,
        url: current.url,
        title: current.title,
        subtitle: current.subtitle,
        faviconUrl: current.faviconUrl,
        faviconFilePath: current.faviconFilePath ?? group.faviconFilePath,
        bookmarkFolderPath: current.bookmarkFolderPath ?? group.bookmarkFolderPath,
        annotations: annotations,
      );
    }
    return merged;
  }

  int _compareAnnotationsBySource(LibraryAnnotationItem a, LibraryAnnotationItem b) {
    if (a.isMarginBacked != b.isMarginBacked) {
      return a.isMarginBacked ? -1 : 1;
    }
    return b.modifiedAt.compareTo(a.modifiedAt);
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

  Future<void> _syncSelected(BuildContext context) async {
    final state = ref.read(atprotoAuthRepositoryProvider).state;
    if (state is! AtprotoAuthConnected) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Connect ATProto'),
          content: const Text('Connect an ATProto account before selecting annotations for sync.'),
          actions: [CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    final action = await _chooseSyncSelectionAction(context, 'Annotations');
    if (action == null || !mounted) return;
    final sync = ref.read(atprotoSyncRepositoryProvider);
    for (final annotationId in _selectedIds) {
      if (action == _SyncSelectionAction.keepSynced) {
        await sync.selectForSync(
          accountDid: state.account.did,
          localTable: AtprotoSyncLocalTable.annotations.value,
          localId: annotationId,
          collection: MarginSyncCollection.note.value,
        );
      } else {
        await sync.deselectForSync(
          accountDid: state.account.did,
          localTable: AtprotoSyncLocalTable.annotations.value,
          localId: annotationId,
          collection: MarginSyncCollection.note.value,
          deleteRemote: action == _SyncSelectionAction.stopAndDeleteRemote,
        );
      }
    }
    if (mounted) setState(_selectedIds.clear);
  }

  void _openExport(BuildContext context, Iterable<String>? selectedIds, String format) {
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
        content: Text('Delete $_selectedIds.length selected annotation(s)?'),
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
    unawaited(_reloadAnnotations());
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
    unawaited(_reloadAnnotations());
  }
}

const int _annotationsPageSize = 100;

class _AllAnnotationsContent extends StatelessWidget {
  const _AllAnnotationsContent({
    required this.embedded,
    required this.groups,
    required this.filter,
    required this.isEditing,
    required this.selectedIds,
    required this.hasMore,
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onFilterChanged,
    required this.onToggleEditing,
    required this.onExportAll,
    required this.onOpenPage,
    required this.onOpenAnnotation,
    required this.onToggleSelection,
    required this.onShowMore,
  });

  final bool embedded;
  final List<LibraryAnnotationGroup> groups;
  final LibraryAnnotationFilter filter;
  final bool isEditing;
  final Set<String> selectedIds;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;
  final ValueChanged<LibraryAnnotationFilter> onFilterChanged;
  final VoidCallback onToggleEditing;
  final VoidCallback onExportAll;
  final ValueChanged<String> onOpenPage;
  final ValueChanged<String> onOpenAnnotation;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Funnotation(color: CupertinoColors.activeBlue, child: Text('Annotations')),
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
            SliverToBoxAdapter(
              child: MarkerGroupFrame(
                children: [
                  _AnnotationPageRow(group: group, onPressed: () => onOpenPage(group.id)),
                  for (final entry in _annotationSectionEntries(group.annotations))
                    if (entry.label != null)
                      _AnnotationSourceHeader(label: entry.label!, isMargin: entry.annotation.isMarginBacked)
                    else
                      _AnnotationRow(
                        annotation: entry.annotation,
                        isEditing: isEditing,
                        isSelected: selectedIds.contains(entry.annotation.id),
                        onPressed: () =>
                            isEditing ? onToggleSelection(entry.annotation.id) : onOpenAnnotation(entry.annotation.id),
                      ),
                ],
              ),
            ),
          if (loadMoreError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                  loadMoreError!,
                  style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13, letterSpacing: 0),
                ),
              ),
            ),
          if (hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: CupertinoButton.filled(
                  onPressed: isLoadingMore ? null : onShowMore,
                  child: Text(isLoadingMore ? 'Loading…' : 'Load More'),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
        ],
      ],
    );
  }

  List<_AnnotationSectionEntry> _annotationSectionEntries(List<LibraryAnnotationItem> annotations) {
    return [
      for (final (index, annotation) in annotations.indexed)
        _AnnotationSectionEntry(
          annotation: annotation,
          label: index == 0 || annotations[index - 1].isMarginBacked != annotation.isMarginBacked
              ? (annotation.isMarginBacked ? 'Margin' : 'Local')
              : null,
        ),
    ];
  }
}

class _AnnotationSectionEntry {
  const _AnnotationSectionEntry({required this.annotation, required this.label});

  final LibraryAnnotationItem annotation;
  final String? label;
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
    return MarkerRowButton(
      onPressed: onPressed,
      leading: MarkerFileFavicon(
        filePath: page.faviconFilePath,
        fallbackHost: page.subtitle,
        fallbackIcon: icon,
        fallbackColor: accentColor,
      ),
      title: _titleWithBookmarkFolder(page.title, page.bookmarkFolderPath),
      subtitle: preview == null
          ? '${page.subtitle} · $annotationText'
          : '${page.subtitle} · $annotationText · "$preview"',
    );
  }
}

class _ShowAllRow extends StatelessWidget {
  const _ShowAllRow({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MarkerRowButton(
    onPressed: onPressed,
    leading: const MarkerIconTile(icon: CupertinoIcons.ellipsis_vertical, color: CupertinoColors.systemPurple),
    title: 'Show All',
    subtitle: 'Open the full section',
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

    return MarkerRowButton(
      onPressed: onPressed,
      leading: MarkerFileFavicon(
        filePath: group.faviconFilePath,
        fallbackHost: group.subtitle,
        fallbackIcon: CupertinoIcons.globe,
        fallbackColor: CupertinoColors.systemTeal,
      ),
      title: _titleWithBookmarkFolder(group.title, bookmarkFolderPath),
      subtitle: '${group.subtitle} · $annotationText',
    );
  }
}

class _AnnotationRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(atprotoAuthRepositoryProvider).state;
    final syncState = authState is AtprotoAuthConnected
        ? SyncRecordState.fromAtproto(
            ref
                    .watch(
                      _annotationSyncStatusProvider((accountDid: authState.account.did, annotationId: annotation.id)),
                    )
                    .value ??
                AtprotoLocalSyncStatus.localOnly,
          )
        : SyncRecordState.localOnly;
    return MarkerRowButton(
      onPressed: onPressed,
      leading: isEditing ? _SelectionDot(isSelected: isSelected) : _AnnotationSourceIcon(annotation: annotation),
      title: annotation.excerpt,
      subtitle:
          '${annotation.typeLabel} · ${annotation.pageTitle} · Source: ${annotation.isMarginBacked ? 'Margin' : 'Local'}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SyncStateBadge(state: syncState),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey2, size: 17),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.result, required this.onPressed});

  final LibrarySearchResult result;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MarkerRowButton(
    onPressed: onPressed,
    leading: MarkerIconTile(
      icon: result.type == LibrarySearchResultType.annotation ? CupertinoIcons.pencil : CupertinoIcons.doc_text,
      color: result.type == LibrarySearchResultType.annotation
          ? CupertinoColors.systemYellow
          : CupertinoColors.activeBlue,
    ),
    title: result.title,
    titleWidget: Funnotation(
      color: CupertinoColors.systemYellow.withValues(alpha: 0.28),
      padding: 2,
      child: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
    subtitle: result.subtitle,
  );
}

class _AnnotationSourceHeader extends StatelessWidget {
  const _AnnotationSourceHeader({required this.label, required this.isMargin});

  final String label;
  final bool isMargin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    child: Row(
      children: [
        if (isMargin)
          SvgPicture.asset('assets/icons/margin.svg', width: 16, height: 16)
        else
          const Icon(CupertinoIcons.device_phone_portrait, color: CupertinoColors.systemGrey2, size: 15),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

class _AnnotationSourceIcon extends StatelessWidget {
  const _AnnotationSourceIcon({required this.annotation});

  final LibraryAnnotationItem annotation;

  @override
  Widget build(BuildContext context) {
    if (annotation.isMarginBacked) {
      return MarkerIconTile(
        icon: CupertinoIcons.doc_text,
        color: CupertinoColors.activeBlue,
        opacity: 0.18,
        child: Padding(padding: const EdgeInsets.all(8), child: SvgPicture.asset('assets/icons/margin.svg')),
      );
    }
    return MarkerIconTile(
      icon: annotation.isNote ? CupertinoIcons.chat_bubble_text : CupertinoIcons.pencil,
      color: annotation.isNote ? CupertinoColors.activeBlue : CupertinoColors.systemYellow,
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

String _titleWithBookmarkFolder(String title, String? bookmarkFolderPath) {
  return bookmarkFolderPath == null ? title : '$title · $bookmarkFolderPath';
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
                        onKeepPageSynced: () => _syncPageAnnotations(value.pageId),
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
                onSync: _selectedIds.isEmpty ? null : _syncSelected,
                onDelete: _selectedIds.isEmpty ? null : _deleteSelected,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String annotationId) => setState(() {
    if (!_selectedIds.add(annotationId)) {
      _selectedIds.remove(annotationId);
    }
  });

  void _openInBrowser(Uri url) {
    ref.read(readerControllerProvider.notifier).setUrlText(url.toString());
    context.goNamed(AppRoute.browser.routeName);
  }

  Future<void> _syncPageAnnotations(String? pageId) async {
    if (pageId == null) return;
    final state = ref.read(atprotoAuthRepositoryProvider).state;
    if (state is! AtprotoAuthConnected) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Connect ATProto'),
          content: const Text('Connect an ATProto account before keeping page annotations synced.'),
          actions: [CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    await ref.read(atprotoSyncRepositoryProvider).selectAnnotationsForPageForSync(state.account.did, pageId);
    ref.invalidate(libraryPageDetailProvider(widget.pageId));
    ref.invalidate(allAnnotationGroupsProvider);
    ref.invalidate(librarySnapshotProvider);
  }

  Future<void> _syncSelected() async {
    final state = ref.read(atprotoAuthRepositoryProvider).state;
    if (state is! AtprotoAuthConnected) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Connect ATProto'),
          content: const Text('Connect an ATProto account before selecting annotations for sync.'),
          actions: [CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    final sync = ref.read(atprotoSyncRepositoryProvider);
    for (final annotationId in _selectedIds) {
      await sync.selectForSync(
        accountDid: state.account.did,
        localTable: AtprotoSyncLocalTable.annotations.value,
        localId: annotationId,
        collection: MarginSyncCollection.note.value,
      );
    }
    if (mounted) setState(_selectedIds.clear);
  }

  void _openExport(Iterable<String>? selectedIds, String format) => context.pushNamed(
    AppRoute.annotationExport.routeName,
    queryParameters: {'format': format, if (selectedIds != null) 'selected': selectedIds.join(',')},
  );

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
    required this.onKeepPageSynced,
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
  final VoidCallback onKeepPageSynced;
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
            _PlainActionRow(
              icon: CupertinoIcons.cloud_upload,
              label: 'Keep page annotations synced',
              onPressed: onKeepPageSynced,
            ),
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
          MarkerGroupFrame(
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

enum _SyncSelectionAction { keepSynced, stopOnly, stopAndDeleteRemote }

Future<_SyncSelectionAction?> _chooseSyncSelectionAction(BuildContext context, String title) {
  return showCupertinoModalPopup<_SyncSelectionAction>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text('Selected $title'),
      message: const Text('Keep these items continuously synced, or stop syncing future changes.'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(_SyncSelectionAction.keepSynced),
          child: const Text('Keep synced'),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(_SyncSelectionAction.stopOnly),
          child: const Text('Stop syncing'),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(_SyncSelectionAction.stopAndDeleteRemote),
          child: const Text('Delete synced copies…'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
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
              child: Text(
                candidate.label,
                style: TextStyle(
                  color: filter == candidate ? CupertinoColors.white : CupertinoColors.activeBlue,
                  fontSize: 13,
                  letterSpacing: 0,
                ),
              ),
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
    required this.onSync,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback? onEdit;
  final VoidCallback? onExportMarkdown;
  final VoidCallback? onExportJson;
  final VoidCallback? onSync;
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
              onPressed: onSync,
              child: const Text('Sync'),
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
  Widget build(BuildContext context) => MarkerFileFavicon(
    filePath: detail.faviconFilePath,
    fallbackHost: detail.subtitle,
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
        Funnotation(
          child: Text(
            'No Matches',
            style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0),
            textAlign: TextAlign.center,
          ),
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
        Funnotation(
          child: Text(
            'No Saved Pages',
            style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0),
            textAlign: TextAlign.center,
          ),
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
        Funnotation(
          child: Text(
            'No Annotations',
            style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0),
            textAlign: TextAlign.center,
          ),
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
