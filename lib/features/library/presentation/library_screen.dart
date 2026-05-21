import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/features/browser/application/reader_controller.dart';
import 'package:marker/features/library/data/library_repository.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(librarySnapshotProvider);

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
    required this.onOpenUrl,
    required this.onOpenAnnotation,
    required this.onOpenAnnotations,
  });

  final LibrarySnapshot snapshot;
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
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: CupertinoSearchTextField(
              enabled: false,
              placeholder: 'Search pages & annotations',
              backgroundColor: Color(0xFF1C1C20),
              style: TextStyle(color: CupertinoColors.white, letterSpacing: 0),
              placeholderStyle: TextStyle(color: CupertinoColors.systemGrey, letterSpacing: 0),
            ),
          ),
        ),
        if (snapshot.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyLibrary())
        else ...[
          _LibraryPageSection(
            title: 'Bookmarks',
            pages: snapshot.bookmarkedPages,
            icon: CupertinoIcons.bookmark_fill,
            accentColor: CupertinoColors.activeBlue,
            onOpenUrl: onOpenUrl,
          ),
          _LibraryPageSection(
            title: 'Recently Annotated',
            pages: snapshot.recentPages,
            icon: CupertinoIcons.globe,
            accentColor: CupertinoColors.systemTeal,
            onOpenUrl: onOpenUrl,
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
}

class _LibraryPageSection extends StatelessWidget {
  const _LibraryPageSection({
    required this.title,
    required this.pages,
    required this.icon,
    required this.accentColor,
    required this.onOpenUrl,
  });

  final String title;
  final List<LibraryPageItem> pages;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<Uri> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: _SectionFrame(
        title: title,
        children: [
          for (final page in pages)
            _PageRow(page: page, icon: icon, accentColor: accentColor, onPressed: () => onOpenUrl(page.url)),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    if (annotations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
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
}

class AllAnnotationsScreen extends ConsumerWidget {
  const AllAnnotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(allAnnotationGroupsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: groups.when(
          data: (items) => _AllAnnotationsContent(
            groups: items,
            onOpenUrl: (url) => _openInBrowser(context, ref, url),
            onOpenAnnotation: (annotationId) => _openAnnotation(context, annotationId),
          ),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => _LibraryError(message: error.toString()),
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

class _AllAnnotationsContent extends StatelessWidget {
  const _AllAnnotationsContent({required this.groups, required this.onOpenUrl, required this.onOpenAnnotation});

  final List<LibraryAnnotationGroup> groups;
  final ValueChanged<Uri> onOpenUrl;
  final ValueChanged<String> onOpenAnnotation;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Annotations'),
          backgroundColor: CupertinoColors.black,
          border: null,
          previousPageTitle: 'Library',
        ),
        if (groups.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyAnnotations())
        else ...[
          for (final group in groups)
            SliverToBoxAdapter(
              child: _LibraryGroupFrame(
                children: [
                  _AnnotationPageRow(group: group, onPressed: () => onOpenUrl(group.url)),
                  for (final annotation in group.annotations)
                    _AnnotationRow(annotation: annotation, onPressed: () => onOpenAnnotation(annotation.id)),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
        ],
      ],
    );
  }
}

class _LibraryGroupFrame extends StatelessWidget {
  const _LibraryGroupFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
  Widget build(BuildContext context) {
    return _LibraryRowButton(
      onPressed: onPressed,
      leading: const _LibraryIcon(icon: CupertinoIcons.book, color: CupertinoColors.systemPurple),
      title: 'All Annotations',
      subtitle: 'Browse every highlight and note',
    );
  }
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
  const _AnnotationRow({required this.annotation, required this.onPressed});

  final LibraryAnnotationItem annotation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _LibraryRowButton(
      onPressed: onPressed,
      leading: _LibraryIcon(
        icon: annotation.motivation == 'commenting' ? CupertinoIcons.chat_bubble_text : CupertinoIcons.pencil,
        color: annotation.motivation == 'commenting' ? CupertinoColors.activeBlue : CupertinoColors.systemYellow,
      ),
      title: annotation.excerpt,
      subtitle: annotation.pageTitle,
    );
  }
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
  Widget build(BuildContext context) {
    return CupertinoButton(
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
}

class _LibraryIcon extends StatelessWidget {
  const _LibraryIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 19),
    );
  }
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
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xFF24242A), borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
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

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Padding(
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
}

class _EmptyAnnotations extends StatelessWidget {
  const _EmptyAnnotations();

  @override
  Widget build(BuildContext context) {
    return const Padding(
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
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message});

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
