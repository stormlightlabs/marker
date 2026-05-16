enum AppRoute {
  library(path: '/library', routeName: 'library'),
  browser(path: '/browser', routeName: 'browser'),
  settings(path: '/settings', routeName: 'settings'),
  history(path: '/settings/history', routeName: 'history'),
  logs(path: '/settings/logs', routeName: 'logs'),
  annotation(path: '/annotations/:annotationId', routeName: 'annotation');

  const AppRoute({required this.path, required this.routeName});

  final String path;
  final String routeName;
}
