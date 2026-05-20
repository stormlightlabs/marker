import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/app/router.dart';

class MarkerApp extends ConsumerWidget {
  const MarkerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return CupertinoApp.router(
      title: 'Marker',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoColors.black,
      ),
    );
  }
}
