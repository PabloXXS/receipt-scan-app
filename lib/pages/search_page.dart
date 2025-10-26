import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/sliver_pull_to_refresh.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Content(title: 'Камера', icon: Icons.camera_alt);
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            trailing: const Icon(CupertinoIcons.add),
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          ),
          BluePullToRefresh(
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            topRadius: 0,
            onRefresh: () async {
              await Future<void>.delayed(
                  const Duration(milliseconds: 800));
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + 72,
              top: 16,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 72),
                    const SizedBox(height: 12),
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
