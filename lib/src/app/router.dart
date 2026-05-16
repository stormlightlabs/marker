import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/src/app/app_transitions.dart';
import 'package:marker/src/app/routes.dart';
import 'package:marker/src/features/annotations/presentation/annotation_detail_screen.dart';
import 'package:marker/src/features/browser/presentation/browser_screen.dart';
import 'package:marker/src/features/library/presentation/library_screen.dart';
import 'package:marker/src/features/settings/presentation/browser_history_screen.dart';
import 'package:marker/src/features/settings/presentation/logs_screen.dart';
import 'package:marker/src/features/settings/presentation/settings_screen.dart';

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
        path: AppRoute.annotation.path,
        name: AppRoute.annotation.routeName,
        pageBuilder: (context, state) {
          final annotationId = state.pathParameters['annotationId'] ?? '';
          return MarkerTransitionPage<void>(
            key: state.pageKey,
            child: AnnotationDetailScreen(annotationId: annotationId),
          );
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
