enum AppRoute {
  library(path: '/library', routeName: 'library'),
  browser(path: '/browser', routeName: 'browser'),
  annotation(path: '/annotations/:annotationId', routeName: 'annotation');

  const AppRoute({required this.path, required this.routeName});

  final String path;
  final String routeName;
}
