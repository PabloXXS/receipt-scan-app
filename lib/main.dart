import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const TicketApp());
}

class TicketApp extends StatelessWidget {
  const TicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    SearchPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final double extraBottomPadding = bottomInset > 0 ? 8.0 : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: true,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: extraBottomPadding + 8),
        child: _RoundedBottomBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            items: const <_BottomItem>[
              _BottomItem(icon: Icons.list_alt_rounded, label: 'Список'),
              _BottomItem(icon: Icons.camera_alt_rounded, label: 'Камера'),
              _BottomItem(icon: Icons.settings_rounded, label: 'Настройки'),
            ],
          ),
      ),
    );
  }
}

class _BottomItem {
  const _BottomItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _RoundedBottomBar extends StatelessWidget {
  const _RoundedBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final List<_BottomItem> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(items.length, (int i) {
            final bool selected = i == currentIndex;
            final Color iconColor = selected ? Colors.white : Colors.white70;
            final Color textColor = selected ? Colors.white : Colors.white70;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(items[i].icon, color: iconColor),
                      const SizedBox(height: 6),
                      Text(
                        items[i].label,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

