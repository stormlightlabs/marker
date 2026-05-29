import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/app/routes.dart';

void popOrGoNamed(BuildContext context, AppRoute fallbackRoute) {
  return (context.canPop()) ? context.pop() : context.goNamed(fallbackRoute.routeName);
}
