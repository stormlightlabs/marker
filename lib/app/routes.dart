enum AppRoute {
  library(path: '/library', routeName: 'library'),
  browser(path: '/browser', routeName: 'browser'),
  bookmarks(path: '/bookmarks', routeName: 'bookmarks'),
  bookmarksFolder(path: '/bookmarks/folder/:id', routeName: 'bookmarks-folder'),
  bookmarkDetail(path: '/bookmarks/:id', routeName: 'bookmark-detail'),
  bookmarkEdit(path: '/bookmarks/:id/edit', routeName: 'bookmark-edit'),
  bookmarksExport(path: '/bookmarks/export', routeName: 'bookmarks-export'),
  settings(path: '/settings', routeName: 'settings'),
  history(path: '/settings/history', routeName: 'history'),
  logs(path: '/settings/logs', routeName: 'logs'),
  annotation(path: '/annotations/:annotationId', routeName: 'annotation');

  const AppRoute({required this.path, required this.routeName});

  final String path;
  final String routeName;
}
