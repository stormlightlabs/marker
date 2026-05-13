enum AppRoute {
  browser(path: '/browser', routeName: 'browser');

  const AppRoute({required this.path, required this.routeName});

  final String path;
  final String routeName;
}
