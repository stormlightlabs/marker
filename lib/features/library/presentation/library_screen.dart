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
  const _LibraryContent({required this.snapshot, required this.onOpenUrl, required this.onOpenAnnotation});

  final LibrarySnapshot snapshot;
  final ValueChanged<Uri> onOpenUrl;
  final ValueChanged<String> onOpenAnnotation;

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
            title: 'Recent Pages',
            pages: snapshot.recentPages,
            icon: CupertinoIcons.globe,
            accentColor: CupertinoColors.systemTeal,
            onOpenUrl: onOpenUrl,
          ),
          _AnnotationSection(annotations: snapshot.recentAnnotations, onOpenAnnotation: onOpenAnnotation),
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
  const _AnnotationSection({required this.annotations, required this.onOpenAnnotation});

  final List<LibraryAnnotationItem> annotations;
  final ValueChanged<String> onOpenAnnotation;

  @override
  Widget build(BuildContext context) {
    if (annotations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: _SectionFrame(
        title: 'Recent Annotations',
        children: [
          for (final annotation in annotations)
            _AnnotationRow(annotation: annotation, onPressed: () => onOpenAnnotation(annotation.id)),
        ],
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

    return _LibraryRowButton(
      onPressed: onPressed,
      leading: _LibraryIcon(icon: icon, color: accentColor),
      title: page.title,
      subtitle: '${page.subtitle} · $annotationText',
    );
  }
}

class _AnnotationRow extends StatelessWidget {
  const _AnnotationRow({required this.annotation, required this.onPressed});

  final LibraryAnnotationItem annotation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isNote = annotation.motivation == 'commenting';

    return _LibraryRowButton(
      onPressed: onPressed,
      leading: _LibraryIcon(
        icon: isNote ? CupertinoIcons.chat_bubble_text : CupertinoIcons.pencil,
        color: isNote ? CupertinoColors.activeBlue : CupertinoColors.systemYellow,
      ),
      title: annotation.motivation,
      subtitle: '${annotation.pageTitle} · "${annotation.excerpt}"',
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
