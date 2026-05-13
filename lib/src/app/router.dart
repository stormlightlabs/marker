import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/src/app/routes.dart';
import 'package:marker/src/features/browser/presentation/browser_screen.dart';
import 'package:marker/src/features/library/presentation/library_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoute.library.path,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoute.library.path),
      GoRoute(
        path: AppRoute.library.path,
        name: AppRoute.library.routeName,
        pageBuilder: (context, state) => const CupertinoPage<void>(child: LibraryScreen()),
      ),
      GoRoute(
        path: AppRoute.browser.path,
        name: AppRoute.browser.routeName,
        pageBuilder: (context, state) => const CupertinoPage<void>(child: BrowserScreen()),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
