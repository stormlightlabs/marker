import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:marker/src/app/app_tab_bar.dart';
import 'package:marker/src/app/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const CupertinoSliverNavigationBar(
                    largeTitle: Text('Settings'),
                    backgroundColor: CupertinoColors.black,
                    border: null,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF151519),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => context.pushNamed(AppRoute.history.routeName),
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(14, 12, 12, 12),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.clock, color: CupertinoColors.activeBlue, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Browser History',
                                        style: TextStyle(color: CupertinoColors.white, fontSize: 16, letterSpacing: 0),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Recent page visits and clear history',
                                        style: TextStyle(
                                          color: CupertinoColors.systemGrey,
                                          fontSize: 12,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey, size: 17),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const MarkerTabBar(activeRoute: AppRoute.settings),
          ],
        ),
      ),
    );
  }
}
