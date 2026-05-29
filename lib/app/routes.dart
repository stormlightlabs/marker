enum AppRoute {
  browser(path: '/browser', routeName: 'browser'),
  feeds(path: '/feeds', routeName: 'feeds'),
  bookmarks(path: '/bookmarks', routeName: 'bookmarks'),
  library(path: '/library', routeName: 'library'),
  bookmarksFolder(path: '/bookmarks/folder/:id', routeName: 'bookmarks-folder'),
  bookmarkDetail(path: '/bookmarks/:id', routeName: 'bookmark-detail'),
  bookmarkEdit(path: '/bookmarks/:id/edit', routeName: 'bookmark-edit'),
  bookmarksExport(path: '/bookmarks/export', routeName: 'bookmarks-export'),
  settings(path: '/settings', routeName: 'settings'),
  sync(path: '/settings/sync', routeName: 'sync'),
  history(path: '/settings/history', routeName: 'history'),
  logs(path: '/settings/logs', routeName: 'logs'),
  about(path: '/settings/about', routeName: 'about'),
  annotations(path: '/annotations', routeName: 'annotations'),
  libraryPage(path: '/library/pages/:pageId', routeName: 'library-page'),
  annotationExport(path: '/annotations/export', routeName: 'annotation-export'),
  annotation(path: '/annotations/:annotationId', routeName: 'annotation');

  const AppRoute({required this.path, required this.routeName});

  final String path;
  final String routeName;
}
