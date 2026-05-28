import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marker/app/router.dart';
import 'package:marker/features/browser/application/browser_engine_warmup.dart';
import 'package:marker/features/settings/data/settings_repository.dart';

class MarkerApp extends ConsumerStatefulWidget {
  const MarkerApp({super.key});

  @override
  ConsumerState<MarkerApp> createState() => _MarkerAppState();
}

class _MarkerAppState extends ConsumerState<MarkerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(browserEngineWarmupProvider).warmUp());
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final funEnabled = ref.watch(funEnabledProvider).value ?? true;
    return CupertinoApp.router(
      title: 'Marker',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoColors.black,
        textTheme: funEnabled
            ? CupertinoTextThemeData(
                navLargeTitleTextStyle: GoogleFonts.slacksideOne(
                  color: CupertinoColors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                navTitleTextStyle: GoogleFonts.slacksideOne(
                  color: CupertinoColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              )
            : const CupertinoTextThemeData(),
      ),
    );
  }
}
