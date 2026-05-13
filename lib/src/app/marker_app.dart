import 'package:flutter/cupertino.dart';
import 'package:marker/src/features/browser/presentation/browser_screen.dart';

class MarkerApp extends StatelessWidget {
  const MarkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Marker',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: BrowserScreen(),
    );
  }
}
