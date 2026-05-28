import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/app_transitions.dart';
import 'package:marker/app/routes.dart';
import 'package:marker/features/annotations/presentation/annotation_detail_screen.dart';
import 'package:marker/features/bookmarks/presentation/bookmarks_screen.dart';
import 'package:marker/features/browser/presentation/browser_screen.dart';
import 'package:marker/features/library/presentation/library_screen.dart';
import 'package:marker/features/settings/presentation/about_screen.dart';
import 'package:marker/features/settings/presentation/browser_history_screen.dart';
import 'package:marker/features/settings/presentation/logs_screen.dart';
import 'package:marker/features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoute.library.path,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoute.library.path),
      GoRoute(
        path: AppRoute.library.path,
        name: AppRoute.library.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(key: state.pageKey, child: const LibraryScreen()),
      ),
      GoRoute(
        path: AppRoute.browser.path,
        name: AppRoute.browser.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(key: state.pageKey, child: const BrowserScreen()),
      ),
      GoRoute(
        path: AppRoute.bookmarks.path,
        name: AppRoute.bookmarks.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(key: state.pageKey, child: const BookmarksScreen()),
      ),
      GoRoute(
        path: AppRoute.bookmarksExport.path,
        name: AppRoute.bookmarksExport.routeName,
        pageBuilder: (context, state) {
          final selected = state.uri.queryParametersAll['selected'];
          return MarkerTransitionPage<void>(
            key: state.pageKey,
            child: BookmarksExportScreen(selectedIds: selected?.isEmpty == true ? null : selected),
          );
        },
      ),
      GoRoute(
        path: AppRoute.bookmarksFolder.path,
        name: AppRoute.bookmarksFolder.routeName,
        pageBuilder: (context, state) {
          final folderId = state.pathParameters['id'] ?? '';
          return MarkerTransitionPage<void>(
            key: state.pageKey,
            child: BookmarksScreen(folderId: folderId),
          );
        },
      ),
      GoRoute(
        path: AppRoute.bookmarkEdit.path,
        name: AppRoute.bookmarkEdit.routeName,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MarkerTransitionPage<void>(
            key: state.pageKey,
            child: BookmarkEditScreen(id: id),
          );
        },
      ),
      GoRoute(
        path: AppRoute.bookmarkDetail.path,
        name: AppRoute.bookmarkDetail.routeName,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MarkerTransitionPage<void>(
            key: state.pageKey,
            child: BookmarkDetailScreen(id: id),
          );
        },
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoute.history.path,
        name: AppRoute.history.routeName,
        pageBuilder: (context, state) =>
            MarkerTransitionPage<void>(key: state.pageKey, child: const BrowserHistoryScreen()),
      ),
      GoRoute(
        path: AppRoute.logs.path,
        name: AppRoute.logs.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(key: state.pageKey, child: const LogsScreen()),
      ),
      GoRoute(
        path: AppRoute.about.path,
        name: AppRoute.about.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(key: state.pageKey, child: const AboutScreen()),
      ),
      GoRoute(
        path: AppRoute.annotations.path,
        name: AppRoute.annotations.routeName,
        pageBuilder: (context, state) =>
            MarkerTransitionPage<void>(key: state.pageKey, child: const AllAnnotationsScreen()),
      ),
      GoRoute(
        path: AppRoute.libraryPage.path,
        name: AppRoute.libraryPage.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(
          key: state.pageKey,
          child: LibraryPageDetailScreen(pageId: state.pathParameters['pageId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoute.annotationExport.path,
        name: AppRoute.annotationExport.routeName,
        pageBuilder: (context, state) {
          final selected = state.uri.queryParameters['selected'];
          return MarkerTransitionPage<void>(
            key: state.pageKey,
            child: AnnotationExportScreen(
              selectedIds: selected == null || selected.isEmpty ? null : selected.split(','),
              format: state.uri.queryParameters['format'] ?? 'markdown',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoute.annotation.path,
        name: AppRoute.annotation.routeName,
        pageBuilder: (context, state) => MarkerTransitionPage<void>(
          key: state.pageKey,
          child: AnnotationDetailScreen(annotationId: state.pathParameters['annotationId'] ?? ''),
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
