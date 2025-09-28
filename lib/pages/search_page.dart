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
    final double top = MediaQuery.of(context).viewPadding.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.search, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.add, color: Colors.white, size: 24),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: CustomScrollView(
              slivers: <Widget>[
                BluePullToRefresh(
                  backgroundColor: Colors.blue.shade600,
                  topRadius: 0,
                  onRefresh: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 800));
                  },
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewPadding.bottom + 16 + 72,
                    top: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(icon, size: 72),
                          const SizedBox(height: 12),
                          Text(title, style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


