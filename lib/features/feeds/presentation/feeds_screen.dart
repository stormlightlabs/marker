import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material show Icons;
import 'package:marker/app/app_tab_bar.dart';
import 'package:marker/app/routes.dart';

class FeedsScreen extends StatelessWidget {
  const FeedsScreen({super.key});

  @override
  Widget build(BuildContext context) => const CupertinoPageScaffold(
    backgroundColor: CupertinoColors.black,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text('Feeds'),
                  backgroundColor: CupertinoColors.black,
                  border: null,
                ),
                SliverFillRemaining(hasScrollBody: false, child: _FeedsPlaceholder()),
              ],
            ),
          ),
          MarkerTabBar(activeRoute: AppRoute.feeds),
        ],
      ),
    ),
  );
}

class _FeedsPlaceholder extends StatelessWidget {
  const _FeedsPlaceholder();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(material.Icons.rss_feed, color: CupertinoColors.systemOrange, size: 42),
          SizedBox(height: 14),
          Text(
            'Feeds are coming soon',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'A home for RSS subscriptions and future feed work.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14, height: 1.35),
          ),
        ],
      ),
    ),
  );
}
